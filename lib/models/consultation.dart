import 'screening_result.dart';

/// Status of a consultation request.
enum ConsultationStatus {
  pending,
  accepted,
  declined,
  completed,

  /// The patient said the booked time doesn't work and asked for another.
  rescheduleRequested;

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
      case ConsultationStatus.rescheduleRequested:
        return 'Reschedule requested';
    }
  }
}

/// One message in the chat between a patient and their psychologist.
class DirectMessage {
  final String id;

  /// True if the psychologist wrote it, false if the patient did.
  final bool fromDoctor;
  final String text;
  final DateTime sentAt;

  DirectMessage({
    required this.id,
    required this.fromDoctor,
    required this.text,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromDoctor': fromDoctor,
        'text': text,
        'sentAt': sentAt.millisecondsSinceEpoch,
      };

  factory DirectMessage.fromJson(Map<String, dynamic> json) => DirectMessage(
        id: json['id'] as String,
        fromDoctor: json['fromDoctor'] as bool,
        text: json['text'] as String,
        sentAt: DateTime.fromMillisecondsSinceEpoch(json['sentAt'] as int),
      );
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

  /// Why the patient can't make the booked time (set with
  /// [ConsultationStatus.rescheduleRequested]).
  String? rescheduleReason;
  DateTime? rescheduleRequestedAt;

  /// Chat between the patient and the psychologist about this request.
  final List<DirectMessage> messages;
  DateTime? patientReadAt;
  DateTime? doctorReadAt;

  /// Messages the other side wrote that [asDoctor]'s side has not opened yet.
  int unreadFor({required bool asDoctor}) {
    final readAt = asDoctor ? doctorReadAt : patientReadAt;
    return messages
        .where((m) =>
            m.fromDoctor != asDoctor &&
            (readAt == null || m.sentAt.isAfter(readAt)))
        .length;
  }

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
    this.rescheduleReason,
    this.rescheduleRequestedAt,
    List<DirectMessage>? messages,
    this.patientReadAt,
    this.doctorReadAt,
  })  : messages = messages ?? [],
        requestedAt = requestedAt ?? DateTime.now();

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
        'rescheduleReason': rescheduleReason,
        'rescheduleRequestedAt': rescheduleRequestedAt?.millisecondsSinceEpoch,
        'messages': messages.map((m) => m.toJson()).toList(),
        'patientReadAt': patientReadAt?.millisecondsSinceEpoch,
        'doctorReadAt': doctorReadAt?.millisecondsSinceEpoch,
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
      rescheduleReason: json['rescheduleReason'] as String?,
      rescheduleRequestedAt: json['rescheduleRequestedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              json['rescheduleRequestedAt'] as int),
      messages: [
        for (final m in (json['messages'] as List? ?? const []))
          DirectMessage.fromJson(m as Map<String, dynamic>),
      ],
      patientReadAt: json['patientReadAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['patientReadAt'] as int),
      doctorReadAt: json['doctorReadAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['doctorReadAt'] as int),
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
