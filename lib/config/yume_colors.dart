import 'package:flutter/material.dart';

/// Bảng màu khớp web EXE201 (`theme.css` — sakura red).
abstract final class YumeColors {
  static const primary = Color(0xFFE11D48);
  static const primaryHover = Color(0xFFBE123C);
  static const pink = primary;
  static const pinkDark = primaryHover;
  static const pinkLight = Color(0xFFFFE4E6);
  static const sakura = Color(0xFFF43F5E);
  static const sky = Color(0xFFE3F2FD);
  static const ink = Color(0xFF0F172A);
  static const text = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const surface = Color(0xFFFFFBFE);
  static const card = Colors.white;
  static const border = Color(0x1F0F172A);

  static const homeGradient = [
    Color(0xFFFFF1F2),
    Color(0xFFFFFBFE),
    Color(0xFFF8FAFC),
  ];
}
