import 'package:flutter/material.dart';
import './circle_button.dart';
import '../app_theme.dart'; // path to your memoirTheme

class MapButtons extends StatelessWidget {
  const MapButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // bottom-right main action (pink)
        //Positioned(
          //bottom: 24,
          //right: 20,
          //child: CircleButton(
            //onTap: () => debugPrint('Main action tapped'),
            //icon: Icons.favorite,
            //bgColor: memoirTheme.tertiary,     // vivid pink
            //iconColor: memoirTheme.onTertiary, // usually white
            //size: 64,
            //semanticLabel: 'Favorite',
            //elevation: 12,
          //),
        //),

        // slightly above the main action (camera)
        // Camera button with gradient
          // Camera button with soft fill + gradient outline
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


        // bottom-left pill-like "Map Memories"
        //Positioned(
          //bottom: 20,
          //left: 14,
          //child: ElevatedButton.icon(
            //onPressed: () => debugPrint('Map Memories'),
            //icon: Icon(Icons.map, color: memoirTheme.onSurface),
            //label: Text(
              //'Map Memories',
              //style: TextStyle(color: memoirTheme.onSurface),
            //),
            //style: ElevatedButton.styleFrom(
              //backgroundColor: memoirTheme.surface, // soft card color
              //elevation: 6,
              //padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              //shape: RoundedRectangleBorder(
                //borderRadius: BorderRadius.circular(16),
                //side: BorderSide(color: memoirTheme.surfaceVariant.withOpacity(0.6)),
              //),
            //),
          //),
        //),

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

         // Calendar button
        /*Positioned(
          top: 35,
          right: 10,
          child: CircleButton(
            onTap: () => debugPrint('Calendar tapped'),
            icon: Icons.calendar_today_outlined,
            bgColor: memoirTheme.surface,
            iconColor: memoirTheme.onSurface,
            size: 52,
            semanticLabel: 'Calendar',
          ),
        ),
         // Settings button
        //Positioned(
          //top: 35,
          //left: 10,
          //child: CircleButton(
            //onTap: () => debugPrint('Settings tapped'),
            //icon: Icons.settings_outlined,
            //bgColor: memoirTheme.surface,
            //iconColor: memoirTheme.onSurface,
            //size: 52,
            //semanticLabel: 'Settings',
          //),
        //),*/
      ],
    );
  }
}
