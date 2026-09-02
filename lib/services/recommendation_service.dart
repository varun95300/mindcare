import '../models/quiz_question.dart';
import '../models/psychologist.dart';
import '../models/screening_result.dart';
import '../data/seed_psychologists.dart';

/// Recommends psychologists based on screening results.
class RecommendationService {
  /// Get ranked psychologist recommendations for a screening result.
  static List<PsychologistRecommendation> recommend(ScreeningResult result) {
    final primary = result.primaryDomain;
    final secondary = result.secondaryDomain;

    final recommendations = <PsychologistRecommendation>[];

    for (final psy in SeedPsychologists.all) {
      if (!psy.isAvailable) continue;

      final matchScore = _calculateMatchScore(psy, primary, secondary);
      final matchingSpecs = _getMatchingSpecializations(psy, primary, secondary);
      final explanation = _generateExplanation(psy, primary, secondary, matchingSpecs);

      recommendations.add(PsychologistRecommendation(
        psychologist: psy,
        matchScore: matchScore,
        explanation: explanation,
        matchingSpecializations: matchingSpecs,
      ));
    }

    // Sort by match score (highest first)
    recommendations.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return recommendations;
  }

  /// Calculate match score: specialization (60%) + rating (20%) + experience (20%).
  static double _calculateMatchScore(
    Psychologist psy,
    ScreeningDomain primary,
    ScreeningDomain? secondary,
  ) {
    // Specialization match (0.0 to 1.0)
    double specMatch = 0.1; // base score
    final hasPrimary = psy.specializations.contains(primary);
    final hasSecondary =
        secondary != null && psy.specializations.contains(secondary);

    if (hasPrimary && hasSecondary) {
      specMatch = 1.0;
    } else if (hasPrimary) {
      specMatch = 0.7;
    } else if (hasSecondary) {
      specMatch = 0.4;
    }

    // Rating normalized (0.0 to 1.0, assuming 1-5 scale)
    final ratingNorm = (psy.rating - 1.0) / 4.0;

    // Experience normalized (0.0 to 1.0, cap at 20 years)
    final expNorm = (psy.yearsExperience / 20.0).clamp(0.0, 1.0);

    return (specMatch * 0.6) + (ratingNorm * 0.2) + (expNorm * 0.2);
  }

  /// Get the specializations that match the user's screening profile.
  static List<ScreeningDomain> _getMatchingSpecializations(
    Psychologist psy,
    ScreeningDomain primary,
    ScreeningDomain? secondary,
  ) {
    final matching = <ScreeningDomain>[];
    if (psy.specializations.contains(primary)) matching.add(primary);
    if (secondary != null && psy.specializations.contains(secondary)) {
      matching.add(secondary);
    }
    return matching;
  }

  /// Generate a human-readable explanation of why this psychologist was recommended.
  static String _generateExplanation(
    Psychologist psy,
    ScreeningDomain primary,
    ScreeningDomain? secondary,
    List<ScreeningDomain> matchingSpecs,
  ) {
    if (matchingSpecs.length >= 2) {
      return 'Recommended because ${psy.name} specializes in '
          '${matchingSpecs.map((s) => s.label).join(" and ")}, '
          'which match your screening profile.';
    } else if (matchingSpecs.length == 1) {
      return 'Recommended because ${psy.name} specializes in '
          '${matchingSpecs.first.label}, your primary screening area.';
    } else {
      return '${psy.name} is a highly rated professional who may be able to '
          'help with your concerns.';
    }
  }
}
