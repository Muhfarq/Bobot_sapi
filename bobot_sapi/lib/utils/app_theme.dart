// lib/utils/app_theme.dart

import 'package:flutter/material.dart';

class AppColors {
  static const hijau = Color(0xFF1B6B4A);
  static const hijauMuda = Color(0xFFB8EDCF);
  static const hijauCard = Color(0xFFE8F8EE);
  static const hijauText = Color(0xFF2D9E6B);
  static const merah = Color(0xFFE53935);
  static const abu = Color(0xFF9E9E9E);
  static const abuMuda = Color(0xFFF5F5F5);
  static const putih = Color(0xFFFFFFFF);
  static const gelap = Color(0xFF1A1A1A);
  static const teksAbu = Color(0xFF757575);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.hijau,
          primary: AppColors.hijau,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.putih,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.hijau,
          foregroundColor: AppColors.putih,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.putih,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.hijau,
            foregroundColor: AppColors.putih,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.abuMuda,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

void showStyledSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF004D34),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ),
  );
}
