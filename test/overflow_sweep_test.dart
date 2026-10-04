import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindcare/config/theme.dart';
import 'package:mindcare/data/seed_psychologists.dart';
import 'package:mindcare/models/user_model.dart';
import 'package:mindcare/services/auth_service.dart';
import 'package:mindcare/services/consultation_service.dart';
import 'package:mindcare/services/local_store.dart';
import 'package:mindcare/services/mood_service.dart';
import 'package:mindcare/services/recommendation_service.dart';
import 'package:mindcare/views/chat_screening_screen.dart';
import 'package:mindcare/views/consultation_chat_screen.dart';
import 'package:mindcare/views/login_screen.dart';
import 'package:mindcare/views/patient/breathing_screen.dart';
import 'package:mindcare/views/processing_screen.dart';
import 'package:mindcare/views/psychologist/dashboard_screen.dart';
import 'package:mindcare/views/psychologist/patient_report_screen.dart';
import 'package:mindcare/views/psychologist/schedule_appointment_screen.dart';
import 'package:mindcare/views/psychologist_profile_screen.dart';
import 'package:mindcare/views/quiz_intro_screen.dart';
import 'package:mindcare/views/recommendations_screen.dart';
import 'package:mindcare/views/screening_complete_screen.dart';
import 'package:mindcare/views/share_more_screen.dart';
import 'package:mindcare/views/welcome_screen.dart';

/// Renders every screen at many widths and text sizes and fails on ANY
/// layout error (overflowed RenderFlex and friends), listing each one.
class _Case {
  final String name;
  final UserRole? role;
  final String psychologistId;
  final Widget Function(ConsultationService service) build;
  final Future<void> Function(WidgetTester tester)? interact;

  const _Case(this.name, this.build,
      {this.role, this.psychologistId = 'psy_001', this.interact});
}

Future<void> _tapText(WidgetTester t, String text, {int index = 0}) async {
  final f = find.text(text);
  if (f.evaluate().length <= index) return;
  await t.ensureVisible(f.at(index));
  await t.tap(f.at(index), warnIfMissed: false);
  await t.pumpAndSettle();
}

final _cases = <_Case>[
  _Case('welcome', (_) => const WelcomeScreen()),
  _Case('login', (_) => const LoginScreen(), interact: (t) async {
    await _tapText(t, 'Psychologist');
    await _tapText(t, "Don't have an account? Create one");
    await _tapText(t, 'User');
  }),
  _Case('patient home', (_) => const QuizIntroScreen(),
      role: UserRole.patient, interact: (t) async {
    await _tapText(t, 'Calm');
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    await _tapText(t, 'Change');
  }),
  for (final tab in ['Journal', 'Mood', 'Wellness', 'Care'])
    _Case('patient $tab', (_) => const QuizIntroScreen(),
        role: UserRole.patient, interact: (t) async {
      await _tapText(t, tab);
      if (tab == 'Mood') {
        await _tapText(t, 'Trends');
        await _tapText(t, 'History');
      }
    }),
  _Case('patient profile', (_) => const QuizIntroScreen(),
      role: UserRole.patient, interact: (t) async {
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await t.pumpAndSettle();
    await _tapText(t, 'Profile');
  }),
  _Case('patient care with appointments', (s) => const QuizIntroScreen(),
      role: UserRole.patient, interact: (t) async {
    await _tapText(t, 'Care');
    await _tapText(t, "I'm not available");
  }),
  for (final tab in ['Overview', 'Requests', 'Schedule'])
    _Case('doctor $tab', (_) => const PsychologistDashboardScreen(),
        role: UserRole.psychologist, interact: (t) async {
      await _tapText(t, tab);
      if (tab == 'Requests') {
        await _tapText(t, 'Reschedule');
        await _tapText(t, 'All');
      }
      if (tab == 'Schedule') {
        await _tapText(t, 'Block time');
      }
    }),
  _Case('doctor (other profile)', (_) => const PsychologistDashboardScreen(),
      role: UserRole.psychologist, psychologistId: 'psy_008'),
  _Case('patient report', (s) {
    final r = s.allRequests.firstWhere((x) => x.id == 'req_seed_4');
    return PatientReportScreen(request: r);
  }),
  _Case('schedule appointment', (s) {
    final r = s.allRequests.firstWhere((x) => x.id == 'req_seed_1');
    return ScheduleAppointmentScreen(request: r);
  }),
  _Case('direct chat (doctor)', (s) {
    final r = s.allRequests.firstWhere((x) => x.id == 'req_seed_1');
    s.sendDirectMessage(r.id,
        fromDoctor: true,
        text: 'Hello, thanks for reaching out. Could you tell me a little more about the panic attacks and when they usually start?');
    s.sendDirectMessage(r.id, fromDoctor: false, text: 'Before exams mostly.');
    return ConsultationChatScreen(requestId: r.id, asDoctor: true);
  }, role: UserRole.psychologist),
  _Case('direct chat (patient)', (s) {
    final r = s.allRequests.firstWhere((x) => x.id == 'req_seed_7');
    s.sendDirectMessage(r.id, fromDoctor: true, text: 'See you soon!');
    return ConsultationChatScreen(requestId: r.id, asDoctor: false);
  }, role: UserRole.patient),
  _Case('recommendations', (s) {
    final r = s.allRequests.firstWhere((x) => x.id == 'req_seed_1');
    return RecommendationsScreen(result: r.screeningResult);
  }, role: UserRole.patient),
  _Case('psychologist profile', (s) {
    final r = s.allRequests.firstWhere((x) => x.id == 'req_seed_1');
    final rec = RecommendationService.recommend(r.screeningResult).first;
    return PsychologistProfileScreen(
      psychologist: SeedPsychologists.all.last,
      recommendation: rec,
      screeningResult: r.screeningResult,
    );
  }, role: UserRole.patient),
  _Case('share more', (s) {
    final r = s.allRequests.firstWhere((x) => x.id == 'req_seed_1');
    return ShareMoreScreen(result: r.screeningResult);
  }, role: UserRole.patient),
  _Case('screening complete', (s) {
    final r = s.allRequests.firstWhere((x) => x.id == 'req_seed_1');
    return Builder(
      builder: (context) => Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          settings: RouteSettings(arguments: {'result': r.screeningResult}),
          builder: (_) => const ScreeningCompleteScreen(),
        ),
      ),
    );
  }, role: UserRole.patient),
  _Case('processing', (_) => const ProcessingScreen(), role: UserRole.patient),
  _Case('breathing', (_) => const BreathingScreen(), role: UserRole.patient),
  _Case('chat screening', (_) => const ChatScreeningScreen(),
      role: UserRole.patient, interact: (t) async {
    await t.pump(const Duration(seconds: 3));
    await t.pump(const Duration(seconds: 1));
  }),
];

void main() {
  const widths = [320.0, 360.0, 390.0, 600.0, 768.0, 1024.0, 1440.0];
  const scales = [1.0, 1.3];

  for (final scale in scales) {
    for (final width in widths) {
      testWidgets('no layout errors at ${width.toInt()}px, text x$scale',
          (tester) async {
        final problems = <String>[];

        for (final c in _cases) {
          SharedPreferences.setMockInitialValues({});
          LocalStore.instance.resetCache();

          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          tester.view.physicalSize = Size(width, width < 700 ? 760 : 900);
          tester.view.devicePixelRatio = 1.0;
          tester.platformDispatcher.textScaleFactorTestValue = scale;

          final auth = AuthService();
          await tester
              .runAsync(() => Future.delayed(const Duration(milliseconds: 40)));
          if (c.role != null) {
            await tester.runAsync(
                () => auth.signInAsDemo(c.role!, psychologistId: c.psychologistId));
          }
          final service = ConsultationService();
          await tester
              .runAsync(() => Future.delayed(const Duration(milliseconds: 80)));
          // An accepted appointment for the demo patient (for Care actions).
          if (c.role == UserRole.patient) {
            final req = service.sendRequest(
              patientName: 'Demo Student',
              patientEmail: 'student.demo@mindcare.app',
              psychologistId: 'psy_008',
              screeningResult:
                  service.allRequests.firstWhere((x) => x.id == 'req_seed_1').screeningResult,
              message: 'Hello',
            );
            service.acceptAndSchedule(req.id,
                scheduledAt: DateTime.now().add(const Duration(days: 2)),
                note: 'Looking forward to speaking with you.');
          }

          final errors = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString().split('\n').first;
            // Fonts cannot be downloaded in tests; not a layout problem.
            if (msg.contains('google_fonts')) return;
            final where = RegExp(r'lib/[A-Za-z_/]+\.dart:\d+')
                .allMatches(details.toDiagnosticsNode().toStringDeep())
                .map((m) => m.group(0))
                .toSet()
                .take(2)
                .join(' ');
            final creator = RegExp(r'creator: ([^\n]+)')
                .firstMatch(details.toDiagnosticsNode().toStringDeep())
                ?.group(1)
                ?.split(' ← ')
                .take(7)
                .join('<');
            errors.add('$msg @ $where | $creator');
            File('overflow_log.txt').writeAsStringSync(
              '=== [${c.name}] ${width.toInt()}px x$scale\n'
              '${details.toDiagnosticsNode().toStringDeep()}\n',
              mode: FileMode.append,
            );
          };

          await tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: auth),
              ChangeNotifierProvider.value(value: service),
              ChangeNotifierProvider(create: (_) => MoodService()),
            ],
            child: MaterialApp(
              theme: MindCareTheme.lightTheme,
              home: c.build(service),
            ),
          ));
          try {
            await tester.pumpAndSettle();
            if (c.interact != null) await c.interact!(tester);
          } catch (e) {
            errors.add('threw: $e'.split('\n').first);
          }
          final ex = tester.takeException();
          if (ex != null) errors.add(ex.toString().split('\n').first);

          // Dispose the tree so timers end cleanly before the next case.
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 5));
          FlutterError.onError = previous;

          for (final e in errors.toSet()) {
            problems.add('[${c.name}] $e');
          }
        }

        expect(problems, isEmpty,
            reason: 'at ${width.toInt()}px x$scale:\n${problems.join('\n')}');
      });
    }
  }
}
