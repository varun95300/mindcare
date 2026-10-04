import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/consultation.dart';
import '../../models/quiz_question.dart';
import '../../models/screening_result.dart';
import '../../models/text_analysis.dart';
import '../../widgets/motion.dart';
import '../../widgets/ui.dart';

// Emotions reuse the palette: muted tones, no stray colours.
final _emotionColors = <Emotion, Color>{
  Emotion.sadness: MindCareTheme.depressionColor,
  Emotion.fear: MindCareTheme.anxietyColor,
  Emotion.anger: MindCareTheme.terracotta,
  Emotion.shame: MindCareTheme.interpersonalColor,
  Emotion.loneliness: MindCareTheme.butterDeep,
  Emotion.hopelessness: MindCareTheme.primaryDark,
  Emotion.exhaustion: MindCareTheme.stressColor,
  Emotion.overwhelm: MindCareTheme.accent,
  Emotion.joy: MindCareTheme.success,
  Emotion.calm: MindCareTheme.primary,
};

/// Horizontal bars with a label, a value and a colour.
class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String trailing;

  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                    fontSize: 13, color: MindCareTheme.textPrimary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: max == 0 ? 0 : (value / max).clamp(0.0, 1.0),
                ),
                duration: Motion.of(context, const Duration(milliseconds: 650)),
                curve: Curves.easeOut,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 12,
                  backgroundColor: MindCareTheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(trailing,
                textAlign: TextAlign.right,
                style: text.bodyMedium?.copyWith(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// How many patients sit at each risk level.
class RiskBreakdown extends StatelessWidget {
  final List<ConsultationRequest> requests;
  const RiskBreakdown({super.key, required this.requests});

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final l in RiskLevel.values)
        l: requests
            .where((r) => r.screeningResult.peakRiskLevel == l)
            .length,
    };
    final max = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (requests.isEmpty) {
      return const EmptyState(
        icon: Icons.health_and_safety_outlined,
        title: 'No data yet',
        message: 'Risk levels show once patients reach out.',
      );
    }
    return Column(
      children: [
        for (final l in RiskLevel.values.reversed)
          _BarRow(
            label: l == RiskLevel.none ? 'No flags' : l.label,
            value: counts[l]!.toDouble(),
            max: max.toDouble(),
            color: RiskPill.colorFor(l),
            trailing: '${counts[l]}',
          ),
      ],
    );
  }
}

/// Emotions expressed, summed across the given patients.
class EmotionBars extends StatelessWidget {
  final List<ScreeningResult> results;
  final int top;

  const EmotionBars({super.key, required this.results, this.top = 6});

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final r in results) {
      r.emotionSummary.forEach((k, v) => totals[k] = (totals[k] ?? 0) + v);
    }
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.isEmpty) {
      return const EmptyState(
        icon: Icons.mood_outlined,
        title: 'No emotion data',
        message: 'Appears after a chat with free-text answers.',
      );
    }
    final max = ranked.first.value;
    return Column(
      children: [
        for (final e in ranked.take(top))
          Builder(builder: (context) {
            final emotion = Emotion.values.firstWhere(
              (x) => x.name == e.key,
              orElse: () => Emotion.sadness,
            );
            return _BarRow(
              label: emotion.label,
              value: e.value,
              max: max,
              color: _emotionColors[emotion] ?? MindCareTheme.primary,
              trailing: e.value.toStringAsFixed(1),
            );
          }),
      ],
    );
  }
}

/// Requests received per day over the last week.
class RequestsTrend extends StatelessWidget {
  final List<ConsultationRequest> requests;
  const RequestsTrend({super.key, required this.requests});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [
      for (int i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day).subtract(Duration(days: i)),
    ];
    final counts = [
      for (final d in days)
        requests
            .where((r) =>
                r.requestedAt.year == d.year &&
                r.requestedAt.month == d.month &&
                r.requestedAt.day == d.day)
            .length,
    ];
    final maxY = (counts.fold<int>(0, (a, b) => a > b ? a : b) + 1).toDouble();
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: MindCareTheme.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (v, meta) => Text('${v.toInt()}',
                    style: const TextStyle(
                        fontSize: 11, color: MindCareTheme.textSecondary)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(letters[days[i].weekday - 1],
                        style: const TextStyle(
                            fontSize: 12, color: MindCareTheme.textSecondary)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < counts.length; i++)
                  FlSpot(i.toDouble(), counts[i].toDouble()),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              color: MindCareTheme.primaryDark,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: MindCareTheme.primary.withValues(alpha: 0.18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radar of the four domain scores for one patient.
class DomainRadar extends StatelessWidget {
  final ScreeningResult result;
  const DomainRadar({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final domains = ScreeningDomain.values;
    const labels = {
      ScreeningDomain.anxiety: 'Anxiety',
      ScreeningDomain.depression: 'Depression',
      ScreeningDomain.stress: 'Stress',
      ScreeningDomain.interpersonal: 'Interpersonal',
    };
    return SizedBox(
      height: 260,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 1),
          tickBorderData: const BorderSide(color: MindCareTheme.border),
          gridBorderData: const BorderSide(color: MindCareTheme.border),
          radarBorderData: const BorderSide(color: MindCareTheme.border),
          radarBackgroundColor: Colors.transparent,
          titlePositionPercentageOffset: 0.18,
          titleTextStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: MindCareTheme.textPrimary),
          getTitle: (index, angle) =>
              RadarChartTitle(text: labels[domains[index]]!),
          dataSets: [
            RadarDataSet(
              fillColor: MindCareTheme.primary.withValues(alpha: 0.28),
              borderColor: MindCareTheme.primaryDark,
              borderWidth: 2.5,
              entryRadius: 3.5,
              dataEntries: [
                for (final d in domains)
                  RadarEntry(value: (result.normalizedScores[d] ?? 0) * 100),
              ],
            ),
            // Invisible set pins the scale to 0 - 100.
            RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              entryRadius: 0,
              borderWidth: 0,
              dataEntries: [for (final _ in domains) const RadarEntry(value: 100)],
            ),
          ],
        ),
      ),
    );
  }
}

/// How strongly the patient answered each question, in order.
class AnswerTimeline extends StatelessWidget {
  final ScreeningResult result;
  const AnswerTimeline({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final answers = result.answers;
    if (answers.isEmpty) {
      return const EmptyState(
        icon: Icons.show_chart,
        title: 'No question-by-question data',
        message: 'This report was created without a chat transcript.',
      );
    }
    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 4,
          minX: 0,
          maxX: (answers.length - 1).clamp(1, 100).toDouble(),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: MindCareTheme.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 76,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= LikertResponse.values.length) {
                    return const SizedBox();
                  }
                  return Text(LikertResponse.values[i].label,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 10.5, color: MindCareTheme.textSecondary));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Q${v.toInt() + 1}',
                      style: const TextStyle(
                          fontSize: 11, color: MindCareTheme.textSecondary)),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < answers.length; i++)
                  FlSpot(i.toDouble(), answers[i].response.value.toDouble()),
              ],
              isCurved: false,
              color: MindCareTheme.accent,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: MindCareTheme.accent.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One patient's emotions as coloured bars.
class PatientEmotions extends StatelessWidget {
  final ScreeningResult result;
  const PatientEmotions({super.key, required this.result});

  @override
  Widget build(BuildContext context) =>
      EmotionBars(results: [result], top: 5);
}

/// Placeholder so imports of [ConsultationRequest] stay used by callers.
typedef RequestList = List<ConsultationRequest>;
