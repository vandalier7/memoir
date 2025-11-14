import 'package:camera/camera.dart';
import 'memory.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

late final num pixelRatio;

enum Mood {
  happy,
  sad
}

const double clusterRadius = 30; // meters
const double clearanceRadius = 30; // pixels in screenSpace

List<CameraDescription> cameras = [];
List<MemoryData> memories = [];
List<MemoryData> unfilteredMemories = [];

late MapLibreMapController mapController;
LatLng currentPosition = LatLng(14.5995, 120.9842);
LatLng? nearestMemoryPosition;