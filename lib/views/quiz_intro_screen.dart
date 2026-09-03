import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'quiz_screen.dart';

class QuizIntroScreen extends StatelessWidget {
  const QuizIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthService>().currentUser?.name ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: MindCareTheme.spacingLg),

              Text(
                'Hi $userName 👋',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: MindCareTheme.spacingSm),
              Text(
                'Let\'s talk through how you\'ve been feeling lately.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MindCareTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: MindCareTheme.spacingXl),

              // What to expect
              Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingLg),
                decoration: BoxDecoration(
                  color: MindCareTheme.surface,
                  borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
                  boxShadow: MindCareTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What to Expect',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: MindCareTheme.spacingMd),
                    _ExpectationItem(
                      icon: Icons.timer_outlined,
                      text: 'Takes about 3-5 minutes',
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    _ExpectationItem(
                      icon: Icons.route_outlined,
                      text: 'Questions adapt based on your responses',
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    _ExpectationItem(
                      icon: Icons.lock_outline,
                      text: 'Your answers are completely private',
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    _ExpectationItem(
                      icon: Icons.people_outlined,
                      text: 'Get matched with people who can help',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Domains being screened
              Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingLg),
                decoration: BoxDecoration(
                  color: MindCareTheme.surface,
                  borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
                  boxShadow: MindCareTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What We\'ll Talk About',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: MindCareTheme.spacingMd),
                    Wrap(
                      spacing: MindCareTheme.spacingSm,
                      runSpacing: MindCareTheme.spacingSm,
                      children: [
                        _DomainChip(
                            label: 'Anxiety',
                            color: MindCareTheme.anxietyColor),
                        _DomainChip(
                            label: 'Depression',
                            color: MindCareTheme.depressionColor),
                        _DomainChip(
                            label: 'Stress',
                            color: MindCareTheme.stressColor),
                        _DomainChip(
                            label: 'Interpersonal',
                            color: MindCareTheme.interpersonalColor),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: MindCareTheme.spacingLg),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(MindCareTheme.spacingMd),
                decoration: BoxDecoration(
                  color: MindCareTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
                  border: Border.all(
                    color: MindCareTheme.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: MindCareTheme.warning.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: MindCareTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'This isn\'t a diagnosis — just a starting point. What you share is only ever seen by the professional you choose to connect with.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: MindCareTheme.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingMd),

              // Start Button
              ElevatedButton(
                onPressed: () {
                  context.read<QuizViewModel>().startQuiz();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuizScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('I\'m Ready to Begin'),
              ),
              const SizedBox(height: MindCareTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpectationItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ExpectationItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: MindCareTheme.primary),
        const SizedBox(width: MindCareTheme.spacingSm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _DomainChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DomainChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontSize: 13,
            ),
      ),
    );
  }
}
