import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores da app original: dourado como acento, fundo quase preto no modo
/// escuro e branco no modo claro.
class AppColors {
  static const gold = Color(0xFFC5A059);
  static const darkBg = Color(0xFF121212);
  static const darkCard = Color(0xFF181818);
  static const darkInput = Color(0xFF242424);
  static const darkBorder = Color(0xFF282828);
  static const lightCard = Color(0xFFF8F9FA);
  static const lightInput = Color(0xFFF1F3F5);
  static const lightBorder = Color(0xFFE9ECEF);
  static const green = Color(0xFF1DB954);
  static const red = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.gold,
          onPrimary: AppColors.darkBg,
          surface: AppColors.darkBg,
          surfaceContainerLow: AppColors.darkCard,
          surfaceContainer: AppColors.darkCard,
          surfaceContainerHighest: AppColors.darkInput,
          outlineVariant: AppColors.darkBorder,
          error: AppColors.red,
        ),
        input: AppColors.darkInput,
        card: AppColors.darkCard,
        border: AppColors.darkBorder,
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF8A6A2C),
          onPrimary: Colors.white,
          surface: Colors.white,
          surfaceContainerLow: AppColors.lightCard,
          surfaceContainer: AppColors.lightCard,
          surfaceContainerHighest: AppColors.lightInput,
          outlineVariant: AppColors.lightBorder,
          error: AppColors.red,
        ),
        input: AppColors.lightInput,
        card: AppColors.lightCard,
        border: AppColors.lightBorder,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color input,
    required Color card,
    required Color border,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      // Só o nome da família: o google_fonts 9 usa o pacote material_ui,
      // cujo TextTheme é um tipo diferente do de flutter/material.
      fontFamily: GoogleFonts.poppins().fontFamily,
    );
    final radius = BorderRadius.circular(10);
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: card,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
