/// Urgency the patient assigns when requesting a video call.
enum CallUrgency {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case CallUrgency.low:
        return 'Low';
      case CallUrgency.medium:
        return 'Medium';
      case CallUrgency.high:
        return 'High';
    }
  }

  String get description {
    switch (this) {
      case CallUrgency.low:
        return 'Whenever you can';
      case CallUrgency.medium:
        return 'Within a few days';
      case CallUrgency.high:
        return 'Need to talk soon';
    }
  }

  String get emoji {
    switch (this) {
      case CallUrgency.low:
        return '🟢';
      case CallUrgency.medium:
        return '🟡';
      case CallUrgency.high:
        return '🔴';
    }
  }
}

/// Lifecycle of a call request.
enum CallStatus {
  pending,
  scheduled,
  active,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case CallStatus.pending:
        return 'Pending';
      case CallStatus.scheduled:
        return 'Scheduled';
      case CallStatus.active:
        return 'In Progress';
      case CallStatus.completed:
        return 'Completed';
      case CallStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// A patient's request for a video call with their psychologist.
class CallRequest {
  final String id;
  final String patientName;
  final String patientEmail;
  final String psychologistId;

  /// Short free-text context the patient writes ("I've been having panic
  /// attacks again").
  final String? note;
  final CallUrgency urgency;
  CallStatus status;
  final DateTime requestedAt;

  /// Set by the psychologist when they schedule the call.
  DateTime? scheduledAt;

  /// Duration the psychologist picks (30, 45 or 60 min).
  int durationMinutes;

  /// Agora channel name — generated when the call is scheduled.
  String? channelName;

  /// The consultation request this call is related to (if any).
  final String? consultationId;

  CallRequest({
    required this.id,
    required this.patientName,
    required this.patientEmail,
    required this.psychologistId,
    this.note,
    this.urgency = CallUrgency.medium,
    this.status = CallStatus.pending,
    DateTime? requestedAt,
    this.scheduledAt,
    this.durationMinutes = 30,
    this.channelName,
    this.consultationId,
  }) : requestedAt = requestedAt ?? DateTime.now();

  /// Whether the "Join Call" button should be active for either side.
  bool get isJoinable {
    if (status == CallStatus.active) return true;
    if (status != CallStatus.scheduled || scheduledAt == null) return false;
    final now = DateTime.now();
    final windowStart = scheduledAt!.subtract(const Duration(minutes: 5));
    final windowEnd =
        scheduledAt!.add(Duration(minutes: durationMinutes + 10));
    return now.isAfter(windowStart) && now.isBefore(windowEnd);
  }

  /// Countdown text shown before a scheduled call becomes joinable.
  String? get countdownLabel {
    if (status != CallStatus.scheduled || scheduledAt == null) return null;
    final diff = scheduledAt!.difference(DateTime.now());
    if (diff.isNegative) return null;
    if (diff.inDays > 0) return 'In ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return 'In ${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 5) return 'In ${diff.inMinutes}m';
    return null; // within join window
  }

  /// Human-readable scheduled time.
  String? get scheduledAtLabel {
    if (scheduledAt == null) return null;
    return _formatDateTime(scheduledAt!);
  }

  /// Time-ago label for the request.
  String get timeAgoLabel {
    final diff = DateTime.now().difference(requestedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${requestedAt.day}/${requestedAt.month}/${requestedAt.year}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientName': patientName,
        'patientEmail': patientEmail,
        'psychologistId': psychologistId,
        'note': note,
        'urgency': urgency.name,
        'status': status.name,
        'requestedAt': requestedAt.millisecondsSinceEpoch,
        'scheduledAt': scheduledAt?.millisecondsSinceEpoch,
        'durationMinutes': durationMinutes,
        'channelName': channelName,
        'consultationId': consultationId,
      };

  factory CallRequest.fromJson(Map<String, dynamic> json) => CallRequest(
        id: json['id'] as String,
        patientName: json['patientName'] as String,
        patientEmail: json['patientEmail'] as String,
        psychologistId: json['psychologistId'] as String,
        note: json['note'] as String?,
        urgency: CallUrgency.values.byName(json['urgency'] as String),
        status: CallStatus.values.byName(json['status'] as String),
        requestedAt:
            DateTime.fromMillisecondsSinceEpoch(json['requestedAt'] as int),
        scheduledAt: json['scheduledAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json['scheduledAt'] as int),
        durationMinutes: json['durationMinutes'] as int? ?? 30,
        channelName: json['channelName'] as String?,
        consultationId: json['consultationId'] as String?,
      );

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDateTime(DateTime dt) {
    final weekday = _weekdays[dt.weekday - 1];
    final month = _months[dt.month - 1];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$weekday, ${dt.day} $month at $hour12:$minute $period';
  }
}

