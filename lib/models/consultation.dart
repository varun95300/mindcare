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

  /// Set when the psychologist accepts and schedules an appointment.
  DateTime? scheduledAt;

  /// A short note the psychologist writes to the patient upon accepting —
  /// the patient sees this (unlike the screening result itself).
  String? psychologistNote;

  ConsultationRequest({
    required this.id,
    required this.patientName,
    required this.patientEmail,
    required this.psychologistId,
    required this.screeningResult,
    required this.status,
    this.message,
    DateTime? requestedAt,
    this.scheduledAt,
    this.psychologistNote,
  }) : requestedAt = requestedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientName': patientName,
        'patientEmail': patientEmail,
        'psychologistId': psychologistId,
        'screeningResult': screeningResult.toJson(),
        'requestedAt': requestedAt.millisecondsSinceEpoch,
        'status': status.name,
        'message': message,
        'scheduledAt': scheduledAt?.millisecondsSinceEpoch,
        'psychologistNote': psychologistNote,
      };

  factory ConsultationRequest.fromJson(Map<String, dynamic> json) {
    return ConsultationRequest(
      id: json['id'] as String,
      patientName: json['patientName'] as String,
      patientEmail: json['patientEmail'] as String,
      psychologistId: json['psychologistId'] as String,
      screeningResult: ScreeningResult.fromJson(
          json['screeningResult'] as Map<String, dynamic>),
      requestedAt:
          DateTime.fromMillisecondsSinceEpoch(json['requestedAt'] as int),
      status: ConsultationStatus.values.byName(json['status'] as String),
      message: json['message'] as String?,
      scheduledAt: json['scheduledAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['scheduledAt'] as int),
      psychologistNote: json['psychologistNote'] as String?,
    );
  }

  /// Time ago string for display.
  String get timeAgoLabel {
    final diff = DateTime.now().difference(requestedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${requestedAt.day}/${requestedAt.month}/${requestedAt.year}';
  }

  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Human-readable label for the scheduled appointment, e.g.
  /// "Monday, 15 Dec at 4:30 PM".
  String? get scheduledAtLabel =>
      scheduledAt == null ? null : formatDateTime(scheduledAt!);

  static String formatDateTime(DateTime dt) {
    final weekday = _weekdayNames[dt.weekday - 1];
    final month = _monthNames[dt.month - 1];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$weekday, ${dt.day} $month at $hour12:$minute $period';
  }
}
