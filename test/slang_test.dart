import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare/models/quiz_question.dart';
import 'package:mindcare/models/text_analysis.dart';
import 'package:mindcare/services/answer_validator.dart';
import 'package:mindcare/services/text_analysis_pipeline.dart';
import 'package:mindcare/services/text_utils.dart';

void main() {
  const pipeline = TextAnalysisPipeline();

  group('stretched and shouted words', () {
    test('are repaired', () {
      expect(TextUtils.normalize('YESSS'), 'yes');
      expect(TextUtils.normalize('yesssssssssss'), 'yes');
      expect(TextUtils.normalize('Noooooo!!!'), 'no!!!');
      expect(TextUtils.normalize('sooooo tireddd'), 'so tired');
      expect(TextUtils.normalize('goooood'), 'good');
      expect(TextUtils.normalize('hellooo'), 'hello');
      expect(TextUtils.normalize('hmmmmm'), 'hmm');
    });

    test('real double letters are left alone', () {
      expect(TextUtils.normalize('I feel good, need sleep'), 'i feel good, need sleep');
    });

    test('are accepted as answers', () {
      for (final t in ['YESSS', 'yesssssssssss', 'nooooo', 'yeaaaah', 'okkkkk', 'heyyyyy']) {
        expect(AnswerValidator.check(t), isNull, reason: t);
      }
    });

    test('keyboard mashing is still rejected', () {
      for (final t in ['aaaaaaa', 'zzzzzz', 'asdfghjkl', 'lolololol1234']) {
        expect(AnswerValidator.check(t), isNotNull, reason: t);
      }
    });
  });

  group('slang', () {
    test('is expanded', () {
      expect(TextUtils.normalize('ngl im so stressed fr'), 'i am so stressed');
      expect(TextUtils.normalize('idk man'), 'i do not know man');
      expect(TextUtils.normalize('cant sleep rn'), 'cannot sleep right now');
      expect(TextUtils.normalize('anxious af'), 'very anxious');
      expect(TextUtils.normalize('lowkey tired tho'), 'somewhat tired though');
    });

    test('is read for sentiment, emotion and concern', () {
      final a = pipeline.analyze('ngl im so anxious af rn');
      expect(a.emotion.primary, Emotion.fear);
      expect(a.dominantConcern, ScreeningDomain.anxiety);
      expect(a.sentiment.label, isIn(['negative', 'very_negative']));
    });

    test('YESSS counts as agreeing with a distress question', () {
      final q = pipeline.analyze('YESSSSSS', question: null);
      final plain = pipeline.analyze('yes', question: null);
      expect(q.sentiment.rawScore, plain.sentiment.rawScore);
    });

    test('emoji with a clear feeling are read', () {
      final a = pipeline.analyze('feeling 😢 today');
      expect(a.emotion.scores[Emotion.sadness], isNotNull);
    });
  });

  group('risk slang', () {
    test('"unalive" and "kms" are treated as suicide wording', () {
      for (final t in [
        'i want to unalive myself',
        'honestly kms',
        'i wanna unalive myself fr',
      ]) {
        expect(pipeline.analyze(t).risk.level.needsSafetyResponse, isTrue,
            reason: t);
      }
    });

    test('negated slang is not flagged', () {
      expect(pipeline.analyze('i would never unalive myself').risk.level.needsSafetyResponse,
          isFalse);
    });

    test('casual, harmless slang does not trigger risk', () {
      expect(pipeline.analyze('ngl this exam is killing me lol').risk.level.needsSafetyResponse,
          isFalse);
    });
  });
}
