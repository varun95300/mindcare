import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/consultation.dart';
import '../../services/auth_service.dart';
import '../../services/consultation_service.dart';
import '../../data/seed_psychologists.dart';
import 'patient_report_screen.dart';
import 'schedule_appointment_screen.dart';

class PsychologistDashboardScreen extends StatelessWidget {
  const PsychologistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final consultationService = context.watch<ConsultationService>();
    final user = auth.currentUser;
    final psychologist = user?.psychologistId != null
        ? SeedPsychologists.getById(user!.psychologistId!)
        : null;

    final requests = psychologist != null
        ? consultationService.requestsForPsychologist(psychologist.id)
        : <ConsultationRequest>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Psychologist Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile header
              if (psychologist != null) ...[
                _DashboardHeader(
                    name: psychologist.name, title: psychologist.title),
                const SizedBox(height: MindCareTheme.spacingLg),

                // Quick stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.star,
                        value: '${psychologist.rating}',
                        label: 'Rating',
                        color: MindCareTheme.stressColor,
                      ),
                    ),
                    const SizedBox(width: MindCareTheme.spacingSm),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people,
                        value: '${requests.length}',
                        label: 'Requests',
                        color: MindCareTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: MindCareTheme.spacingSm),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.work,
                        value: '${psychologist.yearsExperience}y',
                        label: 'Experience',
                        color: MindCareTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MindCareTheme.spacingLg),

                // Specializations
                _SectionTitle('Your Specializations'),
                const SizedBox(height: MindCareTheme.spacingSm),
                Wrap(
                  spacing: MindCareTheme.spacingSm,
                  runSpacing: MindCareTheme.spacingSm,
                  children: psychologist.specializations.map((spec) {
                    final color = MindCareTheme.domainColor(spec.label);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(MindCareTheme.radiusFull),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Text(
                        spec.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: color),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: MindCareTheme.spacingLg),
              ],

              // Consultation Requests
              _SectionTitle('Consultation Requests'),
              const SizedBox(height: MindCareTheme.spacingSm),

              if (requests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(MindCareTheme.spacingXl),
                  decoration: BoxDecoration(
                    color: MindCareTheme.surfaceVariant,
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusLg),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 48,
                          color: MindCareTheme.textLight.withOpacity(0.5)),
                      const SizedBox(height: MindCareTheme.spacingSm),
                      Text(
                        'No consultation requests yet',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: MindCareTheme.textLight,
                                ),
                      ),
                      const SizedBox(height: MindCareTheme.spacingXs),
                      Text(
                        'Requests from users will appear here with their screening reports.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: MindCareTheme.textLight,
                                ),
                      ),
                    ],
                  ),
                )
              else
                ...requests.map(
                  (request) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: MindCareTheme.spacingSm),
                    child: _ConsultationRequestCard(request: request),
                  ),
                ),

              const SizedBox(height: MindCareTheme.spacingXl),

              // About section
              if (psychologist != null) ...[
                _SectionTitle('Profile Bio'),
                const SizedBox(height: MindCareTheme.spacingSm),
                Container(
                  padding: const EdgeInsets.all(MindCareTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: MindCareTheme.surface,
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusMd),
                    boxShadow: MindCareTheme.softShadow,
                  ),
                  child: Text(
                    psychologist.bio,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                  ),
                ),
              ],

              const SizedBox(height: MindCareTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String name;
  final String title;
  const _DashboardHeader({required this.name, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: MindCareTheme.heroGradient,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.split(' ').map((w) => w[0]).take(2).join(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(width: MindCareTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingMd),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        boxShadow: MindCareTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: color)),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}

/// Real consultation request card with screening report access.
class _ConsultationRequestCard extends StatelessWidget {
  final ConsultationRequest request;
  const _ConsultationRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status) {
      ConsultationStatus.pending => MindCareTheme.stressColor,
      ConsultationStatus.accepted => MindCareTheme.primary,
      ConsultationStatus.declined => MindCareTheme.error,
      ConsultationStatus.completed => MindCareTheme.success,
    };

    final result = request.screeningResult;

    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingMd),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        boxShadow: MindCareTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient info & status
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: MindCareTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    request.patientName[0],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: MindCareTheme.primaryDark,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: MindCareTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          request.patientName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                MindCareTheme.radiusFull),
                          ),
                          child: Text(
                            request.status.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.timeAgoLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: MindCareTheme.textLight,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MindCareTheme.spacingMd),

          // Screening summary
          Container(
            padding: const EdgeInsets.all(MindCareTheme.spacingSm),
            decoration: BoxDecoration(
              color: MindCareTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(MindCareTheme.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Screening Summary',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: MindCareTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _DomainTag(
                      label: 'Primary: ${result.primaryDomain.label}',
                      color: MindCareTheme.domainColor(
                          result.primaryDomain.label),
                      isPrimary: true,
                    ),
                    if (result.secondaryDomain != null) ...[
                      const SizedBox(width: 6),
                      _DomainTag(
                        label: 'Secondary: ${result.secondaryDomain!.label}',
                        color: MindCareTheme.domainColor(
                            result.secondaryDomain!.label),
                        isPrimary: false,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Scheduled appointment confirmation
          if (request.scheduledAt != null) ...[
            const SizedBox(height: MindCareTheme.spacingSm),
            Container(
              padding: const EdgeInsets.all(MindCareTheme.spacingSm),
              decoration: BoxDecoration(
                color: MindCareTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(MindCareTheme.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available,
                      size: 16, color: MindCareTheme.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.scheduledAtLabel!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MindCareTheme.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Message from patient
          if (request.message != null) ...[
            const SizedBox(height: MindCareTheme.spacingSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.message_outlined,
                    size: 16, color: MindCareTheme.textLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '"${request.message}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: MindCareTheme.spacingMd),

          // Action buttons
          Row(
            children: [
              // View Report button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PatientReportScreen(
                          request: request,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('View Report'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: MindCareTheme.spacingSm),

              // Accept/Decline buttons
              if (request.status == ConsultationStatus.pending) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ScheduleAppointmentScreen(request: request),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('Accept & Schedule'),
                  ),
                ),
              ] else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: Text(
                      request.status.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DomainTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool isPrimary;
  const _DomainTag(
      {required this.label, required this.color, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isPrimary ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
        border: isPrimary ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
            ),
      ),
    );
  }
}
