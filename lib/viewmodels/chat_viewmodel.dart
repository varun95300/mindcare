import 'dart:math';
import 'package:flutter/material.dart';
import '../data/question_bank.dart';
import '../models/chat_message.dart';
import '../models/quiz_question.dart';
import '../models/screening_result.dart';
import '../models/text_analysis.dart';
import '../services/adaptive_engine.dart';
import '../services/answer_validator.dart';
import '../services/text_analysis_pipeline.dart';
import '../services/report_generator.dart';
import '../services/firestore_service.dart';
import '../services/local_store.dart';

/// ViewModel that drives the chatbot screening conversation.
///
/// Orchestrates: Chat UI ↔ TextAnalysisPipeline (sentiment → emotion →
/// keywords → risk → dominant concern) ↔ AdaptiveEngine ↔ storage.
///
/// The conversation is saved on this device after every exchange, so leaving
/// the screen, switching to the psychologist view or refreshing the page
/// resumes exactly where the user left off.
class ChatViewModel extends ChangeNotifier {
  static const _sessions = 'chat_sessions';

  final AdaptiveEngine _engine = AdaptiveEngine();
  final TextAnalysisPipeline _pipeline = const TextAnalysisPipeline();
  final FirestoreService _firestore = FirestoreService();
  final Random _random = Random();

  /// Recently used acknowledgement lines, so the bot doesn't repeat itself.
  final List<String> _recentReplies = [];

  final List<ChatMessage> _messages = [];
  QuizQuestion? _currentQuestion;
  bool _isTyping = false;
  bool _isComplete = false;
  ScreeningResult? _result;
  String? _screeningId;
  String? _patientId;
  bool _safetyShown = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isComplete => _isComplete;
  ScreeningResult? get result => _result;
  String? get screeningId => _screeningId;
  QuizQuestion? get currentQuestion => _currentQuestion;
  double get progress => _isComplete ? 1.0 : _engine.progress;
  RiskLevel get peakRiskLevel => _engine.peakRisk.level;

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static bool _isLocalPatient(String id) =>
      id.startsWith('demo_') || id.startsWith('local_');

  // ─── Saved sessions ────────────────────────────────────────────────

  /// Whether [patientId] has a saved conversation (for the intro screen).
  static Future<bool> hasSavedSession(String patientId) async {
    final docs = await LocalStore.instance.readAll(_sessions);
    return docs.any((d) => d['id'] == patientId);
  }

  /// The finished screening report for [patientId], if the chat was completed.
  static Future<ScreeningResult?> loadFinishedResult(String patientId) async {
    try {
      final docs = await LocalStore.instance.readAll(_sessions);
      final saved = docs.where((d) => d['id'] == patientId);
      if (saved.isEmpty) return null;
      final doc = saved.first;
      if (doc['isComplete'] != true || doc['result'] == null) return null;
      return ScreeningResult.fromJson(doc['result'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Could not load finished result: $e');
      return null;
    }
  }

  /// Delete the saved conversation and screening for [patientId].
  static Future<void> clearSession(String patientId) async {
    final store = LocalStore.instance;
    final sessions = await store.readAll(_sessions);
    sessions.removeWhere((d) => d['id'] == patientId);
    await store.writeAll(_sessions, sessions);
    final screenings = await store.readAll('screenings');
    screenings.removeWhere((d) => d['patientId'] == patientId);
    await store.writeAll('screenings', screenings);
  }

  Future<void> _saveSession() async {
    final id = _patientId;
    if (id == null) return;
    await LocalStore.instance.upsert(_sessions, {
      'id': id,
      'messages': _messages.map((m) => m.toMap()).toList(),
      'engine': _engine.sessionToJson(),
      'currentQuestionId': _currentQuestion?.id,
      'isComplete': _isComplete,
      'screeningId': _screeningId,
      'result': _result?.toJson(),
      'safetyShown': _safetyShown,
    });
  }

  /// Returns true if a saved conversation was loaded.
  Future<bool> _restoreSession(String patientId) async {
    try {
      final docs = await LocalStore.instance.readAll(_sessions);
      final saved = docs.where((d) => d['id'] == patientId);
      if (saved.isEmpty) return false;
      final doc = saved.first;

      final restored = (doc['messages'] as List)
          .map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
          .toList();
      if (restored.isEmpty) return false;

      _engine.restoreSession(doc['engine'] as Map<String, dynamic>);
      _messages
        ..clear()
        ..addAll(restored);
      final qid = doc['currentQuestionId'] as String?;
      _currentQuestion = qid == null ? null : QuestionBank.getById(qid);
      _isComplete = doc['isComplete'] as bool? ?? false;
      _screeningId = doc['screeningId'] as String?;
      _safetyShown = doc['safetyShown'] as bool? ?? false;
      final resultJson = doc['result'] as Map<String, dynamic>?;
      if (resultJson != null) _result = ScreeningResult.fromJson(resultJson);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Could not restore chat session: $e');
      return false;
    }
  }

  // ─── Conversation ──────────────────────────────────────────────────

  /// Resume the saved conversation, or start with an intro message and the
  /// first question.
  Future<void> startConversation(String patientId) async {
    _patientId = patientId;
    if (await _restoreSession(patientId)) return;

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
    await _saveSession();
  }

  /// Whether the answer buttons should be shown right now.
  bool get canQuickReply =>
      !_isComplete && !_isTyping && _currentQuestion != null;

  ChatMessage _addUserMessage(String text) {
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: text.trim(),
    );
    _messages.add(msg);
    notifyListeners();
    return msg;
  }

  /// Process a user's free-text reply.
  ///
  /// Replies that are not real answers (random keys, bare numbers) are not
  /// scored: the bot explains and waits for a proper answer.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isComplete || _isTyping) return;

    // 1. Add user message to chat
    final userMsg = _addUserMessage(text);

    // 1b. Reject non-answers instead of scoring them
    final problem = AnswerValidator.check(text);
    if (problem != null) {
      _isTyping = true;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));
      await _addBotMessage(_pick(problem == AnswerProblem.noWords
          ? _noWordsReplies
          : _gibberishReplies));
      await _saveSession();
      return;
    }

    // 2. Run the on-device pipeline: sentiment → emotion → keywords →
    //    risk → dominant concern
    final analysis = _pipeline.analyze(text, question: _currentQuestion);

    // Update user message with analysis data (for storage)
    _messages[_messages.length - 1] = ChatMessage(
      id: userMsg.id,
      sender: 'user',
      text: text.trim(),
      sentimentScore: analysis.severityScore,
      sentimentLabel: analysis.sentiment.label,
      emotionLabel: analysis.emotion.primary?.name,
      riskLevel: analysis.risk.level.name,
      dominantConcern: analysis.dominantConcern?.name,
      createdAt: userMsg.createdAt,
    );

    // 3. Feed the answer and the text signals to the adaptive engine
    if (_currentQuestion != null) {
      _engine.recordAnswer(
        _currentQuestion!,
        _mapSeverityToLikert(analysis.severityScore),
      );
    }
    _engine.recordSignals(analysis);

    await _respondAndContinue(
      reply: _generateEmpathyReply(analysis),
      needsSafety: analysis.risk.level.needsSafetyResponse,
    );
  }

  /// The user tapped one of the answer buttons (Never … Almost always).
  Future<void> sendQuickReply(LikertResponse response) async {
    if (!canQuickReply) return;
    final question = _currentQuestion!;

    final label = _labelFor(response);
    final userMsg = _addUserMessage(response.label);
    _messages[_messages.length - 1] = ChatMessage(
      id: userMsg.id,
      sender: 'user',
      text: response.label,
      sentimentScore: response.value.clamp(0, 3),
      sentimentLabel: label,
      createdAt: userMsg.createdAt,
    );

    _engine.recordAnswer(question, response);
    await _respondAndContinue(
      reply: _pick(_sentimentReplies[label]!),
      needsSafety: false,
    );
  }

  String _labelFor(LikertResponse r) {
    switch (r) {
      case LikertResponse.never:
        return 'positive';
      case LikertResponse.rarely:
      case LikertResponse.sometimes:
        return 'neutral';
      case LikertResponse.often:
        return 'negative';
      case LikertResponse.almostAlways:
        return 'very_negative';
    }
  }

  /// Shared tail of every accepted answer: acknowledge, show safety info if
  /// needed, then finish or ask the next question.
  Future<void> _respondAndContinue({
    required String? reply,
    required bool needsSafety,
  }) async {
    // Typing indicator
    _isTyping = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    // Empathetic acknowledgment
    if (reply != null) {
      await _addBotMessage(reply);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Safety response when the message indicates high risk
    if (needsSafety && !_safetyShown) {
      _safetyShown = true;
      await _addBotMessage(_safetyMessage);
      await Future.delayed(const Duration(milliseconds: 700));
    }

    // Finished?
    if (_engine.isComplete) {
      await _finishConversation();
      return;
    }

    // Ask the next question
    _currentQuestion = _engine.selectNextQuestion();
    if (_currentQuestion == null) {
      await _finishConversation();
      return;
    }
    await _addBotMessage(
      _currentQuestion!.text,
      questionId: _currentQuestion!.id,
    );

    _isTyping = false;
    notifyListeners();
    await _saveSession();
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
    _currentQuestion = null;

    if (_patientId != null && _isLocalPatient(_patientId!)) {
      // Local accounts: keep everything on this device.
      _screeningId = 'scr_${DateTime.now().millisecondsSinceEpoch}';
      await LocalStore.instance.upsert('screenings', {
        'id': _screeningId,
        'patientId': _patientId,
        'result': _result!.toJson(),
        'messages': _messages.map((m) => m.toMap()).toList(),
      });
    } else if (_patientId != null) {
      try {
        // Firestore can hang when unreachable, so never wait forever.
        _screeningId = await _firestore
            .saveScreening(patientId: _patientId!, result: _result!)
            .timeout(const Duration(seconds: 8));

        // Save chat messages
        for (final msg in _messages) {
          await _firestore
              .saveChatMessage(screeningId: _screeningId!, message: msg)
              .timeout(const Duration(seconds: 8));
        }
      } catch (e) {
        debugPrint('Error saving screening: $e');
        // Still mark as complete even if save fails
      }
    }

    _isComplete = true;
    _isTyping = false;
    notifyListeners();
    await _saveSession();
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

  // ─── Replies ───────────────────────────────────────────────────────

  static const String _safetyMessage =
      "I'm really concerned about what you just shared, and I'm glad you told "
      "me. You deserve support right now. If you might act on these thoughts "
      "or feel unsafe, please contact your local emergency number or a crisis "
      "line straight away (for example Tele-MANAS 14416 in India, or 988 in "
      "the US), or reach out to someone you trust. You don't have to go "
      "through this alone. 💙";

  static const List<String> _noWordsReplies = [
    "I can only work with words, not numbers or symbols. Could you answer in a short sentence, or tap one of the options below?",
    "I didn't catch an answer there. Try telling me in a few words, or pick one of the options below.",
  ];

  static const List<String> _gibberishReplies = [
    "I didn't quite understand that. Could you say it in a few words, or tap one of the options below?",
    "Sorry, I couldn't make that out. Please answer in your own words, or choose one of the options below.",
    "That didn't read like an answer to me. A short sentence is perfect, or use the buttons below.",
  ];

  static const Map<String, List<String>> _sentimentReplies = {
    'very_negative': [
      "I hear you, and I'm sorry you're going through that.",
      "That sounds really tough. Thank you for being honest.",
      "I appreciate you sharing something so personal.",
      "That must be really difficult. You're not alone in this.",
      "Thank you for trusting me with that. It sounds heavy.",
      "I'm sorry it's been this hard. I'm listening.",
      "That takes courage to say out loud.",
      "It makes sense that this has been weighing on you.",
    ],
    'negative': [
      "Thank you for sharing that with me.",
      "I understand. Let's keep going when you're ready.",
      "I hear you. Thank you for being open.",
      "That's really helpful to know. Thank you.",
      "That sounds like it hasn't been easy.",
      "Thanks for being honest about that.",
      "I can see why that would be draining.",
      "Noted, and thank you for putting it into words.",
    ],
    'neutral': [
      "Got it, thank you.",
      "Thanks for sharing.",
      "Understood. Let me ask you something else.",
      "Okay, noted.",
      "Thanks, that helps me understand.",
      "I see. Thanks for explaining.",
      "Alright, thank you. Let's look at another side of things.",
      "That's useful context, thanks.",
    ],
    'positive': [
      "That's great to hear!",
      "Glad that's going well.",
      "Nice, that's a good sign.",
      "Good to know that isn't weighing on you.",
      "That's reassuring, thank you.",
      "Happy to hear it.",
      "That sounds like a bright spot.",
      "Thanks, that's good to know. 🌱",
    ],
  };

  static const Map<Emotion, List<String>> _emotionReplies = {
    Emotion.sadness: [
      "It sounds like you've been feeling really low. Thank you for telling me.",
      "That sounds like a lot of sadness to carry.",
      "I'm sorry things have felt so heavy lately.",
    ],
    Emotion.fear: [
      "That sounds like a lot of worry to carry. I'm glad you shared it.",
      "Feeling on edge like that is exhausting. Thank you for telling me.",
      "It sounds like your mind hasn't had much chance to settle.",
    ],
    Emotion.anger: [
      "I can hear how frustrating that has been.",
      "It makes sense to feel upset about that.",
      "That sounds really irritating to deal with.",
    ],
    Emotion.shame: [
      "It sounds like you're being very hard on yourself. That can really weigh on you.",
      "That kind of guilt is painful. Thank you for being open about it.",
      "You're sharing something difficult, and that matters.",
    ],
    Emotion.loneliness: [
      "Feeling alone can be so painful. Thank you for opening up about it.",
      "That sounds really isolating. I'm glad you told me.",
      "Wanting connection is completely human.",
    ],
    Emotion.hopelessness: [
      "That sounds really heavy, and I'm sorry you feel this way.",
      "Feeling stuck like that is hard. Thank you for saying it.",
      "I'm glad you told me, even though it's painful.",
    ],
    Emotion.exhaustion: [
      "It sounds like you're running on empty. That's a lot to deal with.",
      "Being that tired takes a toll on everything.",
      "That sounds really draining.",
    ],
    Emotion.overwhelm: [
      "That sounds overwhelming. Thank you for putting it into words.",
      "It sounds like there's a lot on your plate right now.",
      "Feeling swamped like that is really hard.",
    ],
  };

  /// Pick a line at random, avoiding the ones used most recently.
  String _pick(List<String> options) {
    final fresh = options.where((o) => !_recentReplies.contains(o)).toList();
    final choice = (fresh.isNotEmpty ? fresh : options)[
        _random.nextInt(fresh.isNotEmpty ? fresh.length : options.length)];
    _recentReplies.add(choice);
    if (_recentReplies.length > 6) _recentReplies.removeAt(0);
    return choice;
  }

  /// Generate a brief empathetic reply based on sentiment and emotion.
  String? _generateEmpathyReply(TextAnalysis analysis) {
    final sentiment = analysis.sentiment;

    // A strong, clearly named emotion gets a reply that reflects it.
    final emotion = analysis.emotion;
    final primary = emotion.primary;
    if (primary != null &&
        !primary.isPositive &&
        emotion.intensity >= 0.4 &&
        sentiment.label != 'positive') {
      return _pick(_emotionReplies[primary]!);
    }

    return _pick(
      _sentimentReplies[sentiment.label] ?? _sentimentReplies['neutral']!,
    );
  }
}
