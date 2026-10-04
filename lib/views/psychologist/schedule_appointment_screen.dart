import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/consultation.dart';
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
  final _noteController =
      TextEditingController(text: 'Looking forward to speaking with you.');

  @override
  void dispose() {
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
    });
  }

  void _confirm() {
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
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
