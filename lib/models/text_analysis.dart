import 'quiz_question.dart';
import 'sentiment_result.dart';

/// Emotions the on-device emotion analyzer can recognise.
enum Emotion {
  sadness,
  fear,
  anger,
  shame,
  loneliness,
  hopelessness,
  exhaustion,
  overwhelm,
  joy,
  calm;

  String get label {
    switch (this) {
      case Emotion.sadness:
        return 'Sadness';
      case Emotion.fear:
        return 'Fear / Anxiety';
      case Emotion.anger:
        return 'Anger / Frustration';
      case Emotion.shame:
        return 'Guilt / Shame';
      case Emotion.loneliness:
        return 'Loneliness';
      case Emotion.hopelessness:
        return 'Hopelessness';
      case Emotion.exhaustion:
        return 'Exhaustion';
      case Emotion.overwhelm:
        return 'Overwhelm';
      case Emotion.joy:
        return 'Joy';
      case Emotion.calm:
        return 'Calm';
    }
  }

  /// Positive emotions do not point towards a concern domain.
  bool get isPositive => this == Emotion.joy || this == Emotion.calm;

  /// How strongly this emotion points towards each screening domain.
  Map<ScreeningDomain, double> get domainAffinity {
    switch (this) {
      case Emotion.sadness:
        return {ScreeningDomain.depression: 1.0};
      case Emotion.fear:
        return {ScreeningDomain.anxiety: 1.0};
      case Emotion.anger:
        return {
          ScreeningDomain.interpersonal: 0.6,
          ScreeningDomain.stress: 0.5,
        };
      case Emotion.shame:
        return {
          ScreeningDomain.depression: 0.7,
          ScreeningDomain.interpersonal: 0.3,
        };
      case Emotion.loneliness:
        return {
          ScreeningDomain.interpersonal: 1.0,
          ScreeningDomain.depression: 0.3,
        };
      case Emotion.hopelessness:
        return {ScreeningDomain.depression: 1.0};
      case Emotion.exhaustion:
        return {
          ScreeningDomain.stress: 0.7,
          ScreeningDomain.depression: 0.5,
        };
      case Emotion.overwhelm:
        return {
          ScreeningDomain.stress: 1.0,
          ScreeningDomain.anxiety: 0.3,
        };
      case Emotion.joy:
      case Emotion.calm:
        return const {};
    }
  }
}

/// Output of the emotion analyzer for one user message.
class EmotionResult {
  /// Strength (0+) of every detected emotion. Absent emotions are omitted.
  final Map<Emotion, double> scores;

  const EmotionResult({this.scores = const {}});

  bool get isEmpty => scores.isEmpty;

  List<MapEntry<Emotion, double>> get ranked {
    final entries = scores.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Emotion? get primary => isEmpty ? null : ranked.first.key;

  Emotion? get secondary => scores.length < 2 ? null : ranked[1].key;

  /// Overall emotional intensity from 0 (flat) to 1 (very intense).
  double get intensity {
    if (isEmpty) return 0;
    return (ranked.first.value / 4.0).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() => {
        'primary': primary?.name,
        'secondary': secondary?.name,
        'intensity': intensity,
        'scores': scores.map((k, v) => MapEntry(k.name, v)),
      };
}

/// How much risk a message (or the whole conversation) indicates.
enum RiskLevel {
  none,
  low,
  moderate,
  high,
  critical;

  String get label {
    switch (this) {
      case RiskLevel.none:
        return 'None detected';
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.moderate:
        return 'Moderate';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.critical:
        return 'Critical';
    }
  }

  /// True when the app should show crisis resources straight away.
  bool get needsSafetyResponse => index >= RiskLevel.high.index;

  static RiskLevel fromName(String? name) {
    for (final level in RiskLevel.values) {
      if (level.name == name) return level;
    }
    return RiskLevel.none;
  }
}

/// Output of the risk detector for one user message.
class RiskResult {
  final RiskLevel level;

  /// 0–10 score behind the level.
  final double score;

  /// The phrases / signals that triggered the level (for the clinician).
  final List<String> flags;

  const RiskResult({
    this.level = RiskLevel.none,
    this.score = 0,
    this.flags = const [],
  });

  Map<String, dynamic> toMap() => {
        'level': level.name,
        'score': score,
        'flags': flags,
      };
}

/// Combined result of the whole text pipeline for one user message:
/// sentiment → emotion → keywords/context → risk → dominant concern.
class TextAnalysis {
  final SentimentResult sentiment;
  final EmotionResult emotion;
  final RiskResult risk;

  /// How strongly this message points to each screening domain.
  final Map<ScreeningDomain, double> concernScores;

  /// The domain this message most points to (null if no clear signal).
  final ScreeningDomain? dominantConcern;

  /// 0–1: how clear the dominant concern is versus the others.
  final double concernConfidence;

  /// Final 0–3 severity fed to the adaptive engine (sentiment severity,
  /// raised when emotion intensity or risk is high).
  final int severityScore;

  const TextAnalysis({
    required this.sentiment,
    required this.emotion,
    required this.risk,
    required this.concernScores,
    required this.dominantConcern,
    required this.concernConfidence,
    required this.severityScore,
  });

  Map<String, dynamic> toMap() => {
        'sentiment': sentiment.toMap(),
        'emotion': emotion.toMap(),
        'risk': risk.toMap(),
        'concernScores': concernScores.map((k, v) => MapEntry(k.name, v)),
        'dominantConcern': dominantConcern?.name,
        'concernConfidence': concernConfidence,
        'severityScore': severityScore,
      };
}
