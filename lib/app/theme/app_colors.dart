import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Light Palette
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGlassSurface = Color(0xD8FFFFFF); // ~85% opacity
  static const Color lightGlassBorder = Color(0x334E8CFF);
  static const Color lightTextPrimary = Color(0xFF172033);
  static const Color lightTextSecondary = Color(0xFF647089);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE5E9F2);

  // Dark Palette
  static const Color darkBackground = Color(0xFF0D1220);
  static const Color darkSurface = Color(0xFF151C2E);
  static const Color darkGlassSurface = Color(0xB21A233A); // ~70% opacity
  static const Color darkGlassBorder = Color(0x288987FF);
  static const Color darkTextPrimary = Color(0xFFF4F6FF);
  static const Color darkTextSecondary = Color(0xFFA8B0C5);
  static const Color darkCardBg = Color(0xFF151C2E);
  static const Color darkDivider = Color(0xFF232D47);

  // Accents (Shared & Mode Adaptive)
  static const Color accentIndigo = Color(0xFF5B5CE2);
  static const Color accentIndigoDark = Color(0xFF8987FF);
  static const Color accentBlue = Color(0xFF4E8CFF);
  static const Color accentCyan = Color(0xFF58C7D9);
  static const Color accentCyanDark = Color(0xFF6DD5E7);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1F10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1FF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1FEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0x1F3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5B5CE2), Color(0xFF4E8CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentCyanGradient = LinearGradient(
    colors: [Color(0xFF4E8CFF), Color(0xFF58C7D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassLightGradient = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0x99F6F7FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassDarkGradient = LinearGradient(
    colors: [Color(0xD81E2942), Color(0x99131A2C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
