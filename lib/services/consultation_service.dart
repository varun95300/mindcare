import 'package:flutter/material.dart';
import '../models/consultation.dart';
import '../models/screening_result.dart';
import '../models/quiz_question.dart';
import '../models/domain_evidence.dart';
import '../models/text_analysis.dart';
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

  /// A service with no loading or seeding (used to build seed data).
  ConsultationService.empty();

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
      // New demo requests shipped in a later version are merged in once.
      final meta = await store.readAll('meta');
      final savedVersion =
          meta.isEmpty ? 0 : (meta.first['seedVersion'] as int? ?? 0);
      if (savedVersion < _seedVersion) {
        _mergeSeeds();
        _persist();
      }
      notifyListeners();
    } else {
      addSeedRequests();
      _persist();
    }
    await store.upsert('meta', {'id': 'meta', 'seedVersion': _seedVersion});
  }

  /// Bump when [addSeedRequests] gains new demo requests.
  static const _seedVersion = 2;

  /// Adds seed requests that are missing and refreshes the report of ones
  /// already saved, keeping any status the psychologist already set.
  void _mergeSeeds() {
    final fresh = ConsultationService.empty().._buildSeeds();
    for (final seed in fresh._requests) {
      final i = _requests.indexWhere((r) => r.id == seed.id);
      if (i < 0) {
        _requests.add(seed);
      } else if (seed.id.startsWith('req_seed_')) {
        final old = _requests[i];
        _requests[i] = ConsultationRequest(
          id: old.id,
          patientName: old.patientName,
          patientEmail: old.patientEmail,
          psychologistId: old.psychologistId,
          screeningResult: seed.screeningResult
            ..patientNote = old.screeningResult.patientNote,
          status: old.status,
          message: old.message,
          requestedAt: old.requestedAt,
          scheduledAt: old.scheduledAt,
          psychologistNote: old.psychologistNote,
          rescheduleReason: old.rescheduleReason,
          rescheduleRequestedAt: old.rescheduleRequestedAt,
        );
      }
    }
  }

  void _persist() {
    LocalStore.instance
        .writeAll(_collection, _requests.map((r) => r.toJson()).toList());
  }

  /// Wipe saved data and go back to the seeded demo requests.
  Future<void> resetDemoData() async {
    _requests.clear();
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
        .where((r) =>
            r.psychologistId == psychologistId &&
            r.scheduledAt != null &&
            r.status == ConsultationStatus.accepted)
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
    request.rescheduleReason = null;
    request.rescheduleRequestedAt = null;
    _persist();
    notifyListeners();
  }

  /// The patient can't make the booked time and asks for another one.
  void requestReschedule(String requestId, {String? reason}) {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = ConsultationStatus.rescheduleRequested;
    request.rescheduleReason =
        reason?.trim().isEmpty ?? true ? null : reason!.trim();
    request.rescheduleRequestedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  /// Delete a single request (patient cancels, or psychologist clears it).
  void removeRequest(String requestId) {
    _requests.removeWhere((r) => r.id == requestId);
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
    _buildSeeds();
    notifyListeners();
  }

  void _buildSeeds() {

    ScreeningResult buildResult({
      required ScreeningDomain primary,
      required ScreeningDomain secondary,
      required double primaryScore,
      required double secondaryScore,
      required List<String> observations,
      required String recommendation,
      RiskLevel risk = RiskLevel.none,
      List<String> riskFlags = const [],
      Map<String, double> emotions = const {},
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
        peakRiskLevel: risk,
        riskFlags: riskFlags,
        emotionSummary: emotions,
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
          risk: RiskLevel.moderate,
          riskFlags: const ['panic attacks'],
          emotions: const {'fear': 7.5, 'overwhelm': 3.0},
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
          risk: RiskLevel.low,
          emotions: const {'overwhelm': 6.0, 'exhaustion': 3.5},
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
      ConsultationRequest(
        id: 'req_seed_4',
        patientName: 'Kabir Singh',
        patientEmail: 'kabir.demo@mindcare.app',
        psychologistId: 'psy_002',
        screeningResult: buildResult(
          primary: ScreeningDomain.depression,
          secondary: ScreeningDomain.anxiety,
          primaryScore: 0.82,
          secondaryScore: 0.46,
          observations: const [
            'Frequently selected higher responses for questions related to depression.',
            'Several responses showed moderate indicators across anxiety.',
          ],
          recommendation:
              'May benefit from speaking with a professional experienced in depression.',
          risk: RiskLevel.high,
          riskFlags: const ['no reason to live', 'hopeless'],
          emotions: const {'hopelessness': 8.0, 'sadness': 5.5, 'loneliness': 2.5},
        )..patientNote =
            "I've stopped going to classes and honestly there's no reason to live like this.",
        status: ConsultationStatus.pending,
        requestedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ConsultationRequest(
        id: 'req_seed_5',
        patientName: 'Neha Gupta',
        patientEmail: 'neha.demo@mindcare.app',
        psychologistId: 'psy_003',
        screeningResult: buildResult(
          primary: ScreeningDomain.interpersonal,
          secondary: ScreeningDomain.stress,
          primaryScore: 0.69,
          secondaryScore: 0.41,
          observations: const [
            'Your responses showed a notably stronger pattern in Interpersonal / Trauma compared to other areas.',
          ],
          recommendation:
              'May benefit from speaking with a professional experienced in interpersonal difficulties.',
          emotions: const {'anger': 5.0, 'loneliness': 4.0},
        )..patientNote =
            'Things at home have been tense for months and I feel like nobody listens.',
        status: ConsultationStatus.pending,
        requestedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ConsultationRequest(
        id: 'req_seed_6',
        patientName: 'Aditya Rao',
        patientEmail: 'aditya.demo@mindcare.app',
        psychologistId: 'psy_004',
        screeningResult: buildResult(
          primary: ScreeningDomain.interpersonal,
          secondary: ScreeningDomain.depression,
          primaryScore: 0.74,
          secondaryScore: 0.33,
          observations: const [
            'Frequently selected higher responses for questions related to interpersonal / trauma.',
          ],
          recommendation:
              'May benefit from speaking with a trauma-informed professional.',
          risk: RiskLevel.low,
          emotions: const {'loneliness': 5.5, 'shame': 3.0},
        ),
        status: ConsultationStatus.pending,
        requestedAt: DateTime.now().subtract(const Duration(hours: 20)),
      ),
      ConsultationRequest(
        id: 'req_seed_7',
        patientName: 'Zoya Ali',
        patientEmail: 'zoya.demo@mindcare.app',
        psychologistId: 'psy_008',
        screeningResult: buildResult(
          primary: ScreeningDomain.anxiety,
          secondary: ScreeningDomain.stress,
          primaryScore: 0.66,
          secondaryScore: 0.5,
          observations: const [
            'Several responses showed moderate indicators across anxiety and stress.',
          ],
          recommendation:
              'May benefit from speaking with a professional experienced in exam-related anxiety.',
          emotions: const {'fear': 6.0, 'overwhelm': 4.5},
        )..patientNote = 'My final exams start next week and I keep freezing up.',
        status: ConsultationStatus.accepted,
        requestedAt: DateTime.now().subtract(const Duration(days: 1)),
        scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
        psychologistNote: 'Happy to help you prepare. See you then.',
      ),
    ]);
    notifyListeners();
  }
}
