/// A single message in the chatbot screening conversation.
class ChatMessage {
  final String id;
  final String sender; // 'bot' or 'user'
  final String text;
  final String? questionId; // non-null when bot asks a screening question
  final int? sentimentScore; // 0-3 severity, only for user messages
  final String? sentimentLabel; // e.g. 'negative', 'very_negative'
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.questionId,
    this.sentimentScore,
    this.sentimentLabel,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isBot => sender == 'bot';
  bool get isUser => sender == 'user';
  bool get isQuestion => questionId != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'questionId': questionId,
      'sentimentScore': sentimentScore,
      'sentimentLabel': sentimentLabel,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      sender: map['sender'] as String,
      text: map['text'] as String,
      questionId: map['questionId'] as String?,
      sentimentScore: map['sentimentScore'] as int?,
      sentimentLabel: map['sentimentLabel'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}
