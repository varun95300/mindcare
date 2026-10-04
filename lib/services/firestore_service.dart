import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/screening_result.dart';
import '../models/quiz_question.dart';
import '../models/domain_evidence.dart';
import '../models/chat_message.dart';

/// Central service for all Firestore read/write operations.
///
/// Collections:
///   users/{uid}           — user profile (name, email, role)
///   psychologists/{id}    — psychologist profiles
///   screenings/{id}       — completed screening results
///   screenings/{id}/chat_messages/{msgId} — chat conversation
///   consultations/{id}    — consultation requests
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════════════════════════

  /// Create or update a user profile.
  Future<void> saveUser({
    required String uid,
    required String name,
    required String email,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user data by UID.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ═══════════════════════════════════════════════════════════════════
  // PSYCHOLOGISTS
  // ═══════════════════════════════════════════════════════════════════

  /// Get all psychologists.
  Future<List<Map<String, dynamic>>> getAllPsychologists() async {
    final snapshot = await _db.collection('psychologists').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get a psychologist by ID.
  Future<Map<String, dynamic>?> getPsychologist(String id) async {
    final doc = await _db.collection('psychologists').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// Seed psychologist data (idempotent).
  Future<void> seedPsychologists(List<Map<String, dynamic>> psychologists) async {
    final batch = _db.batch();
    for (final psy in psychologists) {
      final id = psy['id'] as String;
      final ref = _db.collection('psychologists').doc(id);
      batch.set(ref, psy, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCREENINGS
  // ═══════════════════════════════════════════════════════════════════

  /// Save a completed screening result.
  Future<String> saveScreening({
    required String patientId,
    required ScreeningResult result,
  }) async {
    final docRef = _db.collection('screenings').doc();
    await docRef.set({
      'patientId': patientId,
      'primaryDomain': result.primaryDomain.name,
      'secondaryDomain': result.secondaryDomain?.name,
      'normalizedScores':
          result.normalizedScores.map((k, v) => MapEntry(k.name, v)),
      'severityLabels':
          result.severityLabels.map((k, v) => MapEntry(k.name, v)),
      'keyObservations': result.keyObservations,
      'methodologyExplanation': result.methodologyExplanation,
      'disclaimer': result.disclaimer,
      'recommendation': result.recommendation,
      'patientNote': result.patientNote,
      'totalQuestions': result.totalQuestions,
      'completedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get a screening by ID.
  Future<Map<String, dynamic>?> getScreening(String id) async {
    final doc = await _db.collection('screenings').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// Get all screenings for a patient.
  Future<List<Map<String, dynamic>>> getScreeningsForPatient(
      String patientId) async {
    final snapshot = await _db
        .collection('screenings')
        .where('patientId', isEqualTo: patientId)
        .orderBy('completedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  // CHAT MESSAGES (subcollection under screenings)
  // ═══════════════════════════════════════════════════════════════════

  /// Save a chat message under a screening.
  Future<void> saveChatMessage({
    required String screeningId,
    required ChatMessage message,
  }) async {
    await _db
        .collection('screenings')
        .doc(screeningId)
        .collection('chat_messages')
        .doc(message.id)
        .set(message.toMap());
  }

  /// Get all chat messages for a screening, ordered by creation time.
  Future<List<ChatMessage>> getChatMessages(String screeningId) async {
    final snapshot = await _db
        .collection('screenings')
        .doc(screeningId)
        .collection('chat_messages')
        .orderBy('createdAt')
        .get();
    return snapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.data()))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONSULTATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Send a consultation request.
  Future<String> sendConsultationRequest({
    required String patientId,
    required String patientName,
    required String patientEmail,
    required String psychologistId,
    required String screeningId,
    String? message,
  }) async {
    final docRef = _db.collection('consultations').doc();
    await docRef.set({
      'patientId': patientId,
      'patientName': patientName,
      'patientEmail': patientEmail,
      'psychologistId': psychologistId,
      'screeningId': screeningId,
      'status': 'pending',
      'message': message,
      'requestedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get consultation requests for a psychologist (real-time stream).
  Stream<List<Map<String, dynamic>>> consultationsForPsychologist(
      String psychologistId) {
    return _db
        .collection('consultations')
        .where('psychologistId', isEqualTo: psychologistId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Check if a consultation already exists for patient + psychologist.
  Future<bool> hasConsultation(String patientId, String psychologistId) async {
    final snapshot = await _db
        .collection('consultations')
        .where('patientId', isEqualTo: patientId)
        .where('psychologistId', isEqualTo: psychologistId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Accept and schedule a consultation.
  Future<void> acceptConsultation(
    String consultationId, {
    required DateTime scheduledAt,
    String? note,
  }) async {
    await _db.collection('consultations').doc(consultationId).update({
      'status': 'accepted',
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'psychologistNote': note,
    });
  }

  /// Decline a consultation.
  Future<void> declineConsultation(String consultationId) async {
    await _db.collection('consultations').doc(consultationId).update({
      'status': 'declined',
    });
  }

  /// Get scheduled appointments for a psychologist.
  Stream<List<Map<String, dynamic>>> scheduledAppointments(
      String psychologistId) {
    return _db
        .collection('consultations')
        .where('psychologistId', isEqualTo: psychologistId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}
