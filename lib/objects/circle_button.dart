import 'package:flutter/material.dart';
import '../app_theme.dart'; // adjust path to where you keep memoirTheme

/// A small circular icon button styled from the memoirTheme.
/// [bgColor] is the background color (use memoirTheme.primary/tertiary/etc).
/// [iconColor] defaults to the matching onColor from the scheme (if provided).
class CircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double size;
  final Color bgColor;
  final Color? iconColor;
  final String? semanticLabel;
  final double elevation;

  const CircleButton({
    Key? key,
    required this.onTap,         
    required this.icon,
    required this.bgColor,
    this.iconColor,
    this.size = 56,
    this.semanticLabel,
    this.elevation = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a Material + InkWell so we get proper touch ripple and semantics
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          splashColor: bgColor.withOpacity(0.12),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // subtle radial gradient so the bubble feels soft
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor.withOpacity(0.98),
                  bgColor.withOpacity(0.92),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: memoirTheme.shadow, // your theme shadow color (already translucent)
                  blurRadius: elevation,
                  offset: Offset(0, elevation / 2),
                )
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: size * 0.5,
                color: iconColor ?? _bestIconColor(bgColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // best-effort to decide white vs dark icon depending on background luminance
  Color _bestIconColor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }
}
