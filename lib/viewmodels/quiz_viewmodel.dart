import 'package:flutter/material.dart';
import '../models/quiz_question.dart';
import '../models/quiz_answer.dart';
import '../models/screening_result.dart';
import '../services/adaptive_engine.dart';
import '../services/report_generator.dart';

/// Quiz state management — drives the adaptive quiz flow.
class QuizViewModel extends ChangeNotifier {
  AdaptiveEngine _engine = AdaptiveEngine();
  QuizQuestion? _currentQuestion;
  LikertResponse? _selectedResponse;
  ScreeningResult? _result;
  bool _isProcessing = false;
  Map<ScreeningDomain, double>? _lastContribution;

  // ===== GETTERS =====

  QuizQuestion? get currentQuestion => _currentQuestion;
  LikertResponse? get selectedResponse => _selectedResponse;
  ScreeningResult? get result => _result;
  bool get isProcessing => _isProcessing;
  bool get isComplete => _engine.isComplete;
  double get progress => _engine.progress;
  int get questionsAnswered => _engine.answers.length;
  List<QuizAnswer> get answers => List.unmodifiable(_engine.answers);
  Map<ScreeningDomain, double>? get lastContribution => _lastContribution;

  /// Evidence snapshot for the current state.
  Map<ScreeningDomain, double> get currentScores => {
        for (final d in ScreeningDomain.values)
          d: _engine.evidence.normalizedScore(d),
      };

  // ===== ACTIONS =====

  /// Start or restart the quiz.
  void startQuiz() {
    _engine = AdaptiveEngine();
    _result = null;
    _isProcessing = false;
    _selectedResponse = null;
    _lastContribution = null;
    _currentQuestion = _engine.selectNextQuestion();
    notifyListeners();
  }

  /// Select a response (doesn't submit yet).
  void selectResponse(LikertResponse response) {
    _selectedResponse = response;
    notifyListeners();
  }

  /// Submit the current answer and advance to the next question.
  void submitAnswer() {
    if (_currentQuestion == null || _selectedResponse == null) return;

    // Record the answer and get evidence contributions
    _lastContribution = _engine.recordAnswer(_currentQuestion!, _selectedResponse!);

    // Reset selection
    _selectedResponse = null;

    // Check if quiz is complete
    if (_engine.isComplete) {
      _generateResult();
    } else {
      // Get next question
      _currentQuestion = _engine.selectNextQuestion();
      if (_currentQuestion == null) {
        _generateResult();
      }
    }

    notifyListeners();
  }

  /// Go back to the previous question (limited — removes last answer).
  bool goBack() {
    if (_engine.answers.isEmpty) return false;

    // We can't truly "undo" the adaptive engine state easily,
    // so for the prototype we restart with all answers except the last one.
    final previousAnswers = List<QuizAnswer>.from(_engine.answers);
    previousAnswers.removeLast();

    // Rebuild engine state
    _engine = AdaptiveEngine();
    _result = null;
    _selectedResponse = null;
    _lastContribution = null;

    // Replay all previous answers
    for (final answer in previousAnswers) {
      _engine.recordAnswer(answer.question, answer.response);
    }

    // Set the current question to the one we just "undid"
    _currentQuestion = _engine.selectNextQuestion();
    notifyListeners();
    return true;
  }

  /// Generate the screening result.
  void _generateResult() {
    _isProcessing = true;
    notifyListeners();

    // In a real app, this could be async. For the prototype, it's instant.
    _result = ReportGenerator.generate(
      evidence: _engine.evidence,
      answers: _engine.answers,
    );
    _isProcessing = false;
    notifyListeners();
  }

  /// Mark processing as complete (used by the processing screen animation).
  void markProcessingComplete() {
    _isProcessing = false;
    notifyListeners();
  }

  /// Attach an optional free-text note the patient wrote in their own
  /// words. Only ever shown to the psychologist they reach out to.
  void setPatientNote(String note) {
    final trimmed = note.trim();
    _result?.patientNote = trimmed.isEmpty ? null : trimmed;
    notifyListeners();
  }
}
