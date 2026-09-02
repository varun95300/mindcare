import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/quiz_question.dart';
import '../models/screening_result.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'reasoning_screen.dart';
import 'recommendations_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuizViewModel>();
    final result = vm.result;

    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('No screening result available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Screening Report'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header card
              _ResultHeaderCard(result: result),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Domain scores
              _DomainScoresCard(result: result),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Key observations
              _ObservationsCard(result: result),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Methodology
              _MethodologyCard(result: result),
              const SizedBox(height: MindCareTheme.spacingLg),

              // View Reasoning Trace
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReasoningScreen(result: result),
                    ),
                  );
                },
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('View Detailed Reasoning Trace'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Disclaimer
              _DisclaimerCard(result: result),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Recommendation CTA
              Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingLg),
                decoration: BoxDecoration(
                  gradient: MindCareTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.people_outlined,
                        color: Colors.white, size: 36),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    Text(
                      'Recommended Next Step',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    Text(
                      result.recommendation,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                    const SizedBox(height: MindCareTheme.spacingMd),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RecommendationsScreen(result: result),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: MindCareTheme.primary,
                      ),
                      child: const Text('View Recommended Psychologists'),
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

class _ResultHeaderCard extends StatelessWidget {
  final ScreeningResult result;
  const _ResultHeaderCard({required this.result});

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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assessment_outlined,
              size: 32,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: MindCareTheme.spacingMd),
          Text(
            'YOUR MINDCARE SCREENING',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: MindCareTheme.textLight,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: MindCareTheme.spacingMd),

          // Primary area
          Text(
            'Primary Area',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MindCareTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
            ),
            child: Text(
              '${result.primaryDomain.label}-related indicators',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: primaryColor,
                  ),
            ),
          ),

          // Secondary area
          if (result.secondaryDomain != null) ...[
            const SizedBox(height: MindCareTheme.spacingMd),
            Text(
              'Secondary Area',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MindCareTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MindCareTheme.domainColor(result.secondaryDomain!.label)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
              ),
              child: Text(
                '${result.secondaryDomain!.label}-related indicators',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MindCareTheme.domainColor(
                          result.secondaryDomain!.label),
                    ),
              ),
            ),
          ],

          const SizedBox(height: MindCareTheme.spacingSm),
          Text(
            '${result.totalQuestions} questions answered',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MindCareTheme.textLight,
                  fontSize: 12,
                ),
          ),
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
          Text(
            'Screening Profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
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
                      Text(
                        domain.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(MindCareTheme.radiusFull),
                        ),
                        child: Text(
                          severity,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                        ),
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
              Text(
                'What Influenced This Result',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
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
                    child: Text(
                      obs,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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

class _MethodologyCard extends StatelessWidget {
  final ScreeningResult result;
  const _MethodologyCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        color: MindCareTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: MindCareTheme.secondary, size: 22),
              const SizedBox(width: MindCareTheme.spacingSm),
              Text(
                'How the Screening Worked',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: MindCareTheme.spacingSm),
          Text(
            result.methodologyExplanation,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  final ScreeningResult result;
  const _DisclaimerCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingMd),
      decoration: BoxDecoration(
        color: MindCareTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        border: Border.all(color: MindCareTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber,
              color: MindCareTheme.warning.withOpacity(0.8), size: 22),
          const SizedBox(width: MindCareTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Disclaimer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: MindCareTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.disclaimer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
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
