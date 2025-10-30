import 'package:flutter/material.dart';

const ColorScheme memoirTheme = ColorScheme(
  brightness: Brightness.light,

  // 🎨 Core colors (your 4 seeds)
  primary: Color(0xFFF7CAC9),        // soft pink
  onPrimary: Color(0xFF442C2E),      // dark text on pink

  secondary: Color(0xFFFDEBD0),      // light pastel beige
  onSecondary: Color(0xFF4A3F35),    // readable brownish text

  tertiary: Color(0xFFF75270),       // vibrant accent pink
  onTertiary: Colors.white,          // white text for contrast

  error: Color(0xFFDC143C),          // crimson red
  onError: Colors.white,   // deep brown-gray text

  surface: Color(0xFFFFF1EE),        // card/panel tone
  onSurface: Color(0xFF2E1F1C),      // readable dark text

  surfaceContainerHighest: Color(0xFFFBE4E2), // subtle pinkish variant
  onSurfaceVariant: Color(0xFF5E4A45),

  // 🪞 Support tones
  outline: Color(0xFFD8B4AF),        // soft muted border
  shadow: Color(0x33000000),         // subtle drop shadow
  inverseSurface: Color(0xFF4A3F3A),
  onInverseSurface: Color(0xFFFFEDEA),
  inversePrimary: Color(0xFFE899A1),
  surfaceTint: Color(0xFFF7CAC9),
);
