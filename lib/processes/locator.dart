import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';


late final GeoLocator geo;

/// Manages GeoJSON polygons (barangays) and queries which one contains a point
class GeoLocator {
  final QuadTree _barangays;

  GeoLocator(this._barangays);

  /// Load and index barangay polygons into a quadtree
  static Future<GeoLocator> loadFromAssets(String path) async {
    debugPrint("Loading barangay GeoJSON...");
    final tree = await _loadGeoJsonToQuadTree(path);
    debugPrint("Barangay GeoJSON loaded.");
    return GeoLocator(tree);
  }

  /// Query which barangay (and its higher data) a point is inside
  Map<String, dynamic>? query(LatLng point) {
    for (final p in _barangays.query(point)) {
      if (pointInPolygon(point, p.points)) {
        return p.properties; // Contains barangay, city, province, region
      }
    }
    return null;
  }
}

/// A polygon and its bounding box
class PolygonBox {
  final Map<String, dynamic> properties;
  final List<LatLng> points;
  late final double minLat, maxLat, minLng, maxLng;

  PolygonBox(this.properties, this.points) {
    minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    minLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    maxLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
  }

  /// Looser bounding-box check with epsilon tolerance to avoid missing edges
  bool contains(LatLng point) {
    const epsilon = 1e-6; // ~11cm margin
    return point.latitude >= minLat - epsilon &&
           point.latitude <= maxLat + epsilon &&
           point.longitude >= minLng - epsilon &&
           point.longitude <= maxLng + epsilon;
  }
}


/// A rectangular area for quadtree partitioning
class QuadRect {
  final double x, y, w, h;
  QuadRect(this.x, this.y, this.w, this.h);

  bool intersects(QuadRect other) =>
      !(other.x - other.w > x + w ||
        other.x + other.w < x - w ||
        other.y - other.h > y + h ||
        other.y + other.h < y - h);
}

/// Quadtree for fast spatial filtering
class QuadTree {
  final QuadRect boundary;
  final int capacity;
  final List<PolygonBox> polygons = [];
  bool divided = false;

  QuadTree? ne, nw, se, sw;

  QuadTree(this.boundary, [this.capacity = 8]);

  bool insert(PolygonBox poly) {
    final rect = QuadRect(
      (poly.minLng + poly.maxLng) / 2,
      (poly.minLat + poly.maxLat) / 2,
      (poly.maxLng - poly.minLng) / 2,
      (poly.maxLat - poly.minLat) / 2,
    );

    if (!boundary.intersects(rect)) return false;

    if (polygons.length < capacity) {
      polygons.add(poly);
      return true;
    }

    if (!divided) _subdivide();
    return (ne!.insert(poly) ||
            nw!.insert(poly) ||
            se!.insert(poly) ||
            sw!.insert(poly));
  }

  void _subdivide() {
    final x = boundary.x;
    final y = boundary.y;
    final w = boundary.w / 2;
    final h = boundary.h / 2;

    ne = QuadTree(QuadRect(x + w, y - h, w, h), capacity);
    nw = QuadTree(QuadRect(x - w, y - h, w, h), capacity);
    se = QuadTree(QuadRect(x + w, y + h, w, h), capacity);
    sw = QuadTree(QuadRect(x - w, y + h, w, h), capacity);
    divided = true;
  }

  List<PolygonBox> query(LatLng point) {
    final range = QuadRect(point.longitude, point.latitude, 0, 0);
    final List<PolygonBox> found = [];

    if (!boundary.intersects(range)) return found;

    for (final p in polygons) {
      if (p.contains(point)) found.add(p);
    }

    if (divided) {
      found.addAll(ne!.query(point));
      found.addAll(nw!.query(point));
      found.addAll(se!.query(point));
      found.addAll(sw!.query(point));
    }

    return found;
  }
}

/// Ray-casting polygon membership test
/// Robust ray-casting polygon membership test with edge handling
bool pointInPolygon(LatLng point, List<LatLng> polygon) {
  bool inside = false;
  final x = point.longitude;
  final y = point.latitude;

  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].longitude, yi = polygon[i].latitude;
    final xj = polygon[j].longitude, yj = polygon[j].latitude;

    // Check if point is exactly a vertex
    if ((y == yi && x == xi) || (y == yj && x == xj)) {
      return true;
    }

    // Check if point lies exactly on an edge
    final cross = (y - yi) * (xj - xi) - (x - xi) * (yj - yi);
    if (cross.abs() < 1e-12 &&
        x >= (xi < xj ? xi : xj) &&
        x <= (xi > xj ? xi : xj) &&
        y >= (yi < yj ? yi : yj) &&
        y <= (yi > yj ? yi : yj)) {
      return true;
    }

    // Standard ray casting with small epsilon to prevent zero-division
    final intersects = ((yi > y) != (yj > y)) &&
        (x < (xj - xi) * (y - yi) / ((yj - yi) + 1e-12) + xi);

    if (intersects) inside = !inside;
  }

  return inside;
}


/// Load and parse GeoJSON into a quadtree
Future<QuadTree> _loadGeoJsonToQuadTree(String path) async {
  final jsonString = await rootBundle.loadString(path);
  final data = jsonDecode(jsonString);
  final features = data['features'] as List;

  final polygons = <PolygonBox>[];

  for (var f in features) {
    final geometry = f['geometry'];
    if (geometry['type'] != 'Polygon') continue;

    final coords = geometry['coordinates'][0];
    final latLngs = coords
        .map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
        .toList();

    polygons.add(PolygonBox(Map<String, dynamic>.from(f['properties']), latLngs));
  }

  // Rough bounds for the Philippines
  final bounds = QuadRect(122.0, 12.5, 10.0, 10.0);
  final tree = QuadTree(bounds);

  for (final p in polygons) {
    tree.insert(p);
  }

  return tree;
}
