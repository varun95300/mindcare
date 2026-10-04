import '../data/afinn_lexicon.dart';
import '../data/mental_health_lexicon.dart';
import '../models/quiz_question.dart';
import '../models/sentiment_result.dart';
import 'text_utils.dart';

/// Pure-Dart, on-device sentiment analyzer.
///
/// Processes free-text user responses entirely in memory — **no data ever
/// leaves the device**.
///
/// Pipeline:
///   1. Tokenize and normalise the input text
///   2. Detect negation and intensifier context
///   3. Score each token against the AFINN-165 lexicon
///   4. Extract domain-specific keywords from the mental-health lexicon
///   5. Detect affirmation / denial phrases
///   6. Compute a compound score → map to 0–3 severity
class SentimentAnalyzer {
  const SentimentAnalyzer();

  /// Analyse [text] in the context of [question] (if available).
  ///
  /// The question context lets us boost severity when the user simply
  /// says "yes" to a distress-related question (the question itself
  /// already tells us which domain is being probed).
  SentimentResult analyze(String text, {QuizQuestion? question}) {
    if (text.trim().isEmpty) {
      return const SentimentResult(
        rawScore: 0,
        label: 'neutral',
        severityScore: 1,
      );
    }

    final lower = text.toLowerCase();
    final tokens = TextUtils.tokenize(lower);

    // 1. Check for affirmation / denial patterns first
    final affirmationScore = _detectAffirmation(lower);
    final denialScore = _detectDenial(lower);

    // 2. Run the AFINN lexicon-based analysis
    double compoundScore = 0;
    final detectedKeywords = <String>[];
    final domainHints = <ScreeningDomain, double>{};

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // Check if this token is in the AFINN lexicon
      final afinnScore = AfinnLexicon.words[token];
      if (afinnScore != null) {
        double score = afinnScore.toDouble();

        // Check for negation in the preceding 1-3 tokens
        final negated = TextUtils.isNegated(tokens, i);
        if (negated) {
          score = -score * 0.75; // Flip polarity but dampen slightly
        }

        // Check for intensifier in the preceding token
        final intensifier = TextUtils.intensifier(tokens, i);
        score *= intensifier;

        compoundScore += score;
        detectedKeywords.add(negated ? 'NOT_$token' : token);
      }

      // 3. Check for domain-specific keywords
      final domainHint = MentalHealthLexicon.domainKeywords[token];
      if (domainHint != null) {
        final domain = domainHint.domain;
        final weight = domainHint.weight;
        domainHints[domain] = (domainHints[domain] ?? 0) + weight;
        if (!detectedKeywords.contains(token)) {
          detectedKeywords.add(token);
        }
      }
    }

    // 4. Factor in affirmation/denial
    // If the user affirms (e.g., "yes, all the time"), treat it as
    // negative sentiment in the context of a distress question.
    if (affirmationScore > denialScore && compoundScore >= -0.5) {
      // User is agreeing with the distress question
      compoundScore -= affirmationScore * 1.5;
    } else if (denialScore > affirmationScore && compoundScore <= 0.5) {
      // User is denying distress
      compoundScore += denialScore * 1.0;
    }

    // 5. Normalise to a rough range and determine severity
    // Clamp the compound score to a reasonable range
    final normalised = compoundScore.clamp(-8.0, 8.0);

    // 6. Map to severity and label
    final label = _toLabel(normalised);
    final severity = _toSeverity(normalised, question: question);

    return SentimentResult(
      rawScore: normalised,
      label: label,
      severityScore: severity,
      domainHints: domainHints,
      detectedKeywords: detectedKeywords,
    );
  }

  // ─── Private helpers ───────────────────────────────────────────────

  /// Detect how strongly the text affirms/agrees.
  double _detectAffirmation(String text) {
    double score = 0;
    for (final phrase in MentalHealthLexicon.affirmationPhrases) {
      if (text.contains(phrase)) {
        score += 1.0;
      }
    }
    return score.clamp(0, 3);
  }

  /// Detect how strongly the text denies/negates.
  double _detectDenial(String text) {
    double score = 0;
    for (final phrase in MentalHealthLexicon.denialPhrases) {
      if (text.contains(phrase)) {
        score += 1.0;
      }
    }
    return score.clamp(0, 3);
  }

  /// Map compound score to a human-readable label.
  String _toLabel(double score) {
    if (score >= 1.5) return 'positive';
    if (score >= -0.5) return 'neutral';
    if (score >= -3.0) return 'negative';
    return 'very_negative';
  }

  /// Map compound score → 0–3 severity.
  ///
  /// The thresholds adapt slightly based on question context.
  int _toSeverity(double score, {QuizQuestion? question}) {
    // If compound score is clearly positive → minimal distress
    if (score >= 1.5) return 0;

    // Neutral zone → mild
    if (score >= -0.5) return 1;

    // Negative → moderate
    if (score >= -3.0) return 2;

    // Very negative → high
    return 3;
  }
}
