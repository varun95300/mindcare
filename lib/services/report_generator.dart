import '../models/quiz_question.dart';
import '../models/quiz_answer.dart';
import '../models/domain_evidence.dart';
import '../models/screening_result.dart';
import 'adaptive_engine.dart';

/// Generates explainable screening reports from quiz evidence.
class ReportGenerator {
  /// Convenience: generate a report directly from an [AdaptiveEngine].
  static ScreeningResult generateReport({required AdaptiveEngine engine}) {
    return generate(evidence: engine.evidence, answers: engine.answers);
  }

  /// Generate a complete screening result with explanations.
  static ScreeningResult generate({
    required DomainEvidence evidence,
    required List<QuizAnswer> answers,
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
          'This is a screening result, not a clinical diagnosis. '
          'Only a qualified mental-health professional can provide a diagnosis. '
          'If you are in crisis or need immediate help, please contact a mental health helpline '
          'or visit your nearest emergency department.',
      recommendation: recommendation,
    );
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
            'You frequently selected higher responses for questions related to '
            '${domain.label.toLowerCase()}, indicating stronger indicators in this area.',
          );
        } else if (domainHighAnswers.length == 1) {
          final q = domainHighAnswers.first;
          observations.add(
            'Your response of "${q.response.label}" to "${_shortenQuestion(q.question.text)}" '
            'contributed evidence toward ${domain.label}.',
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
          'Your responses showed a notably stronger pattern in ${sorted[0].key.label} '
          'compared to other areas.',
        );
      } else if (gap < 0.10) {
        observations.add(
          'Your responses showed similar levels of indicators across '
          '${sorted[0].key.label} and ${sorted[1].key.label}, suggesting '
          'both areas may be worth exploring.',
        );
      }
    }

    return observations;
  }

  /// Generate methodology explanation.
  static String _generateMethodology(int questionCount) {
    return 'The screening asked you $questionCount questions selected adaptively based on '
        'your previous responses. Each answer contributed evidence toward four screening areas: '
        'Anxiety, Depression, Stress, and Interpersonal/Trauma. Questions were chosen to explore '
        'areas where your responses indicated stronger indicators, and to differentiate between '
        'areas with similar patterns. Your answers produced the overall pattern shown above.';
  }

  /// Generate a next-step recommendation.
  static String _generateRecommendation(
    ScreeningDomain primary,
    ScreeningDomain? secondary,
  ) {
    final areas = secondary != null
        ? '${primary.label.toLowerCase()} and ${secondary.label.toLowerCase()}'
        : primary.label.toLowerCase();

    return 'Based on your screening profile, you may find it helpful to speak with a '
        'qualified mental-health professional who specializes in $areas. '
        'Remember, this screening is a starting point — a professional can provide '
        'a thorough assessment and personalized guidance.';
  }

  /// Shorten a question text for display in observations.
  static String _shortenQuestion(String text) {
    if (text.length <= 60) return text;
    return '${text.substring(0, 57)}...';
  }
}
