import '../data/emotion_lexicon.dart';
import '../models/text_analysis.dart';
import 'text_utils.dart';

/// On-device emotion analyzer: tells *which* emotion is being expressed
/// (sentiment only says positive / negative). Pure Dart, no network.
///
/// Negation flips a negative emotion into nothing ("not sad" adds no
/// sadness) and a positive emotion into mild distress ("not happy").
class EmotionAnalyzer {
  const EmotionAnalyzer();

  EmotionResult analyze(String text) {
    if (text.trim().isEmpty) return const EmotionResult();

    final tokens = TextUtils.tokenize(text.toLowerCase());
    final scores = <Emotion, double>{};
    final usedByPhrase = <int>{};

    void add(Emotion emotion, double amount) {
      scores[emotion] = (scores[emotion] ?? 0) + amount;
    }

    // Phrases first so their words are not double counted.
    EmotionLexicon.phrases.forEach((phrase, hint) {
      final length = phrase.split(' ').length;
      for (final start in TextUtils.findPhrase(tokens, phrase)) {
        if (TextUtils.isNegated(tokens, start)) continue;
        for (int k = 0; k < length; k++) {
          usedByPhrase.add(start + k);
        }
        add(hint.emotion, hint.weight * TextUtils.intensifier(tokens, start));
      }
    });

    for (int i = 0; i < tokens.length; i++) {
      if (usedByPhrase.contains(i)) continue;
      final hint = EmotionLexicon.words[tokens[i]];
      if (hint == null) continue;

      final negated = TextUtils.isNegated(tokens, i);
      final boost = TextUtils.intensifier(tokens, i);

      if (negated) {
        // "not happy" hints at low mood; "not sad" / "not anxious" adds nothing.
        if (hint.emotion.isPositive) {
          add(Emotion.sadness, hint.weight * 0.6);
        }
        continue;
      }
      add(hint.emotion, hint.weight * boost);
    }

    return EmotionResult(scores: scores);
  }
}
