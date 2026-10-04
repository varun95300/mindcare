import 'package:flutter/material.dart';
import '../widgets/motion.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../data/seed_psychologists.dart';
import '../models/consultation.dart';
import '../models/screening_result.dart';
import '../services/auth_service.dart';
import '../services/consultation_service.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../widgets/app_shell.dart';
import '../widgets/feedback.dart';
import '../widgets/mood_widgets.dart';
import '../widgets/ui.dart';
import 'patient/patient_pages.dart';
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatScreeningScreen()));
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

    final confirmed = await showSoftDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
                child: Text(
                  'Delete and start new',
                  style: TextStyle(color: MindCareTheme.error),
                ),
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
    Toasts.show('Session cleared. You can start fresh.');
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

    final submitted = await showSoftDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => AlertDialog(
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
                                onPressed:
                                    () => setLocal(
                                      () => controller.text = reason,
                                    ),
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
                              borderRadius: BorderRadius.circular(
                                MindCareTheme.radiusMd,
                              ),
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
                        backgroundColor: MindCareTheme.primary,
                      ),
                      child: const Text('Ask for another time'),
                    ),
                  ],
                ),
          ),
    );

    if (submitted == true) {
      service.requestReschedule(r.id, reason: controller.text);
      if (!mounted) return;
      Toasts.show('Sent. Your psychologist will suggest a new time.');
    }
    controller.dispose();
  }

  Future<void> _confirmRemove(ConsultationRequest r) async {
    final service = context.read<ConsultationService>();
    final doctor =
        SeedPsychologists.getById(r.psychologistId)?.name ?? 'the psychologist';
    final label = switch (r.status) {
      ConsultationStatus.pending => 'Withdraw this request?',
      ConsultationStatus.accepted ||
      ConsultationStatus.rescheduleRequested => 'Cancel this appointment?',
      _ => 'Remove this request?',
    };
    final ok = await showSoftDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
                child: Text(
                  'Remove',
                  style: TextStyle(color: MindCareTheme.error),
                ),
              ),
            ],
          ),
    );
    if (ok == true) service.removeRequest(r.id);
  }

  final GlobalKey<JournalComposerState> _journalKey =
      GlobalKey<JournalComposerState>();

  /// Open the journal, optionally starting with a writing prompt.
  void _goJournal(String prompt) {
    setState(() => _tab = PatientTab.journal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _journalKey.currentState?.setPrompt(prompt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final userId = user?.id ?? 'anonymous';
    final requests = context.watch<ConsultationService>().requestsForPatient(
      user?.email ?? '',
    );
    final upcoming =
        requests
            .where(
              (r) =>
                  r.status == ConsultationStatus.accepted &&
                  r.scheduledAt != null &&
                  r.scheduledAt!.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

    final Widget page = switch (_tab) {
      PatientTab.home => PatientHomePage(
        userId: userId,
        name: user?.name ?? '',
        hasSession: _hasSession,
        chatFinished: _finishedResult != null,
        nextAppointment: upcoming.isEmpty ? null : upcoming.first,
        onOpenChat: _openChat,
        onOpenRecommendations: _openRecommendations,
        onGoTo: (t) => setState(() => _tab = t),
        onJournalPrompt: _goJournal,
      ),
      PatientTab.journal => PatientJournalPage(
        userId: userId,
        composerKey: _journalKey,
      ),
      PatientTab.mood => PatientMoodPage(userId: userId),
      PatientTab.wellness => PatientWellnessPage(
        onGoTo: (t) => setState(() => _tab = t),
        onJournalPrompt: _goJournal,
      ),
      PatientTab.care => _care(requests),
      _ => PatientProfilePage(
        userId: userId,
        name: user?.name ?? '',
        email: user?.email ?? '',
        onSignOut: () {
          auth.signOut();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    };

    return AppShell(
      roleLabel: 'Personal space',
      userName: user?.name ?? 'You',
      userEmail: user?.email,
      items: [
        const NavItem(Icons.home_outlined, 'Home'),
        const NavItem(Icons.edit_note, 'Journal'),
        const NavItem(Icons.show_chart, 'Mood'),
        const NavItem(Icons.spa_outlined, 'Wellness'),
        NavItem(Icons.favorite_border, 'Care', badge: upcoming.length),
      ],
      selectedIndex: _tab,
      onSelect: (i) => setState(() => _tab = i),
      menuExtras: const [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: 10),
              Text('Profile'),
            ],
          ),
        ),
      ],
      onMenuSelected: (v) {
        if (v == 'profile') setState(() => _tab = PatientTab.profile);
      },
      onLogout: () {
        auth.signOut();
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      pageKey: _tab,
      child: page,
    );
  }

  // ─── Care: the conversation and appointments ──────────────────────

  Widget _care(List<ConsultationRequest> requests) {
    final text = Theme.of(context).textTheme;
    final finished = _finishedResult != null;

    final conversation = Panel(
      color: MindCareTheme.primaryLight.withValues(alpha: 0.6),
      borderColor: MindCareTheme.primary.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            finished
                ? 'Your conversation is complete'
                : _hasSession
                ? 'Pick up where you left off'
                : 'Talk it through',
            style: text.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            finished
                ? 'Your answers are saved. See the psychologists who might be a good fit, or read the conversation again.'
                : 'A short, private chat about how you have been feeling lately. About 3 to 5 minutes, and you can leave and resume any time.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (finished)
                FilledButton.icon(
                  onPressed: _openRecommendations,
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Find a psychologist'),
                ),
              finished
                  ? OutlinedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('View conversation'),
                  )
                  : FilledButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      _hasSession
                          ? 'Resume conversation'
                          : 'Start conversation',
                    ),
                  ),
              if (_hasSession)
                TextButton.icon(
                  onPressed: _confirmNewSession,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('End session and start new'),
                  style: TextButton.styleFrom(
                    foregroundColor: MindCareTheme.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: MindCareTheme.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is a screening, not a diagnosis. What you share is analysed on '
                  'your device and only seen by the professional you choose to contact.',
                  style: text.bodyMedium?.copyWith(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: FadeSlideIn.stagger([
        const PageHeader(
          title: 'Care',
          subtitle: 'Talk it through, and keep track of your appointments.',
        ),
        conversation,
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Text('My appointments', style: text.headlineMedium),
            ),
            if (finished)
              FilledButton.icon(
                onPressed: _openRecommendations,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New request'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          const Panel(
            child: EmptyState(
              icon: Icons.event_note_outlined,
              title: 'Nothing here yet.',
              message:
                  'When you reach out to a psychologist, their reply will appear here.',
            ),
          )
        else
          for (final r in requests) ...[
            _AppointmentCard(
              request: r,
              onNotAvailable: () => _askReschedule(r),
              onRemove: () => _confirmRemove(r),
              onMessage:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => ConsultationChatScreen(
                            requestId: r.id,
                            asDoctor: false,
                          ),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
          ],
      ]),
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
        detail =
            r.scheduledAtLabel != null
                ? 'Confirmed for ${r.scheduledAtLabel}'
                : 'Accepted. They will confirm a time soon.';
        tint = MindCareTheme.success;
        icon = Icons.event_available;
      case ConsultationStatus.rescheduleRequested:
        detail =
            'You asked for another time'
            '${r.scheduledAtLabel != null ? ' (was ${r.scheduledAtLabel})' : ''}. '
            'Waiting for a new slot.';
        tint = MindCareTheme.accent;
        icon = Icons.event_repeat;
      case ConsultationStatus.declined:
        detail =
            'This psychologist could not take your request. '
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
                    Text(
                      doctor?.name ?? 'Psychologist',
                      style: text.titleMedium?.copyWith(fontSize: 16),
                    ),
                    Text(
                      doctor?.title ?? '',
                      style: text.bodyMedium?.copyWith(fontSize: 13),
                    ),
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
              color: (tint ?? MindCareTheme.textSecondary).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: tint ?? MindCareTheme.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    detail,
                    style: text.bodyMedium?.copyWith(
                      color: MindCareTheme.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (r.psychologistNote != null) ...[
            const SizedBox(height: 10),
            Text(
              'Note from them: "${r.psychologistNote}"',
              style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          if (r.status == ConsultationStatus.rescheduleRequested &&
              r.rescheduleReason != null) ...[
            const SizedBox(height: 10),
            Text(
              'You told them: "${r.rescheduleReason}"',
              style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
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
                  ConsultationStatus
                      .rescheduleRequested => 'Cancel appointment',
                  _ => 'Remove',
                }),
                style: TextButton.styleFrom(
                  foregroundColor: MindCareTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
