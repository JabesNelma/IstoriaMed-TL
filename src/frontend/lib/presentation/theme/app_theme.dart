import 'package:flutter/material.dart';

/// Single source of truth for colors, typography and spacing across the app.
/// Screens must not hardcode their own values.
abstract final class AppColors {
  static const primary = Color(0xff116466);
  static const primaryDark = Color(0xff0d4f51);
  static const surface = Color(0xfff7fafa);
  static const onSurface = Color(0xff1c2b2b);
  static const muted = Color(0xff5c7373);
  static const danger = Color(0xffb3402f);
  static const border = Color(0xffd6e4e4);
}

abstract final class AppTextStyles {
  static const appTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
  );

  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static const body = TextStyle(fontSize: 15, color: AppColors.onSurface);

  static const caption = TextStyle(fontSize: 13, color: AppColors.muted);

  static const error = TextStyle(fontSize: 14, color: AppColors.danger);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

/// Material theme assembled from the design tokens above.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    surface: AppColors.surface,
  );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surface,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
  );
}
