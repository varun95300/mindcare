import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindcare/models/consultation.dart';
import 'package:mindcare/models/quiz_question.dart';
import 'package:mindcare/models/screening_result.dart';
import 'package:mindcare/services/adaptive_engine.dart';
import 'package:mindcare/services/consultation_service.dart';
import 'package:mindcare/services/local_store.dart';
import 'package:mindcare/services/report_generator.dart';

final _second = RegExp(r'\b(you|your|yours)\b', caseSensitive: false);

List<String> _narrative(ScreeningResult r) => [
      ...r.keyObservations,
      r.methodologyExplanation,
      r.recommendation,
    ];

ScreeningResult _realisticResult() {
  final engine = AdaptiveEngine();
  var guard = 0;
  while (!engine.isComplete && guard++ < 12) {
    final q = engine.selectNextQuestion();
    if (q == null) break;
    engine.recordAnswer(
      q,
      q.primaryDomain == ScreeningDomain.anxiety
          ? LikertResponse.almostAlways
          : LikertResponse.rarely,
    );
  }
  return ReportGenerator.generateReport(engine: engine);
}

Future<void> settle() => Future.delayed(const Duration(milliseconds: 60));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalStore.instance.resetCache();
  });

  group('psychologist sees the PATIENT in the third person', () {
    test('generated report never says "you" or "your"', () {
      final result = _realisticResult();
      expect(_narrative(result), isNotEmpty);
      for (final line in _narrative(result)) {
        expect(_second.hasMatch(line), isFalse, reason: line);
      }
      expect(result.keyObservations.join(' '), contains('The patient'));
    });

    test('demo requests are worded for the psychologist too', () async {
      final service = ConsultationService();
      await settle();
      for (final r in service.allRequests) {
        for (final line in _narrative(r.screeningResult)) {
          expect(_second.hasMatch(line), isFalse,
              reason: '${r.patientName}: $line');
        }
      }
    });

    test('older saved reports written in second person are rewritten', () async {
      final result = _realisticResult();
      // Simulate a report saved before this change.
      final old = result.withNarrative(
        keyObservations: ['You frequently selected higher responses for anxiety.'],
        methodologyExplanation: 'The screening asked you 9 questions.',
        recommendation: 'Based on your screening profile, you may find it helpful...',
        disclaimer: 'If you are in crisis, call a helpline.',
      );
      expect(ReportGenerator.narrativeNeedsRewrite(old), isTrue);

      await LocalStore.instance.writeAll('consultations', [
        ConsultationRequest(
          id: 'req_old',
          patientName: 'Old Patient',
          patientEmail: 'old@x.com',
          psychologistId: 'psy_001',
          screeningResult: old,
          status: ConsultationStatus.pending,
        ).toJson(),
      ]);
      final service = ConsultationService();
      await settle();
      final loaded = service.byId('req_old')!.screeningResult;
      expect(ReportGenerator.narrativeNeedsRewrite(loaded), isFalse);
      expect(loaded.keyObservations.join(' '), contains('The patient'));
      // And it stays that way after a reload (no endless rewriting).
      final again = ConsultationService();
      await settle();
      expect(ReportGenerator.narrativeNeedsRewrite(again.byId('req_old')!.screeningResult),
          isFalse);
    });
  });

  group('the patient is never offered a summary or report', () {
    final patientFacing = [
      'lib/views/quiz_intro_screen.dart',
      'lib/views/chat_screening_screen.dart',
      'lib/views/screening_complete_screen.dart',
      'lib/views/share_more_screen.dart',
      'lib/views/recommendations_screen.dart',
      'lib/views/psychologist_profile_screen.dart',
      'lib/viewmodels/chat_viewmodel.dart',
      'lib/widgets/mood_widgets.dart',
      ...Directory('lib/views/patient')
          .listSync()
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/')),
    ];

    test('no text suggests viewing a summary, report or result', () {
      final forbidden = RegExp(
        r"\b(view|see|read|open|download|show)\b[^'\n]{0,24}\b(summary|report|results?)\b|\byour (report|summary|results?)\b|\bmy summary\b|prepare a summary",
        caseSensitive: false,
      );
      final problems = <String>[];
      for (final path in patientFacing) {
        final lines = File(path).readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('//') || line.startsWith('///')) continue;
          // only string literals matter
          if (!line.contains("'") && !line.contains('"')) continue;
          if (forbidden.hasMatch(line)) problems.add('$path:${i + 1}: $line');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  });
}
