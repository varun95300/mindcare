import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'quiz_intro_screen.dart';
import 'psychologist/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPatient = true;
  bool _isSignUp = true; // true = sign up, false = sign in
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final auth = context.read<AuthService>();
    auth.clearError();

    bool success;
    if (_isSignUp) {
      if (_isPatient && _nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')),
        );
        return;
      }
      success = await auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _isPatient
            ? _nameController.text.trim()
            : 'Dr. Sarah Mitchell',
        role: _isPatient ? UserRole.patient : UserRole.psychologist,
        psychologistId: _isPatient ? null : 'psy_001',
      );
    } else {
      success = await auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      // Small delay to let auth state listener fire
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final user = auth.currentUser;
      if (user != null) {
        if (user.role == UserRole.psychologist) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => const PsychologistDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const QuizIntroScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: MindCareTheme.background,
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Sign In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: MindCareTheme.spacingMd),

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
                      subtitle: 'Find some support',
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

              // Name input (patient sign-up only)
              if (_isPatient && _isSignUp) ...[
                Text(
                  'Your Name',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MindCareTheme.spacingSm),
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration('Enter your name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: MindCareTheme.spacingMd),
              ],

              // Psychologist info
              if (!_isPatient) ...[
                Container(
                  padding: const EdgeInsets.all(MindCareTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: MindCareTheme.primaryLight.withValues(alpha: 0.3),
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: MindCareTheme.primaryDark, size: 20),
                      const SizedBox(width: MindCareTheme.spacingSm),
                      Expanded(
                        child: Text(
                          _isSignUp
                              ? 'You will be linked to the demo psychologist profile (Dr. Sarah Mitchell)'
                              : 'Sign in with your psychologist account',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: MindCareTheme.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MindCareTheme.spacingMd),
              ],

              // Email
              Text('Email', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: MindCareTheme.spacingSm),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('your@email.com'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: MindCareTheme.spacingMd),

              // Password
              Text('Password', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: MindCareTheme.spacingSm),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration('At least 6 characters').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: MindCareTheme.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: MindCareTheme.spacingSm),

              // Error message
              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    auth.error!,
                    style: GoogleFonts.inter(
                      color: MindCareTheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),

              const SizedBox(height: MindCareTheme.spacingXl),

              // Submit button
              ElevatedButton(
                onPressed: auth.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isSignUp ? 'Create Account' : 'Sign In'),
              ),
              const SizedBox(height: MindCareTheme.spacingMd),

              // Toggle sign-up / sign-in
              TextButton(
                onPressed: () {
                  setState(() => _isSignUp = !_isSignUp);
                  auth.clearError();
                },
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign In'
                      : "Don't have an account? Sign Up",
                  style: GoogleFonts.inter(
                    color: MindCareTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: MindCareTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        borderSide:
            BorderSide(color: MindCareTheme.textLight.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        borderSide: const BorderSide(color: MindCareTheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              ? MindCareTheme.primaryLight.withValues(alpha: 0.3)
              : MindCareTheme.surface,
          borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
          border: Border.all(
            color: isSelected
                ? MindCareTheme.primary
                : MindCareTheme.textLight.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected
                  ? MindCareTheme.primary
                  : MindCareTheme.textSecondary,
            ),
            const SizedBox(height: MindCareTheme.spacingSm),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected
                        ? MindCareTheme.primary
                        : MindCareTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
