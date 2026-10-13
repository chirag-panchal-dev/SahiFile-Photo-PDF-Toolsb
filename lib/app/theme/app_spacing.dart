import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Spacing grid (4dp base)
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;

  // Corner Radii
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0; // buttons / text fields
  static const double radiusLg = 22.0; // cards
  static const double radiusXl = 28.0; // sheets / modals
  static const double radiusFull = 999.0;

  // Screen horizontal margins
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );

  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: 20.0,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(18.0);
}
