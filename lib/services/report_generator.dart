import '../models/quiz_question.dart';
import '../models/quiz_answer.dart';
import '../models/domain_evidence.dart';
import '../models/screening_result.dart';
import '../models/text_analysis.dart';
import 'adaptive_engine.dart';

/// Generates explainable screening reports from quiz evidence.
class ReportGenerator {
  /// Convenience: generate a report directly from an [AdaptiveEngine].
  static ScreeningResult generateReport({required AdaptiveEngine engine}) {
    return generate(
      evidence: engine.evidence,
      answers: engine.answers,
      peakRisk: engine.peakRisk,
      emotionTotals: engine.emotionTotals,
      selectionReasons: engine.selectionReasons,
    );
  }

  /// Generate a complete screening result with explanations.
  static ScreeningResult generate({
    required DomainEvidence evidence,
    required List<QuizAnswer> answers,
    RiskResult peakRisk = const RiskResult(),
    Map<Emotion, double> emotionTotals = const {},
    List<String> selectionReasons = const [],
  }) {
    final sorted = evidence.sortedScores;
    final primary = sorted[0];
    final secondary = sorted.length > 1 && sorted[1].value >= 0.20
        ? sorted[1]
        : null;

    final normalizedScores = {
      for (final entry in sorted) entry.key: entry.value,
    };

    final severityLabels = {
      for (final entry in sorted)
        entry.key: DomainEvidence.severityLabel(entry.value),
    };

    final observations = _generateObservations(answers, evidence, primary.key);
    _addTextSignalObservations(observations, peakRisk, emotionTotals);
    final methodology = _generateMethodology(answers.length);
    final recommendation = _generateRecommendation(
      primary.key,
      secondary?.key,
    );

    return ScreeningResult(
      primaryDomain: primary.key,
      secondaryDomain: secondary?.key,
      normalizedScores: normalizedScores,
      severityLabels: severityLabels,
      answers: answers,
      keyObservations: observations,
      methodologyExplanation: methodology,
      disclaimer:
          'This is an automated screening result, not a clinical diagnosis. '
          'It is meant to support, not replace, your own clinical assessment.',
      recommendation: recommendation,
      peakRiskLevel: peakRisk.level,
      riskFlags: peakRisk.flags,
      emotionSummary: {for (final e in emotionTotals.entries) e.key.name: e.value},
      selectionReasons: selectionReasons,
    );
  }

  /// Observations drawn from the free-text analysis (emotion and risk).
  static void _addTextSignalObservations(
    List<String> observations,
    RiskResult peakRisk,
    Map<Emotion, double> emotionTotals,
  ) {
    final ranked = emotionTotals.entries
        .where((e) => !e.key.isPositive)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.isNotEmpty) {
      final names = ranked.take(2).map((e) => e.key.label.toLowerCase()).join(' and ');
      observations.add(
        'In their own words, the feelings that came through most were $names.',
      );
    }
    if (peakRisk.level.index >= RiskLevel.moderate.index) {
      observations.add(
        'Some of the patient wording suggested a ${peakRisk.level.label.toLowerCase()} '
        'level of risk. This is worth reviewing first.',
      );
    }
  }

  /// Generate human-readable observations from the answer pattern.
  static List<String> _generateObservations(
    List<QuizAnswer> answers,
    DomainEvidence evidence,
    ScreeningDomain primary,
  ) {
    final observations = <String>[];

    // Find the highest-scoring answers (Often/Almost Always)
    final highAnswers = answers.where((a) => a.response.value >= 3).toList();
    final moderateAnswers =
        answers.where((a) => a.response.value == 2).toList();
    final lowAnswers = answers.where((a) => a.response.value <= 1).toList();

    // Describe high-scoring patterns
    if (highAnswers.isNotEmpty) {
      final highDomains = <ScreeningDomain>{};
      for (final a in highAnswers) {
        highDomains.add(a.question.primaryDomain);
      }

      for (final domain in highDomains) {
        final domainHighAnswers = highAnswers
            .where((a) => a.question.primaryDomain == domain)
            .toList();
        if (domainHighAnswers.length >= 2) {
          observations.add(
            'The patient frequently gave higher-intensity answers to questions about '
            '${domain.label.toLowerCase()}, indicating stronger indicators in this area.',
          );
        } else if (domainHighAnswers.length == 1) {
          final q = domainHighAnswers.first;
          observations.add(
            'The patient answered "${q.response.label}" when asked "${_shortenQuestion(q.question.text)}", '
            'which contributed evidence toward ${domain.label}.',
          );
        }
      }
    }

    // Describe moderate patterns
    if (moderateAnswers.isNotEmpty && moderateAnswers.length >= 2) {
      final moderateDomains = <ScreeningDomain>{};
      for (final a in moderateAnswers) {
        moderateDomains.add(a.question.primaryDomain);
      }
      final domainNames = moderateDomains.map((d) => d.label).join(' and ');
      observations.add(
        'Several responses showed moderate indicators across $domainNames.',
      );
    }

    // Describe low-scoring areas
    if (lowAnswers.isNotEmpty) {
      final lowDomains = <ScreeningDomain>{};
      for (final a in lowAnswers) {
        lowDomains.add(a.question.primaryDomain);
      }
      // Only mention domains that are NOT the primary
      final otherLowDomains = lowDomains.where((d) => d != primary).toList();
      if (otherLowDomains.isNotEmpty) {
        final names = otherLowDomains.map((d) => d.label).join(' and ');
        observations.add(
          'Responses related to $names were comparatively less prominent.',
        );
      }
    }

    // Add score-based observation
    final sorted = evidence.sortedScores;
    if (sorted.length >= 2) {
      final gap = sorted[0].value - sorted[1].value;
      if (gap > 0.25) {
        observations.add(
          'The patient responses showed a notably stronger pattern in ${sorted[0].key.label} '
          'than in other areas.',
        );
      } else if (gap < 0.10) {
        observations.add(
          'The patient responses showed similar levels of indicators across '
          '${sorted[0].key.label} and ${sorted[1].key.label}, suggesting '
          'both areas may be worth exploring.',
        );
      }
    }

    return observations;
  }

  /// Generate methodology explanation.
  static String _generateMethodology(int questionCount) {
    return 'The patient was asked $questionCount questions, selected adaptively from their '
        'earlier answers and from what they wrote in their own words. Each answer contributed '
        'evidence toward four screening areas: Anxiety, Depression, Stress, and '
        'Interpersonal/Trauma. Questions were chosen to explore areas where responses indicated '
        'stronger indicators, and to tell apart areas with similar patterns. The overall pattern '
        'is shown above.';
  }

  /// Generate a next-step recommendation for the psychologist.
  static String _generateRecommendation(
    ScreeningDomain primary,
    ScreeningDomain? secondary,
  ) {
    final areas = secondary != null
        ? '${primary.label.toLowerCase()} and ${secondary.label.toLowerCase()}'
        : primary.label.toLowerCase();

    return 'Based on this screening profile, the patient may benefit from support focused on '
        '$areas. This screening is only a starting point; a full clinical assessment is needed '
        'before drawing conclusions.';
  }

  /// True if the stored narrative still speaks to the patient ("you / your").
  static bool narrativeNeedsRewrite(ScreeningResult r) {
    // The disclaimer addresses the psychologist ("your clinical assessment"),
    // so only the patient-facing wording of the other fields is checked.
    final texts = [
      ...r.keyObservations,
      r.methodologyExplanation,
      r.recommendation,
    ];
    final second = RegExp(r'\b(you|your|yours)\b', caseSensitive: false);
    return texts.any(second.hasMatch);
  }

  /// Rebuild the narrative fields (observations, methodology, recommendation,
  /// disclaimer) from the stored data, in the psychologist's perspective.
  static ScreeningResult rewriteNarrative(ScreeningResult r) {
    final evidence = DomainEvidence();
    r.normalizedScores.forEach((d, v) => evidence.addEvidence(d, v, 1.0));
    final emotions = <Emotion, double>{};
    r.emotionSummary.forEach((name, v) {
      for (final e in Emotion.values) {
        if (e.name == name) emotions[e] = v;
      }
    });
    final observations =
        _generateObservations(r.answers, evidence, r.primaryDomain);
    _addTextSignalObservations(
      observations,
      RiskResult(level: r.peakRiskLevel, flags: r.riskFlags),
      emotions,
    );
    return r.withNarrative(
      keyObservations: observations,
      methodologyExplanation: _generateMethodology(r.answers.length),
      recommendation: _generateRecommendation(r.primaryDomain, r.secondaryDomain),
      disclaimer:
          'This is an automated screening result, not a clinical diagnosis. '
          'It is meant to support, not replace, your own clinical assessment.',
    );
  }

  /// Shorten a question text for display in observations.
  static String _shortenQuestion(String text) {
    if (text.length <= 60) return text;
    return '${text.substring(0, 57)}...';
  }
}
