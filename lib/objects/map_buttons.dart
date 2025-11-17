import 'package:flutter/material.dart';
import './circle_button.dart';
import '../app_theme.dart'; // path to your memoirTheme
import '../screens/bin_screen.dart';
import 'package:presentation/camera_ui/camera_screen.dart';
import 'globals.dart';

class MapButtons extends StatelessWidget {
  const MapButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera button - smaller but still prominent with shadow
        Positioned(
          bottom: 15,
          right: 15,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              splashColor: const Color(0xFFF75270).withOpacity(0.3),
              onTap: () {
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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF75270),
                        Color.fromARGB(255, 250, 132, 154),
                        Color.fromARGB(255, 252, 165, 181),
                        Color.fromARGB(255, 245, 200, 157),
                        Color.fromARGB(255, 248, 217, 174),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFF75270).withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
<<<<<<< HEAD
                  child: const Icon(
                    Icons.camera_alt,
                    size: 26,
                    color: Colors.white,
=======
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent, // transparent background
                      ),
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF75270),
                              Color.fromARGB(255, 250, 132, 154),
                              Color.fromARGB(255, 245, 200, 157),
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcIn,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 30,
                          color: Colors.black,
                        ),
                      ),
                    ),
>>>>>>> account-settings
                  ),
                ),
              ),
            ),
          ),
        ),
        // Bin button - smaller and more subtle
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