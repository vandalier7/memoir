import 'package:flutter/material.dart';
import '../app_theme.dart';

// Reusable Shimmer Widget that can be used anywhere
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  
  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
        return _ShimmerScope(
          shimmerPosition: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  final double shimmerPosition;

  const _ShimmerScope({
    required this.shimmerPosition,
    required super.child,
  });

  static double of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();
    return scope?.shimmerPosition ?? 0.0;
  }

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) {
    return oldWidget.shimmerPosition != shimmerPosition;
  }
}

class ProfileSkeleton extends StatefulWidget {
  const ProfileSkeleton({super.key});

  @override
  State<ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<ProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
    return Container(
      color: memoirTheme.background,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return SingleChildScrollView(
            physics: const PageScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Profile Picture Skeleton
              SkeletonBox(
                width: 100,
                height: 100,
                borderRadius: 50,
                shape: BoxShape.circle,
              ),
              
              const SizedBox(height: 10),
              
              // Username Skeleton
              SkeletonBox(
                width: 150,
                height: 24,
                borderRadius: 12,
              ),
              
              const SizedBox(height: 12),
              
              // Stats Row Skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatSkeleton(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("•", style: TextStyle(color: Colors.grey, fontSize: 20)),
                  ),
                  _StatSkeleton(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("•", style: TextStyle(color: Colors.grey, fontSize: 20)),
                  ),
                  _StatSkeleton(),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Activity Preview Skeleton
              SkeletonBox(
                width: double.infinity,
                height: 160,
                borderRadius: 16,
              ),
              
              const SizedBox(height: 40),
              
              // Additional Content Skeleton
              SkeletonBox(
                width: double.infinity,
                height: 300,
                borderRadius: 16,
              ),
              
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    ),
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkeletonBox(
          width: 40,
          height: 20,
          borderRadius: 10,
        ),
        const SizedBox(height: 4),
        SkeletonBox(
          width: 60,
          height: 14,
          borderRadius: 7,
        ),
      ],
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 4,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final shimmerPosition = _ShimmerScope.of(context);
    
    if (shape == BoxShape.circle) {
      return ClipOval(
        child: Container(
          width: width ?? height,
          height: height,
          color: Colors.grey[300],
          child: CustomPaint(
            painter: _ShimmerPainter(
              shimmerPosition: shimmerPosition,
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
            ),
            child: Container(),
          ),
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: CustomPaint(
          painter: _ShimmerPainter(
            shimmerPosition: shimmerPosition,
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
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