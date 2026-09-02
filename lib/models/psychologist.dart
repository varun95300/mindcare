import 'quiz_question.dart';

/// Psychologist profile for recommendations.
class Psychologist {
  final String id;
  final String name;
  final String title;
  final List<ScreeningDomain> specializations;
  final int yearsExperience;
  final double rating;
  final int reviewCount;
  final double consultationFee;
  final String consultationMode;
  final String bio;
  final String profileImageUrl;
  final bool isAvailable;

  const Psychologist({
    required this.id,
    required this.name,
    required this.title,
    required this.specializations,
    required this.yearsExperience,
    required this.rating,
    required this.reviewCount,
    required this.consultationFee,
    required this.consultationMode,
    required this.bio,
    this.profileImageUrl = '',
    this.isAvailable = true,
  });

  /// Returns the specialization labels as a formatted string.
  String get specializationLabels =>
      specializations.map((s) => s.label).join(', ');

  /// Returns experience as a formatted string.
  String get experienceLabel =>
      '$yearsExperience ${yearsExperience == 1 ? 'year' : 'years'} experience';
}

/// A recommendation with an explanation of why this psychologist was matched.
class PsychologistRecommendation {
  final Psychologist psychologist;
  final double matchScore;
  final String explanation;
  final List<ScreeningDomain> matchingSpecializations;

  const PsychologistRecommendation({
    required this.psychologist,
    required this.matchScore,
    required this.explanation,
    required this.matchingSpecializations,
  });
}
