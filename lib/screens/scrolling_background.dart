import 'package:flutter/material.dart';
import 'dart:math';
import '../objects/globals.dart';

class FloatingIcon {
  Offset position;
  Offset velocity;
  double size;
  AssetImage icon;
  double opacity;

  FloatingIcon({
    required this.position,
    required this.velocity,
    required this.size,
    required this.icon,
    required this.opacity,
  });
}

class InfiniteScrollingBackground extends StatefulWidget {
  final Widget child;
  final int iconCount;

  const InfiniteScrollingBackground({
    Key? key,
    required this.child,
    this.iconCount = 15,
  }) : super(key: key);

  @override
  State<InfiniteScrollingBackground> createState() =>
      _InfiniteScrollingBackgroundState();
}

class _InfiniteScrollingBackgroundState
    extends State<InfiniteScrollingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<FloatingIcon> _icons = [];
  final Random _random = Random();
  Size? _screenSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_updatePositions);
    _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenSize == null) {
      _screenSize = MediaQuery.of(context).size;
      _initializeIcons();
    }
  }

  void _initializeIcons() {
    if (_screenSize == null) return;

    final moods = Mood.values;
    _icons = List.generate(widget.iconCount, (index) {
      final mood = moods[_random.nextInt(moods.length)];
      return FloatingIcon(
        position: Offset(
          _random.nextDouble() * _screenSize!.width,
          _random.nextDouble() * _screenSize!.height,
        ),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 0.5, // Slow random X velocity
          (_random.nextDouble() - 0.5) * 0.5, // Slow random Y velocity
        ),
        size: 40 + _random.nextDouble() * 80, // Size between 40-120
        icon: getMoodIcon(mood),
        opacity: 0.1 + _random.nextDouble() * 0.2, // Opacity 0.1-0.3
      );
    });
  }

  void _updatePositions() {
    if (_screenSize == null) return;

    setState(() {
      for (var icon in _icons) {
        // Update position
        icon.position += icon.velocity;

        // Wrap around screen edges for infinite scrolling
        if (icon.position.dx < -icon.size) {
          icon.position = Offset(_screenSize!.width + icon.size, icon.position.dy);
        } else if (icon.position.dx > _screenSize!.width + icon.size) {
          icon.position = Offset(-icon.size, icon.position.dy);
        }

        if (icon.position.dy < -icon.size) {
          icon.position = Offset(icon.position.dx, _screenSize!.height + icon.size);
        } else if (icon.position.dy > _screenSize!.height + icon.size) {
          icon.position = Offset(icon.position.dx, -icon.size);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background icons layer
        Positioned.fill(
          child: CustomPaint(
            painter: _FloatingIconsPainter(_icons),
          ),
        ),
        // Your actual content
        widget.child,
      ],
    );
  }
}

class _FloatingIconsPainter extends CustomPainter {
  final List<FloatingIcon> icons;

  _FloatingIconsPainter(this.icons);

  @override
  void paint(Canvas canvas, Size size) {
    for (var icon in icons) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(icon.opacity)
        ..filterQuality = FilterQuality.high;

      // Create a rect for the icon
      final rect = Rect.fromLTWH(
        icon.position.dx - icon.size / 2,
        icon.position.dy - icon.size / 2,
        icon.size,
        icon.size,
      );

      // Draw the icon with opacity
      canvas.saveLayer(rect, paint);
      paintImage(
        canvas: canvas,
        rect: rect,
        image: icon.icon as dynamic, // Note: This needs proper image loading
        filterQuality: FilterQuality.high,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FloatingIconsPainter oldDelegate) => true;
}

// Usage example:
// Wrap your screen content with this widget
/*
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InfiniteScrollingBackground(
        iconCount: 20, // Adjust number of icons
        child: YourActualContent(),
      ),
    );
  }
}
*/