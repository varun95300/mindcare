import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/quiz_question.dart';
import '../models/screening_result.dart';

class ReasoningScreen extends StatelessWidget {
  final ScreeningResult result;

  const ReasoningScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final trace = result.reasoningTrace;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reasoning Trace'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingLg),
                decoration: BoxDecoration(
                  gradient: MindCareTheme.heroGradient,
                  borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.account_tree,
                        color: Colors.white, size: 32),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    Text(
                      'Why Were These Questions Asked?',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    Text(
                      'This trace shows how each answer contributed to your screening profile.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Question-by-question trace
              ...trace.asMap().entries.map((entry) {
                final idx = entry.key;
                final step = entry.value;
                final isLast = idx == trace.length - 1;
                return _ReasoningStepCard(
                  step: step,
                  isLast: isLast,
                );
              }),

              const SizedBox(height: MindCareTheme.spacingLg),

              // Final evidence summary
              _FinalSummaryCard(result: result),

              const SizedBox(height: MindCareTheme.spacingLg),

              // Conclusion
              _ConclusionCard(result: result),

              const SizedBox(height: MindCareTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasoningStepCard extends StatelessWidget {
  final ReasoningStep step;
  final bool isLast;

  const _ReasoningStepCard({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MindCareTheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: MindCareTheme.primary, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      'Q${step.questionNumber}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MindCareTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: MindCareTheme.primaryLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: MindCareTheme.spacingSm),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: MindCareTheme.spacingMd),
              padding: const EdgeInsets.all(MindCareTheme.spacingMd),
              decoration: BoxDecoration(
                color: MindCareTheme.surface,
                borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
                boxShadow: MindCareTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Text(
                    step.questionText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: MindCareTheme.spacingSm),

                  // Answer
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _responseColor(step.responseValue).withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(MindCareTheme.radiusFull),
                    ),
                    child: Text(
                      'Answer: ${step.responseLabel} (${step.responseValue}/4)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _responseColor(step.responseValue),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                    ),
                  ),
                  const SizedBox(height: MindCareTheme.spacingSm),

                  // Evidence contributed
                  Text(
                    'Evidence contributed:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: MindCareTheme.textLight,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: step.evidenceContributed.entries
                        .where((e) => e.value > 0)
                        .map((e) {
                      final color = MindCareTheme.domainColor(e.key.label);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(MindCareTheme.radiusFull),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          '+${e.value.toStringAsFixed(1)} ${e.key.label}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _responseColor(int value) {
    if (value >= 4) return MindCareTheme.accent;
    if (value >= 3) return MindCareTheme.stressColor;
    if (value >= 2) return MindCareTheme.primary;
    return MindCareTheme.success;
  }
}

class _FinalSummaryCard extends StatelessWidget {
  final ScreeningResult result;
  const _FinalSummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        boxShadow: MindCareTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Evidence Summary',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: MindCareTheme.spacingMd),
          ...ScreeningDomain.values.map((domain) {
            final score = result.normalizedScores[domain] ?? 0.0;
            final severity = result.severityLabels[domain] ?? 'Low';
            final color = MindCareTheme.domainColor(domain.label);
            return Padding(
              padding: const EdgeInsets.only(bottom: MindCareTheme.spacingSm),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      '${domain.label}:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(MindCareTheme.radiusFull),
                    ),
                    child: Text(
                      severity,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${(score * 100).toInt()}%)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MindCareTheme.textLight,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ConclusionCard extends StatelessWidget {
  final ScreeningResult result;
  const _ConclusionCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final secondaryText = result.secondaryDomain != null
        ? ', followed by ${result.secondaryDomain!.label}'
        : '';

    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        color: MindCareTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        border: Border.all(color: MindCareTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Therefore:',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: MindCareTheme.primary,
                ),
          ),
          const SizedBox(height: MindCareTheme.spacingSm),
          Text(
            'Primary screening area = ${result.primaryDomain.label}$secondaryText.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: MindCareTheme.spacingSm),
          Text(
            'This conclusion was reached by comparing accumulated evidence '
            'across all four screening domains based on your ${result.totalQuestions} answers.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
