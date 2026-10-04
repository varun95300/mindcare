import 'text_utils.dart';
import 'vocabulary.dart';

/// Why a reply was not accepted as an answer.
enum AnswerProblem {
  /// Only digits, symbols or emoji — no words to analyse.
  noWords,

  /// Letters, but nothing that looks like real language ("asdfgh").
  gibberish,
}

/// Checks that a free-text reply is a real answer before it is analysed.
///
/// Anything that does not read as language (random keys, bare numbers) is
/// rejected and the question is asked again, instead of being scored as if
/// the user had meant something. On-device, no network.
class AnswerValidator {
  const AnswerValidator._();

  /// Returns null if [text] looks like a real answer.
  static AnswerProblem? check(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return AnswerProblem.noWords;

    final tokens = TextUtils.tokenize(trimmed.toLowerCase())
        .where((t) => RegExp(r'[a-z]').hasMatch(t))
        .toList();
    if (tokens.isEmpty) return AnswerProblem.noWords;

    final known = tokens.where(Vocabulary.isKnown).length;
    // At least one recognisable word, and not mostly noise.
    if (known == 0) return AnswerProblem.gibberish;
    if (tokens.length >= 4 && known / tokens.length < 0.25) {
      return AnswerProblem.gibberish;
    }
    return null;
  }
}
