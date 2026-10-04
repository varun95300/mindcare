import '../models/quiz_question.dart';
import '../models/sentiment_result.dart';
import '../models/text_analysis.dart';
import 'emotion_analyzer.dart';
import 'risk_detector.dart';
import 'sentiment_analyzer.dart';

/// The full on-device text pipeline for one user message:
///
///   Sentiment → Emotion → Keyword / context detection → Risk
///   → Dominant concern
///
/// Voice input is handled upstream: a speech-to-text transcript is simply
/// fed in as [text]. Nothing here touches the network.
class TextAnalysisPipeline {
  final SentimentAnalyzer _sentiment;
  final EmotionAnalyzer _emotion;
  final RiskDetector _risk;

  const TextAnalysisPipeline({
    SentimentAnalyzer sentiment = const SentimentAnalyzer(),
    EmotionAnalyzer emotion = const EmotionAnalyzer(),
    RiskDetector risk = const RiskDetector(),
  })  : _sentiment = sentiment,
        _emotion = emotion,
        _risk = risk;

  /// Analyse [text], optionally in the context of the [question] it answers.
  TextAnalysis analyze(String text, {QuizQuestion? question}) {
    // 1. Sentiment (positive / negative / neutral) + keyword extraction
    final sentiment = _sentiment.analyze(text, question: question);

    // 2. Emotion (which feeling is expressed)
    final emotion = _emotion.analyze(text);

    // 3. Risk
    final risk = _risk.analyze(text, sentiment: sentiment, emotion: emotion);

    // 4. Dominant concern: keyword hints + emotion affinity + question context
    final concernScores = _concernScores(sentiment, emotion, question);
    final ranked = concernScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = concernScores.values.fold<double>(0, (a, b) => a + b);

    ScreeningDomain? dominant;
    double confidence = 0;
    if (ranked.isNotEmpty && ranked.first.value >= 0.8 && total > 0) {
      dominant = ranked.first.key;
      confidence = ranked.first.value / total;
    }

    return TextAnalysis(
      sentiment: sentiment,
      emotion: emotion,
      risk: risk,
      concernScores: concernScores,
      dominantConcern: dominant,
      concernConfidence: confidence,
      severityScore: _finalSeverity(sentiment.severityScore, emotion, risk),
    );
  }

  Map<ScreeningDomain, double> _concernScores(
    SentimentResult sentiment,
    EmotionResult emotion,
    QuizQuestion? question,
  ) {
    final scores = {for (final d in ScreeningDomain.values) d: 0.0};

    // Keyword hints from the mental-health lexicon (already weighted).
    sentiment.domainHints.forEach((domain, weight) {
      scores[domain] = scores[domain]! + weight;
    });

    // Emotion → domain affinity.
    emotion.scores.forEach((emo, strength) {
      emo.domainAffinity.forEach((domain, affinity) {
        scores[domain] = scores[domain]! + strength * affinity * 0.6;
      });
    });

    // Question context: a distressed answer ("yes, constantly") says little
    // by itself, but it does confirm the domain the question was probing.
    if (question != null && sentiment.severityScore >= 2) {
      final boost = sentiment.severityScore == 3 ? 1.2 : 0.8;
      scores[question.primaryDomain] =
          scores[question.primaryDomain]! + boost * question.primaryWeight;
      if (question.secondaryDomain != null) {
        scores[question.secondaryDomain!] =
            scores[question.secondaryDomain!]! + boost * question.secondaryWeight;
      }
    }

    return scores;
  }

  /// Sentiment severity, raised when emotion or risk shows the user is worse
  /// off than the wording alone suggests.
  int _finalSeverity(int base, EmotionResult emotion, RiskResult risk) {
    var severity = base;
    final negativeEmotion = emotion.primary != null && !emotion.primary!.isPositive;
    if (negativeEmotion && emotion.intensity >= 0.6 && severity < 2) {
      severity = 2;
    }
    if (risk.level.index >= RiskLevel.moderate.index && severity < 2) severity = 2;
    if (risk.level.needsSafetyResponse) severity = 3;
    return severity;
  }
}
