import 'quiz_question.dart';
import 'quiz_answer.dart';
import 'text_analysis.dart';

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

  /// Highest risk reading seen in the user's free-text replies, and the
  /// phrases that triggered it. Shown to the clinician only.
  final RiskLevel peakRiskLevel;
  final List<String> riskFlags;

  /// Total strength of each emotion expressed across the conversation.
  final Map<String, double> emotionSummary;

  /// Why each question was selected (hybrid selector trace).
  final List<String> selectionReasons;

  /// An optional free-text note the patient wrote in their own words,
  /// captured right after the quiz. Only ever shown to the psychologist
  /// they reach out to — never back to the patient.
  String? patientNote;

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
    this.patientNote,
    this.peakRiskLevel = RiskLevel.none,
    this.riskFlags = const [],
    this.emotionSummary = const {},
    this.selectionReasons = const [],
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'primaryDomain': primaryDomain.name,
        'secondaryDomain': secondaryDomain?.name,
        'normalizedScores':
            normalizedScores.map((k, v) => MapEntry(k.name, v)),
        'severityLabels': severityLabels.map((k, v) => MapEntry(k.name, v)),
        'answers': answers.map((a) => a.toJson()).toList(),
        'keyObservations': keyObservations,
        'methodologyExplanation': methodologyExplanation,
        'disclaimer': disclaimer,
        'recommendation': recommendation,
        'completedAt': completedAt.millisecondsSinceEpoch,
        'patientNote': patientNote,
        'peakRiskLevel': peakRiskLevel.name,
        'riskFlags': riskFlags,
        'emotionSummary': emotionSummary,
        'selectionReasons': selectionReasons,
      };

  factory ScreeningResult.fromJson(Map<String, dynamic> json) {
    ScreeningDomain domain(String name) => ScreeningDomain.values.byName(name);
    return ScreeningResult(
      primaryDomain: domain(json['primaryDomain'] as String),
      secondaryDomain: json['secondaryDomain'] == null
          ? null
          : domain(json['secondaryDomain'] as String),
      normalizedScores:
          (json['normalizedScores'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(domain(k), (v as num).toDouble()),
      ),
      severityLabels: (json['severityLabels'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(domain(k), v as String)),
      answers: (json['answers'] as List)
          .map((a) => QuizAnswer.fromJson(a as Map<String, dynamic>))
          .whereType<QuizAnswer>()
          .toList(),
      keyObservations: List<String>.from(json['keyObservations'] as List),
      methodologyExplanation: json['methodologyExplanation'] as String,
      disclaimer: json['disclaimer'] as String,
      recommendation: json['recommendation'] as String,
      completedAt:
          DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int),
      patientNote: json['patientNote'] as String?,
      peakRiskLevel: RiskLevel.fromName(json['peakRiskLevel'] as String?),
      riskFlags: List<String>.from(json['riskFlags'] as List? ?? const []),
      emotionSummary:
          (json['emotionSummary'] as Map<String, dynamic>? ?? const {})
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
      selectionReasons:
          List<String>.from(json['selectionReasons'] as List? ?? const []),
    );
  }

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
