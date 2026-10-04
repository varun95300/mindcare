import '../models/quiz_question.dart';

/// Custom mental-health keyword lexicon that maps specific words and
/// phrases to screening domains and provides extra severity weighting.
///
/// This supplements the general AFINN sentiment lexicon with
/// domain-specific clinical vocabulary.
class MentalHealthLexicon {
  /// Words that suggest a specific screening domain.
  /// Each word maps to { domain: ScreeningDomain, weight: double }.
  static const Map<String, _DomainHint> domainKeywords = {
    // === Anxiety domain ===
    'anxious': _DomainHint(ScreeningDomain.anxiety, 1.5),
    'anxiety': _DomainHint(ScreeningDomain.anxiety, 1.5),
    'worry': _DomainHint(ScreeningDomain.anxiety, 1.2),
    'worried': _DomainHint(ScreeningDomain.anxiety, 1.2),
    'worrying': _DomainHint(ScreeningDomain.anxiety, 1.2),
    'worries': _DomainHint(ScreeningDomain.anxiety, 1.2),
    'panic': _DomainHint(ScreeningDomain.anxiety, 2.0),
    'panicking': _DomainHint(ScreeningDomain.anxiety, 2.0),
    'panicked': _DomainHint(ScreeningDomain.anxiety, 2.0),
    'restless': _DomainHint(ScreeningDomain.anxiety, 1.2),
    'restlessness': _DomainHint(ScreeningDomain.anxiety, 1.2),
    'nervous': _DomainHint(ScreeningDomain.anxiety, 1.2),
    'nervousness': _DomainHint(ScreeningDomain.anxiety, 1.2),
    'fear': _DomainHint(ScreeningDomain.anxiety, 1.5),
    'fearful': _DomainHint(ScreeningDomain.anxiety, 1.5),
    'scared': _DomainHint(ScreeningDomain.anxiety, 1.2),
    'dread': _DomainHint(ScreeningDomain.anxiety, 1.5),
    'overthinking': _DomainHint(ScreeningDomain.anxiety, 1.5),
    'overthink': _DomainHint(ScreeningDomain.anxiety, 1.5),
    'racing': _DomainHint(ScreeningDomain.anxiety, 1.0),
    'palpitations': _DomainHint(ScreeningDomain.anxiety, 1.5),
    'sweating': _DomainHint(ScreeningDomain.anxiety, 1.0),
    'trembling': _DomainHint(ScreeningDomain.anxiety, 1.2),
    'shaking': _DomainHint(ScreeningDomain.anxiety, 1.0),
    'uneasy': _DomainHint(ScreeningDomain.anxiety, 1.0),
    'tense': _DomainHint(ScreeningDomain.anxiety, 1.0),
    'phobia': _DomainHint(ScreeningDomain.anxiety, 1.5),

    // === Depression domain ===
    'depressed': _DomainHint(ScreeningDomain.depression, 2.0),
    'depression': _DomainHint(ScreeningDomain.depression, 2.0),
    'hopeless': _DomainHint(ScreeningDomain.depression, 2.0),
    'hopelessness': _DomainHint(ScreeningDomain.depression, 2.0),
    'worthless': _DomainHint(ScreeningDomain.depression, 2.0),
    'worthlessness': _DomainHint(ScreeningDomain.depression, 2.0),
    'empty': _DomainHint(ScreeningDomain.depression, 1.5),
    'emptiness': _DomainHint(ScreeningDomain.depression, 1.5),
    'numb': _DomainHint(ScreeningDomain.depression, 1.5),
    'numbness': _DomainHint(ScreeningDomain.depression, 1.5),
    'unmotivated': _DomainHint(ScreeningDomain.depression, 1.5),
    'motivation': _DomainHint(ScreeningDomain.depression, 0.5),
    'meaningless': _DomainHint(ScreeningDomain.depression, 1.8),
    'pointless': _DomainHint(ScreeningDomain.depression, 1.8),
    'useless': _DomainHint(ScreeningDomain.depression, 1.5),
    'cry': _DomainHint(ScreeningDomain.depression, 1.2),
    'crying': _DomainHint(ScreeningDomain.depression, 1.2),
    'cried': _DomainHint(ScreeningDomain.depression, 1.2),
    'tears': _DomainHint(ScreeningDomain.depression, 1.0),
    'sad': _DomainHint(ScreeningDomain.depression, 1.2),
    'sadness': _DomainHint(ScreeningDomain.depression, 1.2),
    'unhappy': _DomainHint(ScreeningDomain.depression, 1.2),
    'miserable': _DomainHint(ScreeningDomain.depression, 1.8),
    'gloomy': _DomainHint(ScreeningDomain.depression, 1.2),
    'exhausted': _DomainHint(ScreeningDomain.depression, 1.2),
    'fatigue': _DomainHint(ScreeningDomain.depression, 1.2),
    'fatigued': _DomainHint(ScreeningDomain.depression, 1.2),
    'tired': _DomainHint(ScreeningDomain.depression, 1.0),
    'sluggish': _DomainHint(ScreeningDomain.depression, 1.0),
    'lethargic': _DomainHint(ScreeningDomain.depression, 1.2),
    'apathetic': _DomainHint(ScreeningDomain.depression, 1.5),
    'apathy': _DomainHint(ScreeningDomain.depression, 1.5),
    'suicidal': _DomainHint(ScreeningDomain.depression, 3.0),
    'suicide': _DomainHint(ScreeningDomain.depression, 3.0),
    'selfharm': _DomainHint(ScreeningDomain.depression, 3.0),

    // === Stress domain ===
    'stress': _DomainHint(ScreeningDomain.stress, 1.5),
    'stressed': _DomainHint(ScreeningDomain.stress, 1.5),
    'stressful': _DomainHint(ScreeningDomain.stress, 1.5),
    'stressing': _DomainHint(ScreeningDomain.stress, 1.5),
    'overwhelmed': _DomainHint(ScreeningDomain.stress, 1.8),
    'overwhelming': _DomainHint(ScreeningDomain.stress, 1.8),
    'overloaded': _DomainHint(ScreeningDomain.stress, 1.5),
    'overload': _DomainHint(ScreeningDomain.stress, 1.5),
    'burnout': _DomainHint(ScreeningDomain.stress, 2.0),
    'burnt': _DomainHint(ScreeningDomain.stress, 1.2),
    'burned': _DomainHint(ScreeningDomain.stress, 1.2),
    'pressure': _DomainHint(ScreeningDomain.stress, 1.5),
    'pressured': _DomainHint(ScreeningDomain.stress, 1.5),
    'deadline': _DomainHint(ScreeningDomain.stress, 1.2),
    'deadlines': _DomainHint(ScreeningDomain.stress, 1.2),
    'workload': _DomainHint(ScreeningDomain.stress, 1.5),
    'overwork': _DomainHint(ScreeningDomain.stress, 1.5),
    'overworked': _DomainHint(ScreeningDomain.stress, 1.5),
    'hectic': _DomainHint(ScreeningDomain.stress, 1.2),
    'chaos': _DomainHint(ScreeningDomain.stress, 1.2),
    'chaotic': _DomainHint(ScreeningDomain.stress, 1.2),
    'rush': _DomainHint(ScreeningDomain.stress, 0.8),
    'rushed': _DomainHint(ScreeningDomain.stress, 1.0),
    'exam': _DomainHint(ScreeningDomain.stress, 1.0),
    'exams': _DomainHint(ScreeningDomain.stress, 1.0),
    'assignment': _DomainHint(ScreeningDomain.stress, 0.8),
    'assignments': _DomainHint(ScreeningDomain.stress, 0.8),
    'insomnia': _DomainHint(ScreeningDomain.stress, 1.5),
    'sleepless': _DomainHint(ScreeningDomain.stress, 1.2),
    'sleep': _DomainHint(ScreeningDomain.stress, 0.5),

    // === Interpersonal / Trauma domain ===
    'lonely': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'loneliness': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'alone': _DomainHint(ScreeningDomain.interpersonal, 1.2),
    'isolated': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'isolation': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'withdrawn': _DomainHint(ScreeningDomain.interpersonal, 1.2),
    'withdraw': _DomainHint(ScreeningDomain.interpersonal, 1.2),
    'abandoned': _DomainHint(ScreeningDomain.interpersonal, 1.8),
    'abandonment': _DomainHint(ScreeningDomain.interpersonal, 1.8),
    'betrayed': _DomainHint(ScreeningDomain.interpersonal, 2.0),
    'betrayal': _DomainHint(ScreeningDomain.interpersonal, 2.0),
    'rejected': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'rejection': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'neglected': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'neglect': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'bullied': _DomainHint(ScreeningDomain.interpersonal, 2.0),
    'bullying': _DomainHint(ScreeningDomain.interpersonal, 2.0),
    'bully': _DomainHint(ScreeningDomain.interpersonal, 2.0),
    'abused': _DomainHint(ScreeningDomain.interpersonal, 2.5),
    'abuse': _DomainHint(ScreeningDomain.interpersonal, 2.5),
    'abusive': _DomainHint(ScreeningDomain.interpersonal, 2.5),
    'trauma': _DomainHint(ScreeningDomain.interpersonal, 2.5),
    'traumatic': _DomainHint(ScreeningDomain.interpersonal, 2.5),
    'traumatized': _DomainHint(ScreeningDomain.interpersonal, 2.5),
    'trust': _DomainHint(ScreeningDomain.interpersonal, 0.8),
    'distrust': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'conflict': _DomainHint(ScreeningDomain.interpersonal, 1.2),
    'conflicts': _DomainHint(ScreeningDomain.interpersonal, 1.2),
    'fight': _DomainHint(ScreeningDomain.interpersonal, 1.0),
    'fighting': _DomainHint(ScreeningDomain.interpersonal, 1.0),
    'breakup': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'divorce': _DomainHint(ScreeningDomain.interpersonal, 1.5),
    'toxic': _DomainHint(ScreeningDomain.interpersonal, 1.8),
    'manipulate': _DomainHint(ScreeningDomain.interpersonal, 1.8),
    'manipulated': _DomainHint(ScreeningDomain.interpersonal, 1.8),
    'gaslighting': _DomainHint(ScreeningDomain.interpersonal, 2.0),
    'relationship': _DomainHint(ScreeningDomain.interpersonal, 0.5),
    'family': _DomainHint(ScreeningDomain.interpersonal, 0.3),
    'parents': _DomainHint(ScreeningDomain.interpersonal, 0.3),
  };

  /// Words that negate the meaning of the following word.
  static const Set<String> negators = {
    'not', "n't", 'no', 'never', 'neither', 'nobody', 'nothing',
    'nowhere', 'nor', 'cannot', "can't", "don't", "doesn't", "didn't",
    "won't", "wouldn't", "shouldn't", "couldn't", "isn't", "aren't",
    "wasn't", "weren't", "hasn't", "haven't", "hadn't", 'hardly',
    'barely', 'scarcely', 'seldom', 'rarely',
  };

  /// Words that intensify the sentiment of the following word.
  static const Map<String, double> intensifiers = {
    'very': 1.5,
    'really': 1.5,
    'extremely': 2.0,
    'incredibly': 2.0,
    'absolutely': 2.0,
    'completely': 1.8,
    'totally': 1.8,
    'so': 1.3,
    'super': 1.5,
    'deeply': 1.5,
    'highly': 1.5,
    'terribly': 1.5,
    'awfully': 1.5,
    'quite': 1.2,
    'pretty': 1.2,
    'fairly': 1.1,
    'somewhat': 0.8,
    'slightly': 0.6,
    'a bit': 0.7,
    'a little': 0.7,
    'kind of': 0.8,
    'sort of': 0.8,
    'much': 1.3,
    'too': 1.3,
    'most': 1.5,
    'especially': 1.5,
    'particularly': 1.3,
    'constantly': 1.5,
    'always': 1.5,
    'every': 1.3,
    'everyday': 1.3,
  };

  /// Affirmation phrases that indicate the user is confirming the question.
  /// These push severity up regardless of general sentiment.
  static const Set<String> affirmationPhrases = {
    'yes', 'yeah', 'yep', 'yup', 'ya', 'ye',
    'definitely', 'absolutely', 'for sure', 'of course',
    'all the time', 'every day', 'everyday', 'constantly',
    'always', 'often', 'frequently', 'usually',
    'a lot', 'too much', 'so much',
    'i do', 'i have', 'i am', "i've been",
    'true', 'exactly', 'right',
  };

  /// Denial phrases that indicate the user is denying the question.
  /// These push severity down.
  static const Set<String> denialPhrases = {
    'no', 'nope', 'nah', 'not really', 'not at all',
    'never', 'rarely', 'hardly ever', 'almost never',
    'i dont', "i don't", "i haven't", 'i have not',
    "i'm not", 'im not', "i'm fine", 'im fine',
    "i'm good", 'im good', "i'm okay", 'im okay',
    'not much', 'not often',
  };
}

/// A hint about which screening domain a keyword relates to.
class _DomainHint {
  final ScreeningDomain domain;
  final double weight;
  const _DomainHint(this.domain, this.weight);
}
