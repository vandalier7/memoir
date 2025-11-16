import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'memory_preview.dart';
import 'memory_pin_widget.dart';

import 'globals.dart';

import 'dart:math';

class MemoryData {
  final String? description;
  final bool head;
  final Mood mood;
  final String addressString;
  final LatLng position;
  late final double decay;
  final String? imageUrl; // Network image URL
  final String? memoryId;

  MemoryData({
    required this.addressString,
    required this.position,
    required this.mood,
    this.decay = 16.0,
    this.head = true,
    this.imageUrl,
<<<<<<< HEAD
    this.memoryId,
=======
    this.description
>>>>>>> alpha-version
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
  final List<MemoryData> memories; // Changed to list
  final LatLng position;
  final MapLibreMapController mapController;
  final bool isHoldingMap;
  final bool isClustered;
  final void Function(bool value) holdingCallback;
  final double decay;
  final double mapZoom;
  final void Function(List<MemoryData>) onShowMemories; // Changed to list
  final bool showPreview; // Control from parent
  final VoidCallback onClosePreview; // Callback to close
  final void Function(List<MemoryData>) onLongPress; // Callback with new memories

  const MemoryPin({
    super.key,
    this.size = const Size(50, 50),
    required this.memories,
    required this.position,
    required this.mapController,
    required this.isHoldingMap,
    required this.isClustered,
    required this.holdingCallback,
    required this.decay,
    required this.mapZoom,
    required this.onShowMemories,
    this.showPreview = false,
    required this.onClosePreview,
    required this.onLongPress,
  });

  factory MemoryPin.ofMemories(
    List<MemoryData> memories,
    LatLng position,
    MapLibreMapController mapController,
    bool isHoldingMap,
    bool isClustered,
    void Function(bool value) holdingCallback, {
    double decay = 16.0,
    double mapZoom = 14.0,
    Key? key,
    Size size = const Size(50, 50),
    required void Function(List<MemoryData>) onShowMemories,
    bool showPreview = false,
    required VoidCallback onClosePreview,
    required void Function(List<MemoryData>) onLongPress,
  }) {
    return MemoryPin(
      key: key,
      size: size,
      memories: memories,
      position: position,
      decay: decay,
      mapController: mapController,
      isHoldingMap: isHoldingMap,
      isClustered: isClustered,
      holdingCallback: holdingCallback,
      mapZoom: mapZoom,
      onShowMemories: onShowMemories,
      showPreview: showPreview,
      onClosePreview: onClosePreview,
      onLongPress: onLongPress,
    );
  }

  // Keep this for backward compatibility
  factory MemoryPin.ofMemory(
    MemoryData data,
    MapLibreMapController mapController,
    bool isHoldingMap,
    bool isClustered,
    void Function(bool value) holdingCallback, {
    double mapZoom = 14.0,
    Key? key,
    Size size = const Size(50, 50),
    required void Function(MemoryData) onShowMemory,
    bool showPreview = false,
    required VoidCallback onClosePreview,
    required void Function(List<MemoryData>) onLongPress,
  }) {
    return MemoryPin(
      key: key,
      size: size,
      memories: [data],
      position: data.position,
      decay: data.decay,
      mapController: mapController,
      isHoldingMap: isHoldingMap,
      isClustered: isClustered,
      holdingCallback: holdingCallback,
      mapZoom: mapZoom,
      onShowMemories: (memories) => onShowMemory(memories.first),
      showPreview: showPreview,
      onClosePreview: onClosePreview,
      onLongPress: onLongPress,
    );
  }

  @override
  State<MemoryPin> createState() => _MemoryPinState();
}

class _MemoryPinState extends State<MemoryPin>
    with SingleTickerProviderStateMixin {
  Point? screenPoint;
  final Random _random = Random();

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
    
    if (!mounted) {return;}
    
    setState(() {
      screenPoint = point;
    });
  }

  List<MemoryData> _generateRandomMemories() {
    final count = _random.nextInt(5) + 1; // 1-5 memories
    final List<MemoryData> newMemories = [];
    
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

    for (int i = 0; i < count; i++) {
      final randomMood = _random.nextBool() ? Mood.happy : Mood.sad;
      final suffix = addressSuffixes[_random.nextInt(addressSuffixes.length)];
      
      newMemories.add(MemoryData(
        addressString: "${widget.memories.first.addressString} - $suffix",
        position: widget.position,
        mood: randomMood,
        decay: widget.decay,
        imageUrl: null, // No image for randomly generated memories
      ));
    }
    
    return newMemories;
  }

  @override
  Widget build(BuildContext context) {
    if (screenPoint == null || widget.memories.isEmpty) {
      return const SizedBox.shrink();
    }

    // Debug print to check state
    debugPrint(
        "MemoryPin build - showPreview: ${widget.showPreview}, isHoldingMap: ${widget.isHoldingMap}");

    // Calculate dimensions and offsets
    final pinWidth = 50.0;
    final previewWidth = widget.showPreview ? 100.0 : 0.0;
    final maxWidth = previewWidth > pinWidth ? previewWidth : pinWidth;

    final pinHeight = 60.0; // Pin marker + pointer
    // Multiple previews stack with 8px spacing between them
    final previewHeight = widget.showPreview 
        ? (widget.memories.length * 108.0) + ((widget.memories.length - 1) * 8.0)
        : 0.0;
    final totalHeight = pinHeight + previewHeight;

    return Positioned(
      left: screenPoint!.x / pixelRatio! -
          (maxWidth / 2), // Center on widest element
      top: screenPoint!.y / pixelRatio! - totalHeight, // Adjust for full height
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
          onLongPress: () {
            // Generate random memories on long press
            final newMemories = _generateRandomMemories();
            widget.onLongPress(newMemories);
          },
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
              final pinScreenPoint =
                  await widget.mapController.toScreenLocation(widget.position);
              if (pinScreenPoint == null) return;

              final pinX = pinScreenPoint.x / pixelRatio!;
              final pinY = pinScreenPoint.y / pixelRatio!;

              // Define rectangular tolerance area (in pixels from center)
              const horizontalTolerance = 70.0; // Width of center rectangle
              const verticalTolerance = 200.0; // Height of center rectangle
              const offsetX =
                  0.0; // Horizontal offset from center (positive = right, negative = left)
              const offsetY =
                  100.0; // Vertical offset from center (positive = down, negative = up)

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
                  widget.onShowMemories(widget.memories);
                }
              } else {
                // Otherwise animate to position first
                widget.holdingCallback.call(true);

                // Generate and show random memories
                final newMemories = _generateRandomMemories();
                widget.onLongPress(newMemories);

                // await widget.mapController.animateCamera(
                //   CameraUpdate.newLatLngZoom(
                //     LatLng(widget.position.latitude, widget.position.longitude),
                //     widget.decay + 0.5
                //   ),
                //   duration: Duration(milliseconds: 700)
                // );

                // Show preview after animation
                widget.onShowMemories(widget.memories);
              }
            }
          },
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity:
                  (!widget.isHoldingMap && widget.decay <= widget.mapZoom && widget.isClustered)
                      ? 1.0
                      : 0.0,
              duration: Duration(milliseconds: 100),
              child: MemoryPinWidget(
                memories: widget.memories,
                showPreviews: widget.showPreview,
                onClosePreviews: widget.onClosePreview,
              ),
            ),
          ),
        ),
      ),
    );
  }
}