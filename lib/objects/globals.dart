import 'package:camera/camera.dart';
import 'memory.dart';

late final num pixelRatio;

enum Mood {
  happy,
  sad
}

const double clusterRadius = 30; // meters

List<CameraDescription> cameras = [];
List<MemoryData> memories = [];
List<MemoryData> unfilteredMemories = [];
