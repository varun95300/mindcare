import '../models/quiz_question.dart';

/// The complete question bank for the adaptive screening quiz.
///
/// Questions are organized by phase:
/// - Phase 1: Broad screening openers
/// - Phase 2: Focused exploration per domain
/// - Phase 3: Confirmation/severity probes
class QuestionBank {
  static const List<QuizQuestion> allQuestions = [
    // ========== PHASE 1: BROAD SCREENING ==========

    QuizQuestion(
      id: 'Q1',
      text:
          'Have you been feeling more overwhelmed or emotionally strained than usual?',
      primaryDomain: ScreeningDomain.stress,
      secondaryDomain: ScreeningDomain.anxiety,
      primaryWeight: 0.8,
      secondaryWeight: 0.5,
      purpose: 'Broad opener — detects general distress level',
      phase: 1,
    ),
    QuizQuestion(
      id: 'Q2',
      text:
          'Do you find yourself worrying about things more than you feel is necessary?',
      primaryDomain: ScreeningDomain.anxiety,
      secondaryDomain: ScreeningDomain.stress,
      primaryWeight: 1.0,
      secondaryWeight: 0.3,
      purpose: 'Early anxiety probe — distinguishes worry from general stress',
      phase: 1,
    ),
    QuizQuestion(
      id: 'Q3',
      text:
          'Have you noticed a loss of interest or enjoyment in activities you usually like?',
      primaryDomain: ScreeningDomain.depression,
      purpose:
          'Early depression probe — anhedonia is a key depression indicator',
      phase: 1,
    ),

    // ========== PHASE 2: FOCUSED EXPLORATION ==========

    // Anxiety-focused
    QuizQuestion(
      id: 'Q4',
      text: 'Do you often feel restless, on edge, or unable to sit still?',
      primaryDomain: ScreeningDomain.anxiety,
      secondaryDomain: ScreeningDomain.stress,
      primaryWeight: 1.0,
      secondaryWeight: 0.4,
      purpose: 'Somatic anxiety — restlessness and agitation',
      phase: 2,
    ),
    QuizQuestion(
      id: 'Q5',
      text:
          'Have you experienced sudden, intense feelings of panic or fear that come on quickly?',
      primaryDomain: ScreeningDomain.anxiety,
      primaryWeight: 1.0,
      purpose: 'Panic indicator — distinguishes anxiety severity',
      phase: 2,
    ),
    QuizQuestion(
      id: 'Q8',
      text:
          'Do you experience physical symptoms like a racing heart, sweating, or trembling during stressful moments?',
      primaryDomain: ScreeningDomain.anxiety,
      secondaryDomain: ScreeningDomain.stress,
      primaryWeight: 1.0,
      secondaryWeight: 0.3,
      purpose: 'Physical manifestation of anxiety vs stress',
      phase: 2,
    ),

    // Depression-focused
    QuizQuestion(
      id: 'Q6',
      text:
          'Have you been feeling unusually tired or lacking energy, even after adequate rest?',
      primaryDomain: ScreeningDomain.depression,
      secondaryDomain: ScreeningDomain.stress,
      primaryWeight: 1.0,
      secondaryWeight: 0.5,
      purpose: 'Fatigue probe — overlaps depression and stress',
      phase: 2,
    ),
    QuizQuestion(
      id: 'Q9',
      text:
          'Have you felt hopeless or like things are unlikely to get better?',
      primaryDomain: ScreeningDomain.depression,
      primaryWeight: 1.0,
      purpose: 'Hopelessness — key depression severity indicator',
      phase: 2,
    ),
    QuizQuestion(
      id: 'Q12',
      text:
          'Do you find it difficult to concentrate, make decisions, or remember things?',
      primaryDomain: ScreeningDomain.depression,
      secondaryDomain: ScreeningDomain.stress,
      primaryWeight: 0.8,
      secondaryWeight: 0.5,
      purpose: 'Cognitive symptoms — shared between depression and stress',
      phase: 2,
    ),

    // Stress-focused
    QuizQuestion(
      id: 'Q7',
      text:
          'Do you find it hard to stop thinking about stressful tasks, deadlines, or responsibilities?',
      primaryDomain: ScreeningDomain.stress,
      secondaryDomain: ScreeningDomain.anxiety,
      primaryWeight: 1.0,
      secondaryWeight: 0.4,
      purpose: 'Rumination on stressors vs general anxiety',
      phase: 2,
    ),
    QuizQuestion(
      id: 'Q10',
      text:
          'Do you feel you are constantly under pressure with no time to relax or recharge?',
      primaryDomain: ScreeningDomain.stress,
      primaryWeight: 1.0,
      purpose: 'Chronic stress indicator — pressure and overload',
      phase: 2,
    ),

    // Interpersonal-focused
    QuizQuestion(
      id: 'Q11',
      text:
          'Have you been avoiding social situations or pulling away from people close to you?',
      primaryDomain: ScreeningDomain.interpersonal,
      secondaryDomain: ScreeningDomain.depression,
      primaryWeight: 1.0,
      secondaryWeight: 0.4,
      purpose: 'Social withdrawal — overlaps interpersonal and depression',
      phase: 2,
    ),
    QuizQuestion(
      id: 'Q13',
      text:
          'Have you had difficulty trusting others or feeling emotionally safe around people?',
      primaryDomain: ScreeningDomain.interpersonal,
      primaryWeight: 1.0,
      purpose: 'Trust and emotional safety — interpersonal/trauma indicator',
      phase: 2,
    ),
    QuizQuestion(
      id: 'Q14',
      text:
          'Do you often feel that conflicts or relationship difficulties significantly affect your emotional wellbeing?',
      primaryDomain: ScreeningDomain.interpersonal,
      secondaryDomain: ScreeningDomain.stress,
      primaryWeight: 1.0,
      secondaryWeight: 0.3,
      purpose: 'Relationship impact — distinguishes interpersonal from stress',
      phase: 2,
    ),

    // ========== PHASE 3: CONFIRMATION / CROSS-CUTTING ==========

    QuizQuestion(
      id: 'Q15',
      text:
          'Have you had trouble sleeping — either difficulty falling asleep, staying asleep, or sleeping too much?',
      primaryDomain: ScreeningDomain.stress,
      secondaryDomain: ScreeningDomain.depression,
      primaryWeight: 0.6,
      secondaryWeight: 0.6,
      purpose: 'Sleep disruption — cross-cutting symptom for confirmation',
      phase: 3,
    ),
  ];

  /// Phase 1 questions (broad openers).
  static List<QuizQuestion> get phase1Questions =>
      allQuestions.where((q) => q.phase == 1).toList();

  /// Phase 2 questions for a specific domain.
  static List<QuizQuestion> phase2ForDomain(ScreeningDomain domain) =>
      allQuestions
          .where((q) => q.phase == 2 && q.primaryDomain == domain)
          .toList();

  /// Phase 3 confirmation questions.
  static List<QuizQuestion> get phase3Questions =>
      allQuestions.where((q) => q.phase == 3).toList();

  /// Get a question by ID.
  static QuizQuestion? getById(String id) {
    try {
      return allQuestions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }
}
