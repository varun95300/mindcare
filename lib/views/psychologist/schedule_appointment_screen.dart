import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/consultation.dart';
import '../../models/time_block.dart';
import '../../services/consultation_service.dart';

/// Lets the psychologist accept a request by picking a date & time —
/// shown alongside their existing upcoming appointments so they can avoid
/// clashes — and leave a short note the patient will see.
class ScheduleAppointmentScreen extends StatefulWidget {
  final ConsultationRequest request;
  const ScheduleAppointmentScreen({super.key, required this.request});

  @override
  State<ScheduleAppointmentScreen> createState() =>
      _ScheduleAppointmentScreenState();
}

class _ScheduleAppointmentScreenState
    extends State<ScheduleAppointmentScreen> {
  DateTime? _selectedDateTime;

  /// Clashes found when the psychologist pressed Confirm. Null until then:
  /// nothing is flagged while they are still choosing a time.
  List<ScheduleConflict>? _conflicts;
  final ScrollController _scrollController = ScrollController();
  final _noteController =
      TextEditingController(text: 'Looking forward to speaking with you.');

  @override
  void dispose() {
    _scrollController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 11, minute: 0),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _conflicts = null; // a new choice starts clean
    });
  }

  /// Runs when Confirm is pressed: flags any clash straight away at the top
  /// of the page and holds the booking until the psychologist decides.
  void _confirm() {
    if (_selectedDateTime == null) return;
    final service = context.read<ConsultationService>();
    final clashes = service.findConflicts(
      widget.request.psychologistId,
      _selectedDateTime!,
      excludeRequestId: widget.request.id,
    );
    if (clashes.isNotEmpty) {
      setState(() => _conflicts = clashes);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      return;
    }
    _commit();
  }

  void _commit() {
    if (_selectedDateTime == null) return;
    context.read<ConsultationService>().acceptAndSchedule(
          widget.request.id,
          scheduledAt: _selectedDateTime!,
          note: _noteController.text,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final consultationService = context.watch<ConsultationService>();
    final upcoming = consultationService
        .scheduledAppointments(widget.request.psychologistId)
        .where((r) => r.id != widget.request.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule with ${widget.request.patientName}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_conflicts != null && _conflicts!.isNotEmpty) ...[
                _ClashBanner(
                  conflicts: _conflicts!,
                  chosen: _selectedDateTime!,
                  onPickAnother: () {
                    setState(() => _conflicts = null);
                    _pickDateTime();
                  },
                  onScheduleAnyway: _commit,
                ),
                const SizedBox(height: MindCareTheme.spacingLg),
              ],
              if (widget.request.status ==
                  ConsultationStatus.rescheduleRequested) ...[
                Container(
                  padding: const EdgeInsets.all(MindCareTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: MindCareTheme.accent.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusMd),
                    border: Border.all(
                        color: MindCareTheme.accent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.request.patientName} cannot make the booked time',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (widget.request.scheduledAtLabel != null)
                        Text('Was: ${widget.request.scheduledAtLabel}'),
                      Text(
                          'Reason: ${widget.request.rescheduleReason ?? 'not given'}'),
                      const SizedBox(height: 4),
                      const Text('Pick a new time below to confirm it.'),
                    ],
                  ),
                ),
                const SizedBox(height: MindCareTheme.spacingLg),
              ],
              if (upcoming.isNotEmpty) ...[
                Text(
                  'Your Upcoming Appointments',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: MindCareTheme.spacingSm),
                ...upcoming.map((r) => _UpcomingAppointmentTile(request: r)),
                const SizedBox(height: MindCareTheme.spacingLg),
              ],

              Text('Pick a Time', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: MindCareTheme.spacingSm),
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.all(MindCareTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: MindCareTheme.surface,
                    borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
                    border: Border.all(
                      color: _selectedDateTime != null
                          ? MindCareTheme.primary
                          : MindCareTheme.textLight.withValues(alpha: 0.3),
                      width: _selectedDateTime != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: _selectedDateTime != null
                            ? MindCareTheme.primary
                            : MindCareTheme.textLight,
                      ),
                      const SizedBox(width: MindCareTheme.spacingSm),
                      Expanded(
                        child: Text(
                          _selectedDateTime != null
                              ? ConsultationRequest.formatDateTime(
                                  _selectedDateTime!)
                              : 'Tap to choose a date and time',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: _selectedDateTime != null
                                    ? MindCareTheme.textPrimary
                                    : MindCareTheme.textLight,
                              ),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: MindCareTheme.textLight),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingLg),

              Text(
                'Note to ${widget.request.patientName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: MindCareTheme.spacingSm),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a short note (optional)',
                  filled: true,
                  fillColor: MindCareTheme.surface,
                  contentPadding: const EdgeInsets.all(MindCareTheme.spacingMd),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingXl),

              ElevatedButton(
                onPressed: _selectedDateTime != null ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('Confirm Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingAppointmentTile extends StatelessWidget {
  final ConsultationRequest request;
  const _UpcomingAppointmentTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: MindCareTheme.spacingSm),
      padding: const EdgeInsets.all(MindCareTheme.spacingMd),
      decoration: BoxDecoration(
        color: MindCareTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined,
              size: 18, color: MindCareTheme.textSecondary),
          const SizedBox(width: MindCareTheme.spacingSm),
          Expanded(
            child: Text(
              request.patientName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            request.scheduledAtLabel ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MindCareTheme.textLight,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

/// Shown at the top of the page when the chosen time overlaps something.
class _ClashBanner extends StatelessWidget {
  final List<ScheduleConflict> conflicts;
  final DateTime chosen;
  final VoidCallback onPickAnother;
  final VoidCallback onScheduleAnyway;

  const _ClashBanner({
    required this.conflicts,
    required this.chosen,
    required this.onPickAnother,
    required this.onScheduleAnyway,
  });

  String _range(DateTime a, DateTime b) =>
      '${ConsultationRequest.formatDateTime(a)} to ${_clock(b)}';

  String _clock(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingMd),
      decoration: BoxDecoration(
        color: MindCareTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        border: Border.all(color: MindCareTheme.error, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: MindCareTheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflicts.length == 1
                      ? 'Scheduling clash'
                      : '${conflicts.length} scheduling clashes',
                  style: text.titleMedium?.copyWith(color: MindCareTheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You picked ${ConsultationRequest.formatDateTime(chosen)} '
            '(1 hour), which overlaps:',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 8),
          for (final c in conflicts)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(c.isBlock ? Icons.lock_outline : Icons.event_busy,
                      size: 16, color: MindCareTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${c.title}\n${_range(c.start, c.end)}',
                      style: text.bodyMedium
                          ?.copyWith(color: MindCareTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onPickAnother,
                style: FilledButton.styleFrom(
                    backgroundColor: MindCareTheme.primary),
                child: const Text('Pick another time'),
              ),
              OutlinedButton(
                onPressed: onScheduleAnyway,
                style: OutlinedButton.styleFrom(
                    foregroundColor: MindCareTheme.error),
                child: const Text('Schedule anyway'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
