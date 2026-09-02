import '../models/quiz_question.dart';
import '../models/quiz_answer.dart';
import '../models/domain_evidence.dart';
import '../data/question_bank.dart';

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
class AdaptiveEngine {
  final DomainEvidence evidence = DomainEvidence();
  final List<QuizAnswer> answers = [];
  final Set<String> _askedIds = {};

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

  /// Select the next question based on current evidence.
  QuizQuestion? selectNextQuestion() {
    if (isComplete) return null;

    final asked = answers.length;

    // Phase 1: Broad screening (first 2-3 questions)
    if (asked == 0) {
      return _getQuestion('Q1'); // Always start with the broad opener
    }

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
