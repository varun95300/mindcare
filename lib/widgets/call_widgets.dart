import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../data/seed_psychologists.dart';
import '../models/call_request.dart';
import '../models/consultation.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../services/consultation_service.dart';
import '../views/video_call_screen.dart';
import 'ui.dart';

Color _urgencyColor(CallUrgency u) => switch (u) {
      CallUrgency.high => MindCareTheme.terracotta,
      CallUrgency.medium => MindCareTheme.butterDeep,
      CallUrgency.low => MindCareTheme.primaryDark,
    };

/// Small coloured badge showing a call's urgency.
class UrgencyBadge extends StatelessWidget {
  final CallUrgency urgency;
  const UrgencyBadge(this.urgency, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = _urgencyColor(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${urgency.emoji} ${urgency.label}',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

void _openCall(BuildContext context, CallRequest call,
    {required bool asDoctor, required String otherName}) {
  if (call.channelName == null) return;
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => VideoCallScreen(
      callId: call.id,
      channelName: call.channelName!,
      otherName: otherName,
      asDoctor: asDoctor,
    ),
  ));
}

/// Rebuilds every 20 seconds so countdowns and the "Join" window stay fresh.
class _Ticker extends StatefulWidget {
  final WidgetBuilder builder;
  const _Ticker({required this.builder});

  @override
  State<_Ticker> createState() => _TickerState();
}

class _TickerState extends State<_Ticker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 20), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// ═════════════════════════════════════════════════════════════════
// PATIENT SIDE
// ═════════════════════════════════════════════════════════════════

/// "Video calls" section on the patient's Care tab.
class PatientCallsSection extends StatelessWidget {
  const PatientCallsSection({super.key});

  Future<void> _request(BuildContext context, List<String> doctorIds) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final result = await showDialog<_CallRequestResult>(
      context: context,
      builder: (_) => _RequestCallDialog(doctorIds: doctorIds),
    );
    if (result == null || !context.mounted) return;
    context.read<CallService>().requestCall(
          patientName: user.name,
          patientEmail: user.email,
          psychologistId: result.psychologistId,
          urgency: result.urgency,
          note: result.note,
        );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Call request sent. Your psychologist will pick a time.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = context.watch<AuthService>().currentUser;
    final calls = context.watch<CallService>();
    final consults = context.watch<ConsultationService>();
    if (user == null) return const SizedBox.shrink();

    // Only psychologists who accepted the patient can be called.
    final doctorIds = <String>{
      for (final r in consults.requestsForPatient(user.email))
        if (r.status == ConsultationStatus.accepted ||
            r.status == ConsultationStatus.completed)
          r.psychologistId,
    }.toList();

    final mine = calls
        .callsForPatient(user.email)
        .where((c) => c.status != CallStatus.cancelled)
        .toList();

    return _Ticker(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 12,
            children: [
              Text('Video calls', style: text.headlineMedium),
              FilledButton.icon(
                onPressed:
                    doctorIds.isEmpty ? null : () => _request(context, doctorIds),
                icon: const Icon(Icons.videocam_outlined, size: 18),
                label: const Text('Request a call'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            doctorIds.isEmpty
                ? 'Once a psychologist accepts your request, you can ask them for a video call here.'
                : 'Ask for a call and tell them how urgent it feels. They will pick a time that works.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (mine.isEmpty)
            const Panel(
              child: EmptyState(
                icon: Icons.videocam_outlined,
                title: 'No call requests yet.',
                message: 'Your requested and scheduled calls will show up here.',
              ),
            )
          else
            for (final c in mine) ...[
              _PatientCallCard(call: c),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _CallRequestResult {
  final String psychologistId;
  final CallUrgency urgency;
  final String? note;
  const _CallRequestResult(this.psychologistId, this.urgency, this.note);
}

class _RequestCallDialog extends StatefulWidget {
  final List<String> doctorIds;
  const _RequestCallDialog({required this.doctorIds});

  @override
  State<_RequestCallDialog> createState() => _RequestCallDialogState();
}

class _RequestCallDialogState extends State<_RequestCallDialog> {
  late String _doctorId = widget.doctorIds.first;
  CallUrgency _urgency = CallUrgency.medium;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Request a video call'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.doctorIds.length > 1) ...[
                Text('Who would you like to talk to?',
                    style: text.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _doctorId,
                  items: [
                    for (final id in widget.doctorIds)
                      DropdownMenuItem(
                        value: id,
                        child: Text(
                            SeedPsychologists.getById(id)?.name ?? 'Psychologist'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _doctorId = v ?? _doctorId),
                ),
                const SizedBox(height: 18),
              ],
              Text('How urgent is it?', style: text.titleMedium),
              const SizedBox(height: 8),
              for (final u in CallUrgency.values.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _urgency = u),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _urgency == u
                            ? _urgencyColor(u).withValues(alpha: 0.12)
                            : null,
                        border: Border.all(
                          color: _urgency == u
                              ? _urgencyColor(u)
                              : MindCareTheme.border,
                          width: _urgency == u ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(u.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.label, style: text.titleMedium),
                                Text(u.description,
                                    style: text.bodyMedium
                                        ?.copyWith(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text('Anything they should know? (optional)',
                  style: text.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  hintText: 'A few words about what you would like to talk about',
                ),
              ),
              if (_urgency == CallUrgency.high) ...[
                const SizedBox(height: 8),
                Text(
                  'If you are in immediate danger or thinking about harming '
                  'yourself, please contact your local emergency number or a '
                  'crisis line right now. A call request is not instant.',
                  style: text.bodyMedium?.copyWith(
                      fontSize: 12.5, color: MindCareTheme.terracotta),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
              context, _CallRequestResult(_doctorId, _urgency, _note.text)),
          child: const Text('Send request'),
        ),
      ],
    );
  }
}

class _PatientCallCard extends StatelessWidget {
  final CallRequest call;
  const _PatientCallCard({required this.call});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final doctor = SeedPsychologists.getById(call.psychologistId);
    final doctorName = doctor?.name ?? 'Psychologist';
    final calls = context.read<CallService>();

    final String detail = switch (call.status) {
      CallStatus.pending => 'Requested ${call.timeAgoLabel}. Waiting for a time.',
      CallStatus.scheduled =>
        '${call.scheduledAtLabel} · ${call.durationMinutes} min',
      CallStatus.active => 'Your call is in progress.',
      CallStatus.completed => 'Call finished.',
      CallStatus.cancelled => 'Cancelled.',
    };

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(doctorName.replaceFirst('Dr. ', ''), size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctorName,
                        style: text.titleMedium?.copyWith(fontSize: 16)),
                    Text(call.status.label,
                        style: text.bodyMedium?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              UrgencyBadge(call.urgency),
            ],
          ),
          const SizedBox(height: 12),
          Text(detail, style: text.bodyLarge),
          if (call.note != null) ...[
            const SizedBox(height: 6),
            Text('Your note: "${call.note}"',
                style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (call.status == CallStatus.scheduled ||
                  call.status == CallStatus.active)
                FilledButton.icon(
                  onPressed: call.isJoinable
                      ? () => _openCall(context, call,
                          asDoctor: false, otherName: doctorName)
                      : null,
                  icon: const Icon(Icons.videocam, size: 18),
                  label: Text(call.isJoinable
                      ? 'Join call'
                      : (call.countdownLabel ?? 'Join call')),
                ),
              if (call.status == CallStatus.pending ||
                  call.status == CallStatus.scheduled)
                TextButton(
                  onPressed: () => calls.cancel(call.id),
                  child: Text(call.status == CallStatus.pending
                      ? 'Cancel request'
                      : 'Cancel call'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// PSYCHOLOGIST SIDE
// ═════════════════════════════════════════════════════════════════

/// "Call queue" for a psychologist: pending requests sorted by urgency,
/// followed by scheduled calls.
class DoctorCallQueue extends StatelessWidget {
  final String psychologistId;
  const DoctorCallQueue({super.key, required this.psychologistId});

  Future<void> _schedule(BuildContext context, CallRequest call) async {
    final picked = await showDialog<_ScheduleResult>(
      context: context,
      builder: (_) => _ScheduleCallDialog(call: call),
    );
    if (picked == null || !context.mounted) return;
    context
        .read<CallService>()
        .schedule(call.id, at: picked.at, durationMinutes: picked.minutes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Call with ${call.patientName} scheduled.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final service = context.watch<CallService>();
    final queue = service.queueFor(psychologistId);
    final upcoming = service.upcomingFor(psychologistId);

    return _Ticker(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Call requests', style: text.headlineMedium),
          const SizedBox(height: 4),
          Text('Most urgent first. Pick a time and the patient is notified.',
              style: text.bodyMedium),
          const SizedBox(height: 16),
          if (queue.isEmpty)
            const Panel(
              child: EmptyState(
                icon: Icons.phone_in_talk_outlined,
                title: 'No pending call requests.',
                message: 'When a patient asks for a call, it will appear here.',
              ),
            )
          else
            for (final c in queue) ...[
              _QueueCard(call: c, onSchedule: () => _schedule(context, c)),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 28),
          Text('Scheduled calls', style: text.headlineMedium),
          const SizedBox(height: 16),
          if (upcoming.isEmpty)
            const Panel(
              child: EmptyState(
                icon: Icons.event_outlined,
                title: 'Nothing scheduled.',
                message: 'Calls you schedule will be listed here.',
              ),
            )
          else
            for (final c in upcoming) ...[
              _UpcomingCard(call: c),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final CallRequest call;
  final VoidCallback onSchedule;
  const _QueueCard({required this.call, required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final calls = context.read<CallService>();
    return Panel(
      borderColor: call.urgency == CallUrgency.high
          ? MindCareTheme.terracotta.withValues(alpha: 0.6)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(call.patientName, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(call.patientName,
                        style: text.titleMedium?.copyWith(fontSize: 16)),
                    Text('Requested ${call.timeAgoLabel} · ${call.urgency.description}',
                        style: text.bodyMedium?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              UrgencyBadge(call.urgency),
            ],
          ),
          if (call.note != null) ...[
            const SizedBox(height: 12),
            Text('"${call.note}"',
                style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onSchedule,
                icon: const Icon(Icons.event_available, size: 18),
                label: const Text('Schedule call'),
              ),
              TextButton(
                onPressed: () => calls.cancel(call.id),
                style: TextButton.styleFrom(
                    foregroundColor: MindCareTheme.textSecondary),
                child: const Text('Decline'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final CallRequest call;
  const _UpcomingCard({required this.call});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final calls = context.read<CallService>();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(call.patientName, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(call.patientName,
                        style: text.titleMedium?.copyWith(fontSize: 16)),
                    Text(
                        call.status == CallStatus.active
                            ? 'In progress'
                            : '${call.scheduledAtLabel} · ${call.durationMinutes} min',
                        style: text.bodyMedium?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              UrgencyBadge(call.urgency),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: call.isJoinable
                    ? () => _openCall(context, call,
                        asDoctor: true, otherName: call.patientName)
                    : null,
                icon: const Icon(Icons.videocam, size: 18),
                label: Text(call.isJoinable
                    ? 'Join'
                    : (call.countdownLabel ?? 'Join')),
              ),
              TextButton(
                onPressed: () => calls.cancel(call.id),
                child: const Text('Cancel call'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleResult {
  final DateTime at;
  final int minutes;
  const _ScheduleResult(this.at, this.minutes);
}

class _ScheduleCallDialog extends StatefulWidget {
  final CallRequest call;
  const _ScheduleCallDialog({required this.call});

  @override
  State<_ScheduleCallDialog> createState() => _ScheduleCallDialogState();
}

class _ScheduleCallDialogState extends State<_ScheduleCallDialog> {
  late DateTime _date;
  late TimeOfDay _time;
  int _minutes = 30;

  @override
  void initState() {
    super.initState();
    // High urgency defaults to today, medium to tomorrow, low to in 3 days.
    final offset = switch (widget.call.urgency) {
      CallUrgency.high => 0,
      CallUrgency.medium => 1,
      CallUrgency.low => 3,
    };
    final base = DateTime.now().add(Duration(days: offset, hours: offset == 0 ? 1 : 0));
    _date = DateTime(base.year, base.month, base.day);
    _time = TimeOfDay(
        hour: offset == 0 ? base.hour : 10, minute: 0);
  }

  DateTime get _at =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final calls = context.read<CallService>();
    final consults = context.read<ConsultationService>();

    final callClashes = calls.clashesFor(
        widget.call.psychologistId, _at, _minutes,
        excludeCallId: widget.call.id);
    final apptClashes =
        consults.findConflicts(widget.call.psychologistId, _at);
    final hasClash = callClashes.isNotEmpty || apptClashes.isNotEmpty;
    final inPast = _at.isBefore(DateTime.now());

    return AlertDialog(
      title: Text('Schedule call with ${widget.call.patientName}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              UrgencyBadge(widget.call.urgency),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.call.urgency.description,
                    style: text.bodyMedium),
              ),
            ]),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                        '${_date.day}/${_date.month}/${_date.year}'),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 180)),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule, size: 16),
                    label: Text(_time.format(context)),
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _time);
                      if (t != null) setState(() => _time = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Length', style: text.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final m in const [30, 45, 60])
                  ChoiceChip(
                    label: Text('$m min'),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
              ],
            ),
            if (hasClash || inPast) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MindCareTheme.terracotta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  inPast
                      ? 'That time has already passed.'
                      : 'This overlaps: ${[
                          ...apptClashes.map((c) => c.title),
                          ...callClashes.map((c) => 'Call with ${c.patientName}'),
                        ].join(', ')}.',
                  style: text.bodyMedium?.copyWith(
                      fontSize: 13, color: MindCareTheme.terracotta),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: inPast
              ? null
              : () => Navigator.pop(context, _ScheduleResult(_at, _minutes)),
          child: Text(hasClash ? 'Schedule anyway' : 'Schedule'),
        ),
      ],
    );
  }
}

