import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../data/seed_psychologists.dart';
import '../models/user_model.dart';
import 'local_store.dart';

/// Local authentication service (test build).
///
/// Username + password accounts and demo accounts live in the on-device
/// [LocalStore]; the logged-in user is remembered across refreshes.
class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isPsychologist => _currentUser?.role == UserRole.psychologist;
  bool get isLoading => false;
  String? get error => _error;

  bool _sessionLoaded = false;

  /// False until the saved session (if any) has been read from disk.
  bool get sessionLoaded => _sessionLoaded;

  AuthService() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final docs = await LocalStore.instance.readAll('session');
      if (docs.isNotEmpty && _currentUser == null) {
        final d = docs.first;
        _currentUser = AppUser(
          id: d['userId'] as String,
          name: d['name'] as String,
          email: d['email'] as String,
          role: d['role'] == 'psychologist'
              ? UserRole.psychologist
              : UserRole.patient,
          psychologistId: d['psychologistId'] as String?,
        );
      }
    } catch (e) {
      debugPrint('Could not restore session: $e');
    }
    _sessionLoaded = true;
    notifyListeners();
  }

  /// Remember the logged-in local/demo user so a refresh keeps them in.
  Future<void> _saveSession(AppUser user) => LocalStore.instance.writeAll(
        'session',
        [
          {
            'id': 'current',
            'userId': user.id,
            'name': user.name,
            'email': user.email,
            'role': user.role.name,
            'psychologistId': user.psychologistId,
          }
        ],
      );

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  /// Create a username + password account stored on this device only.
  /// (Test build: the hash protects against casual reading, nothing more.)
  Future<bool> signUpLocal({
    required String username,
    required String password,
    required String name,
    required UserRole role,
    String? psychologistId,
  }) async {
    _error = null;
    final user = username.trim().toLowerCase();
    if (user.length < 3) {
      return _fail('Username must be at least 3 characters.');
    }
    if (password.length < 4) {
      return _fail('Password must be at least 4 characters.');
    }
    if (name.trim().isEmpty) return _fail('Please enter your name.');

    final accounts = await LocalStore.instance.readAll('accounts');
    if (accounts.any((a) => a['username'] == user)) {
      return _fail('That username is taken. Try signing in instead.');
    }
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final id = 'local_$user';
    await LocalStore.instance.upsert('accounts', {
      'id': id,
      'username': user,
      'salt': salt,
      'hash': _hash(salt, password),
      'name': name.trim(),
      'role': role.name,
      'psychologistId': role == UserRole.psychologist
          ? (psychologistId ?? 'psy_001')
          : null,
    });
    return _startLocalSession(AppUser(
      id: id,
      name: name.trim(),
      email: '$user@mindcare.local',
      role: role,
      psychologistId: role == UserRole.psychologist
          ? (psychologistId ?? 'psy_001')
          : null,
    ));
  }

  /// Sign in to a username + password account made with [signUpLocal].
  Future<bool> signInLocal({
    required String username,
    required String password,
  }) async {
    _error = null;
    final user = username.trim().toLowerCase();
    final accounts = await LocalStore.instance.readAll('accounts');
    final matches = accounts.where((a) => a['username'] == user);
    if (matches.isEmpty) return _fail('No account with that username.');
    final account = matches.first;
    if (_hash(account['salt'] as String, password) != account['hash']) {
      return _fail('Incorrect password.');
    }
    final role = account['role'] == 'psychologist'
        ? UserRole.psychologist
        : UserRole.patient;
    return _startLocalSession(AppUser(
      id: account['id'] as String,
      name: account['name'] as String,
      email: '$user@mindcare.local',
      role: role,
      psychologistId: role == UserRole.psychologist
          ? (account['psychologistId'] as String? ?? 'psy_001')
          : null,
    ));
  }

  Future<bool> _startLocalSession(AppUser user) async {
    _currentUser = user;
    await _saveSession(user);
    notifyListeners();
    return true;
  }

  bool _fail(String message) {
    _error = message;
    notifyListeners();
    return false;
  }

  /// Fixed fake accounts for the test build. Their ids never change, so
  /// everything saved under them is still there when you come back.
  static const demoPatientId = 'demo_patient';
  static const demoPsychologistId = 'demo_psychologist';

  /// Log in as a fake user or psychologist. Data is kept
  /// in the on-device [LocalStore].
  Future<bool> signInAsDemo(UserRole role,
      {String psychologistId = 'psy_001'}) async {
    _error = null;
    _currentUser = role == UserRole.psychologist
        ? AppUser(
            id: '${demoPsychologistId}_$psychologistId',
            name: SeedPsychologists.getById(psychologistId)?.name ??
                'Psychologist',
            email: 'doctor.demo@mindcare.app',
            role: UserRole.psychologist,
            psychologistId: psychologistId,
          )
        : const AppUser(
            id: demoPatientId,
            name: 'Demo Student',
            email: 'student.demo@mindcare.app',
            role: UserRole.patient,
          );
    await _saveSession(_currentUser!);
    notifyListeners();
    return true;
  }

  /// Sign out.
  Future<void> signOut() async {
    _currentUser = null;
    await LocalStore.instance.writeAll('session', []);
    notifyListeners();
  }

  /// Sign out alias for backwards compatibility.
  Future<void> logout() => signOut();

  /// Clear error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
