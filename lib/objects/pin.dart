import 'package:flutter/material.dart';
import 'globals.dart';

class UserPin extends StatelessWidget {
  final String addressString;
  final Color color;
  final bool showLabel;
  final VoidCallback? onTap;
  final List<Mood>? moods; // Multiple moods for gradient border
  final double borderWidth;

  const UserPin({
    super.key,
    required this.addressString,
    this.color = Colors.white,
    this.showLabel = true,
    this.onTap,
    this.moods,
    this.borderWidth = 4.0,
  });

  // Get color for each mood
  Color _getMoodColor(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return Colors.yellow;
      case Mood.sad:
        return Colors.blue;
      // Add more moods as needed
    }
  }

  // Generate gradient from moods
  Gradient? _getMoodGradient() {
    if (moods == null || moods!.isEmpty) return null;
    
    if (moods!.length == 1) {
      // Single mood - solid color
      final moodColor = _getMoodColor(moods![0]);
      return LinearGradient(
        colors: [moodColor, moodColor],
      );
    }
    
    // Multiple moods - create gradient
    final colors = moods!.map((mood) => _getMoodColor(mood)).toList();
    return SweepGradient(
      colors: colors,
      // Ensure smooth transition back to start
      stops: List.generate(colors.length, (i) => i / colors.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodGradient = _getMoodGradient();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label above pi

        // Pin marker with mood gradient border
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: const Color(0xFFF75270).withOpacity(0.3),
            onTap: onTap,
            child: moodGradient != null
                ? CustomPaint(
                    painter: GradientBorderPainter(
                      gradient: moodGradient,
                      strokeWidth: borderWidth,
                    ),
                    child: Container(
                      width: 50,
                      height: 50,
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
                            color: const Color(0xFFF75270).withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
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
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF75270).withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
          ),
        ),

        // Pin pointer
        Container(
          padding: const EdgeInsets.only(top: 2),
          child: CustomPaint(
            size: const Size(20, 10),
            painter: PinPointerPainter(
              color: color,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF75270),
                  Color.fromARGB(255, 250, 132, 154),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GradientBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;

  GradientBorderPainter({
    required this.gradient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PinPointerPainter extends CustomPainter {
  final Color color;
  final Gradient? gradient;

  PinPointerPainter({required this.color, this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    if (gradient != null) {
      paint.shader = gradient!.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    } else {
      paint.color = color;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}