import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare/models/call_request.dart';
import 'package:mindcare/services/call_service.dart';
import 'package:mindcare/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

CallRequest _request(
  CallService s, {
  required String name,
  required CallUrgency urgency,
  String doctor = 'psy_001',
}) =>
    s.requestCall(
      patientName: name,
      patientEmail: '$name@test.app',
      psychologistId: doctor,
      urgency: urgency,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalStore.instance.resetCache();
  });

  test('queue lists the most urgent first, then the longest waiting', () {
    final s = CallService.empty();
    final low = _request(s, name: 'low', urgency: CallUrgency.low);
    final high1 = _request(s, name: 'high1', urgency: CallUrgency.high);
    final med = _request(s, name: 'med', urgency: CallUrgency.medium);
    final high2 = _request(s, name: 'high2', urgency: CallUrgency.high);

    final ids = s.queueFor('psy_001').map((c) => c.id).toList();
    expect(ids, [high1.id, high2.id, med.id, low.id]);
  });

  test('queue only shows pending calls for that psychologist', () {
    final s = CallService.empty();
    final mine = _request(s, name: 'a', urgency: CallUrgency.low);
    _request(s, name: 'b', urgency: CallUrgency.high, doctor: 'psy_002');
    final done = _request(s, name: 'c', urgency: CallUrgency.high);
    s.schedule(done.id, at: DateTime.now().add(const Duration(days: 1)));

    expect(s.queueFor('psy_001').map((c) => c.id), [mine.id]);
    expect(s.upcomingFor('psy_001').map((c) => c.id), [done.id]);
  });

  test('scheduling sets time, length and a shared channel name', () {
    final s = CallService.empty();
    final c = _request(s, name: 'a', urgency: CallUrgency.medium);
    final at = DateTime.now().add(const Duration(hours: 3));
    s.schedule(c.id, at: at, durationMinutes: 45);

    final saved = s.byId(c.id)!;
    expect(saved.status, CallStatus.scheduled);
    expect(saved.scheduledAt, at);
    expect(saved.durationMinutes, 45);
    expect(saved.channelName, 'mindcare_${c.id}');
  });

  test('join opens 5 minutes before the start and closes after the call', () {
    final s = CallService.empty();
    final c = _request(s, name: 'a', urgency: CallUrgency.high);

    s.schedule(c.id, at: DateTime.now().add(const Duration(hours: 2)));
    expect(s.byId(c.id)!.isJoinable, isFalse);
    expect(s.byId(c.id)!.countdownLabel, isNotNull);

    s.schedule(c.id, at: DateTime.now().add(const Duration(minutes: 3)));
    expect(s.byId(c.id)!.isJoinable, isTrue);

    s.schedule(c.id,
        at: DateTime.now().subtract(const Duration(hours: 3)),
        durationMinutes: 30);
    expect(s.byId(c.id)!.isJoinable, isFalse);
  });

  test('clashes are found between overlapping scheduled calls', () {
    final s = CallService.empty();
    final a = _request(s, name: 'a', urgency: CallUrgency.low);
    final b = _request(s, name: 'b', urgency: CallUrgency.low);
    final start = DateTime.now().add(const Duration(days: 1));
    s.schedule(a.id, at: start, durationMinutes: 30);

    expect(
      s.clashesFor('psy_001', start.add(const Duration(minutes: 15)), 30,
          excludeCallId: b.id),
      hasLength(1),
    );
    expect(
      s.clashesFor('psy_001', start.add(const Duration(minutes: 45)), 30,
          excludeCallId: b.id),
      isEmpty,
    );
  });

  test('call requests survive a save and load', () {
    final s = CallService.empty();
    final c = _request(s, name: 'a', urgency: CallUrgency.high);
    s.schedule(c.id, at: DateTime.now().add(const Duration(days: 1)));

    final copy = CallRequest.fromJson(s.byId(c.id)!.toJson());
    expect(copy.urgency, CallUrgency.high);
    expect(copy.status, CallStatus.scheduled);
    expect(copy.channelName, s.byId(c.id)!.channelName);
  });
}

