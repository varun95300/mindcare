import '../data/question_bank.dart';
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

  Map<String, dynamic> toJson() => {
        'questionId': question.id,
        'response': response.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'evidence': evidenceContributed.map((k, v) => MapEntry(k.name, v)),
      };

  /// Returns null if the question id is no longer in the question bank.
  static QuizAnswer? fromJson(Map<String, dynamic> json) {
    final question = QuestionBank.getById(json['questionId'] as String);
    if (question == null) return null;
    return QuizAnswer(
      question: question,
      response: LikertResponse.values.byName(json['response'] as String),
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      evidenceContributed: (json['evidence'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(ScreeningDomain.values.byName(k), (v as num).toDouble()),
      ),
    );
  }

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
