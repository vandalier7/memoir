import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'objects/pin.dart';
import 'objects/memory.dart';
import 'objects/globals.dart';

import 'processes/location_iq.dart';



class MapBody extends StatefulWidget {
  const MapBody({super.key});

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

  double mapZoom = 16;

  List<MemoryData> memories = [];

  final locIQ = LocationIQService('pk.2e56aa59169aa53b63093b78aff0e291'); 

double pinAlpha = 1;

  @override
  void initState() {
    super.initState();
    _getLocation();
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

  void updateZoom(value) {
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
        prominence: mapZoom
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
            }
          },

          
          
          child: MapLibreMap(
            compassEnabled: false,
            
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
          if (screenPoint != null) 
            Positioned(
              left: screenPoint!.x/pixelRatio! - 75, // adjust to center icon
              top: screenPoint!.y/pixelRatio! - 50,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  updateMapHold(true);
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
            for (final memory in memories)
            MemoryPin(
              position: memory.position,
              addressString: memory.addressString,
              prominence: memory.prominence,
              mapController: mapController,
              isHoldingMap: isHoldingMap,
              mood: memory.mood,
              holdingCallback: updateMapHold,
              mapZoom: mapZoom,
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

