import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Central motion tokens. Every animation in the app takes its duration and
/// curve from here, and honours the system "reduce motion" setting.
class Motion {
  const Motion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration smooth = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve standard = Cubic(0.2, 0.8, 0.2, 1);
  static const Curve soft = Cubic(0.22, 1, 0.36, 1);

  /// True when the user has asked the system for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// [base], or zero when motion is reduced.
  static Duration of(BuildContext context, Duration base) =>
      reduced(context) ? Duration.zero : base;
}

/// Fades content in while it rises a few pixels. Use [delay] to stagger.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.smooth,
    this.offset = 10,
  });

  /// Wrap [children] so they settle in one after another, [step] apart.
  /// Delays are capped so the whole sequence finishes in roughly 600ms.
  static List<Widget> stagger(
    List<Widget> children, {
    Duration step = const Duration(milliseconds: 70),
    int maxSteps = 7,
  }) {
    return [
      for (int i = 0; i < children.length; i++)
        FadeSlideIn(
          delay: step * (i < maxSteps ? i : maxSteps),
          child: children[i],
        ),
    ];
  }

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.soft,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder:
          (context, child) => Opacity(
            opacity: _curve.value,
            child: Transform.translate(
              offset: Offset(0, (1 - _curve.value) * widget.offset),
              child: child,
            ),
          ),
    );
  }
}

/// Route transition: a quiet fade with a few pixels of upward travel.
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: Motion.soft);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Gives any control a tactile feel: a tiny compression while pressed and a
/// 1px lift on hover. Does not interfere with the child's own taps.
class Tactile extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const Tactile({super.key, required this.child, this.enabled = true});

  @override
  State<Tactile> createState() => _TactileState();
}

class _TactileState extends State<Tactile> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || Motion.reduced(context)) return widget.child;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.97 : 1.0,
          duration: Motion.fast,
          curve: Motion.standard,
          child: AnimatedSlide(
            offset: Offset(0, _hover && !_down ? -1 / 48 : 0),
            duration: Motion.normal,
            curve: Motion.standard,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A soft sage glow around a text field while it has focus.
class GlowOnFocus extends StatefulWidget {
  final Widget child;
  final double radius;
  const GlowOnFocus({
    super.key,
    required this.child,
    this.radius = MindCareTheme.radiusMd,
  });

  @override
  State<GlowOnFocus> createState() => _GlowOnFocusState();
}

class _GlowOnFocusState extends State<GlowOnFocus> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.normal),
        curve: Motion.standard,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow:
              _focused
                  ? [
                    BoxShadow(
                      color: MindCareTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                  : const [],
        ),
        child: widget.child,
      ),
    );
  }
}

/// A number that counts up to [value] the first time it appears.
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const CountUp({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Motion.of(context, duration),
      curve: Curves.easeOut,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// Smoothly animates its size when the child changes. With reduced motion it
/// simply resizes (a zero-length AnimatedSize is not allowed to relayout).
class SoftSize extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Alignment alignment;

  const SoftSize({
    super.key,
    required this.child,
    this.duration = Motion.normal,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return child;
    return AnimatedSize(
      duration: duration,
      curve: Motion.standard,
      alignment: alignment,
      child: child,
    );
  }
}

/// A modal that fades in while easing from 98% to full size.
Future<T?> showSoftDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: MindCareTheme.textPrimary.withValues(alpha: 0.28),
    transitionDuration: Motion.of(context, const Duration(milliseconds: 220)),
    pageBuilder: (ctx, _, __) => SafeArea(child: Builder(builder: builder)),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.soft,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
