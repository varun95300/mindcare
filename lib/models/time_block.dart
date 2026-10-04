/// Length of every appointment slot on the calendar.
const int kAppointmentMinutes = 60;

/// A stretch of time a psychologist has marked as unavailable.
class TimeBlock {
  final String id;
  final String psychologistId;
  final DateTime start;
  final DateTime end;
  final String reason;

  const TimeBlock({
    required this.id,
    required this.psychologistId,
    required this.start,
    required this.end,
    this.reason = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'psychologistId': psychologistId,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'reason': reason,
      };

  factory TimeBlock.fromJson(Map<String, dynamic> json) => TimeBlock(
        id: json['id'] as String,
        psychologistId: json['psychologistId'] as String,
        start: DateTime.fromMillisecondsSinceEpoch(json['start'] as int),
        end: DateTime.fromMillisecondsSinceEpoch(json['end'] as int),
        reason: json['reason'] as String? ?? '',
      );
}

/// Something that overlaps a time the psychologist is trying to book.
class ScheduleConflict {
  final String title;
  final DateTime start;
  final DateTime end;

  /// True for a blocked-off period, false for another appointment.
  final bool isBlock;

  const ScheduleConflict({
    required this.title,
    required this.start,
    required this.end,
    required this.isBlock,
  });
}

/// Whether two half-open time ranges overlap.
bool timesOverlap(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) =>
    aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
