import 'package:flutter/material.dart';

/// Centralized color definitions for the app.
/// All colors should be accessed through this class instead of hardcoding.
///
/// Usage:
/// ```dart
/// AppColors.textPrimary      // Direct access for light theme colors
/// AppColors.source.douban    // Brand colors (theme-independent)
/// ```
class AppColors {
  AppColors._();

  // ============================================================
  // SEMANTIC COLORS - Text
  // ============================================================

  /// Primary text color - for titles and important content
  /// Light: #1F2937 (Dark Gray)
  static const Color textPrimary = Color(0xFF1F2937);

  /// Secondary text color - for descriptions and less important content
  /// Light: #6B7280 (Cool Gray)
  static const Color textSecondary = Color(0xFF6B7280);

  /// Tertiary text color - for hints and placeholders
  /// Light: #9CA3AF
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Text color on primary/colored backgrounds
  static const Color textOnPrimary = Colors.white;

  /// Text color on dark backgrounds
  static const Color textOnDark = Colors.white;

  /// Disabled text color
  /// Light: #D1D5DB
  static const Color textDisabled = Color(0xFFD1D5DB);

  // ============================================================
  // SEMANTIC COLORS - Background & Surface
  // ============================================================

  /// Main page background
  static const Color background = Colors.white;

  /// Card/container surface color
  /// Light: #F9FAFB
  static const Color surface = Color(0xFFF9FAFB);

  /// Variant surface color (slightly darker)
  /// Light: #F3F4F6
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  /// Elevated surface (cards with shadows)
  static const Color surfaceElevated = Colors.white;

  /// Overlay/modal background
  static const Color overlay = Color(0x80000000);

  /// Placeholder background (for loading states)
  /// Light: #E5E7EB
  static const Color placeholder = Color(0xFFE5E7EB);

  /// Dark placeholder background
  /// Light: #1A2A3A
  static const Color placeholderDark = Color(0xFF1A2A3A);

  // ============================================================
  // SEMANTIC COLORS - Border & Divider
  // ============================================================

  /// Standard divider color
  /// Light: #E5E7EB
  static const Color divider = Color(0xFFE5E7EB);

  /// Border color for inputs and containers
  /// Light: #E5E7EB
  static const Color border = Color(0xFFE5E7EB);

  /// Focused border color
  static Color get borderFocused => primary;

  // ============================================================
  // SEMANTIC COLORS - Interactive States
  // ============================================================

  /// Hover state overlay
  static const Color hover = Color(0x0A000000);

  /// Pressed state overlay
  static const Color pressed = Color(0x1A000000);

  /// Disabled state background
  /// Light: #F3F4F6
  static const Color disabled = Color(0xFFF3F4F6);

  /// Selected state background
  static Color get selected => primary.withValues(alpha: 0.1);

  // ============================================================
  // BRAND COLORS
  // ============================================================

  /// Primary brand color - Indigo
  /// #6366F1
  static const Color primary = Color(0xFF6366F1);

  /// Primary variant - Darker Indigo
  /// #4F46E5
  static const Color primaryVariant = Color(0xFF4F46E5);

  /// Secondary color - Cool Gray
  /// #6B7280
  static const Color secondary = Color(0xFF6B7280);

  // ============================================================
  // FUNCTIONAL COLORS - Status
  // ============================================================

  /// Success color - Green
  /// #10B981
  static const Color success = Color(0xFF10B981);

  /// Warning color - Amber
  /// #F59E0B
  static const Color warning = Color(0xFFF59E0B);

  /// Error color - Red
  /// #DC2626
  static const Color error = Color(0xFFDC2626);

  /// Info color - Blue
  /// #3B82F6
  static const Color info = Color(0xFF3B82F6);

  // ============================================================
  // FUNCTIONAL COLORS - Rating
  // ============================================================

  /// High rating color (>=70%) - Green
  /// #21D07A
  static const Color ratingHigh = Color(0xFF21D07A);

  /// Medium rating color (40%-70%) - Yellow/Lime
  /// #D2D531
  static const Color ratingMedium = Color(0xFFD2D531);

  /// Low rating color (<40%) - Red
  /// #DB2360
  static const Color ratingLow = Color(0xFFDB2360);

  /// High rating background - Dark Green
  /// #204529
  static const Color ratingHighBg = Color(0xFF204529);

  /// Medium rating background - Dark Yellow
  /// #423D0F
  static const Color ratingMediumBg = Color(0xFF423D0F);

  /// Low rating background - Dark Red
  /// #571435
  static const Color ratingLowBg = Color(0xFF571435);

  /// Rating circle background
  /// #081C22
  static const Color ratingCircleBg = Color(0xFF081C22);

  // ============================================================
  // FUNCTIONAL COLORS - Star/Collection
  // ============================================================

  /// Active star color - Amber
  static const Color starActive = Colors.amber;

  /// Inactive star color
  /// Light: Grey 400
  static const Color starInactive = Color(0xFFBDBDBD);

  /// Gold color for rankings
  /// #FFD700
  static const Color gold = Color(0xFFFFD700);

  /// Gold dark variant
  /// #B8860B
  static const Color goldDark = Color(0xFFB8860B);

  // ============================================================
  // DATA SOURCE BRAND COLORS (Theme-independent)
  // ============================================================

  /// Douban Green
  static const Color sourceDouban = Color(0xFF00C019);

  /// Bangumi Pink
  static const Color sourceBangumi = Color(0xFFF06FA9);

  /// TMDb Dark Blue
  static const Color sourceTmdb = Color(0xFF0D253F);

  /// Maoyan Red
  static const Color sourceMaoyan = Color(0xFFDD2F2F);

  /// Bilibili Blue
  static const Color sourceBilibili = Color(0xFF00A1D6);

  // ============================================================
  // DECORATIVE COLORS - Weekdays (for Daily Schedule)
  // ============================================================

  static const Color weekSun = Color(0xFFEA3724); // Red
  static const Color weekMon = Color(0xFFED702D); // Orange
  static const Color weekTue = Color(0xFFF1A33A); // Yellow-Orange
  static const Color weekWed = Color(0xFFB9DD46); // Lime
  static const Color weekThu = Color(0xFF70B941); // Green
  static const Color weekFri = Color(0xFF3983C3); // Blue
  static const Color weekSat = Color(0xFF2354A0); // Indigo

  // ============================================================
  // DECORATIVE COLORS - Gradients
  // ============================================================

  /// Primary gradient - Pink to Orange (Movie/Video Library)
  static const Color gradientPinkStart = Color(0xFFFF6B9D);
  static const Color gradientPinkEnd = Color(0xFFFF8E53);

  /// Secondary gradient - Purple to Blue (Anime Wall)
  static const Color gradientPurpleStart = Color(0xFF667EEA);
  static const Color gradientPurpleEnd = Color(0xFF764BA2);

  /// Success gradient for dialogs
  static const Color gradientSuccessStart = Color(0xFF667EEA);
  static const Color gradientSuccessEnd = Color(0xFF764BA2);

  /// Error gradient for dialogs
  static const Color gradientErrorStart = Color(0xFFFF6B6B);
  static const Color gradientErrorEnd = Color(0xFFEE5A5A);

  // ============================================================
  // SPECIAL PURPOSE COLORS
  // ============================================================

  /// SnackBar background - Dark
  /// #333333
  static const Color snackBarBackground = Color(0xFF333333);

  /// Toast success background
  /// #4CAF50
  static const Color toastSuccess = Color(0xFF4CAF50);

  /// Pull light switch - Light bulb color
  /// #FFF9C4
  static const Color lightBulb = Color(0xFFFFF9C4);

  /// Shimmer base color
  /// #E0E0E0
  static const Color shimmerBase = Color(0xFFE0E0E0);

  /// Shimmer highlight color
  /// #F5F5F5
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  /// Teal color for grid layout switcher
  static const Color teal = Color(0xFF26A69A);
  static const Color tealDark = Color(0xFF00897B);

  /// Calendar/broadcast item pink
  static const Color calendarPink = Color(0xFFF09199);

  /// Deep surface color for loading states
  /// #1F2937
  static const Color surfaceDeep = Color(0xFF1F2937);

  // ============================================================
  // DARK THEME PALETTE
  // Reference: docs/dark_library_color.md
  // ============================================================

  /// Primary Page Background (Deep Navy)
  /// #0D1B2A
  static const Color backgroundDark = Color(0xFF0D1B2A);

  /// Card/Placeholder Background (Lighter Navy)
  /// #1A2A3A
  static const Color surfaceDark = Color(0xFF1A2A3A);

  /// Grid Layout Switcher Primary (Teal)
  /// #26A69A
  static const Color gridSwitcherPrimary = Color(0xFF26A69A);

  /// Grid Layout Switcher Secondary (Darker Teal)
  /// #00897B
  static const Color gridSwitcherSecondary = Color(0xFF00897B);

  // Gradient Colors (Lists for 3-stop gradients)

  /// Movies/TV Library Gradient (Blue -> Purple -> Violet)
  /// #667EEA -> #764BA2 -> #A855F7
  static const List<Color> gradientMovies = [
    Color(0xFF667EEA),
    Color(0xFF764BA2),
    Color(0xFFA855F7),
  ];

  /// Anime Wall Gradient (Pink -> Orange -> Yellow)
  /// #FF6B9D -> #FF8E53 -> #FFD93D
  static const List<Color> gradientAnime = [
    Color(0xFFFF6B9D),
    Color(0xFFFF8E53),
    Color(0xFFFFD93D),
  ];

  // Dark Theme UI Elements

  /// Silver Edge Border (White 15%)
  static const Color silverEdgeBorder = Color(0x26FFFFFF);

  /// Subtle Glow (White 0.5%)
  static const Color subtleGlow = Color(0x01FFFFFF);

  /// Dark Shadow (Black 40%)
  static const Color shadowDark = Color(0x66000000);

  /// Count Text Label (White 50%)
  static const Color textCountLabel = Color(0x80FFFFFF);

  /// Count Number (White 80%)
  static const Color textCountNumber = Color(0xCCFFFFFF);

  /// Light Bulb ON (Warm Yellow)
  /// #FFF9C4
  static const Color bulbOn = Color(0xFFFFF9C4);

  /// Light Bulb OFF (Light Gray)
  /// #FAFAFA
  static const Color bulbOff = Color(0xFFFAFAFA);

  /// Bulb Border ON (Orange Shade)
  static const Color bulbBorderOn = Color(0xFFFFB74D); // Colors.orange.shade300

  /// Bulb Border OFF (Grey Shade)
  static const Color bulbBorderOff = Color(0xFFBDBDBD); // Colors.grey.shade400

  /// Bulb Icon ON (Orange)
  static const Color bulbIconOn = Colors.orange;

  /// Bulb Icon OFF (Grey Shade)
  static const Color bulbIconOff = Color(0xFFBDBDBD); // Colors.grey.shade400

  // ============================================================
  // RANKING COLORS
  // ============================================================

  /// First place - Gold
  static const Color rankFirst = Color(0xFFFFC107);

  /// Second place - Silver
  static const Color rankSecond = Color(0xFFB0BEC5);

  /// Third place - Bronze
  static const Color rankThird = Color(0xFFCD7F32);

  /// Dark text for ranking
  static const Color rankText = Color(0xFF616161);

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get data source brand color by source type
  static Color getSourceColor(String sourceType) {
    switch (sourceType) {
      case 'douban':
        return sourceDouban;
      case 'bgm':
        return sourceBangumi;
      case 'tmdb':
        return sourceTmdb;
      case 'maoyan':
        return sourceMaoyan;
      case 'bilibili':
        return sourceBilibili;
      default:
        return Colors.grey;
    }
  }

  /// Get rating color based on percentage (0-100)
  static Color getRatingColor(double percentage) {
    if (percentage >= 70) return ratingHigh;
    if (percentage >= 40) return ratingMedium;
    return ratingLow;
  }

  /// Get rating background color based on percentage (0-100)
  static Color getRatingBgColor(double percentage) {
    if (percentage >= 70) return ratingHighBg;
    if (percentage >= 40) return ratingMediumBg;
    return ratingLowBg;
  }

  /// Get ranking color (1st, 2nd, 3rd place)
  static Color getRankColor(int rank) {
    switch (rank) {
      case 1:
        return rankFirst;
      case 2:
        return rankSecond;
      case 3:
        return rankThird;
      default:
        return textSecondary;
    }
  }
}
