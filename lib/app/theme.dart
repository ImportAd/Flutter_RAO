import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цветовая палитра — тёплые бежево-золотые тона,
/// вдохновлённые стилистикой РАО.
class AppColors {
  AppColors._();

  // Основные
  static const Color primary = Color(0xFF8B7355);       // тёплый коричнево-золотой
  static const Color primaryDark = Color(0xFF5E4B35);    // тёмный коричневый
  static const Color primaryLight = Color(0xFFB8A48A);   // светлый бежевый
  static const Color accent = Color(0xFFC5A55A);         // золотой акцент

  // Фоны
  static const Color background = Color(0xFFF7F4EF);     // тёплый кремовый
  static const Color surface = Color(0xFFFFFFFF);         // белый
  static const Color surfaceVariant = Color(0xFFF0EBE3);  // бежевый для карточек

  // Текст
  static const Color textPrimary = Color(0xFF2C2418);     // тёмно-коричневый
  static const Color textSecondary = Color(0xFF6B5D4F);   // приглушённый
  static const Color textHint = Color(0xFF9E9085);        // hint

  // Поля ввода
  static const Color fieldBorder = Color(0xFFD5CDC3);     // рамка поля
  static const Color fieldBorderFocused = Color(0xFF8B7355); // рамка при фокусе
  static const Color fieldBackground = Color(0xFFFFFFFF);
  static const Color fieldDisabled = Color(0xFFF0EBE3);

  // Ошибка
  static const Color error = Color(0xFFD4483B);
  static const Color errorLight = Color(0xFFFCE8E6);

  // Кнопки
  static const Color buttonPrimary = Color(0xFF5E4B35);
  static const Color buttonPrimaryHover = Color(0xFF4A3A28);
  static const Color buttonSecondary = Color(0xFFEDE7DE);
  static const Color buttonSecondaryHover = Color(0xFFDED6CA);
  static const Color buttonDisabled = Color(0xFFE8E3DB);
  static const Color buttonTextDisabled = Color(0xFFB3A99D);

  // Разделители
  static const Color divider = Color(0xFFE8E3DB);

  // Навигация
  static const Color navActive = Color(0xFF8B7355);
  static const Color navInactive = Color(0xFF9E9085);
}

/// Тема приложения
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
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      // Типографика
      textTheme: GoogleFonts.notoSansTextTheme().copyWith(
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.notoSans(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.notoSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.notoSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.notoSans(
          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.notoSans(
          fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.notoSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.notoSans(
          fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textHint,
        ),
        labelLarge: GoogleFonts.notoSans(
          fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
      ),

      // Поля ввода
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.fieldBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.fieldBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.fieldBorderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.divider, width: 1),
        ),
        labelStyle: GoogleFonts.notoSans(fontSize: 14, color: AppColors.textSecondary),
        hintStyle: GoogleFonts.notoSans(fontSize: 14, color: AppColors.textHint),
        errorStyle: GoogleFonts.notoSans(fontSize: 12, color: AppColors.error),
        helperStyle: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textHint),
      ),

      // Кнопки
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.buttonTextDisabled,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.fieldBorder),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Чипы (для кнопок выбора вроде М.П. / Б.П.)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: AppColors.fieldBorder),
      ),

      // Tabs
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.notoSans(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
