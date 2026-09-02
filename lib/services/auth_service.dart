import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// Simple demo authentication service (no Firebase for prototype).
class AuthService extends ChangeNotifier {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isPsychologist => _currentUser?.role == UserRole.psychologist;

  /// Demo users for the prototype.
  static const _demoPatient = AppUser(
    id: 'user_001',
    name: 'Demo User',
    email: 'demo@mindcare.app',
    role: UserRole.patient,
  );

  static const _demoPsychologist = AppUser(
    id: 'user_psy_001',
    name: 'Dr. Sarah Mitchell',
    email: 'dr.mitchell@mindcare.app',
    role: UserRole.psychologist,
    psychologistId: 'psy_001',
  );

  /// Log in as demo patient.
  void loginAsPatient(String name) {
    _currentUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.isEmpty ? _demoPatient.name : name,
      email: _demoPatient.email,
      role: UserRole.patient,
    );
    notifyListeners();
  }

  /// Log in as demo psychologist.
  void loginAsPsychologist() {
    _currentUser = _demoPsychologist;
    notifyListeners();
  }

  /// Log out.
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
