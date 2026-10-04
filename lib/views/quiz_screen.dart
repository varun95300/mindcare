import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/quiz_question.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'share_more_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final vm = context.read<QuizViewModel>();
    vm.submitAnswer();

    if (vm.result != null) {
      // Quiz complete — offer an optional space to share more first
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ShareMoreScreen(result: vm.result!),
        ),
      );
    } else {
      // Animate to next question
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizViewModel>(
      builder: (context, vm, _) {
        final question = vm.currentQuestion;
        if (question == null) return const SizedBox.shrink();

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (!vm.goBack()) {
                  Navigator.of(context).pop();
                } else {
                  _animController.reset();
                  _animController.forward();
                }
              },
            ),
            title: Text('Question ${vm.questionsAnswered + 1}'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(MindCareTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress bar
                  _ProgressSection(progress: vm.progress, questionNum: vm.questionsAnswered + 1),
                  const SizedBox(height: MindCareTheme.spacingXl),

                  // Question
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Question text
                              Text(
                                question.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(height: 1.4),
                              ),
                              const SizedBox(height: MindCareTheme.spacingXl),

                              // Answer options
                              ...LikertResponse.values.map(
                                (response) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: MindCareTheme.spacingSm),
                                  child: _AnswerOption(
                                    response: response,
                                    isSelected:
                                        vm.selectedResponse == response,
                                    onTap: () => vm.selectResponse(response),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Submit button
                  AnimatedOpacity(
                    opacity: vm.selectedResponse != null ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      onPressed: vm.selectedResponse != null ? _onSubmit : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                  const SizedBox(height: MindCareTheme.spacingMd),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  final int questionNum;

  const _ProgressSection({required this.progress, required this.questionNum});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MindCareTheme.textLight,
                    fontSize: 12,
                  ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MindCareTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(MindCareTheme.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: MindCareTheme.primaryLight.withOpacity(0.3),
            valueColor:
                const AlwaysStoppedAnimation<Color>(MindCareTheme.primary),
          ),
        ),
      ],
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final LikertResponse response;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.response,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? MindCareTheme.primary.withOpacity(0.1)
              : MindCareTheme.surface,
          borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? MindCareTheme.primary
                : MindCareTheme.textLight.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio-like indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? MindCareTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? MindCareTheme.primary
                      : MindCareTheme.textLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: MindCareTheme.spacingMd),
            Expanded(
              child: Text(
                response.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? MindCareTheme.primary
                          : MindCareTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
