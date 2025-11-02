import 'package:camera/camera.dart';

late final num pixelRatio;

enum Mood {
  happy,
  sad
}

List<CameraDescription> cameras = [];