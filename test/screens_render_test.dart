import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindcare/config/theme.dart';
import 'package:mindcare/models/user_model.dart';
import 'package:mindcare/services/auth_service.dart';
import 'package:mindcare/services/consultation_service.dart';
import 'package:mindcare/services/local_store.dart';
import 'package:mindcare/services/mood_service.dart';
import 'package:mindcare/views/login_screen.dart';
import 'package:mindcare/views/psychologist/dashboard_screen.dart';
import 'package:mindcare/views/quiz_intro_screen.dart';

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen,
  UserRole? role, {
  required Size size,
  String psychologistId = 'psy_001',
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthService();
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
  if (role != null) {
    await tester.runAsync(
        () => auth.signInAsDemo(role, psychologistId: psychologistId));
  }
  final consultations = ConsultationService();
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: consultations),
      ChangeNotifierProvider(create: (_) => MoodService()),
    ],
    child: MaterialApp(theme: MindCareTheme.lightTheme, home: screen),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalStore.instance.resetCache();
  });

  const desktop = Size(1440, 900);
  const phone = Size(390, 844);

  for (final entry in {'desktop': desktop, 'phone': phone}.entries) {
    group('${entry.key} layout', () {
      testWidgets('psychologist dashboard tabs render without errors',
          (tester) async {
        await pumpScreen(tester, const PsychologistDashboardScreen(),
            UserRole.psychologist,
            size: entry.value);
        expect(find.textContaining('Welcome back'), findsOneWidget);
        expect(tester.takeException(), isNull);

        for (final tab in ['Requests', 'Schedule', 'Overview']) {
          await tester.tap(find.text(tab).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tab);
        }
      });

      testWidgets('patient workspace tabs render', (tester) async {
        await pumpScreen(tester, const QuizIntroScreen(), UserRole.patient,
            size: entry.value);
        expect(find.text('How are you feeling today?'), findsOneWidget);
        expect(find.textContaining('Take a moment for yourself today.'),
            findsOneWidget);
        expect(tester.takeException(), isNull);

        for (final tab in ['Journal', 'Mood', 'Wellness', 'Care', 'Home']) {
          await tester.tap(find.text(tab).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tab);
        }

        // Check in with a mood, then see it reflected.
        await tester.tap(find.text('Calm').first);
        await tester.pumpAndSettle();
        // The card settles into its "Checked in" state shortly after.
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.text('Checked in'), findsOneWidget);
        expect(find.text("Today's check-in"), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('login screen renders for both roles', (tester) async {
        await pumpScreen(tester, const LoginScreen(), null, size: entry.value);
        expect(find.text('Sign In'), findsWidgets);
        await tester.tap(find.text('Psychologist'));
        await tester.pumpAndSettle();
        expect(find.text('Psychologist profile'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('every psychologist profile has a dashboard', (tester) async {
    await pumpScreen(tester, const PsychologistDashboardScreen(),
        UserRole.psychologist,
        size: desktop, psychologistId: 'psy_002');
    expect(find.textContaining('Dr. Raj'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
