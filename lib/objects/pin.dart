import 'package:flutter/material.dart';
import 'package:presentation/objects/globals.dart';
import 'memory.dart';
import 'package:presentation/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserPin extends StatelessWidget {
  final List<MemoryData> memories;
  final bool showPreviews;
  final VoidCallback? onTap;
  final bool showLabel;

  const UserPin({
    super.key,
    this.memories = const [],
    this.showPreviews = false,
    this.onTap,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
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
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: const Color(0xFFF75270).withOpacity(0.3),
                onTap: onTap,
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
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: StreamBuilder<Map<String, dynamic>>(
                      stream: databaseService.getUserStream(storageService.currentUserId!),
                      builder: (context, snapshot) {
                        String? avatarUrl;
                        if (snapshot.hasData) {
                          avatarUrl = snapshot.data!['profile_pic_url'];
                        }

                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: memoirTheme.primary.withValues(alpha: 0.2), // Lighter bg behind image
                          // If URL exists, use it. If not, show default icon.
                          backgroundImage: avatarUrl != null 
                              ?  CachedNetworkImageProvider("$avatarUrl")
                              : const AssetImage('assets/temp.png')
                        );
                      },
                    )
                ),
              ),
            ),
            
            // Memory count badge
            if (memories.isNotEmpty)
              Positioned(
                top: -6,
                right: -6,
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

        // Pin pointer with gradient
        Container(
          padding: const EdgeInsets.only(top: 2),
          child: CustomPaint(
            size: const Size(20, 10),
            painter: PinPointerPainter(
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

class PinPointerPainter extends CustomPainter {
  final Gradient gradient;

  PinPointerPainter({required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

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