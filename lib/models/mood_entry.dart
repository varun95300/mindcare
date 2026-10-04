/// How someone felt at a moment, with an optional journal note.
class MoodEntry {
  final String id;
  final String userId;
  final DateTime createdAt;

  /// 0 = Stressed, 1 = Low, 2 = Okay, 3 = Calm, 4 = Good.
  final int mood;

  /// Journal text. Empty for a plain check-in.
  final String note;

  const MoodEntry({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.mood,
    this.note = '',
  });

  bool get isJournal => note.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'mood': mood,
        'note': note,
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id'] as String,
        userId: json['userId'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        mood: json['mood'] as int,
        note: json['note'] as String? ?? '',
      );
}

/// Names for the five moods, from most to least settled.
class Moods {
  const Moods._();

  static const labels = ['Stressed', 'Low', 'Okay', 'Calm', 'Good'];

  /// Display order in the picker: Good first.
  static const pickerOrder = [4, 3, 2, 1, 0];

  static String label(int mood) => labels[mood.clamp(0, 4)];
}
