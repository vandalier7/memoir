import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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

  void _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_selectedTimer > 0) {
      await Future.delayed(Duration(seconds: _selectedTimer));
    }
    await _controller!.takePicture();
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
          child: Icon(icon, color: Colors.white, size: 22),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                icon: sec == 0 ? Icons.timer_off : Icons.timer,
                onTap: () => _setTimer(sec),
                active: _selectedTimer == sec,
                size: 38,
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
    return Scaffold(
      body: _isInitialized
          ? Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_controller!),
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

                // Bottom-left bin
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: _buildCircularButton(
                    icon: Icons.delete,
                    onTap: () {},
                  ),
                ),

                // Bottom-center capture button
                Positioned(
                  bottom: 25,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        width: 80,
                        height: 80,
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
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
