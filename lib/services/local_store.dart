import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny on-device JSON database for the test build.
///
/// Backed by shared_preferences (browser localStorage on web, a file on
/// desktop), so data survives switching between the user and psychologist
/// sides, and survives app restarts. Nothing leaves the device.
///
/// Each "collection" is stored under one key as a JSON list of documents.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  static const _prefix = 'mindcare.';

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
