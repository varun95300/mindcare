import 'quiz_question.dart';

/// Records a single user answer during the quiz.
class QuizAnswer {
  final QuizQuestion question;
  final LikertResponse response;
  final DateTime timestamp;
  final Map<ScreeningDomain, double> evidenceContributed;

  QuizAnswer({
    required this.question,
    required this.response,
    required this.evidenceContributed,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Human-readable explanation of what this answer contributed.
  String get contributionSummary {
    final parts = <String>[];
    evidenceContributed.forEach((domain, value) {
      if (value > 0) {
        parts.add('${domain.label}: +${value.toStringAsFixed(1)}');
      }
    });
    return parts.join(', ');
  }
}
