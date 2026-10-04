import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare/models/quiz_question.dart';
import 'package:mindcare/models/text_analysis.dart';
import 'package:mindcare/services/adaptive_engine.dart';
import 'package:mindcare/services/text_analysis_pipeline.dart';

void main() {
  const pipeline = TextAnalysisPipeline();

  group('emotion', () {
    test('detects fear from anxious wording', () {
      final a = pipeline.analyze("I'm so anxious and I keep panicking");
      expect(a.emotion.primary, Emotion.fear);
      expect(a.dominantConcern, ScreeningDomain.anxiety);
    });

    test('negated emotion is not counted', () {
      final a = pipeline.analyze("I'm not sad at all");
      expect(a.emotion.scores[Emotion.sadness], isNull);
    });

    test('loneliness points to interpersonal', () {
      final a = pipeline.analyze('I feel so lonely and isolated lately');
      expect(a.emotion.primary, Emotion.loneliness);
      expect(a.dominantConcern, ScreeningDomain.interpersonal);
    });
  });

  group('risk', () {
    test('plain good day has no risk', () {
      final a = pipeline.analyze('I had a great day, feeling happy');
      expect(a.risk.level, RiskLevel.none);
    });

    test('explicit suicidal intent is critical', () {
      final a = pipeline.analyze('I want to kill myself');
      expect(a.risk.level, RiskLevel.critical);
      expect(a.risk.level.needsSafetyResponse, isTrue);
      expect(a.severityScore, 3);
    });

    test('negated self-harm is not flagged', () {
      final a = pipeline.analyze("I would never hurt myself, I'm not suicidal");
      expect(a.risk.level.needsSafetyResponse, isFalse);
    });

    test('passive ideation is high risk', () {
      final a = pipeline.analyze('everyone would be better off without me');
      expect(a.risk.level, RiskLevel.high);
    });

    test('hopelessness is at least moderate', () {
      final a = pipeline.analyze('I feel hopeless and want to give up');
      expect(a.risk.level.index, greaterThanOrEqualTo(RiskLevel.moderate.index));
    });
  });

  group('hybrid selector', () {
    test('first question is always the broad opener', () {
      final engine = AdaptiveEngine();
      expect(engine.selectNextQuestion()!.id, 'Q1');
    });

    test('dominant concern from free text steers the next question', () {
      final engine = AdaptiveEngine();
      final q1 = engine.selectNextQuestion()!;
      final analysis = pipeline.analyze(
        "I'm so lonely, I feel isolated and rejected by everyone",
        question: q1,
      );
      engine.recordAnswer(q1, LikertResponse.sometimes);
      engine.recordSignals(analysis);

      final next = engine.selectNextQuestion()!;
      expect(next.primaryDomain, ScreeningDomain.interpersonal);
      expect(engine.selectionReasons.last, contains('interpersonal'));
    });

    test('risk signal asks the hopelessness check first', () {
      final engine = AdaptiveEngine();
      final q1 = engine.selectNextQuestion()!;
      final analysis = pipeline.analyze(
        'I feel hopeless, there is no hope',
        question: q1,
      );
      engine.recordAnswer(q1, LikertResponse.often);
      engine.recordSignals(analysis);

      expect(engine.peakRisk.level.index,
          greaterThanOrEqualTo(RiskLevel.moderate.index));
      expect(engine.selectNextQuestion()!.id, 'Q9');
    });

    test('no signals falls back to the rule-based follow-up', () {
      final engine = AdaptiveEngine();
      final q1 = engine.selectNextQuestion()!;
      engine.recordAnswer(q1, LikertResponse.sometimes);
      engine.recordSignals(pipeline.analyze('hmm not sure', question: q1));
      expect(engine.selectNextQuestion()!.id, 'Q3'); // original rule for score 2
    });

    test('full conversation never repeats a question', () {
      final engine = AdaptiveEngine();
      final seen = <String>{};
      const replies = [
        'yes I am overwhelmed with deadlines and pressure',
        'I worry constantly and feel anxious',
        'not really, I still enjoy things',
        'yes I am exhausted and tired all the time',
        'sometimes I panic',
        'no I am fine there',
        'I feel lonely',
        'yes always',
        'no',
        'yes',
        'maybe',
        'yes',
      ];
      for (final reply in replies) {
        final q = engine.selectNextQuestion();
        if (q == null) break;
        expect(seen.add(q.id), isTrue, reason: 'repeated ${q.id}');
        final analysis = pipeline.analyze(reply, question: q);
        engine.recordAnswer(q, LikertResponse.values[analysis.severityScore]);
        engine.recordSignals(analysis);
      }
      expect(engine.isComplete || seen.length >= 7, isTrue);
    });
  });
}
