import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/mood_entry.dart';
import '../services/mood_service.dart';
import 'feedback.dart';
import 'motion.dart';
import 'ui.dart';

/// A minimal line-drawn face for one of the five moods.
class MoodFace extends StatelessWidget {
  final int mood;
  final double size;
  final Color? color;

  const MoodFace({super.key, required this.mood, this.size = 44, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FacePainter(
        mood,
        color ?? MindCareTheme.textPrimary.withValues(alpha: 0.85),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final int mood;
  final Color color;
  _FacePainter(this.mood, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.05
          ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;

    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.46, stroke);

    final eyeY = s * 0.42;
    final left = Offset(s * 0.35, eyeY);
    final right = Offset(s * 0.65, eyeY);

    void dots() {
      canvas.drawCircle(left, s * 0.035, fill);
      canvas.drawCircle(right, s * 0.035, fill);
    }

    void closedEyes() {
      for (final c in [left, right]) {
        final r = Rect.fromCenter(center: c, width: s * 0.12, height: s * 0.1);
        canvas.drawArc(r, 0.15 * math.pi, 0.7 * math.pi, false, stroke);
      }
    }

    final mouth = Path();
    switch (mood) {
      case 4: // good: open smile
        dots();
        mouth.moveTo(s * 0.3, s * 0.58);
        mouth.quadraticBezierTo(s * 0.5, s * 0.8, s * 0.7, s * 0.58);
        break;
      case 3: // calm: closed eyes, soft smile
        closedEyes();
        mouth.moveTo(s * 0.37, s * 0.64);
        mouth.quadraticBezierTo(s * 0.5, s * 0.72, s * 0.63, s * 0.64);
        break;
      case 2: // okay: flat
        dots();
        mouth.moveTo(s * 0.37, s * 0.66);
        mouth.lineTo(s * 0.63, s * 0.66);
        break;
      case 1: // low: small frown
        dots();
        mouth.moveTo(s * 0.37, s * 0.7);
        mouth.quadraticBezierTo(s * 0.5, s * 0.6, s * 0.63, s * 0.7);
        break;
      default: // stressed: brows and a wavy mouth
        dots();
        canvas.drawLine(
          Offset(s * 0.28, s * 0.3),
          Offset(s * 0.4, s * 0.34),
          stroke,
        );
        canvas.drawLine(
          Offset(s * 0.72, s * 0.3),
          Offset(s * 0.6, s * 0.34),
          stroke,
        );
        mouth.moveTo(s * 0.34, s * 0.68);
        mouth.quadraticBezierTo(s * 0.42, s * 0.6, s * 0.5, s * 0.68);
        mouth.quadraticBezierTo(s * 0.58, s * 0.76, s * 0.66, s * 0.68);
    }
    canvas.drawPath(mouth, stroke);
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.mood != mood || old.color != color;
}

/// Five soft mood tiles. The selected one fills with its mood colour.
class MoodPicker extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onSelect;
  final double faceSize;

  const MoodPicker({
    super.key,
    required this.selected,
    required this.onSelect,
    this.faceSize = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final mood in Moods.pickerOrder)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _MoodTile(
                mood: mood,
                faceSize: faceSize,
                selected: selected == mood,
                onTap: () => onSelect(mood),
              ),
            ),
          ),
      ],
    );
  }
}

class _MoodTile extends StatefulWidget {
  final int mood;
  final double faceSize;
  final bool selected;
  final VoidCallback onTap;

  const _MoodTile({
    required this.mood,
    required this.faceSize,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_MoodTile> createState() => _MoodTileState();
}

class _MoodTileState extends State<_MoodTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  );

  @override
  void didUpdateWidget(_MoodTile old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected && !Motion.reduced(context)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = MindCareTheme.moodColor(widget.mood);
    final selected = widget.selected;
    return Semantics(
      button: true,
      selected: selected,
      label: Moods.label(widget.mood),
      child: InkWell(
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Motion.of(context, const Duration(milliseconds: 240)),
          curve: Motion.standard,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? color.withValues(alpha: 0.55)
                    : MindCareTheme.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final t = _pulse.value;
                  // 1 -> 1.08 -> 1, with a soft ring spreading outwards.
                  final scale = 1 + 0.08 * math.sin(math.pi * t);
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (_pulse.isAnimating)
                        Opacity(
                          opacity: (1 - t) * 0.55,
                          child: Transform.scale(
                            scale: 1 + 0.6 * t,
                            child: Container(
                              width: widget.faceSize,
                              height: widget.faceSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 2),
                              ),
                            ),
                          ),
                        ),
                      Transform.scale(scale: scale, child: child),
                    ],
                  );
                },
                child: MoodFace(mood: widget.mood, size: widget.faceSize),
              ),
              const SizedBox(height: 8),
              Text(
                Moods.label(widget.mood),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: MindCareTheme.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A gentle curve of the last [days] days. No axis numbers, soft grid.
class MoodChart extends StatelessWidget {
  final List<MoodEntry?> days;
  final double height;

  const MoodChart({super.key, required this.days, this.height = 190});

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final points = <FlSpot>[
      for (int i = 0; i < days.length; i++)
        if (days[i] != null) FlSpot(i.toDouble(), days[i]!.mood.toDouble()),
    ];
    if (points.isEmpty) {
      return const EmptyState(
        icon: Icons.show_chart,
        title: 'Nothing here yet.',
        message: 'Your mood will appear here as you check in.',
      );
    }
    final today = DateTime.now();

    return SizedBox(
      height: height,
      child: _Reveal(
        child: LineChart(
          duration: const Duration(milliseconds: 350),
          LineChartData(
            minX: 0,
            maxX: (days.length - 1).toDouble(),
            minY: -0.5,
            maxY: 4.5,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine:
                  (_) => FlLine(
                    color: MindCareTheme.border.withValues(alpha: 0.7),
                    strokeWidth: 1,
                    dashArray: [4, 6],
                  ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= days.length) return const SizedBox();
                    final d = today.subtract(
                      Duration(days: days.length - 1 - i),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _letters[d.weekday - 1],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: points,
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                color: MindCareTheme.primaryDark.withValues(alpha: 0.7),
                barWidth: 2.5,
                dotData: FlDotData(
                  getDotPainter:
                      (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 6,
                        color: MindCareTheme.moodColor(spot.y.round()),
                        strokeWidth: 2.5,
                        strokeColor: MindCareTheme.surface,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      MindCareTheme.primary.withValues(alpha: 0.25),
                      MindCareTheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws its child in from the left, like the line is being traced.
class _Reveal extends StatelessWidget {
  final Widget child;
  const _Reveal({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, const Duration(milliseconds: 800)),
      curve: Curves.easeOutCubic,
      builder:
          (context, t, child) =>
              ClipRect(clipper: _RevealClipper(t), child: child),
      child: child,
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  final double t;
  _RevealClipper(this.t);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(_RevealClipper old) => old.t != t;
}

/// "Your week in reflection": a few soft, non-clinical observations.
class ReflectionCard extends StatelessWidget {
  final List<String> lines;
  const ReflectionCard({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Panel(
      color: MindCareTheme.butter.withValues(alpha: 0.28),
      borderColor: MindCareTheme.butter,
      title: 'Your week in reflection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7, right: 12),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: MindCareTheme.butterDeep,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: text.bodyLarge?.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A warm writing card, like a page in a notebook.
class JournalComposer extends StatefulWidget {
  final String userId;
  final String title;
  final String hint;
  final int minLines;
  final VoidCallback? onSaved;

  const JournalComposer({
    super.key,
    required this.userId,
    this.title = 'What\'s on your mind?',
    this.hint = 'You don\'t have to write perfectly. Just start.',
    this.minLines = 6,
    this.onSaved,
  });

  @override
  State<JournalComposer> createState() => JournalComposerState();
}

class JournalComposerState extends State<JournalComposer> {
  final _controller = TextEditingController();
  int _mood = 2;
  bool _settled = false;

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Start the entry with a prompt (used by the wellness cards).
  void setPrompt(String prompt) {
    _controller.text = '$prompt ';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final note = _controller.text.trim();
    if (note.isEmpty) return false;
    context.read<MoodService>().addEntry(widget.userId, _mood, note: note);
    _controller.clear();
    Toasts.show('Reflection saved');
    widget.onSaved?.call();
    // The card settles very slightly, like a page being put down.
    if (mounted && !Motion.reduced(context)) {
      setState(() => _settled = true);
      Future<void>.delayed(const Duration(milliseconds: 160), () {
        if (mounted) setState(() => _settled = false);
      });
    } else if (mounted) {
      setState(() {});
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final date =
        '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';

    return AnimatedScale(
      scale: _settled ? 0.994 : 1,
      duration: Motion.of(context, Motion.fast),
      curve: Motion.standard,
      child: Container(
        decoration: BoxDecoration(
          color: MindCareTheme.surface,
          borderRadius: BorderRadius.circular(MindCareTheme.radiusXl),
          border: Border.all(color: MindCareTheme.border),
          boxShadow: MindCareTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: text.headlineMedium),
                        const SizedBox(height: 2),
                        Text(date, style: text.bodyMedium),
                      ],
                    ),
                  ),
                  MoodFace(mood: _mood, size: 34),
                ],
              ),
            ),
            // Ruled paper with the text field on top
            CustomPaint(
              painter: _PaperPainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 4, 24, 4),
                child: TextField(
                  controller: _controller,
                  minLines: widget.minLines,
                  maxLines: null,
                  onChanged: (_) => setState(() {}),
                  style: text.bodyLarge?.copyWith(
                    fontSize: 15.5,
                    height: 30 / 15.5,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How does this feel?', style: text.bodyMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 12,
                    children: [
                      Wrap(
                        children: [
                          for (final m in Moods.pickerOrder)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _mood = m),
                                child: Semantics(
                                  button: true,
                                  selected: _mood == m,
                                  label: Moods.label(m),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _mood == m
                                              ? MindCareTheme.moodColor(
                                                m,
                                              ).withValues(alpha: 0.6)
                                              : Colors.transparent,
                                      border: Border.all(
                                        color:
                                            _mood == m
                                                ? MindCareTheme.moodColor(m)
                                                : MindCareTheme.border,
                                      ),
                                    ),
                                    child: MoodFace(mood: m, size: 28),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      AsyncButton(
                        label: 'Save reflection',
                        loadingLabel: 'Saving',
                        successLabel: 'Saved',
                        onPressed:
                            _controller.text.trim().isEmpty ? null : _save,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line =
        Paint()
          ..color = MindCareTheme.border.withValues(alpha: 0.9)
          ..strokeWidth = 1;
    for (double y = 34; y < size.height; y += 30) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), line);
    }
    final margin =
        Paint()
          ..color = MindCareTheme.accent.withValues(alpha: 0.5)
          ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(32, 0), Offset(32, size.height), margin);
  }

  @override
  bool shouldRepaint(_PaperPainter old) => false;
}

/// A quiet card for a wellness activity.
class WellnessTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final Color tint;
  final VoidCallback onTap;

  const WellnessTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.tint,
    required this.onTap,
  });

  @override
  State<WellnessTile> createState() => _WellnessTileState();
}

class _WellnessTileState extends State<WellnessTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.normal),
        curve: Motion.standard,
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MindCareTheme.surface,
          borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
          border: Border.all(color: MindCareTheme.border),
          boxShadow:
              _hover ? MindCareTheme.cardShadow : MindCareTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSlide(
              offset: Offset(0, _hover ? -0.06 : 0),
              duration: Motion.of(context, Motion.normal),
              curve: Motion.standard,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.tint.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  color: MindCareTheme.textPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.title, style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
              widget.description,
              style: text.bodyMedium?.copyWith(fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: widget.onTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.actionLabel),
                  const SizedBox(width: 6),
                  AnimatedSlide(
                    offset: Offset(_hover ? 0.3 : 0, 0),
                    duration: Motion.of(context, Motion.normal),
                    curve: Motion.standard,
                    child: const Icon(Icons.arrow_forward, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
