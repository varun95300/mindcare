import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/consultation_service.dart';
import 'services/mood_service.dart';
import 'services/firestore_service.dart';
import 'models/user_model.dart';
import 'widgets/feedback.dart';
import 'widgets/motion.dart';
import 'views/welcome_screen.dart';
import 'views/quiz_intro_screen.dart';
import 'views/psychologist/dashboard_screen.dart';
import 'views/screening_complete_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed (local accounts still work): $e');
  }

  // Seed psychologist data to Firestore (idempotent). Not awaited: if
  // Firestore is slow or unreachable, the app must still start.
  _seedPsychologists();

  // A calm card instead of the red error screen if a widget fails to build.
  ErrorWidget.builder = (details) => const Material(
        color: MindCareTheme.background,
        child: GentleError(),
      );

  runApp(const MindCareApp());
}

/// Seeds psychologist profiles into Firestore on first run.
Future<void> _seedPsychologists() async {
  try {
    final firestore = FirestoreService();
    await firestore.seedPsychologists([
      {
        'id': 'psy_001',
        'name': 'Dr. Sarah Mitchell',
        'title': 'Clinical Psychologist',
        'specializations': ['Anxiety', 'Stress', 'Depression'],
        'rating': 4.9,
        'yearsExperience': 12,
        'consultationFee': 1500,
        'bio':
            'Specialises in anxiety disorders and cognitive behavioural therapy with 12+ years of clinical experience.',
      },
      {
        'id': 'psy_002',
        'name': 'Dr. Arjun Patel',
        'title': 'Counselling Psychologist',
        'specializations': ['Depression', 'Interpersonal / Trauma', 'Stress'],
        'rating': 4.7,
        'yearsExperience': 8,
        'consultationFee': 1200,
        'bio':
            'Focuses on depression and interpersonal difficulties using person-centred and trauma-informed approaches.',
      },
      {
        'id': 'psy_003',
        'name': 'Dr. Priya Sharma',
        'title': 'Clinical Psychologist',
        'specializations': ['Anxiety', 'Interpersonal / Trauma'],
        'rating': 4.8,
        'yearsExperience': 15,
        'consultationFee': 1800,
        'bio':
            'Expert in anxiety, PTSD, and relationship issues with a warm, empathetic approach to therapy.',
      },
    ]).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Seeding psychologists: $e (may not have Firestore yet)');
  }
}

class MindCareApp extends StatelessWidget {
  const MindCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ConsultationService()),
        ChangeNotifierProvider(create: (_) => MoodService()),
      ],
      child: MaterialApp(
        title: 'MindCare',
        debugShowCheckedModeBanner: false,
        theme: MindCareTheme.lightTheme,
        builder: (context, child) => ToastHost(child: child ?? const SizedBox()),
        home: const SessionGate(),
        routes: {
          '/screening-complete': (context) =>
              const ScreeningCompleteScreen(),
        },
      ),
    );
  }
}

/// Decides the first screen: the saved session's home if someone is logged
/// in, otherwise the welcome screen. Logging out anywhere just pops back
/// here and it switches to the welcome screen by itself.
class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    // Which screen should be showing, keyed so a change cross-fades.
    final Widget screen;
    if (!auth.sessionLoaded) {
      screen = const LoadingScreen(key: ValueKey('loading'));
    } else if (user == null) {
      screen = const WelcomeScreen(key: ValueKey('welcome'));
    } else if (user.role == UserRole.psychologist) {
      screen = const PsychologistDashboardScreen(key: ValueKey('doctor'));
    } else {
      screen = const QuizIntroScreen(key: ValueKey('patient'));
    }

    return AnimatedSwitcher(
      duration: Motion.of(context, const Duration(milliseconds: 320)),
      switchInCurve: Motion.soft,
      switchOutCurve: Curves.easeIn,
      child: screen,
    );
  }
}
