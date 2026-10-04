import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../data/seed_psychologists.dart';
import '../models/user_model.dart';
import '../widgets/feedback.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

/// Sign in / create account. Username + password accounts are stored on this
/// device (test build); and a one-tap demo login are also offered. After a successful login this screen just pops: the session gate
/// in main.dart shows the right home screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPatient = true;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String _psychologistId = SeedPsychologists.all.first.id;

  UserRole get _role => _isPatient ? UserRole.patient : UserRole.psychologist;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _done(bool success) {
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// Returns whether sign-in worked; the button shows the progress.
  Future<bool> _submitAsync() async {
    final auth = context.read<AuthService>();
    auth.clearError();
    return _isSignUp
        ? auth.signUpLocal(
          username: _usernameController.text,
          password: _passwordController.text,
          name: _nameController.text,
          role: _role,
          psychologistId: _isPatient ? null : _psychologistId,
        )
        : auth.signInLocal(
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }

  Future<bool> _demoAsync() => context.read<AuthService>().signInAsDemo(
    _role,
    psychologistId: _psychologistId,
  );

  /// After the button's "Welcome" check has shown, hand over to the home page.
  void _enter() {
    Future<void>.delayed(const Duration(milliseconds: 500), () => _done(true));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: MindCareTheme.background,
      appBar: AppBar(title: Text(_isSignUp ? 'Create Account' : 'Sign In')),
      body: _frame(
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MindCareTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: FadeSlideIn.stagger([
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BrandMark(size: 44),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A little space for you.',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSignUp
                          ? 'Create your account to begin.'
                          : 'Sign in to continue.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: MindCareTheme.spacingXl),
                    Text(
                      'I am a...',
                      style: Theme.of(context).textTheme.headlineSmall,
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

                    if (!_isPatient) ...[
                      Text(
                        'Psychologist profile',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: MindCareTheme.spacingSm),
                      DropdownButtonFormField<String>(
                        initialValue: _psychologistId,
                        isExpanded: true,
                        decoration: _inputDecoration('Choose your profile'),
                        items: [
                          for (final p in SeedPsychologists.all)
                            DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.name} - ${p.title}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged:
                            (v) => setState(
                              () => _psychologistId = v ?? _psychologistId,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Used when you create an account or use the quick demo login. '
                        'Signing in to an existing account uses the profile it was created with.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: MindCareTheme.spacingMd),
                    ],

                    if (_isSignUp) ...[
                      Text(
                        'Your Name',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: MindCareTheme.spacingSm),
                      GlowOnFocus(
                        child: TextField(
                          controller: _nameController,
                          decoration: _inputDecoration('Enter your name'),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(height: MindCareTheme.spacingMd),
                    ],

                    Text(
                      'Username',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    GlowOnFocus(
                      child: TextField(
                        controller: _usernameController,
                        decoration: _inputDecoration('e.g. shuchi'),
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                      ),
                    ),
                    const SizedBox(height: MindCareTheme.spacingMd),

                    Text(
                      'Password',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: MindCareTheme.spacingSm),
                    GlowOnFocus(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration(
                          'At least 4 characters',
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: MindCareTheme.textSecondary,
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) async {
                          if (await _submitAsync()) _done(true);
                        },
                      ),
                    ),

                    if (auth.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          auth.error!,
                          style: MindCareTheme.inter(
                            color: MindCareTheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: MindCareTheme.spacingLg),

                    SizedBox(
                      width: double.infinity,
                      child: AsyncButton(
                        key: ValueKey(_isSignUp),
                        label: _isSignUp ? 'Create Account' : 'Sign In',
                        loadingLabel:
                            _isSignUp ? 'Creating your space' : 'Signing in',
                        successLabel: 'Welcome',
                        onPressed: _submitAsync,
                        onSuccess: _enter,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _isSignUp = !_isSignUp);
                        auth.clearError();
                      },
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign In'
                            : "Don't have an account? Create one",
                        style: MindCareTheme.inter(
                          color: MindCareTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const Divider(height: MindCareTheme.spacingXl),

                    SizedBox(
                      width: double.infinity,
                      child: AsyncButton(
                        outlined: true,
                        icon: Icons.science_outlined,
                        label:
                            _isPatient
                                ? 'Quick demo login as User'
                                : 'Quick demo login as Psychologist',
                        loadingLabel: 'One moment',
                        successLabel: 'Welcome',
                        onPressed: _demoAsync,
                        onSuccess: _enter,
                      ),
                    ),
                    const SizedBox(height: MindCareTheme.spacingMd),
                    Text(
                      'Test build: accounts and data are saved on this device only. '
                      'Your session stays saved when you switch between User and '
                      'Psychologist.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// On wide screens the form sits next to a brand panel.
  Widget _frame(Widget form) {
    if (!Breakpoints.isWide(context)) {
      return SoftBackdrop(animated: true, child: form);
    }
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            color: MindCareTheme.primary.withValues(alpha: 0.30),
            child: SoftBackdrop(
              animated: true,
              child: LayoutBuilder(
                builder:
                    (context, c) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.all(64),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const BrandMark(size: 52),
                              const SizedBox(height: 32),
                              Text(
                                'A quiet place to check in with yourself.',
                                style: text.displayLarge?.copyWith(
                                  fontSize: 38,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Talk through how you have been feeling, at your own pace, and find someone who can help.',
                                style: text.bodyLarge?.copyWith(
                                  color: MindCareTheme.textSecondary,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 40),
                              for (final line in const [
                                'Chat in your own words, no forms',
                                'Analysed on your device, shared only with your psychologist',
                                'Book and manage appointments in one place',
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: MindCareTheme.primaryDark,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          line,
                                          style: text.bodyLarge,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ),
        Expanded(child: form),
      ],
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
        borderSide: BorderSide(
          color: MindCareTheme.textLight.withValues(alpha: 0.3),
        ),
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
          color:
              isSelected
                  ? MindCareTheme.primaryLight.withValues(alpha: 0.3)
                  : MindCareTheme.surface,
          borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
          border: Border.all(
            color:
                isSelected
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
              color:
                  isSelected
                      ? MindCareTheme.primary
                      : MindCareTheme.textSecondary,
            ),
            const SizedBox(height: MindCareTheme.spacingSm),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color:
                    isSelected
                        ? MindCareTheme.primary
                        : MindCareTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
