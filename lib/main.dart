import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/consultation_service.dart';
import 'viewmodels/quiz_viewmodel.dart';
import 'views/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MindCareApp());
}

class MindCareApp extends StatelessWidget {
  const MindCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => QuizViewModel()),
        ChangeNotifierProvider(create: (_) => ConsultationService()),
      ],
      child: MaterialApp(
        title: 'MindCare',
        debugShowCheckedModeBanner: false,
        theme: MindCareTheme.lightTheme,
        home: const WelcomeScreen(),
      ),
    );
  }
}
