import '../models/text_analysis.dart';

/// Keyword lexicons for on-device emotion and risk detection.
///
/// Emotion words map to an [Emotion] with a weight (roughly 0.5–2.5).
/// Risk phrases are multi-word, lower-case and use expanded contractions
/// (the tokenizer turns "can't" into "cannot", "don't" into "do not", ...).
class EmotionLexicon {
  const EmotionLexicon._();

  static const Map<String, EmotionHint> words = {
    // === Sadness ===
    'sad': EmotionHint(Emotion.sadness, 1.5),
    'sadness': EmotionHint(Emotion.sadness, 1.5),
    'unhappy': EmotionHint(Emotion.sadness, 1.5),
    'depressed': EmotionHint(Emotion.sadness, 2.0),
    'down': EmotionHint(Emotion.sadness, 1.0),
    'low': EmotionHint(Emotion.sadness, 1.0),
    'blue': EmotionHint(Emotion.sadness, 1.0),
    'miserable': EmotionHint(Emotion.sadness, 2.0),
    'heartbroken': EmotionHint(Emotion.sadness, 2.0),
    'grief': EmotionHint(Emotion.sadness, 1.8),
    'grieving': EmotionHint(Emotion.sadness, 1.8),
    'cry': EmotionHint(Emotion.sadness, 1.3),
    'crying': EmotionHint(Emotion.sadness, 1.5),
    'cried': EmotionHint(Emotion.sadness, 1.3),
    'tears': EmotionHint(Emotion.sadness, 1.2),
    'gloomy': EmotionHint(Emotion.sadness, 1.3),
    'numb': EmotionHint(Emotion.sadness, 1.5),
    'empty': EmotionHint(Emotion.sadness, 1.8),
    'emptiness': EmotionHint(Emotion.sadness, 1.8),
    'upset': EmotionHint(Emotion.sadness, 1.2),
    'hurt': EmotionHint(Emotion.sadness, 1.2),
    'disappointed': EmotionHint(Emotion.sadness, 1.2),

    // === Fear / anxiety ===
    'anxious': EmotionHint(Emotion.fear, 1.8),
    'anxiety': EmotionHint(Emotion.fear, 1.8),
    'worried': EmotionHint(Emotion.fear, 1.5),
    'worry': EmotionHint(Emotion.fear, 1.5),
    'worrying': EmotionHint(Emotion.fear, 1.5),
    'nervous': EmotionHint(Emotion.fear, 1.3),
    'scared': EmotionHint(Emotion.fear, 1.8),
    'afraid': EmotionHint(Emotion.fear, 1.8),
    'terrified': EmotionHint(Emotion.fear, 2.3),
    'fear': EmotionHint(Emotion.fear, 1.8),
    'fearful': EmotionHint(Emotion.fear, 1.8),
    'panic': EmotionHint(Emotion.fear, 2.3),
    'panicking': EmotionHint(Emotion.fear, 2.3),
    'panicked': EmotionHint(Emotion.fear, 2.3),
    'dread': EmotionHint(Emotion.fear, 1.8),
    'uneasy': EmotionHint(Emotion.fear, 1.2),
    'tense': EmotionHint(Emotion.fear, 1.2),
    'restless': EmotionHint(Emotion.fear, 1.2),
    'overthinking': EmotionHint(Emotion.fear, 1.5),
    'racing': EmotionHint(Emotion.fear, 1.0),
    'trembling': EmotionHint(Emotion.fear, 1.3),
    'shaking': EmotionHint(Emotion.fear, 1.0),
    'palpitations': EmotionHint(Emotion.fear, 1.5),

    // === Anger / frustration ===
    'angry': EmotionHint(Emotion.anger, 1.8),
    'anger': EmotionHint(Emotion.anger, 1.8),
    'furious': EmotionHint(Emotion.anger, 2.3),
    'mad': EmotionHint(Emotion.anger, 1.5),
    'irritated': EmotionHint(Emotion.anger, 1.3),
    'irritable': EmotionHint(Emotion.anger, 1.3),
    'annoyed': EmotionHint(Emotion.anger, 1.2),
    'frustrated': EmotionHint(Emotion.anger, 1.5),
    'frustrating': EmotionHint(Emotion.anger, 1.5),
    'resentful': EmotionHint(Emotion.anger, 1.5),
    'resent': EmotionHint(Emotion.anger, 1.5),
    'hate': EmotionHint(Emotion.anger, 1.8),
    'rage': EmotionHint(Emotion.anger, 2.3),
    'snapping': EmotionHint(Emotion.anger, 1.3),
    'betrayed': EmotionHint(Emotion.anger, 1.8),

    // === Guilt / shame ===
    'guilty': EmotionHint(Emotion.shame, 1.8),
    'guilt': EmotionHint(Emotion.shame, 1.8),
    'ashamed': EmotionHint(Emotion.shame, 2.0),
    'shame': EmotionHint(Emotion.shame, 2.0),
    'embarrassed': EmotionHint(Emotion.shame, 1.3),
    'worthless': EmotionHint(Emotion.shame, 2.2),
    'useless': EmotionHint(Emotion.shame, 1.8),
    'failure': EmotionHint(Emotion.shame, 1.8),
    'burden': EmotionHint(Emotion.shame, 2.0),
    'stupid': EmotionHint(Emotion.shame, 1.5),
    'pathetic': EmotionHint(Emotion.shame, 1.8),

    // === Loneliness ===
    'lonely': EmotionHint(Emotion.loneliness, 2.0),
    'loneliness': EmotionHint(Emotion.loneliness, 2.0),
    'alone': EmotionHint(Emotion.loneliness, 1.5),
    'isolated': EmotionHint(Emotion.loneliness, 1.8),
    'isolation': EmotionHint(Emotion.loneliness, 1.8),
    'abandoned': EmotionHint(Emotion.loneliness, 2.0),
    'rejected': EmotionHint(Emotion.loneliness, 1.5),
    'ignored': EmotionHint(Emotion.loneliness, 1.3),
    'neglected': EmotionHint(Emotion.loneliness, 1.5),
    'withdrawn': EmotionHint(Emotion.loneliness, 1.3),
    'unwanted': EmotionHint(Emotion.loneliness, 1.8),

    // === Hopelessness ===
    'hopeless': EmotionHint(Emotion.hopelessness, 2.5),
    'hopelessness': EmotionHint(Emotion.hopelessness, 2.5),
    'pointless': EmotionHint(Emotion.hopelessness, 2.2),
    'meaningless': EmotionHint(Emotion.hopelessness, 2.2),
    'trapped': EmotionHint(Emotion.hopelessness, 2.0),
    'stuck': EmotionHint(Emotion.hopelessness, 1.2),
    'helpless': EmotionHint(Emotion.hopelessness, 2.0),
    'despair': EmotionHint(Emotion.hopelessness, 2.5),
    'doomed': EmotionHint(Emotion.hopelessness, 2.0),

    // === Exhaustion ===
    'tired': EmotionHint(Emotion.exhaustion, 1.3),
    'exhausted': EmotionHint(Emotion.exhaustion, 1.8),
    'drained': EmotionHint(Emotion.exhaustion, 1.8),
    'fatigue': EmotionHint(Emotion.exhaustion, 1.5),
    'fatigued': EmotionHint(Emotion.exhaustion, 1.5),
    'lethargic': EmotionHint(Emotion.exhaustion, 1.5),
    'sluggish': EmotionHint(Emotion.exhaustion, 1.2),
    'burnout': EmotionHint(Emotion.exhaustion, 2.0),
    'burnt': EmotionHint(Emotion.exhaustion, 1.5),
    'insomnia': EmotionHint(Emotion.exhaustion, 1.5),
    'sleepless': EmotionHint(Emotion.exhaustion, 1.3),

    // === Overwhelm ===
    'overwhelmed': EmotionHint(Emotion.overwhelm, 2.0),
    'overwhelming': EmotionHint(Emotion.overwhelm, 1.8),
    'stressed': EmotionHint(Emotion.overwhelm, 1.8),
    'stress': EmotionHint(Emotion.overwhelm, 1.5),
    'stressful': EmotionHint(Emotion.overwhelm, 1.5),
    'pressure': EmotionHint(Emotion.overwhelm, 1.5),
    'pressured': EmotionHint(Emotion.overwhelm, 1.5),
    'overloaded': EmotionHint(Emotion.overwhelm, 1.8),
    'swamped': EmotionHint(Emotion.overwhelm, 1.5),
    'hectic': EmotionHint(Emotion.overwhelm, 1.2),

    // === Positive ===
    'happy': EmotionHint(Emotion.joy, 1.8),
    'joy': EmotionHint(Emotion.joy, 1.8),
    'joyful': EmotionHint(Emotion.joy, 1.8),
    'excited': EmotionHint(Emotion.joy, 1.5),
    'grateful': EmotionHint(Emotion.joy, 1.5),
    'great': EmotionHint(Emotion.joy, 1.2),
    'good': EmotionHint(Emotion.joy, 1.0),
    'wonderful': EmotionHint(Emotion.joy, 1.8),
    'hopeful': EmotionHint(Emotion.joy, 1.5),
    'enjoy': EmotionHint(Emotion.joy, 1.3),
    'enjoying': EmotionHint(Emotion.joy, 1.3),
    'calm': EmotionHint(Emotion.calm, 1.5),
    'relaxed': EmotionHint(Emotion.calm, 1.5),
    'peaceful': EmotionHint(Emotion.calm, 1.5),
    'okay': EmotionHint(Emotion.calm, 0.8),
    'fine': EmotionHint(Emotion.calm, 0.8),
    'content': EmotionHint(Emotion.calm, 1.2),
    'rested': EmotionHint(Emotion.calm, 1.2),
  };

  /// Multi-word emotional expressions that single words would miss.
  static const Map<String, EmotionHint> phrases = {
    'cannot sleep': EmotionHint(Emotion.exhaustion, 1.8),
    'cannot cope': EmotionHint(Emotion.overwhelm, 2.2),
    'cannot handle': EmotionHint(Emotion.overwhelm, 2.0),
    'cannot breathe': EmotionHint(Emotion.fear, 2.3),
    'too much': EmotionHint(Emotion.overwhelm, 1.5),
    'on edge': EmotionHint(Emotion.fear, 1.5),
    'no energy': EmotionHint(Emotion.exhaustion, 1.8),
    'no motivation': EmotionHint(Emotion.sadness, 1.5),
    'no point': EmotionHint(Emotion.hopelessness, 2.2),
    'lost interest': EmotionHint(Emotion.sadness, 1.5),
    'feel nothing': EmotionHint(Emotion.sadness, 1.8),
    'all alone': EmotionHint(Emotion.loneliness, 2.0),
    'no one cares': EmotionHint(Emotion.loneliness, 2.2),
    'nobody cares': EmotionHint(Emotion.loneliness, 2.2),
    'let everyone down': EmotionHint(Emotion.shame, 2.0),
    'my fault': EmotionHint(Emotion.shame, 1.5),
    'give up': EmotionHint(Emotion.hopelessness, 2.0),
    'fed up': EmotionHint(Emotion.anger, 1.5),
    'heart racing': EmotionHint(Emotion.fear, 1.8),
    'panic attack': EmotionHint(Emotion.fear, 2.5),
    'panic attacks': EmotionHint(Emotion.fear, 2.5),
    'burned out': EmotionHint(Emotion.exhaustion, 2.0),
    'burnt out': EmotionHint(Emotion.exhaustion, 2.0),
  };

  /// Risk phrases by severity tier. Matched against the token stream, so
  /// they must be lower-case with expanded contractions.
  static const Map<String, double> criticalRiskPhrases = {
    'kill myself': 10,
    'killing myself': 10,
    'end my life': 10,
    'end it all': 9.5,
    'take my own life': 10,
    'want to die': 9.5,
    'wanna die': 9.5,
    'suicidal': 9.5,
    'suicide': 8.5,
    'commit suicide': 10,
    'suicide plan': 10,
    'better off dead': 9.5,
    'wish i was dead': 9.5,
    'wish i were dead': 9.5,
    'wish i were never born': 9,
    'do not want to live': 9.5,
    'do not want to be alive': 9.5,
  };

  static const Map<String, double> highRiskPhrases = {
    'hurt myself': 8,
    'harm myself': 8,
    'hurting myself': 8,
    'cut myself': 8,
    'cutting myself': 8,
    'self harm': 8,
    'selfharm': 8,
    'self-harm': 8,
    'better off without me': 8,
    'no reason to live': 8.5,
    'nothing to live for': 8.5,
    'cannot go on': 7.5,
    'cannot do this anymore': 7.5,
    'do not want to be here': 7.5,
    'disappear forever': 7.5,
    'make it stop': 7,
    'hits me': 7,
    'beats me': 7,
    'hurts me': 7,
    'abused': 7,
    'abusing me': 7,
    'unsafe at home': 7.5,
    'not safe': 6.5,
  };

  static const Map<String, double> moderateRiskPhrases = {
    'no hope': 5,
    'hopeless': 5,
    'give up': 4.5,
    'giving up': 4.5,
    'cannot take it': 5,
    'cannot take it anymore': 5.5,
    'cannot cope': 4.5,
    'worthless': 4.5,
    'burden': 4.5,
    'no one cares': 4.5,
    'nobody cares': 4.5,
    'panic attack': 4.5,
    'panic attacks': 4.5,
    'stopped eating': 4.5,
    'cannot function': 5,
    'cannot get out of bed': 5,
    'cannot stop crying': 4.5,
    'drinking too much': 5,
    'drinking more': 4.5,
    'using drugs': 5,
    'trapped': 4.5,
  };

  static const Map<String, double> lowRiskPhrases = {
    'cannot sleep': 2,
    'not sleeping': 2,
    'lost interest': 2.5,
    'no motivation': 2.5,
    'no energy': 2,
    'losing weight': 2,
    'withdrawing': 2.5,
    'avoiding people': 2.5,
    'alone': 1.5,
    'lonely': 2,
  };
}

/// An emotion plus how strongly a keyword signals it.
class EmotionHint {
  final Emotion emotion;
  final double weight;
  const EmotionHint(this.emotion, this.weight);
}
