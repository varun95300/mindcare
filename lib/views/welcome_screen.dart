import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SoftBackdrop(
        animated: true,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MindCareTheme.spacingLg),
                child: Column(
                  // The page settles in piece by piece, logo first.
                  children: FadeSlideIn.stagger(
                    [
                      const SizedBox(height: MindCareTheme.spacingXxl),
                      const BrandMark(size: 96),
                      const SizedBox(height: MindCareTheme.spacingXl),
                      Text('MindCare',
                          style: text.displayLarge?.copyWith(fontSize: 40)),
                      const SizedBox(height: MindCareTheme.spacingSm),
                      Text(
                        'A little space for you.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge
                            ?.copyWith(color: MindCareTheme.textSecondary),
                      ),
                      const SizedBox(height: MindCareTheme.spacingXxl),
                      const _FeatureItem(
                        icon: Icons.chat_bubble_outline,
                        title: 'A Gentle Conversation',
                        subtitle:
                            'Questions that adjust to how you are feeling, at your pace',
                      ),
                      const SizedBox(height: MindCareTheme.spacingMd),
                      const _FeatureItem(
                        icon: Icons.lock_outline,
                        title: 'Completely Private',
                        subtitle:
                            'Your answers are only ever shown to the professional you choose',
                      ),
                      const SizedBox(height: MindCareTheme.spacingMd),
                      const _FeatureItem(
                        icon: Icons.people_outlined,
                        title: 'Professional Matching',
                        subtitle:
                            'Find someone who understands what you are going through',
                      ),
                      const SizedBox(height: MindCareTheme.spacingXxl),
                      SizedBox(
                        width: double.infinity,
                        child: Tactile(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text('Get Started'),
                          ),
                        ),
                      ),
                      const SizedBox(height: MindCareTheme.spacingMd),
                      Text(
                        'MindCare helps you find support. It does not diagnose.\nPlease reach out to a qualified professional for medical advice.',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: MindCareTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: MindCareTheme.spacingMd),
                    ],
                    step: const Duration(milliseconds: 60),
                    maxSteps: 9,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingMd),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        boxShadow: MindCareTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MindCareTheme.primaryLight,
              borderRadius: BorderRadius.circular(MindCareTheme.radiusSm),
            ),
            child: Icon(icon, color: MindCareTheme.primaryDark, size: 22),
          ),
          const SizedBox(width: MindCareTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
