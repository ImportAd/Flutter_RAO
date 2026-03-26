import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цветовая палитра — бирюзовый акцент по макетам
class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF01909B);       // бирюзовый (из макетов)
  static const Color primaryDark = Color(0xFF00796B);
  static const Color primaryLight = Color(0xFF4DB6AC);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  static const Color fieldBorder = Color(0xFFE0E0E0);
  static const Color fieldBorderFocused = Color(0xFF009688);
  static const Color fieldBackground = Color(0xFFFFFFFF);
  static const Color fieldDisabled = Color(0xFFF5F5F5);
  static const Color fieldDefaultBg = Color(0xFFF0FDFA);  // лёгкий бирюзовый фон для дефолтных полей

  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);

  static const Color divider = Color(0xFFE0E0E0);

  // Кнопки-сегменты (ФОРМАКС | РАО | ВОИС)
  static const Color segmentActive = Color(0xFF009688);
  static const Color segmentActiveBg = Color(0xFF009688);
  static const Color segmentInactiveBg = Color(0xFFF5F5F5);
  static const Color segmentBorder = Color(0xFFE0E0E0);

  // Disabled button
  static const Color buttonDisabled = Color(0xFFE0E0E0);
  static const Color buttonTextDisabled = Color(0xFF9E9E9E);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.notoSansTextTheme().copyWith(
        headlineLarge: GoogleFonts.notoSans(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleLarge: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodySmall: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textHint),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.fieldBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.fieldBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.fieldBorderFocused, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.error)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppColors.divider)),
        hintStyle: GoogleFonts.notoSans(fontSize: 14, color: AppColors.textHint),
        errorStyle: GoogleFonts.notoSans(fontSize: 12, color: AppColors.error),
        helperStyle: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textHint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceVariant, foregroundColor: AppColors.textPrimary,
          elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary, unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary, indicatorSize: TabBarIndicatorSize.tab,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      cardTheme: CardThemeData(
        color: AppColors.surface, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: AppColors.divider)),
      ),
    );
  }
}
