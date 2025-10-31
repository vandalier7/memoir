import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isFlashMenuOpen = false;
  bool _isTimerMenuOpen = false;
  bool _isFlashOn = false;
  int _selectedTimer = 0;
  bool _isRearCamera = true;
  bool _isInitialized = false;
  bool _shutterPressed = false;
  int _countdown = 0;
  bool _showGlow = false; // trigger for glow

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final camera = widget.cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => widget.cameras.first);
    _controller = CameraController(camera, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _switchCamera() async {
    final lensDirection =
        _isRearCamera ? CameraLensDirection.front : CameraLensDirection.back;
    final newCamera = widget.cameras.firstWhere(
      (cam) => cam.lensDirection == lensDirection,
      orElse: () => widget.cameras.first,
    );

    setState(() {
      _isRearCamera = !_isRearCamera;
    });

    await _controller?.dispose();
    _controller = CameraController(newCamera, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  void _setTimer(int seconds) {
    setState(() {
      _selectedTimer = seconds;
      _isTimerMenuOpen = false;
    });
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_selectedTimer > 0) {
      setState(() {
        _countdown = _selectedTimer;
      });

      while (_countdown > 0) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        setState(() {
          _countdown -= 1;
        });
      }
    }

    setState(() {
      _countdown = 0;
      _showGlow = true;
    });

    // Glow fade out after a short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showGlow = false);
    });

    final image = await _controller!.takePicture();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(imagePath: image.path),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
    double size = 40,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: active ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.3),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 1)
                  ]
                : [],
          ),
          child: child ?? Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildHorizontalMenu(List<Widget> items, bool isOpen) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        axis: Axis.horizontal,
        child: child,
      ),
      child: isOpen
          ? ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: items
                        .map((item) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: item,
                            ))
                        .toList(),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTimerMenu() {
    final timers = [0, 3, 5, 10];
    return _buildHorizontalMenu(
      timers
          .map((sec) => _buildCircularButton(
                icon: Icons.timer,
                onTap: () => _setTimer(sec),
                active: _selectedTimer == sec,
                size: 38,
                child: Center(
                  child: Text(
                    sec == 0 ? 'Off' : '$sec',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ))
          .toList(),
      _isTimerMenuOpen,
    );
  }

  Widget _buildFlashMenu() {
    final flashModes = [
      {'icon': Icons.flash_auto, 'mode': FlashMode.auto},
      {'icon': Icons.flash_on, 'mode': FlashMode.torch},
      {'icon': Icons.flash_off, 'mode': FlashMode.off},
    ];

    return _buildHorizontalMenu(
      flashModes
          .map((f) => _buildCircularButton(
                icon: f['icon'] as IconData,
                onTap: () {
                  _controller?.setFlashMode(f['mode'] as FlashMode);
                  setState(() {
                    _isFlashOn = f['mode'] == FlashMode.torch;
                    _isFlashMenuOpen = false;
                  });
                },
                active: (_controller?.value.flashMode == f['mode'] as FlashMode),
                size: 38,
              ))
          .toList(),
      _isFlashMenuOpen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 25.0;
    final captureWidth = 80.0;
    final captureHeight = 80.0;
    final historySize = 60.0;

    return Scaffold(
      body: _isInitialized
          ? Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),

                // Magical glow effect
                AnimatedOpacity(
                  opacity: _showGlow ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                  ),
                ),

                // Countdown
                if (_countdown > 0)
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Top-right controls
                Positioned(
                  top: 50,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFlashMenu(),
                          const SizedBox(width: 8),
                          _buildCircularButton(
                            icon: Icons.flash_on,
                            onTap: () => setState(() {
                              _isFlashMenuOpen = !_isFlashMenuOpen;
                              _isTimerMenuOpen = false;
                            }),
                            active: _isFlashOn,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTimerMenu(),
                          const SizedBox(width: 8),
                          _buildCircularButton(
                            icon: Icons.timer,
                            onTap: () => setState(() {
                              _isTimerMenuOpen = !_isTimerMenuOpen;
                              _isFlashMenuOpen = false;
                            }),
                            active: _isTimerMenuOpen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCircularButton(
                        icon: Icons.cameraswitch,
                        onTap: _switchCamera,
                      ),
                    ],
                  ),
                ),

                // Top-left close
                Positioned(
                  top: 50,
                  left: 20,
                  child: _buildCircularButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                ),

                // Bottom-left history
                Positioned(
                  bottom: bottomPadding + (captureHeight / 2 - historySize / 2),
                  left: 25,
                  child: _buildCircularButton(
                    icon: Icons.history,
                    onTap: () {},
                    size: historySize,
                  ),
                ),

                // Bottom-center capture
                Positioned(
                  bottom: bottomPadding,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTapDown: (_) {
                        setState(() => _shutterPressed = true);
                      },
                      onTapUp: (_) {
                        setState(() => _shutterPressed = false);
                        _takePhoto();
                      },
                      onTapCancel: () {
                        setState(() => _shutterPressed = false);
                      },
                      child: AnimatedScale(
                        scale: _shutterPressed ? 0.85 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          width: captureWidth,
                          height: captureHeight,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.9),
                              width: 5,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
