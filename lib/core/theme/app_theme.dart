import 'package:flutter/material.dart';

/// Central place for all theme configuration for the AIO Workout app.
/// The reference design is a dark, high-contrast fitness UI with
/// vibrant accent cards for metrics (achievements green, steps orange, hydration blue).
class AppTheme {
  // Brand seed — kept for energetic accents. Primary for nav/buttons can be overridden per component.
  static const Color _seedColor = Colors.deepOrange;

  // Accent colors pulled to match the reference screenshot closely
  static const Color achievementGreen = Color(0xFF22C55E);
  static const Color stepsOrange = Color(0xFFF97316);
  static const Color hydrationBlue = Color(0xFF3B82F6);

  // Very dark surfaces to match the reference dark mode
  static const Color darkBackground = Color(0xFF0A0A0C);
  static const Color darkSurface = Color(0xFF151518);
  static const Color darkCard = Color(0xFF1C1C20);

  // Light mode surfaces — clean, modern light theme (still high contrast for fitness)
  static const Color lightBackground = Color(0xFFF8F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F2F6);
  static const Color lightTopAction = Color(0xFFEAEBF0);
  static const Color darkTopAction = Color(0xFF2A2A2E);

  /// Animation tokens (from Agency UI Designer + Mobile Builder guidance).
  /// Premium yet subtle 60fps motion for workout metrics, entrances, and transitions.
  /// Short durations + vsync + fast-out curves keep things battery-friendly and gym-appropriate.
  static const Duration kAnimFast = Duration(milliseconds: 180);
  static const Duration kAnimMedium = Duration(milliseconds: 350);
  static const Duration kAnimEntrance = Duration(milliseconds: 950);
  static const Duration kAnimProgress = Duration(milliseconds: 600);
  static const Curve kEaseOut = Curves.easeOutCubic;
  static const Curve kEaseOutBack = Curves.easeOutBack;

  static final ThemeData light = ThemeData(
    scaffoldBackgroundColor: lightBackground,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).copyWith(
          surface: lightSurface,
          surfaceContainer: lightCard,
          // Keep the same active primary used in dark for consistent nav accent
          primary: const Color(0xFF6366F1),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF1F2937),
          onSurfaceVariant: const Color(0xFF4B5563),
        ),
    cardTheme: const CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    useMaterial3: true,
  );

  static final ThemeData dark = ThemeData(
    scaffoldBackgroundColor: darkBackground,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).copyWith(
          surface: darkSurface,
          surfaceContainer: darkCard,
          // Use a cool blue primary so the active bottom nav (Home) matches the reference screenshot
          primary: const Color(0xFF6366F1),
          onPrimary: Colors.white,
          onSurface: Colors.white,
          onSurfaceVariant: const Color(0xFF9CA3AF),
        ),
    cardTheme: const CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    useMaterial3: true,
  );

  // ---------------------------------------------------------------------------
  // Context-aware helpers so UI code works in both light and dark without
  // scattering Colors.white / Colors.black / magic dark hexes everywhere.
  // Use these in TextStyle color, Container color, Border, etc.
  // ---------------------------------------------------------------------------

  /// The color used for Cards / elevated surfaces (respects current brightness).
  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : lightCard;
  }

  /// Background for the small circular top-right action buttons (theme, etc).
  static Color topActionBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTopAction
        : lightTopAction;
  }

  /// Primary body text color (white in dark, near-black in light).
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Secondary / supporting text (70% opacity).
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70);
  }

  /// Tertiary / caption text.
  /// Uses onSurfaceVariant directly for proper contrast in both themes.
  static Color textTertiary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// Disabled / very subtle text (38% opacity).
  static Color textDisabled(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
  }

  /// Subtle fill used for inactive bars, dividers, borders, hover states, etc.
  /// Produces white@opacity in dark mode and black@opacity in light mode.
  static Color subtleFill(BuildContext context, [double opacity = 0.12]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? Colors.white : Colors.black).withValues(alpha: opacity);
  }
}
