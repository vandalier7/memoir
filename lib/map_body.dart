//map_body.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'objects/pin.dart';
import 'objects/memory.dart';
import 'objects/memory_preview.dart';
import 'objects/memory_pin_widget.dart';

import 'objects/globals.dart';

import 'processes/location_iq.dart';

class MapBody extends StatefulWidget {
  final void Function(List<MemoryData>, MemoryData, int) propagateMemory;
  final void Function() closeMemory;

  const MapBody({super.key, required this.propagateMemory, required this.closeMemory});

  @override
  State<MapBody> createState() => MapState();
}

class MapState extends State<MapBody> {
  String? currentAddress = "...";
  
  Point? screenPoint;
  bool isHoldingMap = false;
  bool considerTapAsDouble = false;
  bool isAnimatingToMemory = false;

  
  
  List<MemoryData>? activeMemories;

  double mapZoom = 16;

  final locIQ = LocationIQService('pk.2e56aa59169aa53b63093b78aff0e291');
  final Random _random = Random();

  double pinAlpha = 1;

  @override
  void initState() {
    super.initState();
    _getLocation();
    
  }

  // Add to MapState:
  Map<LatLng, List<LatLng>> screenSpaceClusters = {}; // Maps cluster center to list of positions
  bool isClusteringInProgress = false;

  Future<void> _performScreenSpaceClustering() async {
  if (isClusteringInProgress) return;
  isClusteringInProgress = true;

  try {
    final Map<LatLng, List<LatLng>> clusters = {};
    final Set<LatLng> clustered = {};
    final double clusterThresholdPixels = 50.0;
    
    final groupedMemories = groupMemoriesByPosition(memories);
    final positions = groupedMemories.keys.toList();
    final nearbyPos = _findNearbyMemoryPosition();
    
    for (final pos1 in positions) {
      if (clustered.contains(pos1)) continue;
      if (pos1 == nearbyPos) continue;
      
      final screen1 = await mapController.toScreenLocation(pos1);
      final List<LatLng> cluster = [pos1];
      clustered.add(pos1);
      
      for (final pos2 in positions) {
        if (pos2 == nearbyPos) continue;
        if (pos1 == pos2) continue;
        if (clustered.contains(pos2)) continue;
        
        final screen2 = await mapController.toScreenLocation(pos2);
        
        final dx = (screen1.x - screen2.x) / pixelRatio!;
        final dy = (screen1.y - screen2.y) / pixelRatio!;
        final distance = sqrt(dx * dx + dy * dy);
        
        if (distance < clusterThresholdPixels) {
          cluster.add(pos2);
          clustered.add(pos2);
        }
      }
      
      // ONLY ADD IF ACTUALLY CLUSTERED WITH OTHERS
      if (cluster.length > 1) {
        double avgLat = 0;
        double avgLng = 0;
        for (final pos in cluster) {
          avgLat += pos.latitude;
          avgLng += pos.longitude;
        }
        avgLat /= cluster.length;
        avgLng /= cluster.length;
        final clusterCenter = LatLng(avgLat, avgLng);
        
        clusters[clusterCenter] = cluster;
      }
      // If cluster.length == 1, don't add it to clusters map
    }
    
    setState(() {
      screenSpaceClusters = clusters;
    });
  } finally {
    isClusteringInProgress = false;
  }
}

  // Find memory position closest to user within clusterRadius
  LatLng? _findNearbyMemoryPosition() {
    final groupedMemories = groupMemoriesByPosition(memories);
    
    for (final position in groupedMemories.keys) {
      final distance = distanceBetween(currentPosition, position);
      if (distance <= clusterRadius) {
        return position;
      }
    }
    return null;
  }

  void zoomToCurrentPosition () async {
    updateMapHold(true);
    closePreview();
    widget.closeMemory();
    
    final targetPosition = nearestMemoryPosition ?? currentPosition;
    
    await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(targetPosition, 18),
        duration: Duration(milliseconds: 1000));
  }

  void showMemories(List<MemoryData> memoriesToShow) {
    setState(() {
      widget.closeMemory();
      activeMemories = memoriesToShow;
      isAnimatingToMemory = true;
    });
  }

  void closePreview() {
    setState(() {
      activeMemories = null;
    });
  }

  Future<void> waitForDoubleTap() async {
    considerTapAsDouble = true;
    await Future.delayed(const Duration(milliseconds: 300));
    considerTapAsDouble = false;
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.high));

    setState(() {
      currentPosition = LatLng(pos.latitude, pos.longitude);
      
    });

    await mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(pos.latitude, pos.longitude),
      ),
    );

    toggleLoading(false);
  }

  Future<void> animateCameraWithOffset({
    required LatLng target,
    double xOffsetPixels = 0,
    double yOffsetPixels = 200,
    int durationMs = 700,
    bool showPreviewAfter = false
  }) async {
    final currentCameraPos = await mapController.queryCameraPosition();
    if (currentCameraPos == null) return;

    final targetScreen = await mapController.toScreenLocation(target);

    final offsetScreenX = targetScreen.x + (xOffsetPixels * pixelRatio!);
    final offsetScreenY = targetScreen.y + (yOffsetPixels * pixelRatio!);

    final offsetLatLng = await mapController
        .toLatLng(Point(offsetScreenX.toDouble(), offsetScreenY.toDouble()));
    updateMapHold(true);
    isAnimatingToMemory = showPreviewAfter;

    await mapController.animateCamera(
        CameraUpdate.newLatLng(offsetLatLng),
        duration: Duration(milliseconds: durationMs));
  }

  void updateMapHold(bool value) {

    final positionToUse = nearestMemoryPosition ?? currentPosition;


    setState(() {
      isHoldingMap = value;
      if (!value) {
        memories.clear();
        for (MemoryData memory in unfilteredMemories) {
          

          if (memory.decay <= mapZoom || memory.position == positionToUse) {
            if (memory.position != positionToUse){
              if (!isWithinPixelThreshold(pos1: memory.position, pos2: positionToUse, pixelThreshold: clearanceRadius, currentZoom: mapZoom)) {
                memories.add(memory);
              }
            }
            else {
              memories.add(memory);
            }
            // memories.add(memory);
          }
          else if (memory.userId! == storageService.currentUserId) {
             // if memory is yours, always show
            if (!isWithinPixelThreshold(pos1: memory.position, pos2: positionToUse, pixelThreshold: clearanceRadius, currentZoom: mapZoom)) {
                memories.add(memory);
                memory.finalDecay = 0;
            }
          }
          else if (friends.contains(memory.userId!) && memory.decay - 10  <= mapZoom) {
            if (!isWithinPixelThreshold(pos1: memory.position, pos2: positionToUse, pixelThreshold: clearanceRadius, currentZoom: mapZoom)) {
                memory.finalDecay = memory.decay - 10;
                memories.add(memory);
                
            }
          }
          else if (followedUsers.contains(memory.userId!) && memory.decay - 10 <= mapZoom) {
            if (!isWithinPixelThreshold(pos1: memory.position, pos2: positionToUse, pixelThreshold: clearanceRadius, currentZoom: mapZoom)) {
                memory.finalDecay = memory.decay - 10;
                memories.add(memory);
                
            }
          }
          
        }
        // memories.add(neaby)
      } else {
        
      }
      if (memories.isEmpty) {}
    });
    for (MemoryData memory in memories) {
      debugPrint(memory.addressString);
    }
    debugPrint(mapZoom.toString());
  }

  Future<void> updateLocation() async {
    var pos = await getUserLocation();
    currentPosition = LatLng(pos!.latitude, pos.longitude);

    _updateScreenPoint();
    _updateAddress();
  }

  Future<void> _updateAddress() async {
    final info = await getAddressFromLocation(currentPosition, locIQ);
    debugPrint(info);

    setState(() {
      currentAddress = info;
    });
  }

  void updateZoom(double value) {
    setState(() {
      mapZoom = value;
    });
  }

  Future<void> _updateScreenPoint() async {
    nearestMemoryPosition = _findNearbyMemoryPosition();
    final positionToUse = nearestMemoryPosition ?? currentPosition;
    
    final point = await mapController.toScreenLocation(positionToUse);
    setState(() {
      screenPoint = point;
      updateMapHold(false);
    });
  }

  void _addMemory(LatLng position) async {
    final info = await getAddressFromLocation(position, locIQ);
    setState(() {
      memories.add(MemoryData(
          position: position,
          addressString: info,
          mood: Mood.happy,
          decay: mapZoom));
    });
    updateMapHold(false);
  }

  void _newAddMemory(LatLng position, bool isHead) async {
    final info = await getAddressFromLocation(position, locIQ);
    unfilteredMemories.add(MemoryData(
          position: position,
          addressString: info,
          mood: Mood.happy,
          decay: mapZoom - 3,
          imageUrl: null,
          head: isHead
        ));
  }

  void _addMultipleMemories(LatLng position) async {
    final info = await getAddressFromLocation(position, locIQ);
    final count = _random.nextInt(5) + 1;
    
    final List<String> addressSuffixes = [
      "First visit",
      "Great times",
      "Another day",
      "Special moment",
      "Passing by",
      "Memorable day",
      "Quick stop",
      "Long stay"
    ];

    setState(() {
      for (int i = 0; i < count; i++) {
        final randomMood = _random.nextBool() ? Mood.happy : Mood.sad;
        final suffix = addressSuffixes[_random.nextInt(addressSuffixes.length)];
        
        memories.add(MemoryData(
          position: position,
          addressString: "$info - $suffix",
          mood: randomMood,
          decay: mapZoom,
          imageUrl: null,
        ));
      }
    });
    updateMapHold(false);
  }

  @override
  Widget build(BuildContext context) {
    final groupedMemories = groupMemoriesByPosition(memories);
    final nearbyMemoryPosition = _findNearbyMemoryPosition();
    
    
    // Build a set of positions that are part of multi-position clusters
    final Set<LatLng> clusteredPositions = {};
    for (final entry in screenSpaceClusters.entries) {
      if (entry.value.length > 1) {
        clusteredPositions.addAll(entry.value);
      }
    }
    
    return Stack(children: [
      Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          updateMapHold(!isHoldingMap);
          if (!considerTapAsDouble) {
            waitForDoubleTap();
          } else {
            updateMapHold(true);
          }
        },
        onPointerMove: (event) {
          if (event.delta.distance > 1) {
            updateMapHold(true);
            isAnimatingToMemory = false;
          }
        },
        child: MapLibreMap(
          compassEnabled: false,
          rotateGesturesEnabled: false,
          styleString:
              "https://api.maptiler.com/maps/dataviz/style.json?key=gyEpeYKGmrox3x3xvhNk",
          onMapCreated: (controller) async {
            mapController = controller;

            await updateLocation();
          },
          onCameraIdle: () async {
            var pos = await mapController.queryCameraPosition();
            updateZoom(pos!.zoom);

            _updateScreenPoint();
            updateMapHold(false);
            
            
            // Perform screen-space clustering after camera stops
            await _performScreenSpaceClustering();
            
            if (!isAnimatingToMemory) {
              closePreview();
            } else {
              isAnimatingToMemory = false;
            }
          },
          onCameraTrackingChanged: (mode) => updateMapHold(true),
          onCameraMove: (pos) {
            updateMapHold(true);
          },
          onMapLongClick: (point, latLng) {
          //   double closestDist = double.maxFinite;
          //   late MemoryData closestMemory;
          //   for (MemoryData memory in memories){
          //     if (!memory.head) {continue;}
              
          //     double dist = distanceBetween(memory.position, latLng);
          //     if (dist < closestDist) {
          //       closestMemory = memory;
          //       closestDist = dist;
          //     }
          //   }
          //   debugPrint("$closestDist");
          //   if (closestDist <= clusterRadius) {
          //     _newAddMemory(closestMemory.position, false);
          //   }
          //   else {
          //     _newAddMemory(latLng, true);
          //   }
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(14.5995, 120.9842),
            zoom: 16.0,
          ),
        ),
      ),

      // Render individual memory pins (skip if near user position)
      for (final entry in groupedMemories.entries)
        if (entry.key != nearbyMemoryPosition)
          MemoryPin.ofMemories(
            entry.value,
            entry.key,
            mapController,
            isHoldingMap,
            !clusteredPositions.contains(entry.key),
            updateMapHold,
            decay: entry.value.first.decay,
            finalDecay: entry.value.first.finalDecay ,
            mapZoom: mapZoom,
            showPreview: false,
            onShowMemories: showMemories,
            onClosePreview: closePreview,
            onLongPress: (newMemories) {
              animateCameraWithOffset(
                target: entry.key,
                showPreviewAfter: true,
                yOffsetPixels: 0,
              );
            },
          ),

      // Render cluster pins
      for (final entry in screenSpaceClusters.entries)
        if (entry.value.length > 1)
          FutureBuilder<Point>(
            future: mapController.toScreenLocation(entry.key),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox.shrink();
              
              final screenPoint = snapshot.data!;
              final allMemoriesInCluster = <MemoryData>[];
              for (final pos in entry.value) {
                if (groupedMemories.containsKey(pos)) {
                  allMemoriesInCluster.addAll(groupedMemories[pos]!);
                }
              }
              
              return Positioned(
                left: screenPoint.x / pixelRatio! - 30,
                top: screenPoint.y / pixelRatio! - 40,
                child: ClusterPin(
                  count: allMemoriesInCluster.length,
                  position: entry.key,
                  mapController: mapController,
                  isHoldingMap: isHoldingMap,
                  holdingCallback: updateMapHold,
                  clusterCallback: screenSpaceClusters.clear,
                ),
              );
            },
          ),

      // UserPin - displays at nearby memory position if within clusterRadius
      if (screenPoint != null)
        Positioned(
          left: screenPoint!.x / pixelRatio - 27,
          top: screenPoint!.y / pixelRatio - 67,
          child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () async {
                closePreview();
                widget.closeMemory();
                updateMapHold(true);
                
                
                final targetPosition = nearbyMemoryPosition ?? currentPosition;
                
                await mapController.animateCamera(
                    CameraUpdate.newLatLng(targetPosition),
                    duration: Duration(milliseconds: 1000));
                
                // Show memories if at a memory location
                if (nearbyMemoryPosition != null) {
                  showMemories(groupedMemories[nearbyMemoryPosition]!);
                }
              },
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: isHoldingMap ? 0.0 : 1.0,
                  duration: Duration(milliseconds: 100),
                  child: UserPin(
                    memories: nearbyMemoryPosition != null 
                        ? groupedMemories[nearbyMemoryPosition]! 
                        : [],
                    showPreviews: false,
                  ),
                ),
              )),
        ),

      // Render active memories previews with hexagonal arrangement
      if (activeMemories != null && activeMemories!.isNotEmpty)
        FutureBuilder<Point>(
          future: mapController.toScreenLocation(activeMemories!.first.position),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            final screenPoint = snapshot.data!;
            final previewWidth = 100.0;
            final previewHeight = 108.0;
            final scaleFactor = 0.75;
            final scaledWidth = previewWidth * scaleFactor;
            final scaledHeight = previewHeight * scaleFactor;
            
            // TODO : preview centering here
            final pinCenterX = screenPoint.x / pixelRatio - 14;
            final pinCenterY = screenPoint.y / pixelRatio - 40;
            
            // Take only first 6 memories
            final displayMemories = activeMemories!.take(6).toList();
            
            return Stack(
              children: displayMemories.asMap().entries.map((entry) {
                final index = entry.key;
                final memory = entry.value;
                
                // Hexagonal arrangement positions
                final radius = 100.0;
                double dx = 0;
                double dy = 0;
                
                if (displayMemories.length == 1) {
                  dx = 0;
                  dy = -radius;
                } else if (displayMemories.length == 2) {
                  dx = 0;
                  dy = index == 0 ? -radius : radius;
                } else if (displayMemories.length == 3) {
                  if (index == 0) {
                    dx = 0;
                    dy = -radius;
                  } else if (index == 1) {
                    dx = -radius * 0.866;
                    dy = radius * 0.5;
                  } else {
                    dx = radius * 0.866;
                    dy = radius * 0.5;
                  }
                } else if (displayMemories.length == 4) {
                  if (index == 0) {
                    dx = 0;
                    dy = -radius;
                  } else if (index == 1) {
                    dx = -radius * 0.866;
                    dy = 0;
                  } else if (index == 2) {
                    dx = radius * 0.866;
                    dy = 0;
                  } else {
                    dx = 0;
                    dy = radius;
                  }
                } else if (displayMemories.length == 5) {
                  final angles = [-90, -18, 54, 126, 198];
                  final angleRad = angles[index] * (pi / 180);
                  dx = radius * cos(angleRad);
                  dy = radius * sin(angleRad);
                } else {
                  final angle = (index * 60 - 90) * (pi / 180);
                  dx = radius * cos(angle);
                  dy = radius * sin(angle);
                }
                
                // Calculate final position, centering preview on its point
                final finalX = pinCenterX + dx - (scaledWidth / 2);
                final finalY = pinCenterY + dy - (scaledHeight / 2);
                
                return Positioned(
                  left: finalX,
                  top: finalY,
                  child: AnimatedOpacity(
                    opacity: !isHoldingMap ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 100),
                    child: Transform.scale(
                      scale: scaleFactor,
                      child: GestureDetector(
                        onTap: () async {
                          updateMapHold(true);
                          final memoriesAtLocation = groupedMemories[memory.position] ?? [memory];
                          widget.propagateMemory(memoriesAtLocation, activeMemories![index], index);
                          await animateCameraWithOffset(
                            target: memory.position,
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            MemoryPreview(
                              addressString: memory.addressString,
                              mood: memory.mood,
                              imageUrl: memory.imageUrl,
                              onClose: closePreview,
                              memoryIndex: index,
                            ),
                            // Mood indicator dot
                            Positioned(
                              top: -4,
                              left: -4,
                              child: Container(
                                margin: EdgeInsets.all(8),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: getMoodColor(memory.mood),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
    ]);
  }
}

Future<Position?> getUserLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied.');
  }

  return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(accuracy: LocationAccuracy.high));
}

Map<LatLng, List<MemoryData>> groupMemoriesByPosition(List<MemoryData> memories) {
  final Map<LatLng, List<MemoryData>> grouped = {};

  for (final memory in memories) {
    final key = memory.position;
    if (!grouped.containsKey(key)) {
      grouped[key] = [];
    }
    grouped[key]!.add(memory);
  }

  return grouped;
}

double distanceBetween(LatLng a, LatLng b) {
  const double earthRadius = 6371000; // in meters

  final double lat1 = a.latitude * pi / 180;
  final double lon1 = a.longitude * pi / 180;
  final double lat2 = b.latitude * pi / 180;
  final double lon2 = b.longitude * pi / 180;

  final double dLat = lat2 - lat1;
  final double dLon = lon2 - lon1;

  final double haversine = pow(sin(dLat / 2), 2) +
      cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);

  final double c = 2 * atan2(sqrt(haversine), sqrt(1 - haversine));

  return earthRadius * c;
} 

double metersPerPixelAtZoom(double latitude, double zoom) {
  const double earthCircumference = 40075017; // meters at equator
  final double latitudeRadians = latitude * pi / 180;
  
  // Meters per pixel = (Earth circumference * cos(latitude)) / (256 * 2^zoom)
  return (earthCircumference * cos(latitudeRadians)) / (256 * pow(2, zoom));
}

/// Convert pixel distance to meters at current zoom and latitude
double pixelsToMeters(double pixels, double latitude, double zoom) {
  return pixels * metersPerPixelAtZoom(latitude, zoom);
}

/// Convert meter distance to pixels at current zoom and latitude
double metersToPixels(double meters, double latitude, double zoom) {
  return meters / metersPerPixelAtZoom(latitude, zoom);
}

/// Check if two positions are within pixel threshold at current zoom
bool isWithinPixelThreshold({
  required LatLng pos1,
  required LatLng pos2,
  required double pixelThreshold,
  required double currentZoom,
}) {
  // Calculate real-world distance in meters
  final metersDistance = distanceBetween(pos1, pos2);
  
  // Convert pixel threshold to meters at this zoom level
  // Use average latitude for the calculation
  final avgLatitude = (pos1.latitude + pos2.latitude) / 2;
  final metersThreshold = pixelsToMeters(pixelThreshold, avgLatitude, currentZoom);
  
  return metersDistance <= metersThreshold;
}