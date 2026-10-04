import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Firebase-backed authentication service.
///
/// Handles sign-up, sign-in, sign-out, and auth state persistence.
/// User role (patient / psychologist) is stored in Firestore.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isPsychologist => _currentUser?.role == UserRole.psychologist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthService() {
    // Listen to Firebase auth state changes for auto-login
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Called when Firebase auth state changes (login, logout, app start).
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    // Fetch user profile from Firestore
    try {
      final userData = await _firestore.getUser(firebaseUser.uid);
      if (userData != null) {
        _currentUser = AppUser(
          id: firebaseUser.uid,
          name: userData['name'] as String? ?? 'User',
          email: firebaseUser.email ?? '',
          role: userData['role'] == 'psychologist'
              ? UserRole.psychologist
              : UserRole.patient,
          psychologistId: userData['psychologistId'] as String?,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  /// Sign up a new user with email, password, name, and role.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? psychologistId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Save profile to Firestore
      await _firestore.saveUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        role: role == UserRole.psychologist ? 'psychologist' : 'patient',
      );

      _currentUser = AppUser(
        id: uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        psychologistId: psychologistId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in an existing user.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Auth state listener will handle setting _currentUser
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
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
      default:
        return 'Authentication error. Please try again.';
    }
  }
}
