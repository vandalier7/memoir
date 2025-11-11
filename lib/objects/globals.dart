import 'package:camera/camera.dart';
import 'memory.dart';

late final num pixelRatio;

enum Mood {
  happy,
  sad
}

List<CameraDescription> cameras = [];
List<MemoryData> memories = [];