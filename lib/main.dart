import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'pin.dart';

num? pixelRatio;

void main(){
  MapLibreMap.useHybridComposition = true;
    runApp(Root());
}

class Root extends StatelessWidget {
    const Root({super.key});

    @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        title: "Memoir",
        home: MyScaffold(),
    );
  }
}

class MyScaffold extends StatefulWidget {
  const MyScaffold({super.key});

  @override
  State<MyScaffold> createState() => MyState();
}

class MapBody extends StatefulWidget {
  const MapBody({super.key});

  @override
  State<MapBody> createState() => MapState();
}

class MapState extends State<MapBody> {
LatLng? currentPosition;
late MapLibreMapController mapController;
Point? screenPoint;
bool isHoldingMap = false;
double pinAlpha = 1;

  @override
  void initState() {
    super.initState();
    _getLocation();
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
  }

  Future<void> _updateScreenPoint() async {
    if (currentPosition == null) return;
    final point = await mapController.toScreenLocation(currentPosition!);
    setState(() => screenPoint = point);
    // print(screenPoint);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        
        Listener(
          behavior: HitTestBehavior.translucent,
          // onPointerDown: (event) {
          //   if event.
          //   updateMapHold(!isHoldingMap);
          // },

          onPointerDown: (event) {
            updateMapHold(!isHoldingMap);
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
            onCameraIdle: () {
              _updateScreenPoint();
              updateMapHold(false);
            },

            initialCameraPosition: CameraPosition(
              target: LatLng(14.5995, 120.9842), // Manila
              zoom: 16.0,
            ),
          ),
        ),
          if (screenPoint != null) 
            Positioned(
              left: screenPoint!.x/pixelRatio! - 25, // adjust to center icon
              top: screenPoint!.y/pixelRatio! - 50,
              child: GestureDetector(
                onTap: () async {
                  updateMapHold(true);
                  await mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(currentPosition!.latitude, currentPosition!.longitude),
                      14
                    ),
                    duration: Duration(milliseconds: 1000)
    );
                },
                child: AnimatedOpacity(
                  opacity: isHoldingMap ? 0.0 : 1.0, 
                  duration: Duration(milliseconds: 100),
                  child: UserPin(
                    color: Colors.purple.shade300,
                  ),
                )
              ),
            ),
      ]
    );
  }
}

class MyState extends State<MyScaffold> {
  final _textFocusNode = FocusNode();


  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final currentFocus = FocusScope.of(context);
        if (_textFocusNode.hasFocus) {
      // get RenderBox for TextField
      final renderBox = _textFocusNode.context?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        final rect = offset & size; // rectangle of the TextField

        // check if tap is inside
        if (rect.contains(event.position)) {
          // tapped on TextField itself → do nothing
          return;
        }
      }
      // tapped outside → unfocus
      currentFocus.unfocus();
    }
      },
      child: Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          MapBody()
          ,       
          IgnorePointer( // so touches go to the map
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: AlignmentGeometry.xy(0, 0.075),
            radius: 1.0,
            colors: [
              Colors.transparent,   // center is clear
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.3),
            ],
            stops: [0.7, 0.9, 1.0],
            
          ),
        ),
      ),
    ),
          Container(
            margin: EdgeInsets.fromLTRB(10, 40, 10, 0),
            child: TextField(
              focusNode: _textFocusNode,
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: TextStyle(
                  color: Colors.grey
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none
                ),
                suffixIcon: Container(
                  child: CircleAvatar(),
                  margin: EdgeInsets.fromLTRB(0, 0, 12, 0),
                ),
                fillColor: Colors.white
              )
              
            )),
        ],
      )
      
      
    ,
    )
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