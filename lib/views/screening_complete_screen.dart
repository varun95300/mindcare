import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/screening_result.dart';
import 'share_more_screen.dart';
import 'recommendations_screen.dart';

/// Shown to the patient right after the chatbot conversation — deliberately
/// shows no domain scores or severity labels. The patient should never see
/// their own screening result; only the psychologist they reach out to does.
class ScreeningCompleteScreen extends StatelessWidget {
  const ScreeningCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Accept the result from route arguments (passed by ChatScreeningScreen)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final result = args?['result'] as ScreeningResult?;
    final screeningId = args?['screeningId'] as String?;

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
                  // Optional: share more
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ShareMoreScreen(
                              result: result,
                              screeningId: screeningId,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: MindCareTheme.primary),
                      ),
                      child: const Text('Share More (Optional)'),
                    ),
                  ),
                  const SizedBox(height: MindCareTheme.spacingMd),
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
