import 'package:flutter/material.dart';
import '../models/call_request.dart';
import '../models/time_block.dart';
import 'local_store.dart';

/// Manages video-call requests between patients and psychologists.
///
/// Flow: patient requests a call with an urgency -> psychologist sees it in
/// the call queue (high urgency first) -> schedules a time -> both sides can
/// join from 5 minutes before the start.
///
/// Saved to the on-device [LocalStore] after every change.
class CallService extends ChangeNotifier {
  static const _collection = 'call_requests';

  /// Keeps ids unique even when two requests land in the same clock tick.
  static int _idCounter = 0;
  final List<CallRequest> _calls = [];
  bool _loaded = false;

  bool get loaded => _loaded;

  CallService() {
    _load();
  }

  /// A service that does not read or write storage (tests).
  CallService.empty() : _loaded = true;

  Future<void> _load() async {
    for (final doc in await LocalStore.instance.readAll(_collection)) {
      try {
        _calls.add(CallRequest.fromJson(doc));
      } catch (e) {
        debugPrint('Skipping unreadable call request: $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  void _persist() {
    LocalStore.instance
        .writeAll(_collection, _calls.map((c) => c.toJson()).toList());
  }

  CallRequest? byId(String id) {
    for (final c in _calls) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ─── Patient side ────────────────────────────────────────────────

  CallRequest requestCall({
    required String patientName,
    required String patientEmail,
    required String psychologistId,
    required CallUrgency urgency,
    String? note,
    String? consultationId,
  }) {
    final trimmed = note?.trim();
    final call = CallRequest(
      id: 'call_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
      patientName: patientName,
      patientEmail: patientEmail,
      psychologistId: psychologistId,
      urgency: urgency,
      note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      consultationId: consultationId,
    );
    _calls.add(call);
    _persist();
    notifyListeners();
    return call;
  }

  /// Calls a patient has requested, newest first.
  List<CallRequest> callsForPatient(String patientEmail) => _calls
      .where((c) => c.patientEmail == patientEmail)
      .toList()
    ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

  // ─── Psychologist side ───────────────────────────────────────────

  /// Pending requests for a psychologist: highest urgency first, then
  /// oldest first (whoever has waited longest).
  List<CallRequest> queueFor(String psychologistId) => _calls
      .where((c) =>
          c.psychologistId == psychologistId && c.status == CallStatus.pending)
      .toList()
    ..sort((a, b) {
      final byUrgency = b.urgency.index.compareTo(a.urgency.index);
      return byUrgency != 0
          ? byUrgency
          : a.requestedAt.compareTo(b.requestedAt);
    });

  /// Scheduled and in-progress calls, soonest first.
  List<CallRequest> upcomingFor(String psychologistId) => _calls
      .where((c) =>
          c.psychologistId == psychologistId &&
          (c.status == CallStatus.scheduled || c.status == CallStatus.active))
      .toList()
    ..sort((a, b) => (a.scheduledAt ?? a.requestedAt)
        .compareTo(b.scheduledAt ?? b.requestedAt));

  /// Every call (any status) for a psychologist, newest first.
  List<CallRequest> allFor(String psychologistId) => _calls
      .where((c) => c.psychologistId == psychologistId)
      .toList()
    ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

  /// Schedule a pending call. The Agora channel name is generated here so
  /// both sides join the same room.
  void schedule(
    String callId, {
    required DateTime at,
    int durationMinutes = 30,
  }) {
    final call = byId(callId);
    if (call == null) return;
    call.status = CallStatus.scheduled;
    call.scheduledAt = at;
    call.durationMinutes = durationMinutes;
    call.channelName ??= 'mindcare_$callId';
    _persist();
    notifyListeners();
  }

  /// Other scheduled calls that overlap [start]..[start + duration].
  List<CallRequest> clashesFor(
    String psychologistId,
    DateTime start,
    int durationMinutes, {
    String? excludeCallId,
  }) {
    final end = start.add(Duration(minutes: durationMinutes));
    return _calls.where((c) {
      if (c.psychologistId != psychologistId ||
          c.id == excludeCallId ||
          c.status != CallStatus.scheduled ||
          c.scheduledAt == null) {
        return false;
      }
      final cEnd = c.scheduledAt!.add(Duration(minutes: c.durationMinutes));
      return timesOverlap(start, end, c.scheduledAt!, cEnd);
    }).toList();
  }

  // ─── Shared ──────────────────────────────────────────────────────

  void markActive(String callId) {
    final call = byId(callId);
    if (call == null || call.status == CallStatus.active) return;
    call.status = CallStatus.active;
    _persist();
    notifyListeners();
  }

  void complete(String callId) {
    final call = byId(callId);
    if (call == null) return;
    call.status = CallStatus.completed;
    _persist();
    notifyListeners();
  }

  void cancel(String callId) {
    final call = byId(callId);
    if (call == null) return;
    call.status = CallStatus.cancelled;
    _persist();
    notifyListeners();
  }
}

