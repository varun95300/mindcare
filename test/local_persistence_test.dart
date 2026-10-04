import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindcare/models/consultation.dart';
import 'package:mindcare/models/quiz_question.dart';
import 'package:mindcare/models/text_analysis.dart';
import 'package:mindcare/services/adaptive_engine.dart';
import 'package:mindcare/services/consultation_service.dart';
import 'package:mindcare/services/report_generator.dart';

Future<void> settle() => Future.delayed(const Duration(milliseconds: 50));

void main() {
  engineRestoreTests();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('screening result survives a JSON round trip', () {
    final engine = AdaptiveEngine();
    final q = engine.selectNextQuestion()!;
    engine.recordAnswer(q, LikertResponse.often);
    final result = ReportGenerator.generateReport(engine: engine)
      ..patientNote = 'hello';

    final copy = ConsultationRequest.fromJson(ConsultationRequest(
      id: 'r1',
      patientName: 'A',
      patientEmail: 'a@x.com',
      psychologistId: 'psy_001',
      screeningResult: result,
      status: ConsultationStatus.pending,
    ).toJson());

    expect(copy.screeningResult.primaryDomain, result.primaryDomain);
    expect(copy.screeningResult.answers.length, 1);
    expect(copy.screeningResult.patientNote, 'hello');
  });

  test('requests and status changes persist across a restart', () async {
    final first = ConsultationService();
    await settle();
    final seeded = first.allRequests.length;
    expect(seeded, 3);

    final engine = AdaptiveEngine();
    engine.recordAnswer(engine.selectNextQuestion()!, LikertResponse.often);
    final sent = first.sendRequest(
      patientName: 'Demo Student',
      patientEmail: 'student.demo@mindcare.app',
      psychologistId: 'psy_001',
      screeningResult: ReportGenerator.generateReport(engine: engine),
    );
    first.declineRequest(sent.id);
    await settle();

    // "Restart": a brand-new service reads what the old one saved.
    final second = ConsultationService();
    await settle();
    expect(second.allRequests.length, seeded + 1);
    final reloaded =
        second.allRequests.firstWhere((r) => r.id == sent.id);
    expect(reloaded.status, ConsultationStatus.declined);
  });
}

void engineRestoreTests() {
  test('engine conversation state survives save and restore', () {
    final a = AdaptiveEngine();
    final q1 = a.selectNextQuestion()!;
    a.recordAnswer(q1, LikertResponse.often);
    a.concernSignals[ScreeningDomain.stress] = 2.5;
    a.emotionTotals[Emotion.overwhelm] = 3.0;
    a.selectionReasons.add('because');

    final b = AdaptiveEngine()..restoreSession(a.sessionToJson());
    expect(b.answers.length, 1);
    expect(b.concernSignals[ScreeningDomain.stress], 2.5);
    expect(b.emotionTotals[Emotion.overwhelm], 3.0);
    expect(b.selectionReasons, a.selectionReasons.sublist(0, 2));
    // Same next question as if it had never been interrupted.
    expect(b.selectNextQuestion()!.id, a.selectNextQuestion()!.id);
  });
}
