import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/consultation_service.dart';
import 'services/firestore_service.dart';
import 'views/welcome_screen.dart';
import 'views/screening_complete_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Seed psychologist data to Firestore (idempotent)
  await _seedPsychologists();

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
    ]);
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
      ],
      child: MaterialApp(
        title: 'MindCare',
        debugShowCheckedModeBanner: false,
        theme: MindCareTheme.lightTheme,
        home: const WelcomeScreen(),
        routes: {
          '/screening-complete': (context) =>
              const ScreeningCompleteScreen(),
        },
      ),
    );
  }
}
