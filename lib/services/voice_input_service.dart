import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around speech-to-text for the chat screen.
///
/// The transcript is fed into the same text pipeline as typed messages.
/// If speech recognition is unavailable (no mic, permission denied,
/// unsupported browser) [isAvailable] stays false and the UI hides the mic.
class VoiceInputService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;

  bool get isAvailable => _available;
  bool get isListening => _listening;

  Future<void> init() async {
    try {
      _available = await _speech.initialize(
        onStatus: (status) {
          final nowListening = status == 'listening';
          if (nowListening != _listening) {
            _listening = nowListening;
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Speech error: ${e.errorMsg}');
          _listening = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Speech init failed: $e');
      _available = false;
    }
    notifyListeners();
  }

  /// Start listening. [onResult] gets the running transcript and whether it
  /// is final.
  Future<void> start(void Function(String text, bool isFinal) onResult) async {
    if (!_available || _listening) return;
    _listening = true;
    notifyListeners();
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() async {
    if (!_listening) return;
    await _speech.stop();
    _listening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
