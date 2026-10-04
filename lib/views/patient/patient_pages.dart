import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../data/seed_psychologists.dart';
import '../../models/consultation.dart';
import '../../models/mood_entry.dart';
import '../../services/mood_service.dart';
import '../../widgets/mood_widgets.dart';
import '../../widgets/motion.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/sliding_tabs.dart';
import '../../widgets/ui.dart';
import 'breathing_screen.dart';

/// Indexes of the patient workspace tabs.
class PatientTab {
  const PatientTab._();
  static const home = 0;
  static const journal = 1;
  static const mood = 2;
  static const wellness = 3;
  static const care = 4;
  static const profile = 5;
}

String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _shortDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

/// Two-column layout on wide screens, stacked on narrow ones. Items settle in
/// one after another (left and right columns interleaved).
Widget _twoColumns(List<Widget> left, List<Widget> right, {double gap = 24}) {
  const step = 60;
  Widget stack(List<Widget> items, int side, {bool single = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        FadeSlideIn(
          delay: Duration(
            milliseconds: step * (1 + (single ? i : i * 2 + side)),
          ),
          child: items[i],
        ),
      ],
    ],
  );
  return LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth >= 860) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: stack(left, 0)),
            SizedBox(width: gap),
            Expanded(flex: 2, child: stack(right, 1)),
          ],
        );
      }
      return stack([...left, ...right], 0, single: true);
    },
  );
}

// ─── Home ────────────────────────────────────────────────────────────

class PatientHomePage extends StatelessWidget {
  final String userId;
  final String name;
  final bool hasSession;
  final bool chatFinished;
  final ConsultationRequest? nextAppointment;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenRecommendations;
  final ValueChanged<int> onGoTo;
  final ValueChanged<String> onJournalPrompt;

  const PatientHomePage({
    super.key,
    required this.userId,
    required this.name,
    required this.hasSession,
    required this.chatFinished,
    required this.nextAppointment,
    required this.onOpenChat,
    required this.onOpenRecommendations,
    required this.onGoTo,
    required this.onJournalPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodService>();
    if (!mood.loaded) return const PatientHomeSkeleton();
    final text = Theme.of(context).textTheme;
    final first = name.trim().isEmpty ? 'there' : name.trim().split(' ').first;

    final checkIn = _CheckInCard(
      userId: userId,
      onWrite: () => onGoTo(PatientTab.journal),
    );

    final talkTitle =
        chatFinished
            ? 'Your conversation is complete'
            : hasSession
            ? 'Pick up where you left off'
            : 'Talk it through';
    final talkBody =
        chatFinished
            ? 'See the psychologists who might be a good fit.'
            : hasSession
            ? 'Your conversation is saved. Continue whenever you are ready.'
            : 'A gentle chat about how you have been feeling lately.';
    final talkAction =
        chatFinished
            ? 'Find a psychologist'
            : hasSession
            ? 'Resume'
            : 'Start';

    final actions = LayoutBuilder(
      builder: (context, c) {
        final tiles = [
          WellnessTile(
            icon: Icons.air,
            title: 'Take a breath',
            description: 'A 2-minute breathing exercise to slow things down.',
            actionLabel: 'Start',
            tint: MindCareTheme.primary,
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BreathingScreen()),
                ),
          ),
          WellnessTile(
            icon: Icons.chat_bubble_outline,
            title: talkTitle,
            description: talkBody,
            actionLabel: talkAction,
            tint: MindCareTheme.accent,
            onTap: chatFinished ? onOpenRecommendations : onOpenChat,
          ),
        ];
        return c.maxWidth >= 520
            ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: 16),
                Expanded(child: tiles[1]),
              ],
            )
            : Column(
              children: [tiles[0], const SizedBox(height: 16), tiles[1]],
            );
      },
    );

    final journal = JournalComposer(
      userId: userId,
      minLines: 3,
      title: 'What\'s on your mind?',
    );

    final trend = Panel(
      title: 'Your mood this week',
      trailing: TextButton(
        onPressed: () => onGoTo(PatientTab.mood),
        child: const Text('See more'),
      ),
      child: MoodChart(days: mood.lastDays(userId, 7), height: 170),
    );

    final reflection = ReflectionCard(lines: mood.reflections(userId));

    final next =
        nextAppointment == null
            ? null
            : Panel(
              title: 'Next appointment',
              trailing: TextButton(
                onPressed: () => onGoTo(PatientTab.care),
                child: const Text('Details'),
              ),
              child: Row(
                children: [
                  Avatar(
                    (SeedPsychologists.getById(
                              nextAppointment!.psychologistId,
                            )?.name ??
                            'D')
                        .replaceFirst('Dr. ', ''),
                    size: 48,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SeedPsychologists.getById(
                                nextAppointment!.psychologistId,
                              )?.name ??
                              'Your psychologist',
                          style: text.titleMedium,
                        ),
                        Text(
                          nextAppointment!.scheduledAtLabel ?? '',
                          style: text.bodyMedium?.copyWith(
                            color: MindCareTheme.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(
          child: PageHeader(
            title: '${greetingFor(DateTime.now())}, $first',
            subtitle: 'Take a moment for yourself today.',
          ),
        ),
        _twoColumns(
          [checkIn, actions, journal],
          [trend, reflection, if (next != null) next],
        ),
        const SizedBox(height: 32),
        FadeSlideIn(
          delay: const Duration(milliseconds: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A little time for you', style: text.headlineMedium),
              const SizedBox(height: 16),
              _WellnessGrid(
                onGoTo: onGoTo,
                onJournalPrompt: onJournalPrompt,
                compact: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The daily check-in. After a mood is chosen it settles into a quiet
/// "Today's check-in" summary with a checkmark, and can be changed again.
class _CheckInCard extends StatefulWidget {
  final String userId;
  final VoidCallback onWrite;
  const _CheckInCard({required this.userId, required this.onWrite});

  @override
  State<_CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<_CheckInCard> {
  /// null = decide from data (picker until today has a mood).
  bool? _picking;
  Timer? _settleTimer;

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MoodService>();
    final today = service.todayEntry(widget.userId);
    final picking = _picking ?? (today == null);
    final text = Theme.of(context).textTheme;

    final Widget body =
        picking
            ? Column(
              key: const ValueKey('picker'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How are you feeling today?', style: text.titleLarge),
                const SizedBox(height: 2),
                Text(
                  'A small check-in can make a difference.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 16),
                MoodPicker(
                  selected: today?.mood,
                  onSelect: (m) {
                    service.setTodayMood(widget.userId, m);
                    // Let the selection ripple finish before the card settles.
                    _settleTimer?.cancel();
                    _settleTimer = Timer(const Duration(milliseconds: 700), () {
                      if (mounted) setState(() => _picking = false);
                    });
                  },
                ),
              ],
            )
            : Column(
              key: const ValueKey('done'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MindCareTheme.moodColor(
                          today?.mood ?? 2,
                        ).withValues(alpha: 0.55),
                      ),
                      child: MoodFace(mood: today?.mood ?? 2, size: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's check-in", style: text.titleLarge),
                          Text(
                            'Feeling ${Moods.label(today?.mood ?? 2).toLowerCase()} today.',
                            style: text.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: MindCareTheme.primary.withValues(
                                alpha: 0.4,
                              ),
                              borderRadius: BorderRadius.circular(
                                MindCareTheme.radiusFull,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Motion.of(
                                    context,
                                    const Duration(milliseconds: 380),
                                  ),
                                  curve: Curves.easeOutBack,
                                  builder:
                                      (context, t, child) => Opacity(
                                        opacity: t.clamp(0.0, 1.0),
                                        child: Transform.scale(
                                          scale: 0.4 + 0.6 * t,
                                          child: child,
                                        ),
                                      ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: MindCareTheme.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Checked in',
                                    style: text.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'You made space for yourself today. Keep going, gently.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _picking = true),
                      child: const Text('Change'),
                    ),
                    TextButton(
                      onPressed: widget.onWrite,
                      child: const Text('Add a few words'),
                    ),
                  ],
                ),
              ],
            );

    return Panel(
      padding: const EdgeInsets.all(24),
      color: picking ? null : MindCareTheme.primaryLight.withValues(alpha: 0.5),
      borderColor:
          picking ? null : MindCareTheme.primary.withValues(alpha: 0.4),
      child: SoftSize(
        duration: const Duration(milliseconds: 300),
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: Motion.of(context, const Duration(milliseconds: 320)),
          switchInCurve: Motion.soft,
          switchOutCurve: Curves.easeIn,
          layoutBuilder:
              (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, if (current != null) current],
              ),
          child: body,
        ),
      ),
    );
  }
}

// ─── Journal ─────────────────────────────────────────────────────────

class PatientJournalPage extends StatelessWidget {
  final String userId;
  final GlobalKey<JournalComposerState> composerKey;

  const PatientJournalPage({
    super.key,
    required this.userId,
    required this.composerKey,
  });

  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodService>();
    final entries = mood.journalFor(userId);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideIn(
          child: PageHeader(
            title: 'Journal',
            subtitle: 'A private place for whatever is on your mind.',
          ),
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 70),
          child: JournalComposer(key: composerKey, userId: userId),
        ),
        const SizedBox(height: 32),
        Text('Your reflections', style: text.headlineMedium),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          const Panel(
            child: EmptyState(
              icon: Icons.edit_note,
              title: 'Nothing here yet.',
              message: 'Your reflections will appear here as you write.',
            ),
          )
        else
          for (final e in entries) ...[
            _JournalEntryCard(entry: e, onDelete: () => mood.deleteEntry(e.id)),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  final MoodEntry entry;
  final VoidCallback onDelete;
  const _JournalEntryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MindCareTheme.moodColor(entry.mood).withValues(alpha: 0.5),
            ),
            child: MoodFace(mood: entry.mood, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_shortDate(entry.createdAt)}  ·  ${Moods.label(entry.mood)}',
                  style: text.bodyMedium?.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                Text(entry.note, style: text.bodyLarge?.copyWith(fontSize: 15)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: MindCareTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mood ────────────────────────────────────────────────────────────

class PatientMoodPage extends StatefulWidget {
  final String userId;
  const PatientMoodPage({super.key, required this.userId});

  @override
  State<PatientMoodPage> createState() => _PatientMoodPageState();
}

class _PatientMoodPageState extends State<PatientMoodPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    final mood = context.watch<MoodService>();
    final text = Theme.of(context).textTheme;
    if (!mood.loaded) {
      return const Shimmer(
        child: Column(children: [ChartSkeleton(height: 220)]),
      );
    }

    final overview = Column(
      key: const ValueKey('overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveGrid(
          wideColumns: 3,
          narrowColumns: 1,
          children: [
            StatTile(
              icon: Icons.favorite_border,
              label: 'Check-ins this week',
              value: '${mood.checkInDaysThisWeek(userId)}',
              color: MindCareTheme.primary,
            ),
            StatTile(
              icon: Icons.local_fire_department_outlined,
              label: 'Days in a row',
              value: '${mood.streak(userId)}',
              color: MindCareTheme.accent,
            ),
            StatTile(
              icon: Icons.edit_note,
              label: 'Reflections written',
              value: '${mood.journalFor(userId).length}',
              color: MindCareTheme.butterDeep,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _twoColumns(
          [
            Panel(
              title: 'This week',
              subtitle: 'Sage is calm, coral is lower.',
              child: MoodChart(days: mood.lastDays(userId, 7), height: 220),
            ),
          ],
          [ReflectionCard(lines: mood.reflections(userId))],
        ),
      ],
    );

    final month = mood.lastDays(userId, 30);
    final trends = Column(
      key: const ValueKey('trends'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          title: 'The last two weeks',
          child: MoodChart(days: mood.lastDays(userId, 14), height: 220),
        ),
        const SizedBox(height: 24),
        _twoColumns(
          [
            Panel(
              title: 'The last 30 days',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final e in month)
                    Tooltip(
                      message:
                          e == null
                              ? 'No check-in'
                              : '${_shortDate(e.createdAt)}: ${Moods.label(e.mood)}',
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              e == null
                                  ? MindCareTheme.surfaceVariant
                                  : MindCareTheme.moodColor(e.mood),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          [
            Panel(
              title: 'About these colours',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final m in Moods.pickerOrder)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MindCareTheme.moodColor(m),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            Moods.label(m),
                            style: text.bodyLarge?.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'These colours are only a way of seeing your own week. They are not a diagnosis.',
                    style: text.bodyMedium?.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    final all = mood.entriesFor(userId);
    final history = Column(
      key: const ValueKey('history'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (all.isEmpty)
          const Panel(
            child: EmptyState(
              icon: Icons.history,
              title: 'Nothing here yet.',
              message: 'Your reflections will appear here as you check in.',
            ),
          )
        else
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                for (int i = 0; i < all.length && i < 40; i++) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MindCareTheme.moodColor(
                              all[i].mood,
                            ).withValues(alpha: 0.5),
                          ),
                          child: MoodFace(mood: all[i].mood, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            all[i].isJournal
                                ? all[i].note
                                : 'Checked in: ${Moods.label(all[i].mood)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyLarge?.copyWith(fontSize: 14.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _shortDate(all[i].createdAt),
                          style: text.bodyMedium?.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideIn(
          child: PageHeader(
            title: 'Mood',
            subtitle: 'How the last while has felt, at a glance.',
          ),
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SlidingTabs(
                labels: const ['Overview', 'Trends', 'History'],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: Motion.of(context, const Duration(milliseconds: 280)),
          switchInCurve: Motion.soft,
          switchOutCurve: Curves.easeIn,
          transitionBuilder:
              (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.012),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
          layoutBuilder:
              (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              ),
          child: switch (_tab) {
            0 => overview,
            1 => trends,
            _ => history,
          },
        ),
      ],
    );
  }
}

// ─── Wellness ────────────────────────────────────────────────────────

class PatientWellnessPage extends StatelessWidget {
  final ValueChanged<int> onGoTo;
  final ValueChanged<String> onJournalPrompt;

  const PatientWellnessPage({
    super.key,
    required this.onGoTo,
    required this.onJournalPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideIn(
          child: PageHeader(
            title: 'Wellness',
            subtitle: 'Small things that can help you feel a little steadier.',
          ),
        ),
        _WellnessGrid(onGoTo: onGoTo, onJournalPrompt: onJournalPrompt),
      ],
    );
  }
}

class _WellnessGrid extends StatelessWidget {
  final ValueChanged<int> onGoTo;
  final ValueChanged<String> onJournalPrompt;
  final bool compact;

  const _WellnessGrid({
    required this.onGoTo,
    required this.onJournalPrompt,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      WellnessTile(
        icon: Icons.air,
        title: 'Take a breath',
        description: 'A 2-minute breathing exercise to slow things down.',
        actionLabel: 'Start',
        tint: MindCareTheme.primary,
        onTap:
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BreathingScreen())),
      ),
      WellnessTile(
        icon: Icons.self_improvement,
        title: 'Grounding',
        description: 'Come back to the room with five gentle steps.',
        actionLabel: 'Begin',
        tint: MindCareTheme.butter,
        onTap: () => showGroundingDialog(context),
      ),
      WellnessTile(
        icon: Icons.favorite_border,
        title: 'Gratitude',
        description: 'Write down one small thing that went okay today.',
        actionLabel: 'Write',
        tint: MindCareTheme.accent,
        onTap: () {
          onJournalPrompt('Today I am grateful for');
        },
      ),
      if (!compact) ...[
        WellnessTile(
          icon: Icons.timer_outlined,
          title: 'A mindful minute',
          description: 'Sixty seconds to pause between things.',
          actionLabel: 'Start',
          tint: MindCareTheme.butter,
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BreathingScreen(minutes: 1),
                ),
              ),
        ),
        WellnessTile(
          icon: Icons.bedtime_outlined,
          title: 'Sleep reflection',
          description: 'Notice how you slept and what might help tonight.',
          actionLabel: 'Reflect',
          tint: MindCareTheme.primary,
          onTap: () => onJournalPrompt('Last night I slept'),
        ),
        WellnessTile(
          icon: Icons.chat_bubble_outline,
          title: 'Talk it through',
          description:
              'A gentle conversation, and a way to reach a psychologist.',
          actionLabel: 'Open',
          tint: MindCareTheme.accent,
          onTap: () => onGoTo(PatientTab.care),
        ),
      ],
    ];
    return ResponsiveGrid(
      wideColumns: 3,
      narrowColumns: 1,
      children: [
        for (int i = 0; i < tiles.length; i++)
          FadeSlideIn(
            delay: Duration(milliseconds: 70 + 60 * i),
            child: tiles[i],
          ),
      ],
    );
  }
}

// ─── Profile ─────────────────────────────────────────────────────────

class PatientProfilePage extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final VoidCallback onSignOut;

  const PatientProfilePage({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.onSignOut,
  });

  Future<void> _deleteReflections(BuildContext context) async {
    final mood = context.read<MoodService>();
    final ok = await showSoftDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete your reflections?'),
            content: const Text(
              'This removes every mood check-in and journal entry on this device. '
              'It cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep them'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: MindCareTheme.error),
                ),
              ),
            ],
          ),
    );
    if (ok == true) mood.clearFor(userId);
  }

  @override
  Widget build(BuildContext context) {
    final mood = context.watch<MoodService>();
    final text = Theme.of(context).textTheme;

    Widget row(IconData icon, String title, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MindCareTheme.primaryDark),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: text.bodyLarge?.copyWith(fontSize: 15)),
          ),
          Text(value, style: text.bodyMedium),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          padding: const EdgeInsets.all(28),
          child: Row(
            children: [
              Avatar(name, size: 68),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: text.displaySmall),
                    const SizedBox(height: 2),
                    Text('We are glad you are here.', style: text.bodyLarge),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: text.bodyMedium?.copyWith(fontSize: 12.5),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _twoColumns(
          [
            Panel(
              title: 'Your progress',
              child: Column(
                children: [
                  row(
                    Icons.favorite_border,
                    'Check-ins this week',
                    '${mood.checkInDaysThisWeek(userId)}',
                  ),
                  const Divider(),
                  row(
                    Icons.local_fire_department_outlined,
                    'Days in a row',
                    '${mood.streak(userId)}',
                  ),
                  const Divider(),
                  row(
                    Icons.edit_note,
                    'Reflections written',
                    '${mood.journalFor(userId).length}',
                  ),
                ],
              ),
            ),
            Panel(
              title: 'Your preferences',
              child: Column(
                children: [
                  row(
                    Icons.notifications_none,
                    'Gentle reminders',
                    'Coming soon',
                  ),
                  const Divider(),
                  row(Icons.palette_outlined, 'Appearance', 'Warm light'),
                  const Divider(),
                  row(
                    Icons.nights_stay_outlined,
                    'Evening mode',
                    'Coming soon',
                  ),
                ],
              ),
            ),
          ],
          [
            Panel(
              color: MindCareTheme.primaryLight.withValues(alpha: 0.5),
              borderColor: MindCareTheme.primary.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: MindCareTheme.primaryDark,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your space, your privacy.',
                          style: text.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your personal reflections belong to you. They stay on this device, '
                    'and only what you choose to send is seen by a psychologist.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _deleteReflections(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete my reflections'),
                  ),
                ],
              ),
            ),
            Panel(
              title: 'About Mindcare',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mindcare is a screening and support companion, not a diagnosis '
                    'or a replacement for professional care. If you are in crisis, '
                    'please contact your local emergency number or a helpline such as '
                    'Tele-MANAS 14416 (India).',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
