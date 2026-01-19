import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Explicit ColorScheme to prevent system theme interference
  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    error: AppColors.error,
    onError: AppColors.white,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimary,
    surfaceVariant: AppColors.grey800,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.grey600,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.grey800,
    onInverseSurface: AppColors.textPrimary,
    inversePrimary: AppColors.primaryLight,
    surfaceTint: AppColors.primary,
  );

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = ThemeData(brightness: brightness).textTheme;

    TextStyle heading(TextStyle? style,
        {double? fontSize, FontWeight fontWeight = FontWeight.w700, double? letterSpacing, Color? color}) {
      return GoogleFonts.urbanist(
        textStyle: style,
        fontSize: fontSize ?? style?.fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing ?? style?.letterSpacing ?? (-0.1),
        color: color ?? AppColors.textPrimary,
      );
    }

    TextStyle body(TextStyle? style,
        {double? fontSize, FontWeight fontWeight = FontWeight.w400, double? letterSpacing, Color? color}) {
      return GoogleFonts.nunitoSans(
        textStyle: style,
        fontSize: fontSize ?? style?.fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing ?? style?.letterSpacing ?? 0.1,
        color: color ?? AppColors.textPrimary,
      );
    }

    return TextTheme(
      displayLarge: heading(base.displayLarge, fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -0.6),
      displayMedium: heading(base.displayMedium, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      displaySmall: heading(base.displaySmall, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.4),
      headlineLarge: heading(base.headlineLarge, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineMedium: heading(base.headlineMedium, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      headlineSmall: heading(base.headlineSmall, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.15),
      titleLarge: heading(base.titleLarge, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.05),
      titleMedium: heading(base.titleMedium, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.0),
      titleSmall: heading(base.titleSmall, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.05),
      bodyLarge: body(base.bodyLarge, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      bodyMedium: body(base.bodyMedium, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      bodySmall: body(base.bodySmall, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.15, color: AppColors.textSecondary),
      labelLarge: body(base.labelLarge, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelMedium: body(base.labelMedium, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4, color: AppColors.textSecondary),
      labelSmall: body(base.labelSmall, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColors.textSecondary),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme, // Use dark scheme even for "light" theme
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: GoogleFonts.nunitoSans().fontFamily,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.white),
        titleTextStyle: GoogleFonts.urbanist(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.0,
          color: AppColors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2,
          textStyle: GoogleFonts.urbanist(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          textStyle: GoogleFonts.urbanist(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.25,
            color: AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey50,
        labelStyle: GoogleFonts.roboto(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        hintStyle: GoogleFonts.roboto(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.grey900,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.urbanist(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: GoogleFonts.nunitoSans(
          color: AppColors.grey400,
          fontWeight: FontWeight.w500,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      dividerTheme: const DividerThemeData(
        color: AppColors.grey600,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: GoogleFonts.nunitoSans().fontFamily,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.grey900,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.white),
        titleTextStyle: GoogleFonts.urbanist(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.0,
          color: AppColors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2,
          textStyle: GoogleFonts.urbanist(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight),
          textStyle: GoogleFonts.urbanist(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.primaryLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.25,
            color: AppColors.primaryLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey800,
        labelStyle: GoogleFonts.roboto(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        hintStyle: GoogleFonts.roboto(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.grey600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.grey600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.grey900,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.urbanist(
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: GoogleFonts.nunitoSans(
          color: AppColors.grey400,
          fontWeight: FontWeight.w500,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      dividerTheme: const DividerThemeData(
        color: AppColors.grey600,
        thickness: 1,
      ),
    );
  }
}
