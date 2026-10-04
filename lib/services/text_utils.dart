import '../data/mental_health_lexicon.dart';
import '../data/slang_lexicon.dart';
import 'vocabulary.dart';

/// Shared on-device text helpers used by the sentiment, emotion and risk
/// analyzers. Pure Dart — nothing leaves the device.
class TextUtils {
  const TextUtils._();

  static final RegExp _wordPattern = RegExp(r"[a-z]+(?:'[a-z]+)?");
  static final RegExp _afPattern = RegExp(r'\b([a-z]+)\s+(?:af|asf)\b');

  /// Turn how people really type into plain words the analysers know:
  /// stretched letters ("yesss" -> "yes"), slang and abbreviations ("ngl im
  /// so stressed fr" -> "i am so stressed"), "X af" -> "very X", some emoji,
  /// and slang euphemisms for self-harm. Safe to call repeatedly.
  static String normalize(String input) {
    var t = input.toLowerCase();
    SlangLexicon.emoji.forEach((emoji, word) => t = t.replaceAll(emoji, word));
    t = t.replaceAllMapped(_wordPattern, (m) => _fixWord(m[0]!));
    t = t.replaceAllMapped(_afPattern, (m) => 'very ${m[1]}');
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _fixWord(String word) {
    if (word.contains("'")) return word;
    var w = word;
    if (!Vocabulary.isKnown(w)) {
      if (RegExp(r'(.)\1\1').hasMatch(w)) {
        // Three or more of a letter is clearly stretched on purpose.
        w = _repairStretched(w);
      } else if (RegExp(r'(.)\1').hasMatch(w)) {
        // A plain double letter may be a real word ("off", "stuff"), so only
        // repair it into a few short words people commonly stretch.
        final fixed = _repairStretched(w);
        if (_stretchSafe.contains(fixed)) w = fixed;
      }
    }
    return SlangLexicon.map[w] ?? w;
  }

  static const Set<String> _stretchSafe = {
    'yes', 'no', 'so', 'hi', 'hey', 'ok', 'okay', 'yeah', 'yea', 'yep',
    'nah', 'ya', 'plz', 'pls', 'please', 'sorry', 'thanks',
  };

  /// "yesssss" -> "yes", "goood" -> "good", "hellooo" -> "hello". Tries
  /// every way of shortening repeated letters, keeping the longest result
  /// that is a real word. Unknown words just get runs capped at two.
  static String _repairStretched(String word) {
    final runs = <(String, int)>[];
    for (final m in RegExp(r'(.)\1*').allMatches(word)) {
      runs.add((m[1]!, m[0]!.length));
    }
    final stretched = runs.where((r) => r.$2 >= 2).length;
    final capped = runs.map((r) => r.$1 * (r.$2 > 2 ? 2 : r.$2)).join();
    if (stretched > 5) return capped;

    final candidates = <String>[];
    void build(int i, String acc) {
      if (i == runs.length) {
        candidates.add(acc);
        return;
      }
      final (ch, len) = runs[i];
      if (len == 1) {
        build(i + 1, acc + ch);
        return;
      }
      build(i + 1, acc + ch * 2);
      build(i + 1, acc + ch);
    }

    build(0, '');
    candidates.sort((a, b) => b.length.compareTo(a.length));
    for (final c in candidates) {
      if (c.length >= 2 && Vocabulary.isKnown(c)) return c;
    }
    return capped;
  }

  /// Tokenize: normalise slang, expand contractions, strip punctuation, split
  /// on whitespace.
  static List<String> tokenize(String text) {
    var processed = normalize(text)
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
