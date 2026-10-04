import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/psychologist.dart';
import '../models/screening_result.dart';
import '../services/recommendation_service.dart';
import 'psychologist_profile_screen.dart';

class RecommendationsScreen extends StatelessWidget {
  final ScreeningResult result;

  const RecommendationsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final recommendations = RecommendationService.recommend(result);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Psychologists'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'People Who Can Help',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: MindCareTheme.spacingSm),
              Text(
                'Based on what you shared, here are professionals we think could '
                'be a good fit. Take your time, and reach out whenever you feel ready.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Psychologist cards
              ...recommendations.map(
                (rec) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: MindCareTheme.spacingMd),
                  child: _PsychologistCard(
                    recommendation: rec,
                    screeningResult: result,
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

class _PsychologistCard extends StatelessWidget {
  final PsychologistRecommendation recommendation;
  final ScreeningResult screeningResult;

  const _PsychologistCard({
    required this.recommendation,
    required this.screeningResult,
  });

  @override
  Widget build(BuildContext context) {
    final psy = recommendation.psychologist;
    final matchPercent = (recommendation.matchScore * 100).toInt();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PsychologistProfileScreen(
              psychologist: psy,
              recommendation: recommendation,
              screeningResult: screeningResult,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(MindCareTheme.spacingMd),
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
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: MindCareTheme.heroGradient,
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      psy.name.split(' ').map((w) => w[0]).take(2).join(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: MindCareTheme.spacingMd),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        psy.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        psy.title,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                ),
                      ),
                    ],
                  ),
                ),

                // Match percentage
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: MindCareTheme.success.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusFull),
                  ),
                  child: Text(
                    '$matchPercent% match',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MindCareTheme.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MindCareTheme.spacingMd),

            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.star,
                  label: '${psy.rating}',
                  color: MindCareTheme.stressColor,
                ),
                const SizedBox(width: MindCareTheme.spacingSm),
                _StatChip(
                  icon: Icons.work_outline,
                  label: '${psy.yearsExperience}y exp',
                  color: MindCareTheme.secondary,
                ),
                const SizedBox(width: MindCareTheme.spacingSm),
                _StatChip(
                  icon: Icons.currency_rupee,
                  label: '${psy.consultationFee.toInt()}',
                  color: MindCareTheme.primary,
                ),
              ],
            ),
            const SizedBox(height: MindCareTheme.spacingSm),

            // Specializations
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: psy.specializations.map((spec) {
                final isMatch =
                    recommendation.matchingSpecializations.contains(spec);
                final color = MindCareTheme.domainColor(spec.label);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isMatch ? 0.2 : 0.08),
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusFull),
                    border: isMatch
                        ? Border.all(color: color.withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Text(
                    spec.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontSize: 12,
                          fontWeight:
                              isMatch ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: MindCareTheme.spacingSm),

            // Explanation
            Container(
              padding: const EdgeInsets.all(MindCareTheme.spacingSm),
              decoration: BoxDecoration(
                color: MindCareTheme.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(MindCareTheme.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: MindCareTheme.primaryDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      recommendation.explanation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: MindCareTheme.primaryDark,
                          ),
                    ),
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}
