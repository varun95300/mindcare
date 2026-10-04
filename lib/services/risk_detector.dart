import '../data/emotion_lexicon.dart';
import '../models/sentiment_result.dart';
import '../models/text_analysis.dart';
import 'text_utils.dart';

/// On-device risk detector: estimates how much risk a message indicates
/// (none → critical) and records which phrases triggered it.
///
/// This is a screening aid only. It is deliberately sensitive — a false
/// alarm shows a gentle safety message; a miss would be far worse.
class RiskDetector {
  const RiskDetector();

  RiskResult analyze(
    String text, {
    SentimentResult? sentiment,
    EmotionResult? emotion,
  }) {
    if (text.trim().isEmpty) return const RiskResult();

    final tokens = TextUtils.tokenize(text.toLowerCase());
    final hits = <_Hit>[];

    void scan(Map<String, double> phrases) {
      phrases.forEach((phrase, weight) {
        final length = phrase.split(' ').length;
        for (final start in TextUtils.findPhrase(tokens, phrase)) {
          // "I would never hurt myself", "not suicidal" → protective, skip.
          if (TextUtils.isNegated(tokens, start)) continue;
          hits.add(_Hit(phrase, weight, start, start + length));
        }
      });
    }

    scan(EmotionLexicon.criticalRiskPhrases);
    scan(EmotionLexicon.highRiskPhrases);
    scan(EmotionLexicon.moderateRiskPhrases);
    scan(EmotionLexicon.lowRiskPhrases);

    if (hits.isEmpty && !_distressSignals(sentiment, emotion)) {
      return const RiskResult();
    }

    // Strongest phrase wins an overlapping span, so one expression is not
    // counted twice ("cannot take it" inside "cannot take it anymore").
    hits.sort((a, b) => b.weight.compareTo(a.weight));
    final kept = <_Hit>[];
    for (final hit in hits) {
      if (kept.every((k) => hit.end <= k.start || hit.start >= k.end)) {
        kept.add(hit);
      }
    }

    double score = 0;
    if (kept.isNotEmpty) {
      score = kept.first.weight;
      for (final hit in kept.skip(1)) {
        score += hit.weight * 0.2; // corroborating phrases add a little
      }
    }

    // Context modifiers: only nudge an existing signal, never create one
    // from sentiment alone beyond "low".
    if (sentiment != null && sentiment.label == 'very_negative') score += 0.8;
    if (emotion != null) {
      final hopeless = emotion.scores[Emotion.hopelessness] ?? 0;
      score += (hopeless / 2.5).clamp(0.0, 1.0) * 1.0;
    }
    if (kept.isEmpty && _distressSignals(sentiment, emotion)) {
      score = score < 1.5 ? 1.5 : score;
    }
    score = score.clamp(0.0, 10.0);

    return RiskResult(
      level: _toLevel(score),
      score: score,
      flags: kept.map((h) => h.phrase).toList(),
    );
  }

  /// Merge per-message risk into a conversation-level peak.
  static RiskResult peak(RiskResult a, RiskResult b) {
    final higher = b.score > a.score ? b : a;
    final flags = {...a.flags, ...b.flags}.toList();
    return RiskResult(level: higher.level, score: higher.score, flags: flags);
  }

  bool _distressSignals(SentimentResult? sentiment, EmotionResult? emotion) {
    if (sentiment != null && sentiment.label == 'very_negative') return true;
    if (emotion != null && emotion.intensity >= 0.75 && !emotion.primary!.isPositive) {
      return true;
    }
    return false;
  }

  RiskLevel _toLevel(double score) {
    if (score >= 9.0) return RiskLevel.critical;
    if (score >= 7.0) return RiskLevel.high;
    if (score >= 4.0) return RiskLevel.moderate;
    if (score >= 1.5) return RiskLevel.low;
    return RiskLevel.none;
  }
}

class _Hit {
  final String phrase;
  final double weight;
  final int start;
  final int end;
  const _Hit(this.phrase, this.weight, this.start, this.end);
}
