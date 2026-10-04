import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/ui.dart';

/// A slow guided breathing exercise: in for 4, hold for 1, out for 5.
class BreathingScreen extends StatefulWidget {
  final int minutes;
  const BreathingScreen({super.key, this.minutes = 2});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();
  Timer? _timer;
  late int _remaining = widget.minutes * 60;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _finish();
    });
  }

  void _finish() {
    _timer?.cancel();
    _controller.stop();
    setState(() => _done = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  double _scale(double t) {
    if (t < 0.4) return 0.55 + 0.45 * Curves.easeInOut.transform(t / 0.4);
    if (t < 0.5) return 1.0;
    return 1.0 - 0.45 * Curves.easeInOut.transform((t - 0.5) / 0.5);
  }

  String _label(double t) {
    if (t < 0.4) return 'Breathe in';
    if (t < 0.5) return 'Hold';
    return 'Breathe out';
  }

  String get _clock {
    final m = (_remaining ~/ 60).toString();
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: MindCareTheme.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Take a breath'),
      ),
      body: SoftBackdrop(
        animated: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child:
                _done
                    ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: MindCareTheme.primary.withValues(
                              alpha: 0.45,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.spa_outlined,
                            size: 52,
                            color: MindCareTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'You made space for yourself today.',
                          textAlign: TextAlign.center,
                          style: text.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Keep going, gently.', style: text.bodyLarge),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Done'),
                        ),
                      ],
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final t = _controller.value;
                            // With reduced motion the form stays still and only the
                            // words change.
                            final scale =
                                Motion.reduced(context) ? 0.85 : _scale(t);
                            return SizedBox(
                              width: 300,
                              height: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(300, 300),
                                    painter: _BlobPainter(
                                      phase: Motion.reduced(context) ? 0 : t,
                                      scale: scale,
                                    ),
                                  ),
                                  Text(_label(t), style: text.headlineMedium),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(_clock, style: text.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Let your shoulders drop.',
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: _finish,
                          child: const Text('End early'),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

/// A soft, slightly irregular circle that swells and settles with the breath.
class _BlobPainter extends CustomPainter {
  final double phase;
  final double scale;
  _BlobPainter({required this.phase, required this.scale});

  Path _shape(Size size, double radius, double wobble) {
    final c = size.center(Offset.zero);
    final path = Path();
    const n = 72;
    for (int i = 0; i <= n; i++) {
      final a = i / n * 2 * math.pi;
      final r =
          radius *
          (1 +
              wobble * math.sin(3 * a + phase * 2 * math.pi) +
              wobble * 0.6 * math.sin(5 * a - phase * 2 * math.pi * 1.3));
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.width / 2 * scale;
    canvas.drawPath(
      _shape(size, base, 0.025),
      Paint()..color = MindCareTheme.primary.withValues(alpha: 0.26),
    );
    canvas.drawPath(
      _shape(size, base * 0.7, 0.03),
      Paint()..color = MindCareTheme.primary.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.phase != phase || old.scale != scale;
}

/// A short 5-4-3-2-1 grounding exercise, one step at a time.
Future<void> showGroundingDialog(BuildContext context) {
  const steps = [
    ('5', 'things you can see', 'Look around slowly. Name five things.'),
    (
      '4',
      'things you can feel',
      'The chair, your feet on the floor, your clothes.',
    ),
    ('3', 'things you can hear', 'Near or far. Just notice them.'),
    ('2', 'things you can smell', 'Or two smells you like.'),
    ('1', 'thing you can taste', 'Or one slow sip of water.'),
  ];
  return showSoftDialog(
    context: context,
    builder: (ctx) {
      var i = 0;
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final done = i >= steps.length;
          final text = Theme.of(ctx).textTheme;
          return AlertDialog(
            title: Text(done ? 'Well done' : 'Grounding'),
            content: SizedBox(
              width: 360,
              child:
                  done
                      ? Text(
                        'You are here, in this moment. Take one more slow breath.',
                        style: text.bodyLarge,
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].$1,
                            style: text.displayLarge?.copyWith(
                              fontSize: 56,
                              color: MindCareTheme.primaryDark,
                            ),
                          ),
                          Text(steps[i].$2, style: text.headlineSmall),
                          const SizedBox(height: 8),
                          Text(steps[i].$3, style: text.bodyMedium),
                        ],
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(done ? 'Close' : 'Not now'),
              ),
              if (!done)
                FilledButton(
                  onPressed: () => setLocal(() => i++),
                  child: Text(i == steps.length - 1 ? 'Finish' : 'Next'),
                ),
            ],
          );
        },
      );
    },
  );
}
