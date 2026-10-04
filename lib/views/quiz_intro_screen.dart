import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../data/seed_psychologists.dart';
import '../models/consultation.dart';
import '../models/screening_result.dart';
import '../services/auth_service.dart';
import '../services/consultation_service.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../widgets/app_shell.dart';
import '../widgets/ui.dart';
import 'chat_screening_screen.dart';
import 'consultation_chat_screen.dart';
import 'recommendations_screen.dart';

/// The patient's workspace: a home page with the check-in, and an
/// appointments page to follow, reschedule or remove consultation requests.
class QuizIntroScreen extends StatefulWidget {
  const QuizIntroScreen({super.key});

  @override
  State<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends State<QuizIntroScreen> {
  int _tab = 0;
  bool _hasSession = false;
  ScreeningResult? _finishedResult;

  @override
  void initState() {
    super.initState();
    _refreshSession();
  }

  Future<void> _refreshSession() async {
    final id = context.read<AuthService>().currentUser?.id;
    if (id == null) return;
    final has = await ChatViewModel.hasSavedSession(id);
    final result = await ChatViewModel.loadFinishedResult(id);
    if (mounted) {
      setState(() {
        _hasSession = has;
        _finishedResult = result;
      });
    }
  }

  Future<void> _openChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreeningScreen()),
    );
    _refreshSession();
  }

  void _openRecommendations() {
    final result = _finishedResult;
    if (result == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecommendationsScreen(result: result)),
    );
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
    setState(() {
      _hasSession = false;
      _finishedResult = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session cleared. You can start fresh.')),
    );
  }

  /// "I'm not available at this time": tells the psychologist and asks for
  /// another slot.
  Future<void> _askReschedule(ConsultationRequest r) async {
    final service = context.read<ConsultationService>();
    final controller = TextEditingController();
    const quickReasons = [
      'I have class or work then',
      'I am not feeling well',
      'A family commitment came up',
      'Another time of day suits me better',
    ];

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('I\'m not available at this time'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your psychologist will see this and suggest another time. '
                  'You can add when you are free.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final reason in quickReasons)
                      ActionChip(
                        label: Text(reason),
                        onPressed: () =>
                            setLocal(() => controller.text = reason),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. I am busy then. Evenings after 6 PM work best.',
                    filled: true,
                    fillColor: MindCareTheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(MindCareTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: MindCareTheme.primary),
              child: const Text('Ask for another time'),
            ),
          ],
        ),
      ),
    );

    if (submitted == true) {
      service.requestReschedule(r.id, reason: controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sent. Your psychologist will suggest a new time.'),
        ),
      );
    }
    controller.dispose();
  }

  Future<void> _confirmRemove(ConsultationRequest r) async {
    final service = context.read<ConsultationService>();
    final doctor = SeedPsychologists.getById(r.psychologistId)?.name ??
        'the psychologist';
    final label = switch (r.status) {
      ConsultationStatus.pending => 'Withdraw this request?',
      ConsultationStatus.accepted ||
      ConsultationStatus.rescheduleRequested =>
        'Cancel this appointment?',
      _ => 'Remove this request?',
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: Text(
          'This removes your request to $doctor for both of you. '
          'You can reach out again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: TextStyle(color: MindCareTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) service.removeRequest(r.id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final requests = context
        .watch<ConsultationService>()
        .requestsForPatient(user?.email ?? '');
    final confirmed = requests
        .where((r) =>
            r.status == ConsultationStatus.accepted &&
            r.scheduledAt != null &&
            r.scheduledAt!.isAfter(DateTime.now()))
        .length;

    return AppShell(
      roleLabel: 'Patient',
      userName: user?.name ?? 'You',
      userEmail: user?.email,
      items: [
        const NavItem(Icons.home_outlined, 'Home'),
        NavItem(Icons.event_note_outlined, 'My appointments', badge: confirmed),
      ],
      selectedIndex: _tab,
      onSelect: (i) => setState(() => _tab = i),
      onLogout: () {
        auth.signOut();
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: _tab == 0 ? _home(user?.name, requests) : _appointments(requests),
    );
  }

  // ─── Home ─────────────────────────────────────────────────────────

  Widget _home(String? name, List<ConsultationRequest> requests) {
    final text = Theme.of(context).textTheme;
    final first = (name ?? 'there').split(' ').first;
    final next = requests
        .where((r) =>
            r.status == ConsultationStatus.accepted &&
            r.scheduledAt != null &&
            r.scheduledAt!.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

    final hero = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: MindCareTheme.primaryGradient,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusXl),
        boxShadow: MindCareTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _finishedResult != null
                ? 'Your check-in is complete'
                : _hasSession
                    ? 'Pick up where you left off'
                    : 'Start your wellness check-in',
            style: text.displayMedium
                ?.copyWith(color: Colors.white, fontSize: 26),
          ),
          const SizedBox(height: 8),
          Text(
            _finishedResult != null
                ? 'Your answers are saved. See the psychologists who fit best, '
                    'or review the conversation.'
                : 'A short, private chat about how you have been feeling. '
                    'About 3 to 5 minutes, and you can leave and resume any time.',
            style: text.bodyLarge
                ?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (_finishedResult != null)
                FilledButton.icon(
                  onPressed: _openRecommendations,
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Find a psychologist'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: MindCareTheme.primaryDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16),
                  ),
                ),
              FilledButton.icon(
                onPressed: _openChat,
                icon: Icon(_finishedResult != null
                    ? Icons.chat_bubble_outline
                    : Icons.play_arrow_rounded),
                label: Text(_finishedResult != null
                    ? 'View conversation'
                    : _hasSession
                        ? 'Resume conversation'
                        : 'Start conversation'),
                style: FilledButton.styleFrom(
                  backgroundColor: _finishedResult != null
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white,
                  foregroundColor: _finishedResult != null
                      ? Colors.white
                      : MindCareTheme.primaryDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                ),
              ),
              if (_hasSession)
                OutlinedButton.icon(
                  onPressed: _confirmNewSession,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('End session and start new'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    final steps = Panel(
      title: 'How it works',
      child: Column(
        children: const [
          _Step(
            n: 1,
            title: 'Chat about how you feel',
            body: 'Answer in your own words, or tap a quick option.',
          ),
          _Step(
            n: 2,
            title: 'Get matched',
            body: 'We suggest psychologists who fit what you shared.',
          ),
          _Step(
            n: 3,
            title: 'Book a session',
            body: 'Reach out, and follow the reply under My appointments.',
          ),
        ],
      ),
    );

    final nextCard = Panel(
      title: 'Next appointment',
      child: next.isEmpty
          ? const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Nothing booked yet',
              message: 'Once a psychologist confirms a time it appears here.',
            )
          : _NextAppointment(request: next.first),
    );

    final privacy = Panel(
      color: MindCareTheme.primaryLight.withValues(alpha: 0.35),
      borderColor: MindCareTheme.primary.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: MindCareTheme.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is a screening, not a diagnosis. What you share is analysed '
              'on your device and only seen by the professional you choose to '
              'contact. If you are in crisis, call your local emergency number '
              'or a helpline such as Tele-MANAS 14416 (India).',
              style: text.bodyMedium?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Hi, $first',
          subtitle: 'How are you feeling today?',
        ),
        hero,
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 820;
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: steps),
                    const SizedBox(width: 16),
                    Expanded(child: nextCard),
                  ],
                )
              : Column(children: [
                  steps,
                  const SizedBox(height: 16),
                  nextCard,
                ]);
        }),
        const SizedBox(height: 16),
        privacy,
      ],
    );
  }

  // ─── Appointments ─────────────────────────────────────────────────

  Widget _appointments(List<ConsultationRequest> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'My appointments',
          subtitle: 'Requests you have sent and their replies',
          actions: [
            if (_finishedResult != null)
              FilledButton.icon(
                onPressed: _openRecommendations,
                icon: const Icon(Icons.add),
                label: const Text('New request'),
                style: FilledButton.styleFrom(
                    backgroundColor: MindCareTheme.primary),
              ),
          ],
        ),
        if (requests.isEmpty)
          Panel(
            child: EmptyState(
              icon: Icons.event_note_outlined,
              title: 'No appointments yet',
              message: _finishedResult != null
                  ? 'Choose a psychologist to reach out to.'
                  : 'Finish your check-in to get matched with a psychologist.',
              action: FilledButton(
                onPressed: _finishedResult != null
                    ? _openRecommendations
                    : () => setState(() => _tab = 0),
                style: FilledButton.styleFrom(
                    backgroundColor: MindCareTheme.primary),
                child: Text(_finishedResult != null
                    ? 'Find a psychologist'
                    : 'Go to check-in'),
              ),
            ),
          )
        else
          for (final r in requests) ...[
            _AppointmentCard(
              request: r,
              onNotAvailable: () => _askReschedule(r),
              onRemove: () => _confirmRemove(r),
              onMessage: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConsultationChatScreen(
                      requestId: r.id, asDoctor: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String title;
  final String body;

  const _Step({required this.n, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: MindCareTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$n',
                style: const TextStyle(
                    color: MindCareTheme.primaryDark,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium?.copyWith(fontSize: 15)),
                Text(body, style: text.bodyMedium?.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextAppointment extends StatelessWidget {
  final ConsultationRequest request;
  const _NextAppointment({required this.request});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final doctor = SeedPsychologists.getById(request.psychologistId);
    return Row(
      children: [
        Avatar(doctor?.name.replaceFirst('Dr. ', '') ?? 'D', size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doctor?.name ?? 'Psychologist',
                  style: text.titleMedium?.copyWith(fontSize: 16)),
              Text(doctor?.title ?? '',
                  style: text.bodyMedium?.copyWith(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_available,
                      size: 16, color: MindCareTheme.success),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      request.scheduledAtLabel ?? '',
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: MindCareTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final ConsultationRequest request;
  final VoidCallback onNotAvailable;
  final VoidCallback onRemove;
  final VoidCallback onMessage;

  const _AppointmentCard({
    required this.request,
    required this.onNotAvailable,
    required this.onRemove,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = request;
    final doctor = SeedPsychologists.getById(r.psychologistId);

    final String detail;
    final Color? tint;
    final IconData icon;
    switch (r.status) {
      case ConsultationStatus.accepted:
      case ConsultationStatus.completed:
        detail = r.scheduledAtLabel != null
            ? 'Confirmed for ${r.scheduledAtLabel}'
            : 'Accepted. They will confirm a time soon.';
        tint = MindCareTheme.success;
        icon = Icons.event_available;
      case ConsultationStatus.rescheduleRequested:
        detail = 'You asked for another time'
            '${r.scheduledAtLabel != null ? ' (was ${r.scheduledAtLabel})' : ''}. '
            'Waiting for a new slot.';
        tint = MindCareTheme.accent;
        icon = Icons.event_repeat;
      case ConsultationStatus.declined:
        detail = 'This psychologist could not take your request. '
            'You can reach out to someone else.';
        tint = MindCareTheme.error;
        icon = Icons.event_busy;
      case ConsultationStatus.pending:
        detail = 'Sent ${r.timeAgoLabel}. Waiting for a reply.';
        tint = null;
        icon = Icons.hourglass_top;
    }

    final canReschedule = r.status == ConsultationStatus.accepted;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(doctor?.name.replaceFirst('Dr. ', '') ?? 'D', size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor?.name ?? 'Psychologist',
                        style: text.titleMedium?.copyWith(fontSize: 16)),
                    Text(doctor?.title ?? '',
                        style: text.bodyMedium?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              StatusPill(r.status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (tint ?? MindCareTheme.textSecondary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon,
                    size: 18, color: tint ?? MindCareTheme.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(detail,
                      style: text.bodyMedium?.copyWith(
                          color: MindCareTheme.textPrimary, fontSize: 13.5)),
                ),
              ],
            ),
          ),
          if (r.psychologistNote != null) ...[
            const SizedBox(height: 10),
            Text('Note from them: "${r.psychologistNote}"',
                style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          ],
          if (r.status == ConsultationStatus.rescheduleRequested &&
              r.rescheduleReason != null) ...[
            const SizedBox(height: 10),
            Text('You told them: "${r.rescheduleReason}"',
                style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (r.status != ConsultationStatus.declined)
                OutlinedButton.icon(
                  onPressed: onMessage,
                  icon: Badge(
                    isLabelVisible: r.unreadFor(asDoctor: false) > 0,
                    label: Text('${r.unreadFor(asDoctor: false)}'),
                    child: const Icon(Icons.chat_bubble_outline, size: 18),
                  ),
                  label: const Text('Message'),
                ),
              if (canReschedule)
                OutlinedButton.icon(
                  onPressed: onNotAvailable,
                  icon: const Icon(Icons.event_repeat, size: 18),
                  label: const Text('I\'m not available'),
                ),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(switch (r.status) {
                  ConsultationStatus.pending => 'Withdraw request',
                  ConsultationStatus.accepted ||
                  ConsultationStatus.rescheduleRequested =>
                    'Cancel appointment',
                  _ => 'Remove',
                }),
                style: TextButton.styleFrom(
                    foregroundColor: MindCareTheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
