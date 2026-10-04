import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindcare/models/user_model.dart';
import 'package:mindcare/services/auth_service.dart';

Future<void> settle() => Future.delayed(const Duration(milliseconds: 50));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sign up, sign out, wrong password, sign in', () async {
    final auth = AuthService();
    await settle();

    expect(
      await auth.signUpLocal(
          username: 'Shuchi', password: 'pw1234', name: 'Shuchi', role: UserRole.patient),
      isTrue,
    );
    expect(auth.currentUser!.id, 'local_shuchi');
    expect(auth.currentUser!.role, UserRole.patient);

    // Duplicate usernames (case-insensitive) are rejected.
    expect(
      await auth.signUpLocal(
          username: 'shuchi', password: 'other', name: 'X', role: UserRole.patient),
      isFalse,
    );

    await auth.signOut();
    expect(auth.currentUser, isNull);

    expect(await auth.signInLocal(username: 'shuchi', password: 'nope'), isFalse);
    expect(auth.error, 'Incorrect password.');
    expect(await auth.signInLocal(username: 'shuchi', password: 'pw1234'), isTrue);
  });

  test('session survives an app restart, psychologist linked to profile', () async {
    final first = AuthService();
    await settle();
    await first.signUpLocal(
        username: 'doc', password: 'pw1234', name: 'Dr Doc', role: UserRole.psychologist);

    final second = AuthService();
    await settle();
    expect(second.sessionLoaded, isTrue);
    expect(second.currentUser!.name, 'Dr Doc');
    expect(second.currentUser!.psychologistId, 'psy_001');

    await second.signOut();
    final third = AuthService();
    await settle();
    expect(third.currentUser, isNull);
  });
}
