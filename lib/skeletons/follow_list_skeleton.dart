import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_theme.dart';

class FollowersFollowingSkeleton extends StatefulWidget {
  const FollowersFollowingSkeleton({super.key});

  @override
  State<FollowersFollowingSkeleton> createState() => _FollowersFollowingSkeletonState();
}

class _FollowersFollowingSkeletonState extends State<FollowersFollowingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final rand = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: 5, // Show 10 skeleton items
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: memoirTheme.outline.withOpacity(0.2),
            indent: 76,
          ),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar skeleton
                  _SkeletonBox(
                    width: 48,
                    height: 48,
                    borderRadius: 24,
                    shimmerPosition: _animation.value,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Username skeleton
                        // _SkeletonBox(
                        //   width: 120,
                        //   height: 16,
                        //   borderRadius: 8,
                        //   shimmerPosition: _animation.value,
                        // ),
                        // const SizedBox(height: 6),
                        // Full name skeleton
                        _SkeletonBox(
                          width: 90,
                          height: 14,
                          borderRadius: 7,
                          shimmerPosition: _animation.value,
                        ),
                      ],
                    ),
                  ),
                  // Chevron skeleton
                  // _SkeletonBox(
                  //   width: 20,
                  //   height: 20,
                  //   borderRadius: 4,
                  //   shimmerPosition: _animation.value,
                  // ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final double shimmerPosition;

  const _SkeletonBox({
    this.width,
    required this.height,
    required this.borderRadius,
    required this.shimmerPosition,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: CustomPaint(
          painter: _ShimmerPainter(
            shimmerPosition: shimmerPosition,
            baseColor: Colors.pink[200]!.withAlpha(80),
            highlightColor: Colors.pink[100]!.withAlpha(80),
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double shimmerPosition;
  final Color baseColor;
  final Color highlightColor;

  _ShimmerPainter({
    required this.shimmerPosition,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor,
          highlightColor,
          highlightColor,
          baseColor,
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
        transform: _SlideGradientTransform(shimmerPosition),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) {
    return oldDelegate.shimmerPosition != shimmerPosition;
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double position;

  const _SlideGradientTransform(this.position);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * position, 0.0, 0.0);
  }
}