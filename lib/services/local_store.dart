import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny JSON database used by every service.
///
/// Backed by shared_preferences (browser localStorage on web, a file on
/// desktop), so data survives switching between the user and psychologist
/// sides, and survives app restarts.
///
/// Collections listed in [sharedCollections] are also mirrored to Cloud
/// Firestore (one Firestore document per record) once [initCloud] succeeds,
/// so a patient on one device and a psychologist on another see the same
/// data. If Firestore is unreachable the app keeps working locally.
///
/// DEMO MODE: Firestore security rules are open. Tighten them before real use.
///
/// Each "collection" is stored under one key as a JSON list of documents.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  /// Collections shared between devices through Firestore.
  static const sharedCollections = {
    'consultations',
    'time_blocks',
    'call_requests',
    'accounts',
  };

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Drop the cached preferences handle (tests swap the backing store).
  @visibleForTesting
  void resetCache() => _prefs = null;

  static const _prefix = 'mindcare.';

  // ─── Cloud mirror ────────────────────────────────────────────────

  bool _cloud = false;

  /// True once Firestore sync is running.
  bool get cloudEnabled => _cloud;

  /// collection -> record id -> canonical JSON, as last seen in Firestore.
  final Map<String, Map<String, String>> _known = {};

  final StreamController<String> _changes = StreamController.broadcast();

  /// Emits a collection name whenever another device changed it.
  Stream<String> get remoteChanges => _changes.stream;

  CollectionReference<Map<String, dynamic>> _col(String c) =>
      FirebaseFirestore.instance.collection('mindcare_$c');

  static String _docId(Object id) => Uri.encodeComponent(id.toString());

  /// Stable JSON (sorted keys) so equal records always compare equal.
  static String _canon(Object? v) => jsonEncode(_sorted(v));

  static Object? _sorted(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: _sorted(v[k])};
    }
    if (v is List) return v.map(_sorted).toList();
    return v;
  }

  /// Pull the shared collections from Firestore, then keep listening.
  /// Call once at startup, after Firebase.initializeApp. Never throws.
  Future<void> initCloud() async {
    if (_cloud) return;
    try {
      for (final c in sharedCollections) {
        final snap =
            await _col(c).get().timeout(const Duration(seconds: 8));
        if (snap.docs.isEmpty) {
          // First device to use the cloud: upload what it already has.
          final local = await readAll(c);
          _known[c] = {};
          if (local.isNotEmpty) await _push(c, local);
        } else {
          await _applySnapshot(c, snap, notify: false);
        }
      }
      _cloud = true;
      for (final c in sharedCollections) {
        _col(c).snapshots().listen((snap) {
          if (snap.metadata.hasPendingWrites) return;
          _applySnapshot(c, snap, notify: true);
        }, onError: (Object e) => debugPrint('Cloud listen "$c" failed: $e'));
      }
      debugPrint('Cloud sync is on.');
    } catch (e) {
      debugPrint('Cloud sync unavailable, using this device only: $e');
    }
  }

  Future<void> _applySnapshot(
    String c,
    QuerySnapshot<Map<String, dynamic>> snap, {
    required bool notify,
  }) async {
    final docs = snap.docs.map((d) => d.data()).toList();
    _known[c] = {
      for (final d in docs) d['id'].toString(): _canon(d),
    };
    try {
      await (await _p).setString('$_prefix$c', jsonEncode(docs));
    } catch (e) {
      debugPrint('LocalStore cache "$c" failed: $e');
    }
    if (notify) _changes.add(c);
  }

  /// Upload changed records and delete removed ones.
  Future<void> _push(String c, List<Map<String, dynamic>> docs) async {
    final known = _known[c] ??= {};
    final next = {for (final d in docs) d['id'].toString(): _canon(d)};
    final batch = FirebaseFirestore.instance.batch();
    var ops = 0;
    for (final d in docs) {
      final id = d['id'].toString();
      if (known[id] != next[id]) {
        batch.set(_col(c).doc(_docId(id)), d);
        ops++;
      }
    }
    for (final id in known.keys) {
      if (!next.containsKey(id)) {
        batch.delete(_col(c).doc(_docId(id)));
        ops++;
      }
    }
    _known[c] = next;
    if (ops == 0) return;
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Cloud write "$c" failed: $e');
    }
  }

  // ─── Local storage ───────────────────────────────────────────────

  /// Re-read storage from disk / localStorage so changes made by another
  /// browser tab or window become visible.
  Future<void> reload() async {
    try {
      await (await _p).reload();
    } catch (e) {
      debugPrint('LocalStore reload failed: $e');
    }
  }

  /// Read a whole collection (empty list if never written or unreadable).
  Future<List<Map<String, dynamic>>> readAll(String collection) async {
    try {
      final raw = (await _p).getString('$_prefix$collection');
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('LocalStore read "$collection" failed: $e');
      return [];
    }
  }

  /// Replace a whole collection.
  Future<void> writeAll(
    String collection,
    List<Map<String, dynamic>> docs,
  ) async {
    try {
      await (await _p).setString('$_prefix$collection', jsonEncode(docs));
    } catch (e) {
      debugPrint('LocalStore write "$collection" failed: $e');
    }
    if (_cloud && sharedCollections.contains(collection)) {
      await _push(collection, docs);
    }
  }

  /// Insert or replace one document (matched on its `id` field).
  Future<void> upsert(String collection, Map<String, dynamic> doc) async {
    final docs = await readAll(collection);
    final index = docs.indexWhere((d) => d['id'] == doc['id']);
    if (index >= 0) {
      docs[index] = doc;
    } else {
      docs.add(doc);
    }
    await writeAll(collection, docs);
  }

  /// True if the collection has ever been written.
  Future<bool> exists(String collection) async =>
      (await _p).containsKey('$_prefix$collection');

  /// Wipe everything this app stored (used by "reset demo data").
  Future<void> clearAll() async {
    final prefs = await _p;
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await prefs.remove(key);
    }
  }
}
