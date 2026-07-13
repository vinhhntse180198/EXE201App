import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'yume_colors.dart';
import 'yume_perf.dart';

abstract final class AppTheme {
  static bool _fontsReady = false;

  /// UI nhẹ hoặc debug Android: bỏ tải font qua mạng.
  static bool get useBundledSystemFonts =>
      yumeLiteUi && !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static void markFontsReady() => _fontsReady = true;

  /// Noto Sans: hỗ trợ dấu tiếng Việt + kana/kanji cơ bản trên mọi thiết bị.
  static TextStyle font(TextStyle? style) {
    if (useBundledSystemFonts || !_fontsReady) {
      return style ?? const TextStyle();
    }
    return GoogleFonts.notoSans(textStyle: style);
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: YumeColors.pink,
        brightness: Brightness.light,
        surface: YumeColors.surface,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: yumeLiteUi
              ? const FadeUpwardsPageTransitionsBuilder()
              : const _YumeSlideFadeTransitionsBuilder(),
          TargetPlatform.iOS: yumeLiteUi
              ? const CupertinoPageTransitionsBuilder()
              : const _YumeSlideFadeTransitionsBuilder(),
          TargetPlatform.macOS: const _YumeSlideFadeTransitionsBuilder(),
          TargetPlatform.windows: const _YumeSlideFadeTransitionsBuilder(),
          TargetPlatform.linux: const _YumeSlideFadeTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: YumeColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: YumeColors.card,
        foregroundColor: YumeColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: font(const TextStyle(
          color: YumeColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        )),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: YumeColors.card,
        indicatorColor: YumeColors.pink.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return font(const TextStyle(color: YumeColors.pink, fontWeight: FontWeight.w600, fontSize: 11));
          }
          return font(const TextStyle(fontSize: 11, color: YumeColors.muted));
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
          textStyle: font(const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: YumeColors.card,
        labelStyle: font(const TextStyle(color: YumeColors.ink, fontWeight: FontWeight.w500)),
        hintStyle: font(const TextStyle(color: YumeColors.muted)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YumeColors.primary, width: 1.5),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: YumeColors.primary,
        unselectedLabelColor: YumeColors.muted,
        indicatorColor: YumeColors.primary,
        labelStyle: font(const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        unselectedLabelStyle: font(const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: font(const TextStyle(color: YumeColors.ink, fontSize: 15)),
      ),
    );

    if (useBundledSystemFonts || !_fontsReady) {
      return base;
    }

    return base.copyWith(
      textTheme: GoogleFonts.notoSansTextTheme(base.textTheme),
      primaryTextTheme: GoogleFonts.notoSansTextTheme(base.primaryTextTheme),
    );
  }
}

class _YumeSlideFadeTransitionsBuilder extends PageTransitionsBuilder {
  const _YumeSlideFadeTransitionsBuilder();

  static const _kDuration = Duration(milliseconds: 260);
  static const _kReverseDuration = Duration(milliseconds: 220);
  static const _curve = Cubic(0.22, 1, 0.36, 1);

  @override
  Duration get transitionDuration => _kDuration;

  @override
  Duration get reverseTransitionDuration => _kReverseDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.fullscreenDialog) return child;

    final curved = CurvedAnimation(parent: animation, curve: _curve, reverseCurve: _curve);
    final fade = Tween<double>(begin: 0, end: 1).animate(curved);
    final slide = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
