import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'memory_preview.dart';
import 'memory_pin_widget.dart';

import 'globals.dart';

import 'dart:math';

class MemoryData {
  final Mood mood;
  final String addressString;
  final LatLng position;
  late final double decay;
  final String? imageUrl; // Network image URL

  MemoryData ({
      required this.addressString,
      required this.position,
      required this.mood,
      this.decay = 16.0,
      this.imageUrl,
    });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryData &&
          runtimeType == other.runtimeType &&
          position.latitude == other.position.latitude &&
          position.longitude == other.position.longitude &&
          addressString == other.addressString;

  @override
  int get hashCode =>
      position.latitude.hashCode ^
      position.longitude.hashCode ^
      addressString.hashCode;
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
  final void Function(MemoryData) onShowMemory;
  final String? imageUrl; // Network image URL
  final bool showPreview; // Control from parent
  final VoidCallback onClosePreview; // Callback to close
  final VoidCallback onLongPress; // Callback to close

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
    required this.mapZoom,
    required this.onShowMemory,
    this.imageUrl,
    this.showPreview = false,
    required this.onClosePreview,
    required this.onLongPress
  });

  MemoryData getMemoryData() {
    return MemoryData(
      addressString: addressString, 
      position: position, 
      mood: mood,
      imageUrl: imageUrl,
    );
  }

  factory MemoryPin.ofMemory(
    MemoryData data, 
    MapLibreMapController mapController, 
    bool isHoldingMap, 
    void Function(bool value) holdingCallback, 
    {
      double mapZoom = 14.0, 
      Key? key, 
      Size size = const Size(50, 50), 
      required void Function(MemoryData) onShowMemory,
      bool showPreview = false,
      required VoidCallback onClosePreview,
      required VoidCallback onLongPress
    }
  ) {
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
      onShowMemory: onShowMemory,
      imageUrl: data.imageUrl,
      showPreview: showPreview,
      onClosePreview: onClosePreview,
      onLongPress: onLongPress,
    );
  }

  @override
  State<MemoryPin> createState() => _MemoryPinState();
}

class _MemoryPinState extends State<MemoryPin> with SingleTickerProviderStateMixin {
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
      return const SizedBox.shrink();
    }

    // Debug print to check state
    debugPrint("MemoryPin build - showPreview: ${widget.showPreview}, isHoldingMap: ${widget.isHoldingMap}");

    // Calculate dimensions and offsets
    final pinWidth = 50.0;
    final previewWidth = widget.showPreview ? 100.0 : 0.0;
    final maxWidth = previewWidth > pinWidth ? previewWidth : pinWidth;
    
    final pinHeight = 60.0; // Pin marker + pointer
    final previewHeight = widget.showPreview ? 108.0 : 0.0; // 100 + 8 padding
    final totalHeight = pinHeight + previewHeight;

    return Positioned(
      left: screenPoint!.x/pixelRatio! - (maxWidth / 2), // Center on widest element
      top: screenPoint!.y/pixelRatio! - totalHeight, // Adjust for full height
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          // Don't capture, just let it through
        },
        onPointerMove: (event) {
          // If it moves, it's a pan/zoom gesture, not a tap
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: widget.onLongPress,
          onTap: () async {
            // Only process if pin is visible and map isn't being held
            if (widget.decay > widget.mapZoom || !widget.isHoldingMap) return;
          debugPrint("${widget.decay}");
          if (widget.decay <= widget.mapZoom) {
            // Get screen size
            final screenSize = MediaQuery.of(context).size;
            final screenCenterX = screenSize.width / 2;
            final screenCenterY = screenSize.height / 2;
            
            // Get pin's current screen position
            final pinScreenPoint = await widget.mapController.toScreenLocation(widget.position);
            if (pinScreenPoint == null) return;
            
            final pinX = pinScreenPoint.x / pixelRatio!;
            final pinY = pinScreenPoint.y / pixelRatio!;
            
            // Define rectangular tolerance area (in pixels from center)
            const horizontalTolerance = 130.0; // Width of center rectangle
            const verticalTolerance = 200.0;   // Height of center rectangle
            const offsetX = 0.0; // Horizontal offset from center (positive = right, negative = left)
            const offsetY = 100.0; // Vertical offset from center (positive = down, negative = up)
            
            // Apply offset to center point
            final targetCenterX = screenCenterX + offsetX;
            final targetCenterY = screenCenterY + offsetY;
            
            // Check if pin is within rectangular area
            final isInCenterRectangle = 
                (pinX >= targetCenterX - horizontalTolerance && 
                 pinX <= targetCenterX + horizontalTolerance) &&
                (pinY >= targetCenterY - verticalTolerance && 
                 pinY <= targetCenterY + verticalTolerance);
            
            // If already centered (within rectangular area), just show preview
            if (isInCenterRectangle) {
              // Only show preview if map is not being held (pin is visible)
              if (widget.isHoldingMap) {
                widget.holdingCallback.call(false);
                widget.onShowMemory(widget.getMemoryData());
              }
            } else {
              // Otherwise animate to position first
              widget.holdingCallback.call(true);

              widget.onLongPress.call();
              
              // await widget.mapController.animateCamera(
              //   CameraUpdate.newLatLngZoom(
              //     LatLng(widget.position.latitude, widget.position.longitude),
              //     widget.decay + 0.5
              //   ),
              //   duration: Duration(milliseconds: 700)
              // );
              
              // Show preview after animation
              widget.onShowMemory(widget.getMemoryData());
            }
          }
        },
        child: IgnorePointer(
          ignoring: true,
          child: AnimatedOpacity(
            opacity: (!widget.isHoldingMap && widget.decay <= widget.mapZoom) ? 1.0 : 0.0, 
            duration: Duration(milliseconds: 100),
            child: MemoryPinWidget(
              addressString: widget.addressString,
              color: Colors.yellow.shade600,
              showPreview: widget.showPreview,
              mood: widget.mood,
              imageUrl: widget.imageUrl,
              onClosePreview: widget.onClosePreview,
            ),
          ),
        ),
      ),
      )
    );
  }
}