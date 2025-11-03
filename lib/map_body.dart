import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'objects/pin.dart';
import 'objects/memory.dart';
import 'objects/memory_preview.dart';

import 'objects/globals.dart';

import 'processes/location_iq.dart';

class MapBody extends StatefulWidget {
  final void Function(MemoryData) propagateMemory;
  final void Function() closeMemory;

  const MapBody({super.key, required this.propagateMemory, required this.closeMemory});

  @override
  State<MapBody> createState() => MapState();
}

class MapState extends State<MapBody> {
  LatLng currentPosition = LatLng(14.5995, 120.9842);
  String? currentAddress = "...";
  late MapLibreMapController mapController;
  Point? screenPoint;
  bool isHoldingMap = false;
  bool considerTapAsDouble = false;
  bool isAnimatingToMemory = false;

  List<MemoryData>? activeMemories;

  double mapZoom = 16;

  List<MemoryData> memories = [];

  final locIQ = LocationIQService('pk.2e56aa59169aa53b63093b78aff0e291');
  final Random _random = Random();

  double pinAlpha = 1;

  @override
  void initState() {
    super.initState();
    _getLocation();
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

    mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(pos.latitude, pos.longitude),
      ),
    );
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
    setState(() {
      isHoldingMap = value;
    });
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
    final point = await mapController.toScreenLocation(currentPosition);
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
            _updateScreenPoint();
            updateMapHold(false);
            var pos = await mapController.queryCameraPosition();
            updateZoom(pos!.zoom);
            if (!isAnimatingToMemory) {
              closePreview();
            } else {
              isAnimatingToMemory = false;
            }
            debugPrint("$pixelRatio");
          },
          onCameraTrackingChanged: (mode) => updateMapHold(true),
          onCameraMove: (pos) {
            updateMapHold(true);
          },
          onMapLongClick: (point, latLng) {
            _addMultipleMemories(latLng);
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(14.5995, 120.9842),
            zoom: 16.0,
          ),
        ),
      ),

      // Render grouped memory pins
      for (final entry in groupedMemories.entries)
        MemoryPin.ofMemories(
          entry.value,
          entry.key,
          mapController,
          isHoldingMap,
          updateMapHold,
          decay: entry.value.first.decay,
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

      if (screenPoint != null)
        Positioned(
          // TODO : pin centerin here
          left: screenPoint!.x / pixelRatio - 27,
          top: screenPoint!.y / pixelRatio - 67,
          child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () async {
                updateMapHold(true);
                closePreview();
                await mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(currentPosition.latitude, currentPosition.longitude),
                      14,
                    ),
                    duration: Duration(milliseconds: 1000));
              },
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: isHoldingMap ? 0.0 : 1.0,
                  duration: Duration(milliseconds: 100),
                  child: UserPin(
                    color: Colors.purple.shade300,
                    addressString: currentAddress!,
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
            final pinCenterX = screenPoint.x / pixelRatio - 12;
            final pinCenterY = screenPoint.y / pixelRatio - 40;
            
            // Take only first 6 memories
            final displayMemories = activeMemories!.take(6).toList();
            
            return Stack(
              children: displayMemories.asMap().entries.map((entry) {
                final index = entry.key;
                final memory = entry.value;
                
                // Hexagonal arrangement positions
                final radius = 90.0;
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
                          widget.propagateMemory(memory);
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
                            ),
                            // Mood indicator dot
                            Positioned(
                              top: -4,
                              left: -4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: memory.mood == Mood.happy
                                      ? Colors.yellow
                                      : Colors.blue,
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