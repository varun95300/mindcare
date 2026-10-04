import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'screening_complete_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  int _currentStep = 0;
  final _steps = [
    'Analyzing your responses...',
    'Comparing patterns across domains...',
    'Generating your screening profile...',
    'Preparing personalized insights...',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..forward();

    // Step through the analysis steps
    _advanceSteps();
  }

  void _advanceSteps() {
    Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
      } else {
        timer.cancel();
        // Navigate to report after a short delay
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ScreeningCompleteScreen()),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // Pulsing icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.15),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: MindCareTheme.heroGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MindCareTheme.primary
                                .withValues(alpha: 0.3 * _pulseController.value),
                            blurRadius: 30,
                            spreadRadius: 10 * _pulseController.value,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: MindCareTheme.spacingXxl),

              // Current step text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _steps[_currentStep],
                  key: ValueKey(_currentStep),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingXl),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index <= _currentStep ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? MindCareTheme.primary
                          : MindCareTheme.primaryLight,
                      borderRadius:
                          BorderRadius.circular(MindCareTheme.radiusFull),
                    ),
                  );
                }),
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
