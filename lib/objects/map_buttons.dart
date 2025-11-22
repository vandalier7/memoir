import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import './circle_button.dart';
import '../app_theme.dart';
import '../screens/bin_screen.dart';
import 'package:presentation/camera_ui/camera_screen.dart';
import 'globals.dart';

class MapButtons extends StatefulWidget {
  final bool showLocationError;
  final VoidCallback onRetryLocation;
  final VoidCallback onPanToLocation;
  
  const MapButtons({
    super.key, 
    required this.showLocationError,
    required this.onRetryLocation,
    required this.onPanToLocation,
  });

  @override
  State<MapButtons> createState() => _MapButtonsState();
}

class _MapButtonsState extends State<MapButtons> {
  bool isRetrying = false;

  Future<void> _handleLocationButton() async {
    if (widget.showLocationError) {
      // Handle error case
      setState(() {
        isRetrying = true;
      });

      try {
        widget.onRetryLocation();
        
        await Future.delayed(Duration(milliseconds: 1500));
        
        if (widget.showLocationError) {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          LocationPermission permission = await Geolocator.checkPermission();
          
          if (!serviceEnabled || permission == LocationPermission.deniedForever) {
            await Geolocator.openLocationSettings();
          }

          await Future.delayed(Duration(milliseconds: 3500));
        }
      } finally {
        if (mounted) {
          setState(() {
            isRetrying = false;
          });
        }
      }
    } else {
      // No error - pan to location
      widget.onPanToLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera button
        // Camera button - disabled when location error
      Positioned(
        bottom: 15,
        right: 15,
        child: Opacity(
          opacity: widget.showLocationError ? 0.5 : 1.0,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              splashColor: widget.showLocationError 
                  ? Colors.transparent 
                  : const Color(0xFFF75270).withOpacity(0.3),
              onTap: widget.showLocationError 
                  ? null  // Disabled when location error
                  : () {
                      Navigator.pushNamed(context, '/camera');
                    },
              child: AnimatedScale(
                duration: const Duration(milliseconds: 120),
                scale: 1.0,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.showLocationError
                          ? [
                              Colors.grey.shade400,
                              Colors.grey.shade500,
                              Colors.grey.shade600,
                            ]
                          : const [
                              Color(0xFFF75270),
                              Color.fromARGB(255, 250, 132, 154),
                              Color.fromARGB(255, 252, 165, 181),
                              Color.fromARGB(255, 245, 200, 157),
                              Color.fromARGB(255, 248, 217, 174),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.showLocationError 
                            ? Colors.grey.shade500 
                            : Color(0xFFF75270)).withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
        
        // Location button (always shows - changes based on error state)
        Positioned(
          bottom: 152,
          right: 23,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: widget.showLocationError 
                ? memoirTheme.error.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                if (widget.showLocationError && !isRetrying) {
                  _handleLocationButton();
                }
                else if (!widget.showLocationError) {
                  widget.onPanToLocation.call();
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.showLocationError 
                      ? memoirTheme.error 
                      : memoirTheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.showLocationError 
                          ? memoirTheme.error.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.showLocationError && isRetrying
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        widget.showLocationError 
                            ? Icons.location_off
                            : Icons.my_location,
                        size: 22,
                        color: widget.showLocationError 
                            ? Colors.white 
                            : Colors.black,
                      ),
              ),
            ),
          ),
        ),
        
        // Bin button
        Positioned(
          bottom: 97,
          right: 23,
          child: CircleButton(
            onTap: () {
              Navigator.pushNamed(context, '/bin');
            },
            icon: Icons.history_toggle_off_outlined,
            bgColor: memoirTheme.surface,
            iconColor: memoirTheme.onSurface,
            size: 44,
            semanticLabel: 'Bin',
          ),
        ),
      ],
    );
  }
}