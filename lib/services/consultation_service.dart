import 'package:flutter/material.dart';
import '../models/consultation.dart';
import '../models/screening_result.dart';
import '../models/quiz_question.dart';
import '../models/domain_evidence.dart';
import 'local_store.dart';

/// Consultation service shared between user and psychologist views.
/// Stores consultation requests so the psychologist can see user reports.
///
/// Requests are saved to the on-device [LocalStore] after every change, so
/// they survive switching roles and restarting the app.
class ConsultationService extends ChangeNotifier {
  static const _collection = 'consultations';
  final List<ConsultationRequest> _requests = [];

  ConsultationService() {
    _load();
  }

  /// Load saved requests; on the very first run, seed the demo ones.
  Future<void> _load() async {
    final store = LocalStore.instance;
    if (await store.exists(_collection)) {
      for (final doc in await store.readAll(_collection)) {
        try {
          _requests.add(ConsultationRequest.fromJson(doc));
        } catch (e) {
          debugPrint('Skipping unreadable saved request: $e');
        }
      }
      notifyListeners();
    } else {
      addSeedRequests();
      _persist();
    }
  }

  void _persist() {
    LocalStore.instance
        .writeAll(_collection, _requests.map((r) => r.toJson()).toList());
  }

  /// Wipe saved data and go back to the seeded demo requests.
  Future<void> resetDemoData() async {
    _requests.clear();
    await LocalStore.instance.clearAll();
    addSeedRequests();
    _persist();
  }

  /// All consultation requests.
  List<ConsultationRequest> get allRequests => List.unmodifiable(_requests);

  /// Requests for a specific psychologist.
  List<ConsultationRequest> requestsForPsychologist(String psychologistId) {
    return _requests
        .where((r) => r.psychologistId == psychologistId)
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  /// All requests a patient has sent (any psychologist), newest first.
  List<ConsultationRequest> requestsForPatient(String patientEmail) {
    return _requests
        .where((r) => r.patientEmail == patientEmail)
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  /// Delete every request a patient sent (used by "start a new session").
  void removeForPatient(String patientEmail) {
    _requests.removeWhere((r) => r.patientEmail == patientEmail);
    _persist();
    notifyListeners();
  }

  /// Check if a request already exists for this psychologist from this session.
  bool hasRequestFor(String psychologistId, String patientName) {
    return _requests.any(
      (r) => r.psychologistId == psychologistId && r.patientName == patientName,
    );
  }

  /// The existing request (if any) for this psychologist from this patient.
  ConsultationRequest? requestFor(String psychologistId, String patientName) {
    for (final r in _requests) {
      if (r.psychologistId == psychologistId && r.patientName == patientName) {
        return r;
      }
    }
    return null;
  }

  /// All appointments a psychologist already has scheduled, soonest first —
  /// shown to them while picking a new time so they can avoid clashes.
  List<ConsultationRequest> scheduledAppointments(String psychologistId) {
    return _requests
        .where((r) => r.psychologistId == psychologistId && r.scheduledAt != null)
        .toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
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
    _persist();
    notifyListeners();
    return request;
  }

  /// Accept a consultation request (psychologist action).
  void acceptRequest(String requestId) {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = ConsultationStatus.accepted;
    _persist();
    notifyListeners();
  }

  /// Accept a request, schedule an appointment time, and leave a note for
  /// the patient to see when they check back.
  void acceptAndSchedule(
    String requestId, {
    required DateTime scheduledAt,
    String? note,
  }) {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = ConsultationStatus.accepted;
    request.scheduledAt = scheduledAt;
    request.psychologistNote = note?.trim().isEmpty ?? true ? null : note!.trim();
    _persist();
    notifyListeners();
  }

  /// Decline a consultation request (psychologist action).
  void declineRequest(String requestId) {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = ConsultationStatus.declined;
    _persist();
    notifyListeners();
  }

  /// Add seed/demo data so the psychologist dashboard isn't empty on first
  /// run. Real requests sent through the app (e.g. by the demo student)
  /// are appended on top of these, not replaced by them.
  void addSeedRequests() {
    if (_requests.isNotEmpty) return;

    ScreeningResult buildResult({
      required ScreeningDomain primary,
      required ScreeningDomain secondary,
      required double primaryScore,
      required double secondaryScore,
      required List<String> observations,
      required String recommendation,
    }) {
      final scores = {for (final d in ScreeningDomain.values) d: 0.05};
      scores[primary] = primaryScore;
      scores[secondary] = secondaryScore;
      return ScreeningResult(
        primaryDomain: primary,
        secondaryDomain: secondary,
        normalizedScores: scores,
        severityLabels: {
          for (final entry in scores.entries)
            entry.key: DomainEvidence.severityLabel(entry.value),
        },
        answers: const [],
        keyObservations: observations,
        methodologyExplanation:
            'This screening asked adaptive questions selected based on '
            'previous responses, contributing evidence toward four screening '
            'areas: Anxiety, Depression, Stress, and Interpersonal/Trauma.',
        disclaimer:
            'This is a screening result, not a clinical diagnosis. Only a '
            'qualified mental-health professional can provide a diagnosis.',
        recommendation: recommendation,
      );
    }

    _requests.addAll([
      ConsultationRequest(
        id: 'req_seed_1',
        patientName: 'Ananya Verma',
        patientEmail: 'ananya.demo@mindcare.app',
        psychologistId: 'psy_001',
        screeningResult: buildResult(
          primary: ScreeningDomain.anxiety,
          secondary: ScreeningDomain.stress,
          primaryScore: 0.78,
          secondaryScore: 0.52,
          observations: const [
            'Frequently selected higher responses for questions related to anxiety.',
            'Several responses showed moderate indicators across stress.',
          ],
          recommendation:
              'May benefit from speaking with a professional experienced in anxiety and stress.',
        )..patientNote =
            "I've been having panic attacks before exams and I don't know how to stop them.",
        status: ConsultationStatus.pending,
        requestedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ConsultationRequest(
        id: 'req_seed_2',
        patientName: 'Rohan Mehta',
        patientEmail: 'rohan.demo@mindcare.app',
        psychologistId: 'psy_001',
        screeningResult: buildResult(
          primary: ScreeningDomain.stress,
          secondary: ScreeningDomain.depression,
          primaryScore: 0.71,
          secondaryScore: 0.28,
          observations: const [
            'Frequently selected higher responses for questions related to stress.',
            'Responses related to depression were comparatively less prominent.',
          ],
          recommendation:
              'May benefit from speaking with a professional experienced in stress management.',
        )..patientNote =
            "Work has been overwhelming lately and I can't switch off, even at night.",
        status: ConsultationStatus.accepted,
        requestedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ConsultationRequest(
        id: 'req_seed_3',
        patientName: 'Simran Kaur',
        patientEmail: 'simran.demo@mindcare.app',
        psychologistId: 'psy_001',
        screeningResult: buildResult(
          primary: ScreeningDomain.anxiety,
          secondary: ScreeningDomain.interpersonal,
          primaryScore: 0.55,
          secondaryScore: 0.24,
          observations: const [
            'Several responses showed moderate indicators across anxiety.',
          ],
          recommendation:
              'May benefit from speaking with a professional experienced in anxiety.',
        ),
        status: ConsultationStatus.pending,
        message: 'Hoping to find a time to talk sometime this week, thank you.',
        requestedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
    ]);
    notifyListeners();
  }
}
