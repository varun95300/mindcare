/// Represents the four screening domains tracked by MindCare.
enum ScreeningDomain {
  anxiety,
  depression,
  stress,
  interpersonal;

  String get label {
    switch (this) {
      case ScreeningDomain.anxiety:
        return 'Anxiety';
      case ScreeningDomain.depression:
        return 'Depression';
      case ScreeningDomain.stress:
        return 'Stress';
      case ScreeningDomain.interpersonal:
        return 'Interpersonal / Trauma';
    }
  }

  String get description {
    switch (this) {
      case ScreeningDomain.anxiety:
        return 'Worry, nervousness, and apprehension-related indicators';
      case ScreeningDomain.depression:
        return 'Low mood, loss of interest, and motivation-related indicators';
      case ScreeningDomain.stress:
        return 'Feeling overwhelmed, pressure, and exhaustion-related indicators';
      case ScreeningDomain.interpersonal:
        return 'Relationship difficulties, trust, and social withdrawal indicators';
    }
  }
}

/// A single screening question with domain weights.
class QuizQuestion {
  final String id;
  final String text;
  final ScreeningDomain primaryDomain;
  final ScreeningDomain? secondaryDomain;
  final double primaryWeight;
  final double secondaryWeight;
  final String purpose;
  final int phase; // 1 = broad, 2 = focused, 3 = confirmation

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.primaryDomain,
    this.secondaryDomain,
    this.primaryWeight = 1.0,
    this.secondaryWeight = 0.4,
    required this.purpose,
    this.phase = 2,
  });
}

/// Likert scale response options.
enum LikertResponse {
  never(0, 'Never'),
  rarely(1, 'Rarely'),
  sometimes(2, 'Sometimes'),
  often(3, 'Often'),
  almostAlways(4, 'Almost Always');

  final int value;
  final String label;
  const LikertResponse(this.value, this.label);
}
