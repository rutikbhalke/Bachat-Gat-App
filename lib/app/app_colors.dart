import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ------------------------------------------------------------
  // Brand Colors - Premium Pink / Rose Fintech Palette
  // ------------------------------------------------------------

  static const Color primary = Color(0xFFC2185B); // Deep Pink
  static const Color primaryLight = Color(0xFFF06292); // Light Pink
  static const Color primaryDark = Color(0xFF880E4F); // Dark Rose

  // Backward compatibility
  static const Color secondary = Color(0xFFAD1457);
  static const Color accent = Color(0xFFFCE4EC);

  // ------------------------------------------------------------
  // Status Colors
  // ------------------------------------------------------------

  static const Color success = Color(0xFF00897B); // Teal
  static const Color warning = Color(0xFFF9A825); // Amber
  static const Color error = Color(0xFFD32F2F); // Red
  static const Color info = Color(0xFF1976D2); // Blue

  // ------------------------------------------------------------
  // Background & Surfaces
  // ------------------------------------------------------------

  static const Color background = Color(0xFFFFF8FA);
  static const Color surface = Color(0xFFFFFFFF);

  // Very light pink surface
  static const Color surfaceVariant = Color(0xFFFCE4EC);

  // ------------------------------------------------------------
  // Text Colors
  // ------------------------------------------------------------

  static const Color textPrimary = Color(0xFF242124);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textMuted = Color(0xFFBDBDBD);

  // Text displayed on primary/pink backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ------------------------------------------------------------
  // Border & Divider
  // ------------------------------------------------------------

  static const Color border = Color(0xFFF1DDE5);
  static const Color divider = Color(0xFFF7E9EE);

  // ------------------------------------------------------------
  // Finance Specific Colors
  // ------------------------------------------------------------

  // Savings
  static const Color savings = Color(0xFF00897B);

  // Loans
  static const Color loan = Color(0xFFF57F17);

  // Interest
  static const Color interest = Color(0xFF8E24AA);

  // Collection
  static const Color collection = Color(0xFF0288D1);

  // ------------------------------------------------------------
  // Premium Pink Gradient
  // ------------------------------------------------------------

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDF327E),
      Color(0xFFE91E63),
      Color(0xFFE45383),
    ],
  );
}