import 'package:flutter/material.dart';
import './circle_button.dart';
import '../app_theme.dart'; // path to your memoirTheme

class MapButtons extends StatelessWidget {
  const MapButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera button with transparent fill + gradient border + gradient icon
        Positioned(
          bottom: 20,
          right: 10,
          child: Material( // needed for ripple effect
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              splashColor: const Color(0xFFF75270).withOpacity(0.3),
              onTap: () => debugPrint('Camera tapped'),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 120),
                scale: 1.0, 
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
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
                  ),
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
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

         // Bin button
        Positioned(
          bottom: 100,
          right: 22,
          child: CircleButton(
            onTap: () => debugPrint('Bin tapped'),
            icon: Icons.delete_outline,
            bgColor: memoirTheme.surface,
            iconColor: memoirTheme.onSurface,
            size: 53,
            semanticLabel: 'Bin',
          ),
        ),
      ],
    );
  }
}
