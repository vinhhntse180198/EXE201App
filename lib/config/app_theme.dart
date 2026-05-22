import 'package:flutter/material.dart';

import 'yume_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: YumeColors.pink,
        brightness: Brightness.light,
        surface: YumeColors.surface,
      ),
      scaffoldBackgroundColor: YumeColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: YumeColors.card,
        foregroundColor: YumeColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: YumeColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: YumeColors.card,
        indicatorColor: YumeColors.pink.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: YumeColors.pink, fontWeight: FontWeight.w600, fontSize: 11);
          }
          return const TextStyle(fontSize: 11, color: YumeColors.muted);
        }),
      ),
      cardTheme: CardThemeData(
        color: YumeColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: YumeColors.pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: YumeColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YumeColors.primary, width: 1.5),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: YumeColors.primary,
        unselectedLabelColor: YumeColors.muted,
        indicatorColor: YumeColors.primary,
      ),
    );
  }
}
