import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../data/seed_psychologists.dart';
import '../../models/consultation.dart';
import '../../models/quiz_question.dart';
import '../../services/auth_service.dart';
import '../../services/consultation_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/motion.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/ui.dart';
import '../consultation_chat_screen.dart';
import 'analytics_widgets.dart';
import 'doctor_calendar.dart';
import 'patient_report_screen.dart';
import 'schedule_appointment_screen.dart';

/// Psychologist workspace: overview with charts, a searchable request list,
/// and a schedule of confirmed appointments.
class PsychologistDashboardScreen extends StatefulWidget {
  const PsychologistDashboardScreen({super.key});

  @override
  State<PsychologistDashboardScreen> createState() =>
      _PsychologistDashboardScreenState();
}

class _PsychologistDashboardScreenState
    extends State<PsychologistDashboardScreen> {
  int _tab = 0;
  String _search = '';
  ConsultationStatus? _filter;

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
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

  String get _today {
    final d = DateTime.now();
    return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  void _openReport(ConsultationRequest r) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PatientReportScreen(request: r)));
  }

  void _openChat(ConsultationRequest r) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsultationChatScreen(requestId: r.id, asDoctor: true),
      ),
    );
  }

  void _openSchedule(ConsultationRequest r) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScheduleAppointmentScreen(request: r)),
    );
  }

  Future<void> _confirmRemove(ConsultationRequest r) async {
    final service = context.read<ConsultationService>();
    final ok = await showSoftDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove this request?'),
            content: Text(
              'This removes ${r.patientName}\'s request for you and for them. '
              'It cannot be undone.',
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

  Future<void> _resetDemo() async {
    final service = context.read<ConsultationService>();
    final ok = await showSoftDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reset demo data?'),
            content: const Text(
              'All requests go back to the original sample requests. '
              'Accounts and chat sessions are not touched.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
    if (ok == true) await service.resetDemoData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final service = context.watch<ConsultationService>();
    final user = auth.currentUser;
    final psychologist =
        user?.psychologistId != null
            ? SeedPsychologists.getById(user!.psychologistId!)
            : null;
    final requests =
        psychologist != null
            ? service.requestsForPsychologist(psychologist.id)
            : <ConsultationRequest>[];

    final open =
        requests
            .where(
              (r) =>
                  r.status == ConsultationStatus.pending ||
                  r.status == ConsultationStatus.rescheduleRequested,
            )
            .length;

    return AppShell(
      roleLabel: 'Psychologist',
      userName: psychologist?.name ?? user?.name ?? 'Psychologist',
      items: [
        const NavItem(Icons.space_dashboard_outlined, 'Overview'),
        NavItem(Icons.inbox_outlined, 'Requests', badge: open),
        const NavItem(Icons.event_outlined, 'Schedule'),
      ],
      selectedIndex: _tab,
      onSelect: (i) => setState(() => _tab = i),
      menuExtras: const [
        PopupMenuItem(
          value: 'reset',
          child: Row(
            children: [
              Icon(Icons.restart_alt, size: 18),
              SizedBox(width: 10),
              Text('Reset demo data'),
            ],
          ),
        ),
      ],
      onMenuSelected: (v) {
        if (v == 'reset') _resetDemo();
      },
      onLogout: () {
        auth.logout();
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      pageKey: _tab,
      child:
          !service.loaded
              ? const DashboardSkeleton()
              : switch (_tab) {
                0 => _overview(psychologist?.name, requests),
                1 => _requestsPage(requests),
                _ => _schedulePage(requests, psychologist?.id),
              },
    );
  }

  // ─── Overview ─────────────────────────────────────────────────────

  Widget _overview(String? name, List<ConsultationRequest> all) {
    final pending =
        all.where((r) => r.status == ConsultationStatus.pending).toList();
    final reschedule =
        all
            .where((r) => r.status == ConsultationStatus.rescheduleRequested)
            .toList();
    final upcoming =
        all
            .where(
              (r) =>
                  r.status == ConsultationStatus.accepted &&
                  r.scheduledAt != null &&
                  r.scheduledAt!.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    final highRisk =
        all
            .where(
              (r) =>
                  r.status != ConsultationStatus.declined &&
                  r.screeningResult.peakRiskLevel.needsSafetyResponse,
            )
            .toList();

    final needsAttention = [...pending, ...reschedule]..sort((a, b) {
      final risk = b.screeningResult.peakRiskLevel.index.compareTo(
        a.screeningResult.peakRiskLevel.index,
      );
      return risk != 0 ? risk : b.requestedAt.compareTo(a.requestedAt);
    });

    final first = (name ?? 'Doctor').replaceFirst('Dr. ', '').split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: FadeSlideIn.stagger([
        PageHeader(title: 'Welcome back, Dr. $first', subtitle: _today),
        ResponsiveGrid(
          wideColumns: 4,
          narrowColumns: 2,
          children: [
            StatTile(
              icon: Icons.mark_email_unread_outlined,
              label: 'New requests',
              value: '${pending.length}',
              caption: 'Awaiting your reply',
              color: MindCareTheme.butterDeep,
            ),
            StatTile(
              icon: Icons.event_repeat,
              label: 'Reschedule asks',
              value: '${reschedule.length}',
              caption: 'Patient needs a new time',
              color: MindCareTheme.accent,
            ),
            StatTile(
              icon: Icons.event_available_outlined,
              label: 'Upcoming sessions',
              value: '${upcoming.length}',
              caption:
                  upcoming.isEmpty
                      ? 'Nothing booked yet'
                      : 'Next: ${_short(upcoming.first.scheduledAt!)}',
              color: MindCareTheme.primaryDark,
            ),
            StatTile(
              icon: Icons.health_and_safety_outlined,
              label: 'High-risk flags',
              value: '${highRisk.length}',
              caption: highRisk.isEmpty ? 'None right now' : 'Review first',
              color: MindCareTheme.error,
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 820;
            final concern = Panel(
              title: 'Concern areas',
              subtitle: 'Primary area from patients\' screenings',
              child: SizedBox(height: 230, child: _ConcernChart(requests: all)),
            );
            final status = Panel(
              title: 'Request status',
              subtitle:
                  '${all.length} request${all.length == 1 ? '' : 's'} in total',
              child: _StatusDonut(requests: all),
            );
            return wide
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: concern),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: status),
                  ],
                )
                : Column(
                  children: [concern, const SizedBox(height: 16), status],
                );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 1000;
            final risk = Panel(
              title: 'Risk levels',
              subtitle: 'Highest wording-based risk per patient',
              child: RiskBreakdown(requests: all),
            );
            final emotions = Panel(
              title: 'Emotions expressed',
              subtitle: 'Across all patient chats',
              child: EmotionBars(
                results: [for (final r in all) r.screeningResult],
              ),
            );
            final trend = Panel(
              title: 'Requests this week',
              subtitle: 'New requests per day',
              child: RequestsTrend(requests: all),
            );
            return wide
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: risk),
                    const SizedBox(width: 16),
                    Expanded(child: emotions),
                    const SizedBox(width: 16),
                    Expanded(child: trend),
                  ],
                )
                : Column(
                  children: [
                    risk,
                    const SizedBox(height: 16),
                    emotions,
                    const SizedBox(height: 16),
                    trend,
                  ],
                );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 820;
            final attention = Panel(
              title: 'Needs your attention',
              subtitle: 'Highest risk first',
              trailing: TextButton(
                onPressed: () => setState(() => _tab = 1),
                child: const Text('See all requests'),
              ),
              child:
                  needsAttention.isEmpty
                      ? const EmptyState(
                        icon: Icons.task_alt,
                        title: 'All caught up',
                        message: 'No requests are waiting for you.',
                      )
                      : Column(
                        children: [
                          for (final r in needsAttention.take(5))
                            _CompactRequest(
                              request: r,
                              onReport: () => _openReport(r),
                              onSchedule: () => _openSchedule(r),
                            ),
                        ],
                      ),
            );
            final next = Panel(
              title: 'Upcoming appointments',
              subtitle: 'Confirmed sessions',
              trailing: TextButton(
                onPressed: () => setState(() => _tab = 2),
                child: const Text('Open schedule'),
              ),
              child:
                  upcoming.isEmpty
                      ? const EmptyState(
                        icon: Icons.event_busy_outlined,
                        title: 'No sessions yet',
                        message: 'Accept a request to book one.',
                      )
                      : Column(
                        children: [
                          for (final r in upcoming.take(4))
                            _AppointmentTile(
                              request: r,
                              onReport: () => _openReport(r),
                            ),
                        ],
                      ),
            );
            return wide
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: attention),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: next),
                  ],
                )
                : Column(
                  children: [attention, const SizedBox(height: 16), next],
                );
          },
        ),
      ]),
    );
  }

  String _short(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]}, $h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  // ─── Requests ─────────────────────────────────────────────────────

  Widget _requestsPage(List<ConsultationRequest> all) {
    final q = _search.trim().toLowerCase();
    final shown =
        all.where((r) {
          if (_filter != null && r.status != _filter) return false;
          if (q.isEmpty) return true;
          return r.patientName.toLowerCase().contains(q) ||
              r.patientEmail.toLowerCase().contains(q) ||
              r.screeningResult.primaryDomain.label.toLowerCase().contains(q);
        }).toList();

    int count(ConsultationStatus s) => all.where((r) => r.status == s).length;

    Widget chip(String label, ConsultationStatus? status, int n) {
      final selected = _filter == status;
      return ChoiceChip(
        label: Text('$label  $n'),
        selected: selected,
        onSelected: (_) => setState(() => _filter = status),
        selectedColor: MindCareTheme.primaryLight,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color:
              selected
                  ? MindCareTheme.primaryDark
                  : MindCareTheme.textSecondary,
        ),
        side: BorderSide(color: MindCareTheme.border),
        backgroundColor: MindCareTheme.surface,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Requests',
          subtitle: 'Patients who have reached out to you',
        ),
        Panel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ExpandingSearch(onChanged: (v) => setState(() => _search = v)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  chip('All', null, all.length),
                  chip(
                    'Pending',
                    ConsultationStatus.pending,
                    count(ConsultationStatus.pending),
                  ),
                  chip(
                    'Reschedule',
                    ConsultationStatus.rescheduleRequested,
                    count(ConsultationStatus.rescheduleRequested),
                  ),
                  chip(
                    'Accepted',
                    ConsultationStatus.accepted,
                    count(ConsultationStatus.accepted),
                  ),
                  chip(
                    'Declined',
                    ConsultationStatus.declined,
                    count(ConsultationStatus.declined),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: Motion.of(context, const Duration(milliseconds: 240)),
          switchInCurve: Motion.soft,
          child: Column(
            key: ValueKey('${_filter?.name}|$_search'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shown.isEmpty)
                const Panel(
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No matching requests',
                    message: 'Try a different search or filter.',
                  ),
                )
              else
                for (final r in shown) ...[
                  _RequestCard(
                    request: r,
                    onReport: () => _openReport(r),
                    onSchedule: () => _openSchedule(r),
                    onRemove: () => _confirmRemove(r),
                    onMessage: () => _openChat(r),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Schedule ─────────────────────────────────────────────────────

  Widget _schedulePage(List<ConsultationRequest> all, String? psychologistId) {
    final booked =
        all
            .where(
              (r) =>
                  r.status == ConsultationStatus.accepted &&
                  r.scheduledAt != null,
            )
            .toList()
          ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

    // Group by calendar day
    final byDay = <String, List<ConsultationRequest>>{};
    for (final r in booked) {
      final d = r.scheduledAt!;
      final key =
          '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
      byDay.putIfAbsent(key, () => []).add(r);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Schedule',
          subtitle: 'Your calendar, appointments and blocked time',
        ),
        if (psychologistId != null) ...[
          DoctorCalendar(
            psychologistId: psychologistId,
            onOpenAppointment: _openReport,
          ),
          const SizedBox(height: 24),
          Text('Upcoming list', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
        ],
        if (byDay.isEmpty)
          const Panel(
            child: EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Nothing scheduled',
              message: 'Accept a request and pick a time to see it here.',
            ),
          )
        else
          for (final entry in byDay.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  for (final r in entry.value)
                    _AppointmentTile(
                      request: r,
                      onReport: () => _openReport(r),
                      onReschedule: () => _openSchedule(r),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

// ─── Charts ────────────────────────────────────────────────────────

class _ConcernChart extends StatelessWidget {
  final List<ConsultationRequest> requests;
  const _ConcernChart({required this.requests});

  @override
  Widget build(BuildContext context) {
    final counts = {for (final d in ScreeningDomain.values) d: 0};
    for (final r in requests) {
      counts[r.screeningResult.primaryDomain] =
          counts[r.screeningResult.primaryDomain]! + 1;
    }
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxCount == 0) {
      return const EmptyState(
        icon: Icons.bar_chart,
        title: 'No data yet',
        message: 'Charts appear once patients reach out.',
      );
    }
    final domains = ScreeningDomain.values;
    const shortLabels = {
      ScreeningDomain.anxiety: 'Anxiety',
      ScreeningDomain.depression: 'Depression',
      ScreeningDomain.stress: 'Stress',
      ScreeningDomain.interpersonal: 'Interpersonal',
    };

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxCount + 1).toDouble(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine:
              (_) => FlLine(color: MindCareTheme.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget:
                  (v, meta) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: MindCareTheme.textSecondary,
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget:
                  (v, meta) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortLabels[domains[v.toInt()]]!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MindCareTheme.textSecondary,
                      ),
                    ),
                  ),
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < domains.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[domains[i]]!.toDouble(),
                  width: 34,
                  color: MindCareTheme.domainColor(domains[i].label),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusDonut extends StatelessWidget {
  final List<ConsultationRequest> requests;
  const _StatusDonut({required this.requests});

  @override
  Widget build(BuildContext context) {
    final statuses =
        ConsultationStatus.values
            .where((s) => requests.any((r) => r.status == s))
            .toList();
    if (statuses.isEmpty) {
      return const EmptyState(
        icon: Icons.donut_large,
        title: 'No requests yet',
        message: 'Status breakdown shows up here.',
      );
    }
    int count(ConsultationStatus s) =>
        requests.where((r) => r.status == s).length;

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 46,
              sections: [
                for (final s in statuses)
                  PieChartSectionData(
                    value: count(s).toDouble(),
                    color: StatusPill.colorFor(s),
                    radius: 24,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            for (final s in statuses)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: StatusPill.colorFor(s),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s.label} (${count(s)})',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Rows & cards ──────────────────────────────────────────────────

Widget _concernPills(ConsultationRequest r) {
  final res = r.screeningResult;
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      Pill(
        label: res.primaryDomain.label,
        color: MindCareTheme.domainColor(res.primaryDomain.label),
      ),
      if (res.secondaryDomain != null)
        Pill(
          label: res.secondaryDomain!.label,
          color: MindCareTheme.textSecondary,
        ),
    ],
  );
}

/// Short row for the overview's "needs attention" list.
class _CompactRequest extends StatelessWidget {
  final ConsultationRequest request;
  final VoidCallback onReport;
  final VoidCallback onSchedule;

  const _CompactRequest({
    required this.request,
    required this.onReport,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reschedule = request.status == ConsultationStatus.rescheduleRequested;

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: onReport, child: const Text('Report')),
        FilledButton(
          onPressed: onSchedule,
          style: FilledButton.styleFrom(
            backgroundColor: MindCareTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: Text(reschedule ? 'New time' : 'Accept'),
        ),
      ],
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              request.patientName,
              style: text.titleMedium?.copyWith(fontSize: 15),
            ),
            RiskPill(request.screeningResult.peakRiskLevel),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          reschedule
              ? 'Asked to reschedule · ${request.rescheduleReason ?? 'no reason given'}'
              : '${request.screeningResult.primaryDomain.label} · ${request.timeAgoLabel}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodyMedium?.copyWith(fontSize: 13),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 560;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: MindCareTheme.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Avatar(request.patientName, size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: info),
                  if (!narrow) buttons,
                ],
              ),
              if (narrow)
                Align(alignment: Alignment.centerRight, child: buttons),
            ],
          ),
        );
      },
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final ConsultationRequest request;
  final VoidCallback onReport;
  final VoidCallback? onReschedule;

  const _AppointmentTile({
    required this.request,
    required this.onReport,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = request.scheduledAt!;
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final time = '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 84,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: MindCareTheme.primaryLight,
              borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: const TextStyle(
                color: MindCareTheme.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.patientName,
                  style: text.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                _concernPills(request),
              ],
            ),
          ),
          if (onReschedule != null)
            TextButton(
              onPressed: onReschedule,
              child: const Text('Reschedule'),
            ),
          TextButton(onPressed: onReport, child: const Text('Report')),
        ],
      ),
    );
  }
}

/// Full request card used on the Requests tab.
class _RequestCard extends StatelessWidget {
  final ConsultationRequest request;
  final VoidCallback onReport;
  final VoidCallback onSchedule;
  final VoidCallback onRemove;
  final VoidCallback onMessage;

  const _RequestCard({
    required this.request,
    required this.onReport,
    required this.onSchedule,
    required this.onRemove,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = request;
    final risk = r.screeningResult.peakRiskLevel;
    final urgent = risk.needsSafetyResponse;

    final primaryAction = switch (r.status) {
      ConsultationStatus.pending => ('Accept & schedule', true),
      ConsultationStatus.rescheduleRequested => ('Propose new time', true),
      ConsultationStatus.accepted => ('Reschedule', false),
      _ => (null, false),
    };

    return Panel(
      borderColor: urgent ? MindCareTheme.error.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(r.patientName, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.patientName,
                      style: text.titleMedium?.copyWith(fontSize: 16),
                    ),
                    Text(
                      '${r.patientEmail} · ${r.timeAgoLabel}',
                      style: text.bodyMedium?.copyWith(fontSize: 12.5),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [StatusPill(r.status), RiskPill(risk)],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (v) {
                  if (v == 'remove') onRemove();
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18),
                            SizedBox(width: 10),
                            Text('Remove request'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Concern  ',
                style: text.bodyMedium?.copyWith(fontSize: 12.5),
              ),
              Expanded(child: _concernPills(r)),
            ],
          ),
          if (r.status == ConsultationStatus.rescheduleRequested) ...[
            const SizedBox(height: 12),
            _Callout(
              icon: Icons.event_repeat,
              color: MindCareTheme.accent,
              title: 'Patient cannot make the booked time',
              body: [
                if (r.scheduledAtLabel != null) 'Booked: ${r.scheduledAtLabel}',
                'Reason: ${r.rescheduleReason ?? 'not given'}',
              ].join('\n'),
            ),
          ],
          if (r.status == ConsultationStatus.accepted &&
              r.scheduledAtLabel != null) ...[
            const SizedBox(height: 12),
            _Callout(
              icon: Icons.event_available,
              color: MindCareTheme.success,
              title: 'Confirmed',
              body: r.scheduledAtLabel!,
            ),
          ],
          if (urgent && r.screeningResult.riskFlags.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Callout(
              icon: Icons.warning_amber_rounded,
              color: MindCareTheme.error,
              title: 'Risk wording detected',
              body: r.screeningResult.riskFlags.map((f) => '"$f"').join(', '),
            ),
          ],
          if (r.message != null) ...[
            const SizedBox(height: 12),
            Text(
              '"${r.message}"',
              style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('View report'),
              ),
              if (r.status != ConsultationStatus.declined)
                OutlinedButton.icon(
                  onPressed: onMessage,
                  icon: Badge(
                    isLabelVisible: r.unreadFor(asDoctor: true) > 0,
                    label: Text('${r.unreadFor(asDoctor: true)}'),
                    child: const Icon(Icons.chat_bubble_outline, size: 18),
                  ),
                  label: const Text('Message'),
                ),
              if (primaryAction.$1 != null)
                primaryAction.$2
                    ? FilledButton(
                      onPressed: onSchedule,
                      style: FilledButton.styleFrom(
                        backgroundColor: MindCareTheme.primary,
                      ),
                      child: Text(primaryAction.$1!),
                    )
                    : TextButton(
                      onPressed: onSchedule,
                      child: Text(primaryAction.$1!),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _Callout({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: text.bodyMedium?.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A search field that glides open to full width when it gets focus.
class _ExpandingSearch extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _ExpandingSearch({required this.onChanged});

  @override
  State<_ExpandingSearch> createState() => _ExpandingSearchState();
}

class _ExpandingSearchState extends State<_ExpandingSearch> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final full = c.maxWidth;
        final width = _focus.hasFocus ? full : (full < 320 ? full : 320.0);
        return Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: Motion.of(context, const Duration(milliseconds: 260)),
            curve: Motion.soft,
            width: width,
            child: GlowOnFocus(
              child: TextField(
                focusNode: _focus,
                onChanged: widget.onChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by name, email or concern',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
