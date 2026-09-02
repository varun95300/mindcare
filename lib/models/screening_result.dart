import 'quiz_question.dart';
import 'quiz_answer.dart';
import 'domain_evidence.dart';

/// The final screening result with full explanation data.
class ScreeningResult {
  final ScreeningDomain primaryDomain;
  final ScreeningDomain? secondaryDomain;
  final Map<ScreeningDomain, double> normalizedScores;
  final Map<ScreeningDomain, String> severityLabels;
  final List<QuizAnswer> answers;
  final List<String> keyObservations;
  final String methodologyExplanation;
  final String disclaimer;
  final String recommendation;
  final DateTime completedAt;

  ScreeningResult({
    required this.primaryDomain,
    this.secondaryDomain,
    required this.normalizedScores,
    required this.severityLabels,
    required this.answers,
    required this.keyObservations,
    required this.methodologyExplanation,
    required this.disclaimer,
    required this.recommendation,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  /// Number of questions answered.
  int get totalQuestions => answers.length;

  /// The reasoning trace: per-question contribution breakdown.
  List<ReasoningStep> get reasoningTrace {
    return answers.asMap().entries.map((entry) {
      final idx = entry.key;
      final answer = entry.value;
      return ReasoningStep(
        questionNumber: idx + 1,
        questionText: answer.question.text,
        responseLabel: answer.response.label,
        responseValue: answer.response.value,
        evidenceContributed: answer.evidenceContributed,
        primaryDomain: answer.question.primaryDomain,
        secondaryDomain: answer.question.secondaryDomain,
      );
    }).toList();
  }
}

/// A single step in the reasoning trace.
class ReasoningStep {
  final int questionNumber;
  final String questionText;
  final String responseLabel;
  final int responseValue;
  final Map<ScreeningDomain, double> evidenceContributed;
  final ScreeningDomain primaryDomain;
  final ScreeningDomain? secondaryDomain;

  ReasoningStep({
    required this.questionNumber,
    required this.questionText,
    required this.responseLabel,
    required this.responseValue,
    required this.evidenceContributed,
    required this.primaryDomain,
    this.secondaryDomain,
  });

  String get contributionSummary {
    final parts = <String>[];
    evidenceContributed.forEach((domain, value) {
      if (value > 0) {
        parts.add('+${value.toStringAsFixed(1)} ${domain.label}');
      }
    });
    if (parts.isEmpty) return 'Minimal contribution';
    return parts.join(', ');
  }
}
