import 'package:flutter/material.dart';
import '../models/consultation.dart';
import '../models/screening_result.dart';

/// In-memory consultation service shared between user and psychologist views.
/// Stores consultation requests so the psychologist can see user reports.
class ConsultationService extends ChangeNotifier {
  final List<ConsultationRequest> _requests = [];

  /// All consultation requests.
  List<ConsultationRequest> get allRequests => List.unmodifiable(_requests);

  /// Requests for a specific psychologist.
  List<ConsultationRequest> requestsForPsychologist(String psychologistId) {
    return _requests
        .where((r) => r.psychologistId == psychologistId)
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  /// Check if a request already exists for this psychologist from this session.
  bool hasRequestFor(String psychologistId, String patientName) {
    return _requests.any(
      (r) => r.psychologistId == psychologistId && r.patientName == patientName,
    );
  }

  /// Send a consultation request (user action).
  ConsultationRequest sendRequest({
    required String patientName,
    required String patientEmail,
    required String psychologistId,
    required ScreeningResult screeningResult,
    String? message,
  }) {
    final request = ConsultationRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      patientName: patientName,
      patientEmail: patientEmail,
      psychologistId: psychologistId,
      screeningResult: screeningResult,
      status: ConsultationStatus.pending,
      message: message,
    );
    _requests.add(request);
    notifyListeners();
    return request;
  }

  /// Accept a consultation request (psychologist action).
  void acceptRequest(String requestId) {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = ConsultationStatus.accepted;
    notifyListeners();
  }

  /// Decline a consultation request (psychologist action).
  void declineRequest(String requestId) {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = ConsultationStatus.declined;
    notifyListeners();
  }

  /// Add seed/demo data so the psychologist dashboard isn't empty.
  void addSeedRequests() {
    // Only add if empty (avoid duplicates on hot restart)
    if (_requests.isNotEmpty) return;
    // We don't add seed data here anymore — real requests will appear
    // when the user sends them through the flow.
  }
}
