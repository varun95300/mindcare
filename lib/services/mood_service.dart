import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';
import 'local_store.dart';

/// Mood check-ins and journal entries, stored on this device only.
class MoodService extends ChangeNotifier {
  static const _collection = 'moods';
  final List<MoodEntry> _entries = [];
  bool _loaded = false;

  bool get loaded => _loaded;

  MoodService() {
    _load();
  }

  Future<void> _load() async {
    for (final doc in await LocalStore.instance.readAll(_collection)) {
      try {
        _entries.add(MoodEntry.fromJson(doc));
      } catch (e) {
        debugPrint('Skipping unreadable mood entry: $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  void _persist() {
    LocalStore.instance
        .writeAll(_collection, _entries.map((e) => e.toJson()).toList());
  }

  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// A user's entries, newest first.
  List<MoodEntry> entriesFor(String userId) => _entries
      .where((e) => e.userId == userId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Entries with journal text, newest first.
  List<MoodEntry> journalFor(String userId) =>
      entriesFor(userId).where((e) => e.isJournal).toList();

  /// Most recent entry from today, if any.
  MoodEntry? todayEntry(String userId) {
    final today = dayOf(DateTime.now());
    for (final e in entriesFor(userId)) {
      if (dayOf(e.createdAt) == today) return e;
    }
    return null;
  }

  MoodEntry addEntry(String userId, int mood, {String note = ''}) {
    final entry = MoodEntry(
      id: 'mood_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      createdAt: DateTime.now(),
      mood: mood.clamp(0, 4),
      note: note.trim(),
    );
    _entries.add(entry);
    _persist();
    notifyListeners();
    return entry;
  }

  /// Set today's mood from a quick check-in. Replaces an earlier plain
  /// check-in from today so there is one per day (journal entries are kept).
  MoodEntry setTodayMood(String userId, int mood) {
    final today = dayOf(DateTime.now());
    _entries.removeWhere((e) =>
        e.userId == userId && !e.isJournal && dayOf(e.createdAt) == today);
    return addEntry(userId, mood);
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    _persist();
    notifyListeners();
  }

  /// Delete everything saved for this user.
  void clearFor(String userId) {
    _entries.removeWhere((e) => e.userId == userId);
    _persist();
    notifyListeners();
  }

  /// One entry per day (the latest that day) for the last [days] days,
  /// oldest first. Days with no entry are null.
  List<MoodEntry?> lastDays(String userId, int days) {
    final mine = entriesFor(userId);
    final today = dayOf(DateTime.now());
    return [
      for (int i = days - 1; i >= 0; i--)
        () {
          final day = today.subtract(Duration(days: i));
          for (final e in mine) {
            if (dayOf(e.createdAt) == day) return e;
          }
          return null;
        }(),
    ];
  }

  /// How many of the last seven days have a check-in.
  int checkInDaysThisWeek(String userId) =>
      lastDays(userId, 7).where((e) => e != null).length;

  /// Consecutive days with an entry, counting back from today (or yesterday).
  int streak(String userId) {
    final days = {for (final e in entriesFor(userId)) dayOf(e.createdAt)};
    var day = dayOf(DateTime.now());
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Gentle, non-clinical observations. Never a diagnosis.
  List<String> reflections(String userId) {
    final week = lastDays(userId, 7);
    final entries = week.whereType<MoodEntry>().toList();
    final out = <String>[];

    if (entries.isEmpty) {
      return ['Your reflections will appear here as you check in.'];
    }

    final n = entries.length;
    out.add(n == 1
        ? 'You checked in once this week. That counts.'
        : 'You have checked in $n days this week.');

    if (entries.length >= 4) {
      final half = entries.length ~/ 2;
      double avg(List<MoodEntry> l) =>
          l.map((e) => e.mood).reduce((a, b) => a + b) / l.length;
      final earlier = avg(entries.sublist(0, half));
      final recent = avg(entries.sublist(half));
      if (recent <= earlier - 0.75) {
        out.add('Your mood has been lower than usual lately. Be gentle with yourself.');
      } else if (recent >= earlier + 0.75) {
        out.add('Things have felt a little lighter in the last few days.');
      }
    }

    final withNote = entries.where((e) => e.isJournal).toList();
    final without = entries.where((e) => !e.isJournal).toList();
    if (withNote.length >= 2 && without.length >= 2) {
      double avg(List<MoodEntry> l) =>
          l.map((e) => e.mood).reduce((a, b) => a + b) / l.length;
      if (avg(withNote) >= avg(without) + 0.5) {
        out.add('You have been feeling calmer on days when you journal.');
      }
    }
    return out;
  }
}
