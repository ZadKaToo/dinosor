import 'package:flutter/material.dart';

/// Theme helpers — primary semantic colors live on [AppState].
class AppTheme {
  static ThemeData light() => ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF3F8FF),
        primaryColor: const Color(0xFF2563EB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        dialogBackgroundColor: Colors.white,
      );

  static ThemeData dark() => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080C14),
        primaryColor: const Color(0xFF10B981),
      );
}
