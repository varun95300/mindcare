import 'screening_result.dart';

/// Status of a consultation request.
enum ConsultationStatus {
  pending,
  accepted,
  declined,
  completed;

  String get label {
    switch (this) {
      case ConsultationStatus.pending:
        return 'Pending';
      case ConsultationStatus.accepted:
        return 'Accepted';
      case ConsultationStatus.declined:
        return 'Declined';
      case ConsultationStatus.completed:
        return 'Completed';
    }
  }
}

/// A consultation request from a user to a psychologist.
/// Contains the user's screening report so the psychologist can review it.
class ConsultationRequest {
  final String id;
  final String patientName;
  final String patientEmail;
  final String psychologistId;
  final ScreeningResult screeningResult;
  final DateTime requestedAt;
  ConsultationStatus status;
  final String? message; // Optional message from the user

  ConsultationRequest({
    required this.id,
    required this.patientName,
    required this.patientEmail,
    required this.psychologistId,
    required this.screeningResult,
    required this.status,
    this.message,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();

  /// Time ago string for display.
  String get timeAgoLabel {
    final diff = DateTime.now().difference(requestedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${requestedAt.day}/${requestedAt.month}/${requestedAt.year}';
  }
}
