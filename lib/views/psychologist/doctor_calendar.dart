import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/consultation.dart';
import '../../models/time_block.dart';
import '../../services/consultation_service.dart';
import '../../widgets/ui.dart';

/// Week (or day, on phones) calendar for a psychologist: confirmed
/// appointments plus time they have blocked off as unavailable. Tap an empty
/// slot to block time, tap a block to remove it, tap an appointment to open it.
class DoctorCalendar extends StatefulWidget {
  final String psychologistId;
  final void Function(ConsultationRequest request) onOpenAppointment;

  const DoctorCalendar({
    super.key,
    required this.psychologistId,
    required this.onOpenAppointment,
  });

  @override
  State<DoctorCalendar> createState() => _DoctorCalendarState();
}

class _DoctorCalendarState extends State<DoctorCalendar> {
  static const int _startHour = 7;
  static const int _endHour = 21;
  static const double _rowHeight = 56;
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
    'Nov', 'Dec',
  ];

  DateTime _anchor = _dateOnly(DateTime.now());
  final ScrollController _scroll = ScrollController(initialScrollOffset: 56);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<DateTime> _days(bool wide) {
    if (!wide) return [_anchor];
    final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
    return [for (int i = 0; i < 7; i++) monday.add(Duration(days: i))];
  }

  void _shift(bool wide, int direction) {
    setState(() => _anchor = _anchor.add(Duration(days: (wide ? 7 : 1) * direction)));
  }

  String _clock(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  String _hourLabel(int h) => '${h % 12 == 0 ? 12 : h % 12} ${h < 12 ? 'AM' : 'PM'}';

  String _rangeLabel(List<DateTime> days) {
    final a = days.first;
    final b = days.last;
    if (days.length == 1) {
      return '${_weekdays[a.weekday - 1]}, ${a.day} ${_months[a.month - 1]} ${a.year}';
    }
    return '${a.day} ${_months[a.month - 1]} - ${b.day} ${_months[b.month - 1]} ${b.year}';
  }

  // ─── Block time ────────────────────────────────────────────────────

  Future<void> _addBlockDialog({DateTime? start}) async {
    final service = context.read<ConsultationService>();
    var day = _dateOnly(start ?? _anchor);
    var from = start != null
        ? TimeOfDay(hour: start.hour, minute: start.minute)
        : const TimeOfDay(hour: 13, minute: 0);
    var to = TimeOfDay(
        hour: (from.hour + 1).clamp(0, 23), minute: from.minute);
    final reason = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Block time'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark time when you are not available. Patients cannot be '
                  'scheduled into it without a warning.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                      '${_weekdays[day.weekday - 1]}, ${day.day} ${_months[day.month - 1]} ${day.year}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: day,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setLocal(() => day = picked);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                              context: ctx, initialTime: from);
                          if (t != null) setLocal(() => from = t);
                        },
                        child: Text('From ${from.format(ctx)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                              context: ctx, initialTime: to);
                          if (t != null) setLocal(() => to = t);
                        },
                        child: Text('To ${to.format(ctx)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reason,
                  decoration: const InputDecoration(
                    hintText: 'Reason (optional), e.g. Lunch, Training',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: TextStyle(color: MindCareTheme.error, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final s = from.hour * 60 + from.minute;
                final e = to.hour * 60 + to.minute;
                if (e <= s) {
                  setLocal(() => error = 'The end time must be after the start.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: FilledButton.styleFrom(
                  backgroundColor: MindCareTheme.primary),
              child: const Text('Block this time'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      service.addBlock(TimeBlock(
        id: 'blk_${DateTime.now().microsecondsSinceEpoch}',
        psychologistId: widget.psychologistId,
        start: DateTime(day.year, day.month, day.day, from.hour, from.minute),
        end: DateTime(day.year, day.month, day.day, to.hour, to.minute),
        reason: reason.text.trim(),
      ));
    }
    reason.dispose();
  }

  Future<void> _removeBlockDialog(TimeBlock b) async {
    final service = context.read<ConsultationService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(b.reason.isEmpty ? 'Blocked time' : b.reason),
        content: Text('${_clock(b.start)} to ${_clock(b.end)}\n\n'
            'Remove this block and make the time available again?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove block',
                style: TextStyle(color: MindCareTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) service.removeBlock(b.id);
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ConsultationService>();
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final days = _days(wide);
    final text = Theme.of(context).textTheme;

    final appointments = service
        .requestsForPsychologist(widget.psychologistId)
        .where((r) =>
            r.scheduledAt != null &&
            (r.status == ConsultationStatus.accepted ||
                r.status == ConsultationStatus.rescheduleRequested))
        .toList();
    final blocks = service.blocksFor(widget.psychologistId);

    final blockButton = FilledButton.icon(
      onPressed: () => _addBlockDialog(),
      icon: const Icon(Icons.block, size: 18),
      label: const Text('Block time'),
      style: FilledButton.styleFrom(backgroundColor: MindCareTheme.primary),
    );

    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: wide ? 'Previous week' : 'Previous day',
                onPressed: () => _shift(wide, -1),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: wide ? 'Next week' : 'Next day',
                onPressed: () => _shift(wide, 1),
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _anchor = _dateOnly(DateTime.now())),
                child: const Text('Today'),
              ),
              Expanded(
                child: Text(_rangeLabel(days),
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(fontSize: 16)),
              ),
              if (wide) blockButton,
            ],
          ),
          if (!wide) Align(alignment: Alignment.centerRight, child: blockButton),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: const [
              _Legend(color: MindCareTheme.primary, label: 'Appointment'),
              _Legend(color: MindCareTheme.accent, label: 'Reschedule requested'),
              _Legend(color: Color(0xFF8C8C84), label: 'Blocked'),
            ],
          ),
          const SizedBox(height: 12),
          // Day headers
          Row(
            children: [
              const SizedBox(width: 56),
              for (final d in days)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _sameDay(d, DateTime.now())
                          ? MindCareTheme.primaryLight
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(_weekdays[d.weekday - 1],
                            style: text.bodyMedium?.copyWith(fontSize: 12)),
                        Text('${d.day}',
                            style: text.titleMedium?.copyWith(fontSize: 17)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 520,
            child: SingleChildScrollView(
              controller: _scroll,
              child: SizedBox(
                height: (_endHour - _startHour) * _rowHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Stack(
                        children: [
                          for (int h = _startHour; h < _endHour; h++)
                            Positioned(
                              top: (h - _startHour) * _rowHeight - 7,
                              right: 8,
                              child: Text(_hourLabel(h),
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      color: MindCareTheme.textLight)),
                            ),
                        ],
                      ),
                    ),
                    for (final d in days)
                      Expanded(
                        child: _DayColumn(
                          day: d,
                          startHour: _startHour,
                          endHour: _endHour,
                          rowHeight: _rowHeight,
                          appointments: appointments
                              .where((r) => _sameDay(r.scheduledAt!, d))
                              .toList(),
                          blocks: blocks
                              .where((b) => _sameDay(b.start, d))
                              .toList(),
                          clock: _clock,
                          onTapEmpty: (t) => _addBlockDialog(start: t),
                          onTapBlock: _removeBlockDialog,
                          onTapAppointment: widget.onOpenAppointment,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.35),
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
        ],
      );
}

class _DayColumn extends StatelessWidget {
  final DateTime day;
  final int startHour;
  final int endHour;
  final double rowHeight;
  final List<ConsultationRequest> appointments;
  final List<TimeBlock> blocks;
  final String Function(DateTime) clock;
  final void Function(DateTime) onTapEmpty;
  final void Function(TimeBlock) onTapBlock;
  final void Function(ConsultationRequest) onTapAppointment;

  const _DayColumn({
    required this.day,
    required this.startHour,
    required this.endHour,
    required this.rowHeight,
    required this.appointments,
    required this.blocks,
    required this.clock,
    required this.onTapEmpty,
    required this.onTapBlock,
    required this.onTapAppointment,
  });

  double _top(DateTime t) =>
      ((t.hour - startHour) * 60 + t.minute) / 60 * rowHeight;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        // Snap the tapped position to the nearest half hour.
        final minutes =
            (details.localPosition.dy / rowHeight * 60 / 30).floor() * 30;
        final t = DateTime(day.year, day.month, day.day, startHour)
            .add(Duration(minutes: minutes));
        onTapEmpty(t);
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: MindCareTheme.border)),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Hour lines
            for (int h = 0; h < endHour - startHour; h++)
              Positioned(
                top: h * rowHeight,
                left: 0,
                right: 0,
                child: const Divider(height: 1, color: MindCareTheme.border),
              ),
            // Blocked time
            for (final b in blocks)
              Positioned(
                top: _top(b.start),
                left: 2,
                right: 2,
                height: (b.end.difference(b.start).inMinutes / 60 * rowHeight)
                    .clamp(18.0, double.infinity),
                child: GestureDetector(
                  onTap: () => onTapBlock(b),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8C8C84).withValues(alpha: 0.22),
                      border: Border.all(color: const Color(0xFF8C8C84)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 12, color: Color(0xFF5C5C55)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            b.reason.isEmpty ? 'Blocked' : b.reason,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF4A4A44)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Appointments
            for (final r in appointments)
              Positioned(
                top: _top(r.scheduledAt!),
                left: 2,
                right: 2,
                height: kAppointmentMinutes / 60 * rowHeight - 2,
                child: GestureDetector(
                  onTap: () => onTapAppointment(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: (r.status == ConsultationStatus.rescheduleRequested
                              ? MindCareTheme.accent
                              : MindCareTheme.primary)
                          .withValues(alpha: 0.28),
                      border: Border(
                        left: BorderSide(
                          width: 4,
                          color: r.status == ConsultationStatus.rescheduleRequested
                              ? MindCareTheme.accent
                              : MindCareTheme.primaryDark,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.patientName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          clock(r.scheduledAt!),
                          style: const TextStyle(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Current time
            if (isToday &&
                now.hour >= startHour &&
                now.hour < endHour)
              Positioned(
                top: _top(now),
                left: 0,
                right: 0,
                child: Container(height: 2, color: MindCareTheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
