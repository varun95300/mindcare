import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'processing_screen.dart';

/// Shown right after the last question — an optional space for the patient
/// to describe, in their own words, whatever prompted them to check in.
/// Entirely skippable. Whatever is written here is only ever shown to the
/// psychologist they eventually reach out to, never back to the patient.
class ShareMoreScreen extends StatefulWidget {
  const ShareMoreScreen({super.key});

  @override
  State<ShareMoreScreen> createState() => _ShareMoreScreenState();
}

class _ShareMoreScreenState extends State<ShareMoreScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    context.read<QuizViewModel>().setPatientNote(_controller.text);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProcessingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: MindCareTheme.spacingLg),
              Text(
                'Anything else you\'d like to share?',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: MindCareTheme.spacingSm),
              Text(
                'Completely optional. Write in your own words — a moment, '
                'a feeling, anything at all. It goes only to the professional '
                'you choose to reach out to, never back to you.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MindCareTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: MindCareTheme.spacingXl),
              TextField(
                controller: _controller,
                minLines: 6,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText:
                      'For example: something that happened recently, or how '
                      'things have been feeling lately...',
                  filled: true,
                  fillColor: MindCareTheme.surface,
                  contentPadding: const EdgeInsets.all(MindCareTheme.spacingMd),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
                    borderSide: BorderSide(
                      color: MindCareTheme.textLight.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
                    borderSide: const BorderSide(
                      color: MindCareTheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingXl),
              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('Continue'),
              ),
              const SizedBox(height: MindCareTheme.spacingSm),
              TextButton(
                onPressed: _continue,
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
