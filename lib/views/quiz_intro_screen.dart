import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../data/seed_psychologists.dart';
import '../services/auth_service.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';
import '../viewmodels/chat_viewmodel.dart';
import 'chat_screening_screen.dart';

class QuizIntroScreen extends StatefulWidget {
  const QuizIntroScreen({super.key});

  @override
  State<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends State<QuizIntroScreen> {
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _refreshSession();
  }

  Future<void> _refreshSession() async {
    final id = context.read<AuthService>().currentUser?.id;
    if (id == null) return;
    final has = await ChatViewModel.hasSavedSession(id);
    if (mounted) setState(() => _hasSession = has);
  }

  /// "Kill session": wipes this user's saved conversation, report and any
  /// consultation requests they sent, so they can start from scratch.
  Future<void> _confirmNewSession() async {
    final auth = context.read<AuthService>();
    final consultations = context.read<ConsultationService>();
    final user = auth.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a new session?'),
        content: const Text(
          'This deletes your saved conversation, your report and any '
          'consultation requests you have sent. The psychologist will no '
          'longer see them. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep my session'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete and start new',
                style: TextStyle(color: MindCareTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ChatViewModel.clearSession(user.id);
    consultations.removeForPatient(user.email);
    if (!mounted) return;
    setState(() => _hasSession = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session cleared. You can start fresh.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final userName = auth.currentUser?.name ?? 'there';
    final myRequests = context
        .watch<ConsultationService>()
        .requestsForPatient(auth.currentUser?.email ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().signOut();
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
              const SizedBox(height: MindCareTheme.spacingLg),

              Text(
                'Hi $userName 👋',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: MindCareTheme.spacingSm),
              Text(
                'Let\'s talk through how you\'ve been feeling lately.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MindCareTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: MindCareTheme.spacingXl),

              // Status of consultation requests this user has sent
              if (myRequests.isNotEmpty) ...[
                _MyConsultationsCard(requests: myRequests),
                const SizedBox(height: MindCareTheme.spacingLg),
              ],

              // What to expect
              Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingLg),
                decoration: BoxDecoration(
                  color: MindCareTheme.surface,
                  borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
                  boxShadow: MindCareTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What to Expect',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: MindCareTheme.spacingMd),
                    _ExpectationItem(
                      icon: Icons.timer_outlined,
                      text: 'Takes about 3-5 minutes',
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    _ExpectationItem(
                      icon: Icons.route_outlined,
                      text: 'Questions adapt based on your responses',
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    _ExpectationItem(
                      icon: Icons.lock_outline,
                      text: 'Your answers are completely private',
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    _ExpectationItem(
                      icon: Icons.people_outlined,
                      text: 'Get matched with people who can help',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Domains being screened
              Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingLg),
                decoration: BoxDecoration(
                  color: MindCareTheme.surface,
                  borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
                  boxShadow: MindCareTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What We\'ll Talk About',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: MindCareTheme.spacingMd),
                    Wrap(
                      spacing: MindCareTheme.spacingSm,
                      runSpacing: MindCareTheme.spacingSm,
                      children: [
                        _DomainChip(
                            label: 'Anxiety',
                            color: MindCareTheme.anxietyColor),
                        _DomainChip(
                            label: 'Depression',
                            color: MindCareTheme.depressionColor),
                        _DomainChip(
                            label: 'Stress',
                            color: MindCareTheme.stressColor),
                        _DomainChip(
                            label: 'Interpersonal',
                            color: MindCareTheme.interpersonalColor),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: MindCareTheme.spacingLg),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingMd),
                decoration: BoxDecoration(
                  color: MindCareTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
                  border: Border.all(
                    color: MindCareTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: MindCareTheme.warning.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: MindCareTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'This isn\'t a diagnosis — just a starting point. What you share is only ever seen by the professional you choose to connect with.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: MindCareTheme.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingMd),

              // Start Button
              ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ChatScreeningScreen()),
                  );
                  _refreshSession();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                    _hasSession ? 'Resume Conversation' : 'Start Conversation'),
              ),
              if (_hasSession) ...[
                const SizedBox(height: MindCareTheme.spacingSm),
                OutlinedButton.icon(
                  onPressed: _confirmNewSession,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: MindCareTheme.error,
                  ),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('End session and start a new one'),
                ),
              ],
              const SizedBox(height: MindCareTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpectationItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ExpectationItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: MindCareTheme.primary),
        const SizedBox(width: MindCareTheme.spacingSm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _DomainChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DomainChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontSize: 13,
            ),
      ),
    );
  }
}

/// Shows the user how each consultation request they sent is going —
/// pending, accepted with the appointment time, or declined.
class _MyConsultationsCard extends StatelessWidget {
  final List<ConsultationRequest> requests;

  const _MyConsultationsCard({required this.requests});

  Color _color(ConsultationStatus s) {
    switch (s) {
      case ConsultationStatus.accepted:
      case ConsultationStatus.completed:
        return MindCareTheme.success;
      case ConsultationStatus.declined:
        return MindCareTheme.error;
      case ConsultationStatus.pending:
        return MindCareTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        boxShadow: MindCareTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Appointments',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: MindCareTheme.spacingMd),
          for (final r in requests) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    SeedPsychologists.getById(r.psychologistId)?.name ??
                        'Psychologist',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color(r.status).withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusFull),
                  ),
                  child: Text(
                    r.status.label,
                    style: TextStyle(
                      color: _color(r.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (r.status == ConsultationStatus.accepted &&
                r.scheduledAtLabel != null)
              Text('Confirmed for ${r.scheduledAtLabel}',
                  style: Theme.of(context).textTheme.bodyMedium)
            else if (r.status == ConsultationStatus.accepted)
              Text('Accepted. The psychologist will confirm a time.',
                  style: Theme.of(context).textTheme.bodyMedium)
            else if (r.status == ConsultationStatus.pending)
              Text('Sent ${r.timeAgoLabel}. Waiting for a reply.',
                  style: Theme.of(context).textTheme.bodyMedium)
            else if (r.status == ConsultationStatus.declined)
              Text('The psychologist could not take this request.',
                  style: Theme.of(context).textTheme.bodyMedium),
            if (r.psychologistNote != null) ...[
              const SizedBox(height: 4),
              Text('Note from them: "${r.psychologistNote}"',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ],
            if (r != requests.last)
              const Divider(height: MindCareTheme.spacingLg),
          ],
        ],
      ),
    );
  }
}
