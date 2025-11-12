class ChatMessage {
  final String id;
  final String role; // 'user' veya 'assistant'
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });
}
