import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'local_store.dart';

/// Firebase-backed authentication service.
///
/// Handles sign-up, sign-in, sign-out, and auth state persistence.
/// User role (patient / psychologist) is stored in Firestore.
class AuthService extends ChangeNotifier {
  /// Null when Firebase isn't available (tests, offline start). Local and
  /// demo accounts still work without it.
  final FirebaseAuth? _auth = _tryFirebaseAuth();

  static FirebaseAuth? _tryFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase Auth unavailable: $e');
      return null;
    }
  }
  final FirestoreService _firestore = FirestoreService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isPsychologist => _currentUser?.role == UserRole.psychologist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool _sessionLoaded = false;

  /// False until the saved session (if any) has been read from disk.
  bool get sessionLoaded => _sessionLoaded;

  AuthService() {
    _restoreSession();
    // Listen to Firebase auth state changes for auto-login
    _auth?.authStateChanges().listen(_onAuthStateChanged);
  }

  static bool _isLocalId(String? id) =>
      id != null && (id.startsWith('demo_') || id.startsWith('local_'));

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
    });
    return _startLocalSession(AppUser(
      id: id,
      name: name.trim(),
      email: '$user@mindcare.local',
      role: role,
      psychologistId: role == UserRole.psychologist ? 'psy_001' : null,
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
      psychologistId: role == UserRole.psychologist ? 'psy_001' : null,
    ));
  }

  Future<bool> _startLocalSession(AppUser user) async {
    _currentUser = user;
    await _saveSession(user);
    notifyListeners();
    return true;
  }

  bool _finishError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  bool _fail(String message) {
    _error = message;
    notifyListeners();
    return false;
  }

  /// Role chosen on the login screen, used when the Firestore profile
  /// can't be read (test setup without Firestore).
  UserRole _pendingRole = UserRole.patient;
  String? _pendingPsychologistId;

  /// Called when Firebase auth state changes (login, logout, app start).
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      if (!_isLocalId(_currentUser?.id)) {
        _currentUser = null;
        notifyListeners();
      }
      return;
    }
    if (_currentUser?.id == firebaseUser.uid) return;

    // Fetch user profile from Firestore (never wait on it for long)
    Map<String, dynamic>? userData;
    try {
      userData = await _firestore
          .getUser(firebaseUser.uid)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    if (_currentUser?.id == firebaseUser.uid) return;

    _currentUser = AppUser(
      id: firebaseUser.uid,
      name: (userData?['name'] as String?) ??
          firebaseUser.displayName ??
          'User',
      email: firebaseUser.email ?? '',
      role: userData != null
          ? (userData['role'] == 'psychologist'
              ? UserRole.psychologist
              : UserRole.patient)
          : _pendingRole,
      psychologistId: (userData?['psychologistId'] as String?) ??
          _pendingPsychologistId,
    );
    notifyListeners();
  }

  /// Sign in with a Google account (no password, no 2FA).
  ///
  /// The Google provider must be enabled in Firebase Console ->
  /// Authentication -> Sign-in method.
  Future<bool> signInWithGoogle({
    required UserRole role,
    String? psychologistId,
  }) async {
    _isLoading = true;
    _error = null;
    _pendingRole = role;
    _pendingPsychologistId = psychologistId;
    notifyListeners();

    try {
      final auth = _auth;
      if (auth == null) {
        return _finishError('Google sign-in is unavailable right now.');
      }
      final provider = GoogleAuthProvider();
      final credential = kIsWeb
          ? await auth.signInWithPopup(provider)
          : await auth.signInWithProvider(provider);
      final user = credential.user!;

      _currentUser = AppUser(
        id: user.uid,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        role: role,
        psychologistId: psychologistId,
      );

      // Save the profile in the background; login must not depend on it.
      unawaited(_firestore
          .saveUser(
            uid: user.uid,
            name: _currentUser!.name,
            email: _currentUser!.email,
            role: role == UserRole.psychologist ? 'psychologist' : 'patient',
          )
          .timeout(const Duration(seconds: 8))
          .catchError((Object e) => debugPrint('Profile save failed: $e')));

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Google sign-in failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fixed fake accounts for the test build. Their ids never change, so
  /// everything saved under them is still there when you come back.
  static const demoPatientId = 'demo_patient';
  static const demoPsychologistId = 'demo_psychologist';

  /// Log in as a fake user or psychologist without Firebase. Data is kept
  /// in the on-device [LocalStore].
  Future<bool> signInAsDemo(UserRole role) async {
    _error = null;
    _currentUser = role == UserRole.psychologist
        ? const AppUser(
            id: demoPsychologistId,
            name: 'Dr. Sarah Mitchell',
            email: 'doctor.demo@mindcare.app',
            role: UserRole.psychologist,
            psychologistId: 'psy_001',
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

  /// True for the fake accounts above (data goes to LocalStore, not Firestore).
  bool get isDemo =>
      _currentUser?.id == demoPatientId ||
      _currentUser?.id == demoPsychologistId;

  /// Sign out.
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Firebase signOut failed: $e');
    }
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

  /// Map Firebase error codes to user-friendly messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'configuration-not-found':
        return 'Firebase Authentication is not set up for this project yet. '
            'In Firebase Console open Authentication, click Get started, then '
            'enable the Google sign-in method. Or use the demo login below.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled. In Firebase Console open '
            'Authentication > Sign-in method and enable Google.';
      case 'unauthorized-domain':
        return 'This domain is not authorised. In Firebase Console open '
            'Authentication > Settings > Authorized domains and add it.';
      case 'popup-blocked':
        return 'The sign-in popup was blocked. Allow popups and try again.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Sign-in was cancelled.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Authentication error ($code). Please try again.';
    }
  }
}
