import 'dart:io';
import 'package:flutter/material.dart';

class PreviewScreen extends StatelessWidget {
  final String imagePath;
  const PreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen captured image
          Center(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),

          // Top-left close / discard button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pop(context); // Discard: back to camera
              },
            ),
          ),

          // Bottom action buttons
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Discard / Retake
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to camera
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                  child: const Text("Discard"),
                ),
                const SizedBox(width: 20),

                // Confirm / Next
                ElevatedButton(
                  onPressed: () {
                    // Navigate to next tab or screen
                    // Example:
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => NextTabScreen()));
                    Navigator.pop(context, imagePath); // Return image path
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                  child: const Text("Confirm"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
