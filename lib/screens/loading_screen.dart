import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final bool ignoring;
  final bool showLoadingBar; // Add this parameter

  const LoadingScreen({
    super.key, 
    required this.ignoring,
    this.showLoadingBar = true, // Default to true for backward compatibility
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
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
    return IgnorePointer(
      ignoring: widget.ignoring,
      child: AnimatedOpacity(
        opacity: widget.ignoring ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 500),
        child: Material(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: Image.asset("assets/logo.png"),
                  ),
                ),
                const SizedBox(height: 32),
                
                // App Name
                Text(
                  "Memoir",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                if (!widget.showLoadingBar) ...[
                  const SizedBox(height: 48),

                //   Text(
                //   "Memoir",
                //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                //     fontWeight: FontWeight.bold,
                //     color: Theme.of(context).colorScheme.onSurface,
                //   ),
                // ),
                ],
                
                // Conditionally show loading bar
                if (widget.showLoadingBar) ...[
                  const SizedBox(height: 48),
                  
                  // Sliding Loading Bar
                  SizedBox(
                    width: 200,
                    height: 4,
                    child: Stack(
                      children: [
                        // Background track
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Animated slider
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment(_animation.value, 0),
                              child: Container(
                                width: 80,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}