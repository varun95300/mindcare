import '../models/quiz_question.dart';

/// Custom mental-health keyword lexicon that maps specific words and
/// phrases to screening domains and provides extra severity weighting.
///
/// This supplements the general AFINN sentiment lexicon with
/// domain-specific clinical vocabulary.
class MentalHealthLexicon {
  /// Words that suggest a specific screening domain.
  /// Each word maps to { domain: ScreeningDomain, weight: double }.
  static const Map<String, DomainHint> domainKeywords = {
    // === Anxiety domain ===
    'anxious': DomainHint(ScreeningDomain.anxiety, 1.5),
    'anxiety': DomainHint(ScreeningDomain.anxiety, 1.5),
    'worry': DomainHint(ScreeningDomain.anxiety, 1.2),
    'worried': DomainHint(ScreeningDomain.anxiety, 1.2),
    'worrying': DomainHint(ScreeningDomain.anxiety, 1.2),
    'worries': DomainHint(ScreeningDomain.anxiety, 1.2),
    'panic': DomainHint(ScreeningDomain.anxiety, 2.0),
    'panicking': DomainHint(ScreeningDomain.anxiety, 2.0),
    'panicked': DomainHint(ScreeningDomain.anxiety, 2.0),
    'restless': DomainHint(ScreeningDomain.anxiety, 1.2),
    'restlessness': DomainHint(ScreeningDomain.anxiety, 1.2),
    'nervous': DomainHint(ScreeningDomain.anxiety, 1.2),
    'nervousness': DomainHint(ScreeningDomain.anxiety, 1.2),
    'fear': DomainHint(ScreeningDomain.anxiety, 1.5),
    'fearful': DomainHint(ScreeningDomain.anxiety, 1.5),
    'scared': DomainHint(ScreeningDomain.anxiety, 1.2),
    'dread': DomainHint(ScreeningDomain.anxiety, 1.5),
    'overthinking': DomainHint(ScreeningDomain.anxiety, 1.5),
    'overthink': DomainHint(ScreeningDomain.anxiety, 1.5),
    'racing': DomainHint(ScreeningDomain.anxiety, 1.0),
    'palpitations': DomainHint(ScreeningDomain.anxiety, 1.5),
    'sweating': DomainHint(ScreeningDomain.anxiety, 1.0),
    'trembling': DomainHint(ScreeningDomain.anxiety, 1.2),
    'shaking': DomainHint(ScreeningDomain.anxiety, 1.0),
    'uneasy': DomainHint(ScreeningDomain.anxiety, 1.0),
    'tense': DomainHint(ScreeningDomain.anxiety, 1.0),
    'phobia': DomainHint(ScreeningDomain.anxiety, 1.5),

    // === Depression domain ===
    'depressed': DomainHint(ScreeningDomain.depression, 2.0),
    'depression': DomainHint(ScreeningDomain.depression, 2.0),
    'hopeless': DomainHint(ScreeningDomain.depression, 2.0),
    'hopelessness': DomainHint(ScreeningDomain.depression, 2.0),
    'worthless': DomainHint(ScreeningDomain.depression, 2.0),
    'worthlessness': DomainHint(ScreeningDomain.depression, 2.0),
    'empty': DomainHint(ScreeningDomain.depression, 1.5),
    'emptiness': DomainHint(ScreeningDomain.depression, 1.5),
    'numb': DomainHint(ScreeningDomain.depression, 1.5),
    'numbness': DomainHint(ScreeningDomain.depression, 1.5),
    'unmotivated': DomainHint(ScreeningDomain.depression, 1.5),
    'motivation': DomainHint(ScreeningDomain.depression, 0.5),
    'meaningless': DomainHint(ScreeningDomain.depression, 1.8),
    'pointless': DomainHint(ScreeningDomain.depression, 1.8),
    'useless': DomainHint(ScreeningDomain.depression, 1.5),
    'cry': DomainHint(ScreeningDomain.depression, 1.2),
    'crying': DomainHint(ScreeningDomain.depression, 1.2),
    'cried': DomainHint(ScreeningDomain.depression, 1.2),
    'tears': DomainHint(ScreeningDomain.depression, 1.0),
    'sad': DomainHint(ScreeningDomain.depression, 1.2),
    'sadness': DomainHint(ScreeningDomain.depression, 1.2),
    'unhappy': DomainHint(ScreeningDomain.depression, 1.2),
    'miserable': DomainHint(ScreeningDomain.depression, 1.8),
    'gloomy': DomainHint(ScreeningDomain.depression, 1.2),
    'exhausted': DomainHint(ScreeningDomain.depression, 1.2),
    'fatigue': DomainHint(ScreeningDomain.depression, 1.2),
    'fatigued': DomainHint(ScreeningDomain.depression, 1.2),
    'tired': DomainHint(ScreeningDomain.depression, 1.0),
    'sluggish': DomainHint(ScreeningDomain.depression, 1.0),
    'lethargic': DomainHint(ScreeningDomain.depression, 1.2),
    'apathetic': DomainHint(ScreeningDomain.depression, 1.5),
    'apathy': DomainHint(ScreeningDomain.depression, 1.5),
    'suicidal': DomainHint(ScreeningDomain.depression, 3.0),
    'suicide': DomainHint(ScreeningDomain.depression, 3.0),
    'selfharm': DomainHint(ScreeningDomain.depression, 3.0),

    // === Stress domain ===
    'stress': DomainHint(ScreeningDomain.stress, 1.5),
    'stressed': DomainHint(ScreeningDomain.stress, 1.5),
    'stressful': DomainHint(ScreeningDomain.stress, 1.5),
    'stressing': DomainHint(ScreeningDomain.stress, 1.5),
    'overwhelmed': DomainHint(ScreeningDomain.stress, 1.8),
    'overwhelming': DomainHint(ScreeningDomain.stress, 1.8),
    'overloaded': DomainHint(ScreeningDomain.stress, 1.5),
    'overload': DomainHint(ScreeningDomain.stress, 1.5),
    'burnout': DomainHint(ScreeningDomain.stress, 2.0),
    'burnt': DomainHint(ScreeningDomain.stress, 1.2),
    'burned': DomainHint(ScreeningDomain.stress, 1.2),
    'pressure': DomainHint(ScreeningDomain.stress, 1.5),
    'pressured': DomainHint(ScreeningDomain.stress, 1.5),
    'deadline': DomainHint(ScreeningDomain.stress, 1.2),
    'deadlines': DomainHint(ScreeningDomain.stress, 1.2),
    'workload': DomainHint(ScreeningDomain.stress, 1.5),
    'overwork': DomainHint(ScreeningDomain.stress, 1.5),
    'overworked': DomainHint(ScreeningDomain.stress, 1.5),
    'hectic': DomainHint(ScreeningDomain.stress, 1.2),
    'chaos': DomainHint(ScreeningDomain.stress, 1.2),
    'chaotic': DomainHint(ScreeningDomain.stress, 1.2),
    'rush': DomainHint(ScreeningDomain.stress, 0.8),
    'rushed': DomainHint(ScreeningDomain.stress, 1.0),
    'exam': DomainHint(ScreeningDomain.stress, 1.0),
    'exams': DomainHint(ScreeningDomain.stress, 1.0),
    'assignment': DomainHint(ScreeningDomain.stress, 0.8),
    'assignments': DomainHint(ScreeningDomain.stress, 0.8),
    'insomnia': DomainHint(ScreeningDomain.stress, 1.5),
    'sleepless': DomainHint(ScreeningDomain.stress, 1.2),
    'sleep': DomainHint(ScreeningDomain.stress, 0.5),

    // === Interpersonal / Trauma domain ===
    'lonely': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'loneliness': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'alone': DomainHint(ScreeningDomain.interpersonal, 1.2),
    'isolated': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'isolation': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'withdrawn': DomainHint(ScreeningDomain.interpersonal, 1.2),
    'withdraw': DomainHint(ScreeningDomain.interpersonal, 1.2),
    'abandoned': DomainHint(ScreeningDomain.interpersonal, 1.8),
    'abandonment': DomainHint(ScreeningDomain.interpersonal, 1.8),
    'betrayed': DomainHint(ScreeningDomain.interpersonal, 2.0),
    'betrayal': DomainHint(ScreeningDomain.interpersonal, 2.0),
    'rejected': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'rejection': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'neglected': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'neglect': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'bullied': DomainHint(ScreeningDomain.interpersonal, 2.0),
    'bullying': DomainHint(ScreeningDomain.interpersonal, 2.0),
    'bully': DomainHint(ScreeningDomain.interpersonal, 2.0),
    'abused': DomainHint(ScreeningDomain.interpersonal, 2.5),
    'abuse': DomainHint(ScreeningDomain.interpersonal, 2.5),
    'abusive': DomainHint(ScreeningDomain.interpersonal, 2.5),
    'trauma': DomainHint(ScreeningDomain.interpersonal, 2.5),
    'traumatic': DomainHint(ScreeningDomain.interpersonal, 2.5),
    'traumatized': DomainHint(ScreeningDomain.interpersonal, 2.5),
    'trust': DomainHint(ScreeningDomain.interpersonal, 0.8),
    'distrust': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'conflict': DomainHint(ScreeningDomain.interpersonal, 1.2),
    'conflicts': DomainHint(ScreeningDomain.interpersonal, 1.2),
    'fight': DomainHint(ScreeningDomain.interpersonal, 1.0),
    'fighting': DomainHint(ScreeningDomain.interpersonal, 1.0),
    'breakup': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'divorce': DomainHint(ScreeningDomain.interpersonal, 1.5),
    'toxic': DomainHint(ScreeningDomain.interpersonal, 1.8),
    'manipulate': DomainHint(ScreeningDomain.interpersonal, 1.8),
    'manipulated': DomainHint(ScreeningDomain.interpersonal, 1.8),
    'gaslighting': DomainHint(ScreeningDomain.interpersonal, 2.0),
    'relationship': DomainHint(ScreeningDomain.interpersonal, 0.5),
    'family': DomainHint(ScreeningDomain.interpersonal, 0.3),
    'parents': DomainHint(ScreeningDomain.interpersonal, 0.3),
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
class DomainHint {
  final ScreeningDomain domain;
  final double weight;
  const DomainHint(this.domain, this.weight);
}
