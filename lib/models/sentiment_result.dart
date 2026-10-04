import 'quiz_question.dart';

/// Result of the on-device sentiment analysis on a user's free-text reply.
class SentimentResult {
  /// Raw compound score from the lexicon analysis (roughly −5 to +5).
  final double rawScore;

  /// Human-readable label: positive, neutral, negative, very_negative.
  final String label;

  /// Mapped severity score (0–3) that feeds into the AdaptiveEngine,
  /// replacing what was previously a LikertResponse value.
  final int severityScore;

  /// Optional bonus domain hints extracted from keyword matching.
  /// E.g. the word "panic" adds a hint towards Anxiety.
  final Map<ScreeningDomain, double> domainHints;

  /// The specific keywords that were detected in the user's text.
  final List<String> detectedKeywords;

  const SentimentResult({
    required this.rawScore,
    required this.label,
    required this.severityScore,
    this.domainHints = const {},
    this.detectedKeywords = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'rawScore': rawScore,
      'label': label,
      'severityScore': severityScore,
      'domainHints': domainHints.map((k, v) => MapEntry(k.name, v)),
      'detectedKeywords': detectedKeywords,
    };
  }
}
