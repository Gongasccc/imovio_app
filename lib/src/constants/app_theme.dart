import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imovio/src/common_widgets/glass.dart';

/// Cores da app original: dourado como acento, fundo quase preto no modo
/// escuro e branco no modo claro.
class AppColors {
  static const gold = Color(0xFFC5A059);
  static const goldLight = Color(0xFFE6C98A);
  static const darkBg = Color(0xFF121212);
  static const darkCard = Color(0xFF181818);
  static const darkInput = Color(0xFF242424);
  static const darkBorder = Color(0xFF282828);
  static const lightCard = Color(0xFFF8F9FA);
  static const lightInput = Color(0xFFF1F3F5);
  static const lightBorder = Color(0xFFE9ECEF);
  static const lightBg = Color(0xFFF4F1EC);
  static const green = Color(0xFF1DB954);
  static const red = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme:
        ColorScheme.fromSeed(
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
    input: Colors.white.withValues(alpha: 0.06),
    card: Colors.white.withValues(alpha: 0.06),
    border: Colors.white.withValues(alpha: 0.10),
    glass: GlassTheme(
      bar: AppColors.darkBg.withValues(alpha: 0.55),
      edge: Colors.white.withValues(alpha: 0.12),
    ),
  );

  static ThemeData light() => _build(
    brightness: Brightness.light,
    scheme:
        ColorScheme.fromSeed(
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
    input: Colors.white.withValues(alpha: 0.6),
    card: Colors.white.withValues(alpha: 0.55),
    border: Colors.black.withValues(alpha: 0.06),
    glass: GlassTheme(
      bar: Colors.white.withValues(alpha: 0.6),
      edge: Colors.white.withValues(alpha: 0.8),
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color input,
    required Color card,
    required Color border,
    required GlassTheme glass,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // Transparente: o fundo animado (GlassBackground) fica por trás.
      scaffoldBackgroundColor: Colors.transparent,
      // Só o nome da família: o google_fonts 9 usa o pacote material_ui,
      // cujo TextTheme é um tipo diferente do de flutter/material.
      fontFamily: GoogleFonts.poppins().fontFamily,
    );
    final radius = BorderRadius.circular(10);
    return base.copyWith(
      extensions: [glass],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.transparent),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      // Transições e gesto de voltar como numa app de telemóvel: deslizar
      // da esquerda para a direita volta à página anterior.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final p in TargetPlatform.values)
            p: const SwipeBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Cores do vidro das barras (com desfoque) e da sua aresta.
class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({required this.bar, required this.edge});
  final Color bar;
  final Color edge;

  @override
  GlassTheme copyWith({Color? bar, Color? edge}) =>
      GlassTheme(bar: bar ?? this.bar, edge: edge ?? this.edge);

  @override
  GlassTheme lerp(GlassTheme? other, double t) => other == null
      ? this
      : GlassTheme(
          bar: Color.lerp(bar, other.bar, t)!,
          edge: Color.lerp(edge, other.edge, t)!,
        );
}

/// Transição do iOS (deslizar para voltar) em que o gesto funciona em todo
/// o ecrã, e não só nos 20 px da margem esquerda (que no Safari do iPhone
/// são do próprio browser). As abas das páginas não deslizam, para não
/// competirem com este gesto.
class SwipeBackPageTransitionsBuilder extends PageTransitionsBuilder {
  const SwipeBackPageTransitionsBuilder();

  static const _cupertino = CupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final mq = MediaQuery.of(context);
    // O detetor do gesto usa o padding esquerdo como largura da zona de
    // arrasto; a página em si continua a ver o MediaQuery original.
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(
          left: math.max(mq.padding.left, mq.size.width),
        ),
      ),
      child: _cupertino.buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        // Cada página leva o seu fundo, para não se ver a anterior por
        // baixo enquanto desliza (os Scaffolds são transparentes).
        MediaQuery(
          data: mq,
          child: GlassBackground(child: child),
        ),
      ),
    );
  }
}
