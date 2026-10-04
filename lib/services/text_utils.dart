import '../data/mental_health_lexicon.dart';

/// Shared on-device text helpers used by the sentiment, emotion and risk
/// analyzers. Pure Dart — nothing leaves the device.
class TextUtils {
  const TextUtils._();

  /// Tokenize: expand contractions, strip punctuation, split on whitespace.
  /// [text] must already be lower-cased.
  static List<String> tokenize(String text) {
    var processed = text
        .replaceAll("can't", 'cannot')
        .replaceAll("won't", 'will not')
        .replaceAll("don't", 'do not')
        .replaceAll("doesn't", 'does not')
        .replaceAll("didn't", 'did not')
        .replaceAll("isn't", 'is not')
        .replaceAll("aren't", 'are not')
        .replaceAll("wasn't", 'was not')
        .replaceAll("weren't", 'were not')
        .replaceAll("hasn't", 'has not')
        .replaceAll("haven't", 'have not')
        .replaceAll("hadn't", 'had not')
        .replaceAll("wouldn't", 'would not')
        .replaceAll("shouldn't", 'should not')
        .replaceAll("couldn't", 'could not')
        .replaceAll("i'm", 'i am')
        .replaceAll("i've", 'i have')
        .replaceAll("i'll", 'i will')
        .replaceAll("i'd", 'i would');

    // Remove punctuation except hyphens within words
    processed = processed.replaceAll(RegExp(r'[^\w\s-]'), ' ');

    return processed
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Whether the token at [index] is preceded by a negation word within the
  /// previous 3 tokens.
  static bool isNegated(List<String> tokens, int index) {
    final lookback = index < 3 ? index : 3;
    for (int j = 1; j <= lookback; j++) {
      final prev = tokens[index - j];
      if (MentalHealthLexicon.negators.contains(prev) || prev == 'not') {
        return true;
      }
    }
    return false;
  }

  /// Intensifier multiplier for the token at [index] (1.0 if none).
  static double intensifier(List<String> tokens, int index) {
    if (index == 0) return 1.0;
    return MentalHealthLexicon.intensifiers[tokens[index - 1]] ?? 1.0;
  }

  /// Index of every position in [tokens] where the multi-word [phrase]
  /// (already lower-cased, space separated) starts.
  static List<int> findPhrase(List<String> tokens, String phrase) {
    final parts = phrase.split(' ');
    final hits = <int>[];
    for (int i = 0; i + parts.length <= tokens.length; i++) {
      var match = true;
      for (int j = 0; j < parts.length; j++) {
        if (tokens[i + j] != parts[j]) {
          match = false;
          break;
        }
      }
      if (match) hits.add(i);
    }
    return hits;
  }
}
