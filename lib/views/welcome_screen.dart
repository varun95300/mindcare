import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo / Hero
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: MindCareTheme.heroGradient,
                  borderRadius: BorderRadius.circular(MindCareTheme.radiusXl),
                  boxShadow: MindCareTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingXl),

              // Title
              Text(
                'MindCare',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      foreground: Paint()
                        ..shader = MindCareTheme.heroGradient
                            .createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                    ),
              ),
              const SizedBox(height: MindCareTheme.spacingSm),

              Text(
                'Your Mental Wellness Companion',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MindCareTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: MindCareTheme.spacingXxl),

              // Features
              _FeatureItem(
                icon: Icons.quiz_outlined,
                title: 'Adaptive Screening',
                subtitle: 'Personalized questions that adapt to your responses',
              ),
              const SizedBox(height: MindCareTheme.spacingMd),
              _FeatureItem(
                icon: Icons.analytics_outlined,
                title: 'Explainable Results',
                subtitle: 'Understand how your screening profile was determined',
              ),
              const SizedBox(height: MindCareTheme.spacingMd),
              _FeatureItem(
                icon: Icons.people_outlined,
                title: 'Professional Matching',
                subtitle: 'Find specialists who match your screening profile',
              ),

              const Spacer(flex: 3),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingMd),

              // Disclaimer
              Text(
                'MindCare is a screening tool, not a diagnostic service.\nAlways consult a qualified professional for medical advice.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: MindCareTheme.textLight,
                    ),
              ),
              const SizedBox(height: MindCareTheme.spacingMd),
            ],
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
