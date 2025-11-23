import 'package:flutter/material.dart';
import 'memory_preview.dart';
import 'globals.dart';
import 'memory.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MemoryPinWidget extends StatelessWidget {
  final List<MemoryData> memories;
  final bool showPreviews;
  final VoidCallback onClosePreviews;

  const MemoryPinWidget({
    super.key,
    required this.memories,
    this.showPreviews = false,
    required this.onClosePreviews,
  });

  // Get the primary mood (most common or first)
  Mood _getPrimaryMood() {
    if (memories.isEmpty) return Mood.happy;
    
    // Count mood occurrences
    final moodCounts = <Mood, int>{};
    for (var memory in memories) {
      moodCounts[memory.mood] = (moodCounts[memory.mood] ?? 0) + 1;
    }
    
    // Return most common mood
    return moodCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get primary color based on primary mood
  Color _getPrimaryColor() {
    return getMoodColor(_getPrimaryMood());
  }

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return const SizedBox.shrink();
    }

    final primaryMood = _getPrimaryMood();
    final primaryColor = _getPrimaryColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Empty space to maintain layout when previews are shown
        // (previews are rendered at map level, not here)
        if (showPreviews && memories.isNotEmpty)
          SizedBox(
            height: memories.length == 1 ? 140 : 
                   memories.length <= 3 ? 140 : 140,
          ),
        
        // Pin marker with proper clip behavior for shadows
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                child: Image(
                  image: getMoodIcon(primaryMood),
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // Memory count badge
            if (memories.length > 1)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
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
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      '${memories.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        // Pin pointer
        Container(
          padding: const EdgeInsets.only(top: 2),
          child: CustomPaint(
            size: const Size(20, 10),
            painter: PinPointerPainter(color: primaryColor),
          ),
        )
      ],
    );
  }
}

class PinPointerPainter extends CustomPainter {
  final Color color;

  PinPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ClusterPin extends StatelessWidget {
  final int count;
  final LatLng position;
  final MapLibreMapController mapController;
  final bool isHoldingMap;
  final void Function(bool value) holdingCallback;
  final void Function() clusterCallback;

  const ClusterPin({
    super.key,
    required this.count,
    required this.position,
    required this.mapController,
    required this.isHoldingMap,
    required this.holdingCallback,
    required this.clusterCallback
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isHoldingMap ? 0.0 : 1.0,
      duration: Duration(milliseconds: 100),
      child: GestureDetector(
        onTap: () async {
          holdingCallback.call(true);
          CameraPosition? camPos = await mapController.queryCameraPosition();
          await mapController.animateCamera(
            CameraUpdate.newLatLngZoom(position, camPos!.zoom + 2),
            duration: Duration(milliseconds: 800),
          );
          holdingCallback.call(true);
          clusterCallback.call();
          await Future.delayed(Duration(milliseconds: 250));

          holdingCallback.call(false);
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}