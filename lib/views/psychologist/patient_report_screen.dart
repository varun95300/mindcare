import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/quiz_question.dart';
import '../../models/consultation.dart';
import '../../models/screening_result.dart';

/// Screen for psychologists to view a patient's full screening report.
/// This is what the psychologist sees when they tap "View Report" on a
/// consultation request.
class PatientReportScreen extends StatelessWidget {
  final ConsultationRequest request;

  const PatientReportScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final result = request.screeningResult;

    return Scaffold(
      appBar: AppBar(
        title: Text("${request.patientName}'s Report"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient info header
              _PatientInfoCard(request: request),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Screening profile
              _ScreeningProfileCard(result: result),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Domain score bars
              _DomainScoresCard(result: result),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Key observations
              _ObservationsCard(result: result),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Detailed reasoning trace
              _ReasoningTraceCard(result: result),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Methodology
              Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingMd),
                decoration: BoxDecoration(
                  color: MindCareTheme.surfaceVariant,
                  borderRadius:
                      BorderRadius.circular(MindCareTheme.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: MindCareTheme.secondary),
                        const SizedBox(width: 6),
                        Text('How This Screening Worked',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium),
                      ],
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    Text(
                      result.methodologyExplanation,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingMd),
                decoration: BoxDecoration(
                  color: MindCareTheme.warning.withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(MindCareTheme.radiusMd),
                  border: Border.all(
                      color: MindCareTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 18, color: MindCareTheme.stressColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This is an automated screening report, not a clinical assessment. '
                        'Please use this information as a starting point for your professional evaluation.',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientInfoCard extends StatelessWidget {
  final ConsultationRequest request;
  const _PatientInfoCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: MindCareTheme.heroGradient,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                request.patientName[0],
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(width: MindCareTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.patientName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                Text(
                  'Screening completed • ${request.screeningResult.totalQuestions} questions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                ),
                if (request.message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Message: "${request.message}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreeningProfileCard extends StatelessWidget {
  final ScreeningResult result;
  const _ScreeningProfileCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final primaryColor = MindCareTheme.domainColor(result.primaryDomain.label);

    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        boxShadow: MindCareTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'SCREENING PROFILE',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: MindCareTheme.textLight,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: MindCareTheme.spacingMd),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
            ),
            child: Text(
              'Primary: ${result.primaryDomain.label}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: primaryColor,
                  ),
            ),
          ),
          if (result.secondaryDomain != null) ...[
            const SizedBox(height: MindCareTheme.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MindCareTheme.domainColor(result.secondaryDomain!.label)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
              ),
              child: Text(
                'Secondary: ${result.secondaryDomain!.label}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MindCareTheme.domainColor(
                          result.secondaryDomain!.label),
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DomainScoresCard extends StatelessWidget {
  final ScreeningResult result;
  const _DomainScoresCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        boxShadow: MindCareTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Domain Scores',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: MindCareTheme.spacingMd),
          ...ScreeningDomain.values.map((domain) {
            final score = result.normalizedScores[domain] ?? 0.0;
            final severity = result.severityLabels[domain] ?? 'Low';
            final color = MindCareTheme.domainColor(domain.label);
            return Padding(
              padding: const EdgeInsets.only(bottom: MindCareTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(domain.label,
                          style: Theme.of(context).textTheme.titleMedium),
                      Row(
                        children: [
                          Text(
                            '${(score * 100).toInt()}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: MindCareTheme.textLight,
                                    fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(
                                  MindCareTheme.radiusFull),
                            ),
                            child: Text(
                              severity,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusFull),
                    child: LinearProgressIndicator(
                      value: score,
                      minHeight: 8,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
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

class _ObservationsCard extends StatelessWidget {
  final ScreeningResult result;
  const _ObservationsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        boxShadow: MindCareTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: MindCareTheme.stressColor, size: 22),
              const SizedBox(width: MindCareTheme.spacingSm),
              Text('Key Observations',
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: MindCareTheme.spacingMd),
          ...result.keyObservations.map(
            (obs) => Padding(
              padding: const EdgeInsets.only(bottom: MindCareTheme.spacingSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          fontSize: 16, color: MindCareTheme.primary)),
                  Expanded(
                    child: Text(obs,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasoningTraceCard extends StatelessWidget {
  final ScreeningResult result;
  const _ReasoningTraceCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final trace = result.reasoningTrace;

    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        boxShadow: MindCareTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined,
                  color: MindCareTheme.secondary, size: 22),
              const SizedBox(width: MindCareTheme.spacingSm),
              Text('Question-by-Question Trace',
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: MindCareTheme.spacingSm),
          Text(
            'Each question the patient answered and how it contributed to the screening profile:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: MindCareTheme.textSecondary,
                ),
          ),
          const SizedBox(height: MindCareTheme.spacingMd),

          ...trace.map((step) {
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: MindCareTheme.spacingSm),
              child: Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingSm),
                decoration: BoxDecoration(
                  color: MindCareTheme.surfaceVariant,
                  borderRadius:
                      BorderRadius.circular(MindCareTheme.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: MindCareTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(
                                MindCareTheme.radiusFull),
                          ),
                          child: Text(
                            'Q${step.questionNumber}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: MindCareTheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                _responseColor(step.responseValue)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                MindCareTheme.radiusFull),
                          ),
                          child: Text(
                            '${step.responseLabel} (${step.responseValue}/4)',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: _responseColor(
                                        step.responseValue),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.questionText,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: step.evidenceContributed.entries
                          .where((e) => e.value > 0)
                          .map((e) {
                        final color =
                            MindCareTheme.domainColor(e.key.label);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                MindCareTheme.radiusFull),
                          ),
                          child: Text(
                            '+${e.value.toStringAsFixed(1)} ${e.key.label}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),
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
