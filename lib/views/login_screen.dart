import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import 'quiz_intro_screen.dart';
import 'psychologist/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  bool _isPatient = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: MindCareTheme.spacingXl),

              // Role Selection
              Text(
                'I am a...',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: MindCareTheme.spacingMd),

              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.person_outlined,
                      label: 'User',
                      subtitle: 'Take a screening',
                      isSelected: _isPatient,
                      onTap: () => setState(() => _isPatient = true),
                    ),
                  ),
                  const SizedBox(width: MindCareTheme.spacingMd),
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.medical_services_outlined,
                      label: 'Psychologist',
                      subtitle: 'View dashboard',
                      isSelected: !_isPatient,
                      onTap: () => setState(() => _isPatient = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MindCareTheme.spacingXl),

              // Name input (patient only)
              if (_isPatient) ...[
                Text(
                  'Your Name',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MindCareTheme.spacingSm),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    filled: true,
                    fillColor: MindCareTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(MindCareTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(MindCareTheme.radiusMd),
                      borderSide: BorderSide(
                        color: MindCareTheme.textLight.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(MindCareTheme.radiusMd),
                      borderSide: const BorderSide(
                        color: MindCareTheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: MindCareTheme.spacingXl),
              ],

              if (!_isPatient) ...[
                Container(
                  padding: const EdgeInsets.all(MindCareTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: MindCareTheme.primaryLight.withOpacity(0.3),
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: MindCareTheme.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: MindCareTheme.spacingSm),
                      Expanded(
                        child: Text(
                          'You will log in as Dr. Sarah Mitchell (demo psychologist)',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: MindCareTheme.primaryDark,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MindCareTheme.spacingXl),
              ],

              // Continue Button
              ElevatedButton(
                onPressed: () {
                  final auth = context.read<AuthService>();
                  if (_isPatient) {
                    auth.loginAsPatient(_nameController.text.trim());
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const QuizIntroScreen()),
                    );
                  } else {
                    auth.loginAsPsychologist();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const PsychologistDashboardScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(_isPatient ? 'Continue' : 'Log In as Psychologist'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(MindCareTheme.spacingLg),
        decoration: BoxDecoration(
          color: isSelected
              ? MindCareTheme.primaryLight.withOpacity(0.3)
              : MindCareTheme.surface,
          borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
          border: Border.all(
            color: isSelected ? MindCareTheme.primary : MindCareTheme.textLight.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? MindCareTheme.primary : MindCareTheme.textSecondary,
            ),
            const SizedBox(height: MindCareTheme.spacingSm),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected ? MindCareTheme.primary : MindCareTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
