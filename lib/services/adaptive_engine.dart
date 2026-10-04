import '../models/quiz_question.dart';
import '../models/quiz_answer.dart';
import '../models/domain_evidence.dart';
import '../models/text_analysis.dart';
import '../data/question_bank.dart';
import 'risk_detector.dart';

/// The adaptive quiz engine — selects the next question based on
/// accumulated evidence from previous answers.
///
/// Algorithm:
/// Phase 1: Ask broad screening openers (Q1, then probe the indicated area)
/// Phase 2: Focus exploration on domains with strongest/most uncertain evidence
/// Phase 3: Confirm the leading domain and check the secondary
///
/// The engine never repeats a question, prioritizes uncertain areas,
/// and can terminate early when a clear profile emerges.
///
/// Hybrid mode: when the chatbot feeds in [TextAnalysis] signals (via
/// [recordSignals]) the engine blends them with the rule-based phases:
///   1. a moderate-or-higher risk signal asks the hopelessness check (Q9)
///   2. otherwise the dominant concern from the user's own words picks the
///      next domain to probe
///   3. otherwise the original evidence-based phase rules apply
class AdaptiveEngine {
  final DomainEvidence evidence = DomainEvidence();
  final List<QuizAnswer> answers = [];
  final Set<String> _askedIds = {};

  /// Decayed running total of concern signals from the user's free text.
  final Map<ScreeningDomain, double> concernSignals = {
    for (final d in ScreeningDomain.values) d: 0.0,
  };

  /// Highest-risk reading seen in the whole conversation.
  RiskResult peakRisk = const RiskResult();

  /// Running total of each emotion expressed across the conversation.
  final Map<Emotion, double> emotionTotals = {};

  /// Why each question was chosen, in order (for the clinician's trace).
  final List<String> selectionReasons = [];

  static const double _signalThreshold = 1.0;
  static const double _signalDecay = 0.6;

  static const int minQuestions = 7;
  static const int maxQuestions = 12;
  static const double certaintyThreshold = 0.15; // gap needed to be "certain"

  /// Whether the quiz is complete.
  bool get isComplete {
    if (answers.length >= maxQuestions) return true;
    if (answers.length >= minQuestions && evidence.certaintyGap >= certaintyThreshold) {
      return true;
    }
    return false;
  }

  /// Current quiz progress as a fraction (0.0 to 1.0).
  double get progress {
    // Estimate based on expected ~9 questions average
    return (answers.length / 9.0).clamp(0.0, 0.95);
  }

  /// The domain the user's own words point to most strongly (or null).
  ScreeningDomain? get dominantConcern {
    final ranked = concernSignals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.first.value < _signalThreshold) return null;
    return ranked.first.key;
  }

  /// Feed the analysis of a free-text reply into the hybrid selector.
  void recordSignals(TextAnalysis analysis) {
    for (final d in ScreeningDomain.values) {
      concernSignals[d] = concernSignals[d]! * _signalDecay +
          (analysis.concernScores[d] ?? 0.0);
    }
    peakRisk = RiskDetector.peak(peakRisk, analysis.risk);
    analysis.emotion.scores.forEach((emotion, strength) {
      emotionTotals[emotion] = (emotionTotals[emotion] ?? 0) + strength;
    });
  }

  /// Select the next question based on current evidence.
  QuizQuestion? selectNextQuestion() {
    if (isComplete) return null;

    final asked = answers.length;

    // Phase 1: Broad screening (first 2-3 questions)
    if (asked == 0) {
      selectionReasons.add('Broad opener to gauge general distress.');
      return _getQuestion('Q1'); // Always start with the broad opener
    }

    // Hybrid: let the user's own words steer the next question.
    final hybrid = _selectFromSignals();
    if (hybrid != null) return hybrid;

    final question = _selectByRules(asked);
    if (question != null) {
      selectionReasons.add(
        'Evidence-based follow-up (phase ${question.phase}) to clarify the '
        'current profile.',
      );
    }
    return question;
  }

  /// Original rule-based phase selection.
  QuizQuestion? _selectByRules(int asked) {
    if (asked == 1) {
      return _selectPhase1FollowUp();
    }

    if (asked == 2) {
      return _selectSecondProbe();
    }

    // Phase 2: Focused exploration (questions 3-8)
    if (asked < 8) {
      return _selectFocusedQuestion();
    }

    // Phase 3: Confirmation (questions 8+)
    return _selectConfirmationQuestion();
  }

  /// Record an answer and update evidence.
  Map<ScreeningDomain, double> recordAnswer(
      QuizQuestion question, LikertResponse response) {
    final contributions = <ScreeningDomain, double>{};

    // Calculate primary domain contribution
    final primaryAmount = response.value * question.primaryWeight;
    final primaryMax = 4.0 * question.primaryWeight; // max possible (Almost Always)
    evidence.addEvidence(question.primaryDomain, primaryAmount, primaryMax);
    contributions[question.primaryDomain] = primaryAmount;

    // Calculate secondary domain contribution (if applicable)
    if (question.secondaryDomain != null) {
      final secondaryAmount = response.value * question.secondaryWeight;
      final secondaryMax = 4.0 * question.secondaryWeight;
      evidence.addEvidence(question.secondaryDomain!, secondaryAmount, secondaryMax);
      contributions[question.secondaryDomain!] = secondaryAmount;
    }

    evidence.questionsAnswered++;
    _askedIds.add(question.id);

    final answer = QuizAnswer(
      question: question,
      response: response,
      evidenceContributed: contributions,
    );
    answers.add(answer);

    return contributions;
  }

  // ===== Private selection methods =====

  /// Signal-driven selection (risk first, then dominant concern).
  QuizQuestion? _selectFromSignals() {
    // Safety first: any real risk signal gets the hopelessness check.
    if (peakRisk.level.index >= RiskLevel.moderate.index &&
        !_askedIds.contains('Q9')) {
      selectionReasons.add(
        'Risk signal (${peakRisk.level.label}) detected in the words used — '
        'checking for hopelessness.',
      );
      return _getQuestion('Q9');
    }

    final concern = dominantConcern;
    if (concern == null) return null;

    // Avoid tunnelling: after two questions in a row on the same domain,
    // hand back to the evidence-based rules so other domains get probed.
    if (answers.length >= 2) {
      final lastTwo = answers.sublist(answers.length - 2);
      if (lastTwo.every((a) => a.question.primaryDomain == concern)) {
        return null;
      }
    }

    for (final phase in [1, 2, 3]) {
      final question = _findUnaskedForDomain(concern, phase: phase);
      if (question != null) {
        selectionReasons.add(
          'The words used point to ${concern.label.toLowerCase()} — '
          'exploring that area next.',
        );
        return question;
      }
    }
    return null;
  }

  /// After Q1 (broad opener), pick a follow-up based on the initial response.
  QuizQuestion? _selectPhase1FollowUp() {
    final q1Answer = answers.first;
    final q1Score = q1Answer.response.value;

    if (q1Score >= 3) {
      // High distress → probe anxiety (worry) first
      return _getQuestion('Q2');
    } else if (q1Score >= 2) {
      // Moderate → probe depression (loss of interest)
      return _getQuestion('Q3');
    } else {
      // Low → still ask anxiety probe to gather evidence
      return _getQuestion('Q2');
    }
  }

  /// Third question — probe the area NOT yet covered.
  QuizQuestion? _selectSecondProbe() {
    if (!_askedIds.contains('Q3')) return _getQuestion('Q3');
    if (!_askedIds.contains('Q2')) return _getQuestion('Q2');
    // Both asked, go to focused
    return _selectFocusedQuestion();
  }

  /// Phase 2: Select a focused question for the most relevant domain.
  QuizQuestion? _selectFocusedQuestion() {
    final sorted = evidence.sortedScores;

    // Strategy: Ask about the leading domain to confirm, OR ask about
    // uncertain domains (where scores are close) to differentiate.
    final uncertainDomains = evidence.uncertainDomains;

    // If two domains are close, ask a differentiating question
    if (uncertainDomains.length >= 2) {
      // Find a question that targets one of the uncertain domains
      // but hasn't been asked yet
      for (final domain in uncertainDomains) {
        final question = _findUnaskedForDomain(domain, phase: 2);
        if (question != null) return question;
      }
    }

    // Otherwise, ask about the leading domain to confirm it
    for (final entry in sorted) {
      final question = _findUnaskedForDomain(entry.key, phase: 2);
      if (question != null) return question;
    }

    // Fallback: any unasked phase 2 question
    return _findAnyUnasked(phase: 2) ?? _findAnyUnasked(phase: 3);
  }

  /// Phase 3: Confirmation — confirm the leader and check runner-up.
  QuizQuestion? _selectConfirmationQuestion() {
    final sorted = evidence.sortedScores;

    // Try a phase 3 question first
    final phase3 = _findAnyUnasked(phase: 3);
    if (phase3 != null) return phase3;

    // Then try phase 2 for the second-highest domain
    if (sorted.length >= 2) {
      final secondDomain = sorted[1].key;
      final question = _findUnaskedForDomain(secondDomain, phase: 2);
      if (question != null) return question;
    }

    // Any remaining unasked question
    for (final q in QuestionBank.allQuestions) {
      if (!_askedIds.contains(q.id)) return q;
    }

    return null; // All questions asked
  }

  /// Find an unasked question for a specific domain and phase.
  QuizQuestion? _findUnaskedForDomain(ScreeningDomain domain, {int? phase}) {
    for (final q in QuestionBank.allQuestions) {
      if (_askedIds.contains(q.id)) continue;
      if (q.primaryDomain != domain) continue;
      if (phase != null && q.phase != phase) continue;
      return q;
    }
    return null;
  }

  /// Find any unasked question in a specific phase.
  QuizQuestion? _findAnyUnasked({int? phase}) {
    for (final q in QuestionBank.allQuestions) {
      if (_askedIds.contains(q.id)) continue;
      if (phase != null && q.phase != phase) continue;
      return q;
    }
    return null;
  }

  /// Get a specific question by ID (if not already asked).
  QuizQuestion? _getQuestion(String id) {
    if (_askedIds.contains(id)) return null;
    return QuestionBank.getById(id);
  }
}
