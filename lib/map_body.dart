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
    bool isAnimatingToMemory = false; // Flag to prevent closing preview during animation

    MemoryData? activeMemory; // Track which memory is showing preview

    double mapZoom = 16;

    List<MemoryData> memories = [];

    final locIQ = LocationIQService('pk.2e56aa59169aa53b63093b78aff0e291'); 

    double pinAlpha = 1;

    @override
    void initState() {
      super.initState();
      _getLocation();
    }

    void showMemory(MemoryData memory) {
      setState(() {
        widget.closeMemory();
        activeMemory = memory;
        isAnimatingToMemory = true; // Set flag when showing memory
      });
    }

    void closePreview() {
      setState(() {
        activeMemory = null;
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
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.high)
      );

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
      // Get current camera position to maintain zoom
      final currentCameraPos = await mapController.queryCameraPosition();
      if (currentCameraPos == null) return;
      
      // Convert target to screen coordinates
      final targetScreen = await mapController.toScreenLocation(target);
      
      // Apply offset in screen space
      final offsetScreenX = targetScreen.x + (xOffsetPixels * pixelRatio!);
      final offsetScreenY = targetScreen.y + (yOffsetPixels * pixelRatio!);
      
      // Convert back to LatLng
      final offsetLatLng = await mapController.toLatLng(Point(offsetScreenX.toDouble(), offsetScreenY.toDouble()));
      updateMapHold(true);
      isAnimatingToMemory = showPreviewAfter;
      // Animate to the offset position
      await mapController.animateCamera(
        CameraUpdate.newLatLng(
          offsetLatLng
        ),
        duration: Duration(milliseconds: durationMs)
      );
    }

    void updateMapHold(bool value) {
      setState(() {
        isHoldingMap = value;
      });
      // print(value);
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
      // print(screenPoint);
    }

    void _addMemory(LatLng position) async {
      final info = await getAddressFromLocation(position, locIQ);
      setState(() {
        memories.add(MemoryData(
          position: position,
          addressString: info,
          mood: Mood.happy,
          decay: mapZoom
        ));
      });
      updateMapHold(false);

    }

    @override
    Widget build(BuildContext context) {
      return Stack(
        children: [
          
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              updateMapHold(!isHoldingMap);
              if (!considerTapAsDouble) {
                waitForDoubleTap();
              }
              else {
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
              
              styleString: "https://api.maptiler.com/maps/dataviz/style.json?key=gyEpeYKGmrox3x3xvhNk",
              onMapCreated: (controller) async {
                mapController = controller;

                await updateLocation();
              },
              onCameraIdle: () async {
                _updateScreenPoint();
                updateMapHold(false);
                var pos = await mapController.queryCameraPosition();
                updateZoom(pos!.zoom);
                // Only close preview if not animating to a memory
                if (!isAnimatingToMemory) {
                  closePreview();
                } else {
                  // Reset flag after animation completes
                  isAnimatingToMemory = false;
                }
                // debugPrint("${pos.zoom}");
              },

              onCameraTrackingChanged: (mode) => updateMapHold(true),

              

              onCameraMove: (pos) {
                updateMapHold(true);

              },
              onMapLongClick: (point, latLng) {
                // currentPosition = latLng;
                // await _updateAddress();
                // _updateScreenPoint();
                _addMemory(latLng);
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(14.5995, 120.9842), // Manila
                zoom: 16.0,
              ),
            ),
          ),
            
              for (final memory in memories)
              MemoryPin(
                position: memory.position,
                addressString: memory.addressString,
                decay: memory.decay,
                mapController: mapController,
                isHoldingMap: isHoldingMap,
                mood: memory.mood,
                imageUrl: memory.imageUrl,
                holdingCallback: updateMapHold,
                mapZoom: mapZoom,
                showPreview: false, // Don't show preview in pin itself
                onShowMemory: showMemory,
                onClosePreview: closePreview,
                onLongPress: () {
                  animateCameraWithOffset(
                    target: memory.position,
                    showPreviewAfter: true,
                    yOffsetPixels: 0
                    );
                },
              ),
              if (screenPoint != null) 
              Positioned(
                left: screenPoint!.x/pixelRatio! - 75, // adjust to center icon
                top: screenPoint!.y/pixelRatio! - 50,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    updateMapHold(true);
                    closePreview();
                    await mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(currentPosition.latitude, currentPosition.longitude),
                        14
                      ),
                      duration: Duration(milliseconds: 1000)
                    );
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
                  )
                ),
              ),
              
              // Render active memory preview on top of all pins
              if (activeMemory != null)
                FutureBuilder<Point>(
                  future: mapController.toScreenLocation(activeMemory!.position),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    
                    final screenPoint = snapshot.data!;
                    final previewWidth = 100.0;
                    final pinHeight = 60.0;
                    final previewHeight = 108.0;
                    final totalHeight = pinHeight + previewHeight;
                    
                    return Positioned(
                      left: screenPoint.x/pixelRatio! - (previewWidth / 2),
                      top: screenPoint.y/pixelRatio! - totalHeight,
                      child: AnimatedOpacity(
                          opacity: !isHoldingMap ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 100),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 68), // Space for pin below
                            child: GestureDetector(
                              onTap: () async {
                                updateMapHold(true);
                                widget.propagateMemory(activeMemory!);
                                await animateCameraWithOffset(
                                  target: activeMemory!.position,  
                                );
                                
                              },
                              child: MemoryPreview(
                                addressString: activeMemory!.addressString,
                                mood: activeMemory!.mood,
                                imageUrl: activeMemory!.imageUrl,
                                onClose: closePreview,
                              ),
                            )
                          ),
                        ),
                    );
                  },
                ),
        ]
      );
    }
  }

  Future<Position?> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check permission
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

    // Get current position
    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(accuracy: LocationAccuracy.high)
    );
  }