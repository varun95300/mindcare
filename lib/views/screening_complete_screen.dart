import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'recommendations_screen.dart';

/// Shown to the patient right after the quiz — deliberately shows no
/// domain scores or severity labels. The patient should never see their
/// own screening result; only the psychologist they reach out to does.
/// This keeps the psychologist as the one who interprets the result,
/// rather than letting the patient self-diagnose and disengage.
class ScreeningCompleteScreen extends StatelessWidget {
  const ScreeningCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuizViewModel>();
    final result = vm.result;

    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('No screening result available')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(MindCareTheme.spacingXl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: MindCareTheme.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: MindCareTheme.cardShadow,
                    ),
                    child: const Icon(
                      Icons.favorite_outline,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: MindCareTheme.spacingXl),
                  Text(
                    "You've taken the first step.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: MindCareTheme.spacingMd),
                  Text(
                    "That's often the hardest part. We've matched you with "
                    "people who can help — no labels, no scores, just support.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: MindCareTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: MindCareTheme.spacingXxl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                RecommendationsScreen(result: result),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('See Who Can Help'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
