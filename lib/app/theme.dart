import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цветовая палитра — бирюзовый акцент по макетам
class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF01909B);       // бирюзовый (из макетов)
  static const Color primaryDark = Color(0xFFE86B15); // цвет при навидении
  static const Color primaryLight = Color(0xFF4DB6AC);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFF01909B);

///////////////////////// ТЕКСТ ////////////////////////////
  static const Color textPrimary = Color(0xFF000000);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA8A8A8);
  static const Color textHint = Color(0xFF9E9E9E);

  static const Color fieldBorder = Color(0xFFE0E0E0);
  static const Color fieldBorderFocused = Color(0xFF01909B); // цвет рамки
  static const Color fieldBackground = Color(0xFFFFFFFF);
  static const Color fieldDisabled = Color(0xFFF5F5F5);
  static const Color fieldDefaultBg = Color(0xFFF0FDFA);  // лёгкий бирюзовый фон для дефолтных полей

  static const Color error = Color(0xDBE00F0F); // ошибка 
  static const Color errorLight = Color(0xFFFFEBEE);

  static const Color divider = Color(0xFFE0E0E0);

  // Кнопки-сегменты (ФОРМАКС | РАО | ВОИС)
  static const Color segmentActive = Color(0xFF009688);
  static const Color segmentActiveBg = Color(0xFF01909B);
  static const Color segmentInactiveBg = Color(0xFFF5F5F5);
  static const Color segmentBorder = Color(0xFFE0E0E0);

  // Disabled button
  static const Color buttonDisabled = Color(0xFFD3D3D3);
  static const Color buttonTextDisabled = Color(0xAD000000);
  static const Color buttonActiveHover = Color(0xFF006A72);
}





class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.andika().fontFamily, // весь текст без указания стиля будет этого стиля
      
      scaffoldBackgroundColor: AppColors.background,


      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        error: AppColors.error,
      ),


      // ── Текстовые стили из Figma (шрифт Andika) ──
      // H1 bold  · 32/120% · Bold   · letter-spacing -6%
      // H1 reg   · 32/120% · Regular
      // H2 bold  · 22/28   · Bold
      // H2 reg   · 22/28   · Regular
      // H3 bold  · 18/22   · Bold
      // body reg · 18/22   · Regular
      // Inscription · 14/18 · Regular
      // Figma «H1 bold»     →  headlineLarge   (32/120%/Bold/-6%)
      // Figma «H1 reg»      →  headlineMedium  (32/120%/Regular)
      // Figma «H2 bold»     →  titleLarge      (22/28/Bold)
      // Figma «H2 reg»      →  titleMedium     (22/28/Regular)
      // Figma «H3 bold»     →  titleSmall      (18/22/Bold)
      // Figma «body reg»    →  bodyLarge       (18/22/Regular)
      // Figma «Inscription» →  bodyMedium      (14/18/Regular)


      textTheme: GoogleFonts.andikaTextTheme().copyWith(
        headlineLarge: GoogleFonts.andika(fontSize: 32,                    // H1 bold
                                          fontWeight: FontWeight.w700, 
                                          height: 1.20, 
                                          letterSpacing: -1.92, 
                                          color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.andika(fontSize: 32,                   // H1 reg
                                           fontWeight: FontWeight.w400, 
                                           height: 1.20, 
                                           color: AppColors.textPrimary),
        titleLarge: GoogleFonts.andika(fontSize: 22,                       // H2 bold
                                       fontWeight: FontWeight.w700, 
                                       height: 28 / 22, 
                                       color: AppColors.textPrimary),
        titleMedium: GoogleFonts.andika(fontSize: 22,                      // H2 reg
                                        fontWeight: FontWeight.w400, 
                                        height: 28 / 22, 
                                        color: AppColors.textPrimary),
        titleSmall: GoogleFonts.andika(fontSize: 18,                       // H3 bold
                                           fontWeight: FontWeight.w700, 
                                           height: 22 / 18, 
                                           color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.andika(fontSize: 18,                        // body reg
                                      fontWeight: FontWeight.w400, 
                                      height: 22 / 18, 
                                      color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.andika(fontSize: 14,                       // Inscription
                                       fontWeight: FontWeight.w400, 
                                       height: 18 / 14, 
                                       color: AppColors.textSecondary),
        bodySmall: GoogleFonts.andika(fontSize: 12, 
                                      fontWeight: FontWeight.w400, 
                                      height: 16 / 12, color: AppColors.textHint),
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
