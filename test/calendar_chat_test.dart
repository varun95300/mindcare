import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindcare/models/consultation.dart';
import 'package:mindcare/models/time_block.dart';
import 'package:mindcare/services/consultation_service.dart';
import 'package:mindcare/services/local_store.dart';

Future<void> settle() => Future.delayed(const Duration(milliseconds: 60));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalStore.instance.resetCache();
  });

  group('clash detection', () {
    test('overlapping confirmed appointment is a clash; adjacent is not', () async {
      final service = ConsultationService();
      await settle();
      final zoya = service.allRequests.firstWhere((r) => r.id == 'req_seed_7');
      final at = zoya.scheduledAt!;

      // Same time, same doctor, a different request being scheduled
      var c = service.findConflicts('psy_008', at, excludeRequestId: 'other');
      expect(c.length, 1);
      expect(c.first.title, contains('Zoya Ali'));
      expect(c.first.isBlock, isFalse);

      // 30 minutes later still overlaps a 60 minute slot
      c = service.findConflicts('psy_008', at.add(const Duration(minutes: 30)));
      expect(c.length, 1);

      // Starting exactly when it ends does not clash
      c = service.findConflicts(
          'psy_008', at.add(const Duration(minutes: kAppointmentMinutes)));
      expect(c, isEmpty);

      // The request itself is ignored when it is being rescheduled
      c = service.findConflicts('psy_008', at, excludeRequestId: zoya.id);
      expect(c, isEmpty);

      // Another doctor is unaffected
      expect(service.findConflicts('psy_001', at), isEmpty);
    });

    test('blocked time clashes and persists', () async {
      final service = ConsultationService();
      await settle();
      final day = DateTime.now().add(const Duration(days: 5));
      final start = DateTime(day.year, day.month, day.day, 13);
      service.addBlock(TimeBlock(
        id: 'b1',
        psychologistId: 'psy_001',
        start: start,
        end: start.add(const Duration(hours: 1)),
        reason: 'Lunch',
      ));

      final clash = service.findConflicts(
          'psy_001', start.add(const Duration(minutes: 30)));
      expect(clash.single.isBlock, isTrue);
      expect(clash.single.title, 'Blocked: Lunch');
      expect(service.findConflicts('psy_001', start.subtract(const Duration(hours: 2))),
          isEmpty);

      await settle();
      final reloaded = ConsultationService();
      await settle();
      expect(reloaded.blocksFor('psy_001').single.reason, 'Lunch');

      reloaded.removeBlock('b1');
      expect(reloaded.blocksFor('psy_001'), isEmpty);
    });
  });

  group('doctor-patient chat', () {
    test('messages, unread counts and persistence', () async {
      final service = ConsultationService();
      await settle();
      final r = service.allRequests.firstWhere((x) => x.id == 'req_seed_1');
      expect(r.messages, isEmpty);

      service.sendDirectMessage(r.id, fromDoctor: true, text: 'Hello Ananya');
      service.sendDirectMessage(r.id, fromDoctor: false, text: '  ');
      expect(r.messages.length, 1); // blank message ignored

      expect(r.unreadFor(asDoctor: false), 1); // patient has not opened it
      expect(r.unreadFor(asDoctor: true), 0); // doctor wrote it

      service.markRead(r.id, asDoctor: false);
      expect(r.unreadFor(asDoctor: false), 0);

      await Future.delayed(const Duration(milliseconds: 5));
      service.sendDirectMessage(r.id, fromDoctor: false, text: 'Thank you');
      expect(r.unreadFor(asDoctor: true), 1);

      await settle();
      final reloaded = ConsultationService();
      await settle();
      final again = reloaded.byId('req_seed_1')!;
      expect(again.messages.map((m) => m.text), ['Hello Ananya', 'Thank you']);
      expect(again.messages.last.fromDoctor, isFalse);
      expect(again.status, ConsultationStatus.pending);
    });
  });
}
