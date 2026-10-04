import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'motion.dart';

// ─── Toasts ──────────────────────────────────────────────────────────

class _ToastData {
  final int id;
  final String message;
  final IconData icon;
  final Duration duration;
  const _ToastData(this.id, this.message, this.icon, this.duration);
}

/// Small, calm confirmations ("Reflection saved"). Call [Toasts.show]; the
/// [ToastHost] near the top of the app draws them: bottom-right on wide
/// screens, bottom-centre on phones.
class Toasts {
  const Toasts._();

  static final ValueNotifier<List<_ToastData>> _items = ValueNotifier(const []);
  static int _nextId = 0;

  static void show(
    String message, {
    IconData icon = Icons.check_circle_outline,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final item = _ToastData(_nextId++, message, icon, duration);
    // Keep the stack tidy: at most three at once.
    final next = [..._items.value, item];
    _items.value = next.length > 3 ? next.sublist(next.length - 3) : next;
  }

  static void _remove(int id) {
    _items.value = _items.value.where((t) => t.id != id).toList();
  }
}

/// Hosts the toast layer above all routes. Place it in MaterialApp.builder.
class ToastHost extends StatelessWidget {
  final Widget child;
  const ToastHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<List<_ToastData>>(
              valueListenable: Toasts._items,
              builder:
                  (context, items, _) => Align(
                    alignment:
                        wide ? Alignment.bottomRight : Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.all(wide ? 24 : 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            wide
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.center,
                        children: [
                          for (final t in items)
                            _ToastCard(key: ValueKey(t.id), data: t),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastCard extends StatefulWidget {
  final _ToastData data;
  const _ToastCard({super.key, required this.data});

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.soft,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.data.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      Toasts._remove(widget.data.id);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return AnimatedBuilder(
      animation: _curve,
      builder:
          (context, child) => Opacity(
            opacity: _curve.value,
            child: Transform.translate(
              offset: Offset(0, reduced ? 0 : (1 - _curve.value) * 14),
              child: child,
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Material(
          color: Colors.transparent,
          child: Semantics(
            liveRegion: true,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
              decoration: BoxDecoration(
                color: MindCareTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MindCareTheme.border),
                boxShadow: MindCareTheme.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: MindCareTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    widget.data.icon,
                    size: 20,
                    color: MindCareTheme.primaryDark,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.data.message,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Button with loading and success states ──────────────────────────

/// A button that shows what is happening: "Save" -> "Saving ···" ->
/// "✓ Saved" -> back to "Save". [onPressed] returns whether it succeeded.
class AsyncButton extends StatefulWidget {
  final String label;
  final String loadingLabel;
  final String successLabel;
  final IconData? icon;
  final Future<bool> Function()? onPressed;
  final bool outlined;
  final VoidCallback? onSuccess;

  const AsyncButton({
    super.key,
    required this.label,
    this.loadingLabel = 'Saving',
    this.successLabel = 'Saved',
    this.icon,
    required this.onPressed,
    this.outlined = false,
    this.onSuccess,
  });

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

enum _Phase { idle, loading, success }

class _AsyncButtonState extends State<AsyncButton> {
  _Phase _phase = _Phase.idle;

  Future<void> _run() async {
    if (_phase != _Phase.idle || widget.onPressed == null) return;
    final reduced = Motion.reduced(context);
    setState(() => _phase = _Phase.loading);
    final results = await Future.wait<Object?>([
      widget.onPressed!(),
      // Keep "Saving" visible long enough to read, even when it is instant.
      Future<void>.delayed(Duration(milliseconds: reduced ? 150 : 450)),
    ]);
    if (!mounted) return;
    if (results.first == true) {
      setState(() => _phase = _Phase.success);
      widget.onSuccess?.call();
      await Future<void>.delayed(Duration(milliseconds: reduced ? 700 : 1200));
    }
    if (mounted) setState(() => _phase = _Phase.idle);
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_phase) {
      _Phase.idle => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      _Phase.loading => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.loadingLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const _Dots(),
        ],
      ),
      _Phase.success => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CheckPop(),
          const SizedBox(width: 6),
          Text(widget.successLabel),
        ],
      ),
    };

    final child = SoftSize(
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.normal),
        switchInCurve: Motion.standard,
        child: KeyedSubtree(key: ValueKey(_phase), child: content),
      ),
    );

    // While busy, keep the button looking active but ignore taps.
    final VoidCallback? handler =
        widget.onPressed == null
            ? null
            : (_phase == _Phase.idle ? _run : () {});

    return Tactile(
      child:
          widget.outlined
              ? OutlinedButton(onPressed: handler, child: child)
              : FilledButton(onPressed: handler, child: child),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder:
          (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 3; i++)
                Opacity(
                  opacity:
                      0.25 +
                      0.75 *
                          (Motion.reduced(context)
                              ? 1.0
                              : ((_c.value * 3 - i) % 3 < 1
                                  ? 1 - ((_c.value * 3 - i) % 3)
                                  : 0.0)),
                  child: const Text(
                    '·',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
    );
  }
}

class _CheckPop extends StatelessWidget {
  const _CheckPop();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, const Duration(milliseconds: 320)),
      curve: Curves.easeOutBack,
      builder:
          (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.5 + 0.5 * t, child: child),
          ),
      child: const Icon(Icons.check_rounded, size: 20),
    );
  }
}

// ─── Page loader ─────────────────────────────────────────────────────

/// A soft sage form that gently breathes while the app waits.
class BreathingLoader extends StatefulWidget {
  final String? message;
  const BreathingLoader({super.key, this.message = 'Taking a moment…'});

  @override
  State<BreathingLoader> createState() => _BreathingLoaderState();
}

class _BreathingLoaderState extends State<BreathingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eased = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    return Semantics(
      label: 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: eased,
            builder: (context, _) {
              final t = eased.value;
              return Opacity(
                opacity: 0.65 + 0.35 * t,
                child: Transform.scale(
                  scale: 0.92 + 0.13 * t,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MindCareTheme.primary.withValues(alpha: 0.55),
                      border: Border.all(
                        color: MindCareTheme.primary.withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 20),
            Text(
              widget.message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen warm background with the [BreathingLoader] centred.
class LoadingScreen extends StatelessWidget {
  final String? message;
  const LoadingScreen({super.key, this.message = 'Just a second…'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MindCareTheme.background,
      body: Center(child: BreathingLoader(message: message)),
    );
  }
}

// ─── Calm error ──────────────────────────────────────────────────────

/// "Something didn't go as planned." with a way to try again.
class GentleError extends StatelessWidget {
  final VoidCallback? onRetry;
  const GentleError({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FadeSlideIn(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: MindCareTheme.surface,
            borderRadius: BorderRadius.circular(MindCareTheme.radiusXl),
            border: Border.all(color: MindCareTheme.border),
            boxShadow: MindCareTheme.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: MindCareTheme.accent.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: MindCareTheme.terracotta,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Something didn't go as planned.",
                textAlign: TextAlign.center,
                style: text.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text('Please try again.', style: text.bodyMedium),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                Tactile(
                  child: FilledButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
