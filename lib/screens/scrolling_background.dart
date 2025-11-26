import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import '../objects/globals.dart';

class FloatingIcon {
  Offset position;
  double velocity; // Speed multiplier
  double size;
  Mood mood;
  double opacity;

  FloatingIcon({
    required this.position,
    required this.velocity,
    required this.size,
    required this.mood,
    required this.opacity,
  });
}

class InfiniteScrollingBackground extends StatefulWidget {
  final int iconCount;
  final double minVelocity;
  final double maxVelocity;
  final double minSize;
  final double maxSize;
  final double minOpacity;
  final double maxOpacity;
  final double rotationSpeed; // How fast the angle changes

  const InfiniteScrollingBackground({
    Key? key,
    this.iconCount = 20,
    this.minVelocity = 0.2,
    this.maxVelocity = 0.8,
    this.minSize = 40,
    this.maxSize = 120,
    this.minOpacity = 0.1,
    this.maxOpacity = 0.3,
    this.rotationSpeed = 0.001, // Default: full rotation in ~2 minutes
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
  double _currentAngle = 0;

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
        velocity: widget.minVelocity + _random.nextDouble() * (widget.maxVelocity - widget.minVelocity),
        size: widget.minSize + _random.nextDouble() * (widget.maxSize - widget.minSize),
        mood: mood,
        opacity: widget.minOpacity + _random.nextDouble() * (widget.maxOpacity - widget.minOpacity),
      );
    });
  }

  void _updatePositions() {
    if (_screenSize == null) return;

    setState(() {
      // Slowly rotate through 360 degrees
      _currentAngle += widget.rotationSpeed;
      if (_currentAngle > 2 * pi) {
        _currentAngle -= 2 * pi;
      }

      // Calculate direction based on current angle
      final direction = Offset(cos(_currentAngle), sin(_currentAngle));

      for (var icon in _icons) {
        // Move in the slowly rotating direction with varying velocity
        icon.position += direction * icon.velocity;

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
    return CustomPaint(
      painter: _FloatingIconsPainter(_icons),
      child: Container(),
    );
  }
}

class _FloatingIconsPainter extends CustomPainter {
  final List<FloatingIcon> icons;

  _FloatingIconsPainter(this.icons);

  @override
  void paint(Canvas canvas, Size size) {
    for (var icon in icons) {
      final image = preloadedMoodIcons[icon.mood];
      if (image == null) continue;

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
        image: image,
        filterQuality: FilterQuality.high,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FloatingIconsPainter oldDelegate) => true;
}

// Usage example:
// Use it as a child in your Stack
/*
Stack(
  children: [
    InfiniteScrollingBackground(
      iconCount: 20,
      minVelocity: 0.2,    // Slowest icon speed
      maxVelocity: 0.8,    // Fastest icon speed
      minSize: 40,         // Smallest icon size
      maxSize: 120,        // Largest icon size
      minOpacity: 0.1,     // Most transparent
      maxOpacity: 0.3,     // Most opaque
      rotationSpeed: 0.001, // Speed of angle rotation (higher = faster)
    ),
    // Your other content here
    YourActualContent(),
  ],
)
*/