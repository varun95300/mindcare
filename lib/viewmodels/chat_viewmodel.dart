import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/quiz_question.dart';
import '../models/screening_result.dart';
import '../models/sentiment_result.dart';
import '../services/adaptive_engine.dart';
import '../services/sentiment_analyzer.dart';
import '../services/report_generator.dart';
import '../services/firestore_service.dart';

/// ViewModel that drives the chatbot screening conversation.
///
/// Orchestrates: Chat UI ↔ SentimentAnalyzer ↔ AdaptiveEngine ↔ Firestore.
class ChatViewModel extends ChangeNotifier {
  final AdaptiveEngine _engine = AdaptiveEngine();
  final SentimentAnalyzer _analyzer = const SentimentAnalyzer();
  final FirestoreService _firestore = FirestoreService();

  final List<ChatMessage> _messages = [];
  QuizQuestion? _currentQuestion;
  bool _isTyping = false;
  bool _isComplete = false;
  ScreeningResult? _result;
  String? _screeningId;
  String? _patientId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isComplete => _isComplete;
  ScreeningResult? get result => _result;
  String? get screeningId => _screeningId;
  QuizQuestion? get currentQuestion => _currentQuestion;
  double get progress => _engine.progress;

  /// Start the conversation with an intro message and the first question.
  Future<void> startConversation(String patientId) async {
    _patientId = patientId;
    _messages.clear();

    // Send intro message
    await _addBotMessage(
      "Hi! I'm here to help understand how you've been feeling lately. "
      "There are no right or wrong answers — just share whatever feels true for you. "
      "Take your time. 💙",
    );

    // Small delay for natural feel
    await Future.delayed(const Duration(milliseconds: 800));

    // Ask the first question
    _currentQuestion = _engine.selectNextQuestion();
    if (_currentQuestion != null) {
      await _addBotMessage(
        _currentQuestion!.text,
        questionId: _currentQuestion!.id,
      );
    }
  }

  /// Process a user's free-text reply.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isComplete) return;

    // 1. Add user message to chat
    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: text.trim(),
    );
    _messages.add(userMsg);
    notifyListeners();

    // 2. Analyze sentiment on-device
    final sentimentResult = _analyzer.analyze(
      text,
      question: _currentQuestion,
    );

    // Update user message with sentiment data (for storage)
    final enrichedUserMsg = ChatMessage(
      id: userMsg.id,
      sender: 'user',
      text: text.trim(),
      sentimentScore: sentimentResult.severityScore,
      sentimentLabel: sentimentResult.label,
      createdAt: userMsg.createdAt,
    );

    // Replace the last message with enriched version
    _messages[_messages.length - 1] = enrichedUserMsg;

    // 3. Feed severity score to the adaptive engine
    if (_currentQuestion != null) {
      // Map severity (0-3) to LikertResponse
      final likertValue = _mapSeverityToLikert(sentimentResult.severityScore);
      _engine.recordAnswer(_currentQuestion!, likertValue);
    }

    // 4. Show typing indicator
    _isTyping = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    // 5. Send empathetic acknowledgment
    final empathyReply = _generateEmpathyReply(sentimentResult);
    if (empathyReply != null) {
      await _addBotMessage(empathyReply);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 6. Check if quiz is complete
    if (_engine.isComplete) {
      await _finishConversation();
      return;
    }

    // 7. Ask the next question
    _currentQuestion = _engine.selectNextQuestion();
    if (_currentQuestion != null) {
      await _addBotMessage(
        _currentQuestion!.text,
        questionId: _currentQuestion!.id,
      );
    } else {
      await _finishConversation();
    }

    _isTyping = false;
    notifyListeners();
  }

  /// Finish the conversation and generate the report.
  Future<void> _finishConversation() async {
    _isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    await _addBotMessage(
      "Thank you so much for sharing with me. I really appreciate "
      "your openness. 🙏",
    );

    await Future.delayed(const Duration(milliseconds: 800));
    await _addBotMessage(
      "I'll prepare a summary based on our conversation. "
      "Remember, this is just a screening — not a diagnosis. "
      "A qualified professional is the best person to support you.",
    );

    // Generate the screening result
    _result = ReportGenerator.generateReport(
      engine: _engine,
    );

    // Save to Firestore
    if (_patientId != null) {
      try {
        _screeningId = await _firestore.saveScreening(
          patientId: _patientId!,
          result: _result!,
        );

        // Save chat messages
        for (final msg in _messages) {
          await _firestore.saveChatMessage(
            screeningId: _screeningId!,
            message: msg,
          );
        }
      } catch (e) {
        debugPrint('Error saving screening: $e');
        // Still mark as complete even if save fails
      }
    }

    _isComplete = true;
    _isTyping = false;
    notifyListeners();
  }

  /// Add a bot message.
  Future<void> _addBotMessage(String text, {String? questionId}) async {
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_bot',
      sender: 'bot',
      text: text,
      questionId: questionId,
    );
    _messages.add(msg);
    _isTyping = false;
    notifyListeners();
  }

  /// Map severity score (0–3) to a LikertResponse for the adaptive engine.
  LikertResponse _mapSeverityToLikert(int severity) {
    switch (severity) {
      case 0:
        return LikertResponse.never;
      case 1:
        return LikertResponse.rarely;
      case 2:
        return LikertResponse.often;
      case 3:
        return LikertResponse.almostAlways;
      default:
        return LikertResponse.sometimes;
    }
  }

  /// Generate a brief empathetic reply based on sentiment.
  String? _generateEmpathyReply(SentimentResult sentiment) {
    final replies = <String, List<String>>{
      'very_negative': [
        "I hear you, and I'm sorry you're going through that.",
        "That sounds really tough. Thank you for being honest.",
        "I appreciate you sharing something so personal.",
        "That must be really difficult. You're not alone in this.",
      ],
      'negative': [
        "Thank you for sharing that with me.",
        "I understand. Let's keep going when you're ready.",
        "I hear you. Thank you for being open.",
        "That's really helpful to know. Thank you.",
      ],
      'neutral': [
        "Got it, thank you.",
        "Thanks for sharing.",
        "Understood. Let me ask you something else.",
      ],
      'positive': [
        "That's great to hear!",
        "I'm glad things are going well there.",
        "That's wonderful. Thank you for sharing.",
      ],
    };

    final options = replies[sentiment.label] ?? replies['neutral']!;
    // Use a simple hash of the message count to pick a reply (deterministic
    // but varied, and no need for dart:math Random).
    final index = _messages.length % options.length;
    return options[index];
  }
}
