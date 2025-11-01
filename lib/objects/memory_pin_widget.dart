import 'package:flutter/material.dart';
import 'memory_preview.dart';
import 'globals.dart';

class MemoryPinWidget extends StatelessWidget {
  final String addressString;
  final Color color;
  final bool showPreview;
  final Mood mood;
  final String? imageUrl;
  final VoidCallback onClosePreview;

  const MemoryPinWidget({
    super.key,
    required this.addressString,
    this.color = Colors.yellow,
    this.showPreview = false,
    required this.mood,
    this.imageUrl,
    required this.onClosePreview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preview above pin
        if (showPreview)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MemoryPreview(
              addressString: addressString,
              mood: mood,
              imageUrl: imageUrl,
              onClose: onClosePreview,
            ),
          ),
        
        // Pin marker
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
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
          child: Icon(
            mood == Mood.happy ? Icons.sentiment_very_satisfied : Icons.sentiment_dissatisfied,
            color: Colors.white,
            size: 28,
          ),
        ),
        
        // Pin pointer
        Container(
          padding: EdgeInsets.only(top: 2),
          child: CustomPaint(
          size: const Size(20, 10),
          painter: PinPointerPainter(color: color),
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