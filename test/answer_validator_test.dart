import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare/services/answer_validator.dart';

void main() {
  test('rejects numbers, symbols and keyboard mashing', () {
    for (final bad in ['2', '123', '???', 'asdfgh', 'qwertyuiop', 'zzzz xxxx', '   ', '😀']) {
      expect(AnswerValidator.check(bad), isNotNull, reason: '"$bad"');
    }
  });

  test('accepts real answers, including short ones', () {
    for (final ok in [
      'yes', 'no', 'nope', 'not really', 'sometimes', 'idk',
      'I have been feeling anxious lately',
      'my boss keeps piling on work and I cannot sleep',
      "I'm fine, thanks", 'a lot',
    ]) {
      expect(AnswerValidator.check(ok), isNull, reason: '"$ok"');
    }
  });
}
