import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:presentation/objects/pin.dart';

import 'globals.dart';

import 'dart:math';

enum Mood {
  happy,
  sad
}

class MemoryData {
  final Mood mood;
  final String addressString;
  final LatLng position;
  late final double decay;

  MemoryData ({
      required this.addressString,
      required this.position,
      required this.mood,
      this.decay = 16.0
    });
}

class MemoryPin extends StatefulWidget {
  final Size size;
  final String addressString;
  final LatLng position;
  final Mood mood;
  final MapLibreMapController mapController; 
  final bool isHoldingMap;
  final void Function(bool value) holdingCallback;
  final double decay;
  final double mapZoom;

  const MemoryPin({
    super.key, 
    this.size = const Size(50, 50),
    required this.addressString,
    required this.position,
    required this.mood,
    required this.mapController,
    required this.isHoldingMap,
    required this.holdingCallback,
    required this.decay,
    required this.mapZoom
  });

  factory MemoryPin.ofMemory(MemoryData data, MapLibreMapController mapController, bool isHoldingMap, void Function(bool value) holdingCallback, {double mapZoom = 14.0, Key? key, Size size = const Size(50, 50)}) {
    return MemoryPin(
      key: key,
      size: size,
      addressString: data.addressString,
      position: data.position,
      mood: data.mood,
      decay: data.decay,
      mapController: mapController,
      isHoldingMap: isHoldingMap,
      holdingCallback: holdingCallback,
      mapZoom: mapZoom,
    );
  }

  @override
  State<MemoryPin> createState() => _MemoryPinState();
}

class _MemoryPinState extends State<MemoryPin> with SingleTickerProviderStateMixin {
  bool _showPanel = false;
  Point? screenPoint;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MemoryPin oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateScreenPoint();

  }


  Future<void> _updateScreenPoint() async {
    final point = await widget.mapController.toScreenLocation(widget.position);
    setState(() {
      screenPoint = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (screenPoint == null) {
      return const SizedBox.shrink(); // render nothing until screenPoint ready
    }
    var p = widget.decay;
    var z = widget.mapZoom;
    // debugPrint("$p : $z"); 

    return Positioned(
              left: screenPoint!.x/pixelRatio! - 75, // adjust to center icon
              top: screenPoint!.y/pixelRatio! - 50,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  debugPrint("${widget.decay}");
                  if (widget.isHoldingMap && widget.decay <= widget.mapZoom) {
                    widget.holdingCallback.call(true);
                    await widget.mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(widget.position.latitude, widget.position.longitude),
                        widget.decay + 0.5
                      ),
                      duration: Duration(milliseconds: 1000)
                    );
                  }
                },
                child: IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    opacity: (!widget.isHoldingMap && widget.decay <= widget.mapZoom) ? 1.0 : 0.0, 
                    duration: Duration(milliseconds: 100),
                    child: UserPin(addressString: widget.addressString, color: Colors.yellow.shade600,)
                  ),
                )
              ),
            );
  }
}
