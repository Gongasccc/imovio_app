import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:imovio/src/constants/app_theme.dart';

/// Só anima na app a sério: nos testes de widgets uma animação sem fim
/// impede o `pumpAndSettle` de terminar.
bool get _canAnimateForever => WidgetsBinding.instance is WidgetsFlutterBinding;

/// Fundo "liquid glass": manchas de cor desfocadas que derivam devagar.
/// Pinta-se num único [CustomPaint] isolado num [RepaintBoundary], por isso
/// o resto do ecrã não é redesenhado a cada frame.
///
/// O primeiro (à volta da app) tem a animação; os das páginas que abrem por
/// cima usam a mesma, para as manchas coincidirem ao deslizar para voltar.
class GlassBackground extends StatefulWidget {
  const GlassBackground({super.key, required this.child});
  final Widget child;

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassScope extends InheritedWidget {
  const _GlassScope({required this.animation, required super.child});
  final Animation<double> animation;

  @override
  bool updateShouldNotify(_GlassScope old) => old.animation != animation;
}

class _GlassBackgroundState extends State<GlassBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double> _animation = const AlwaysStoppedAnimation(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context.dependOnInheritedWidgetOfExactType<_GlassScope>();
    if (scope != null) {
      _animation = scope.animation;
      return;
    }
    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    _animation = controller;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still || !_canAnimateForever) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _BlobsPainter(_animation, dark: dark)),
          ),
        ),
        widget.child,
      ],
    );
    return _controller == null
        ? content
        : _GlassScope(animation: _animation, child: content);
  }
}

class _BlobsPainter extends CustomPainter {
  _BlobsPainter(this.t, {required this.dark}) : super(repaint: t);
  final Animation<double> t;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..color = dark ? AppColors.darkBg : AppColors.lightBg,
    );
    final a = t.value * 2 * math.pi;
    final s = size.shortestSide;
    final blobs = [
      // dourado, canto superior esquerdo
      (
        Offset(
          size.width * (0.1 + 0.08 * math.sin(a)),
          size.height * (0.08 + 0.05 * math.cos(a)),
        ),
        s * 0.75,
        AppColors.gold.withValues(alpha: dark ? 0.32 : 0.30),
      ),
      // azul, à direita
      (
        Offset(
          size.width * (0.95 - 0.1 * math.cos(a)),
          size.height * (0.55 + 0.08 * math.sin(a)),
        ),
        s * 0.85,
        (dark ? const Color(0xFF3B4A7A) : const Color(0xFF9DB3E8)).withValues(
          alpha: dark ? 0.38 : 0.35,
        ),
      ),
      // cobre, em baixo
      (
        Offset(
          size.width * (0.2 + 0.1 * math.sin(a + 2)),
          size.height * (0.98 - 0.05 * math.cos(a + 1)),
        ),
        s * 0.7,
        (dark ? const Color(0xFF7A4F2A) : const Color(0xFFEBC9A0)).withValues(
          alpha: dark ? 0.32 : 0.4,
        ),
      ),
    ];
    for (final (center, radius, color) in blobs) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobsPainter old) => old.dark != dark || old.t != t;
}

/// Vidro com desfoque real do que está por trás. Usar com moderação (barras,
/// menu, login): o desfoque é o efeito mais pesado no telemóvel.
class FrostedGlass extends StatelessWidget {
  const FrostedGlass({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.sigma = 20,
    this.border = true,
  });
  final Widget child;
  final BorderRadius borderRadius;
  final double sigma;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTheme>()!;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: glass.bar,
            borderRadius: borderRadius,
            border: border ? Border.all(color: glass.edge) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Aparece a subir e a ganhar opacidade. Com [index] os elementos de uma
/// lista entram em cascata (só os primeiros, para não atrasar listas longas).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
    this.duration = const Duration(milliseconds: 420),
  });
  final Widget child;
  final int index;
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _step = Duration(milliseconds: 55);
  late final Duration _delay = _step * math.min(widget.index, 8);
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration + _delay,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delay.inMilliseconds / (widget.duration + _delay).inMilliseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Número que conta até ao valor final quando aparece.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });
  final double value;
  final String Function(double) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return Text(format(value), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text(format(v == value ? value : v), style: style),
    );
  }
}
