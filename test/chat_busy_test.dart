import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindcare/services/local_store.dart';
import 'package:mindcare/viewmodels/chat_viewmodel.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalStore.instance.resetCache();
  });

  test('overlapping sends are processed one at a time (no duplicate replies)',
      () async {
    final vm = ChatViewModel();
    await vm.startConversation('local_test');
    final before = vm.messages.length;

    // The user hammers send while the bot is still replying.
    await Future.wait([
      vm.sendMessage('yes I have been stressed'),
      vm.sendMessage('yes I have been stressed'),
      vm.sendMessage('yes I have been stressed'),
    ]);

    final newMessages = vm.messages.skip(before).toList();
    expect(newMessages.where((m) => m.isUser).length, 1);
    // one acknowledgement + one next question
    expect(newMessages.where((m) => m.isBot).length, lessThanOrEqualTo(2));
    expect(vm.isBusy, isFalse);
    vm.dispose();
  });
}
