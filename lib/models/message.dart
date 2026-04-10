/// Chat message model for the AI Pilot conversation.
///
/// Roles:
///   [MessageRole.user]      — typed by the patient.
///   [MessageRole.assistant] — returned by Gemini.
///   [MessageRole.error]     — sentinel for failed API calls.
enum MessageRole { user, assistant, error }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;

  /// Optional file that was attached with this message (display name only).
  final String? attachedFileName;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.attachedFileName,
  });

  /// Convenience factory — creates a user message stamped right now.
  factory ChatMessage.user(String text, {String? fileName}) => ChatMessage(
        role: MessageRole.user,
        text: text,
        timestamp: DateTime.now(),
        attachedFileName: fileName,
      );

  /// Convenience factory — creates an assistant message stamped right now.
  factory ChatMessage.assistant(String text) => ChatMessage(
        role: MessageRole.assistant,
        text: text,
        timestamp: DateTime.now(),
      );

  /// Convenience factory — creates an error sentinel stamped right now.
  factory ChatMessage.error(String message) => ChatMessage(
        role: MessageRole.error,
        text: message,
        timestamp: DateTime.now(),
      );

  ChatMessage copyWith({
    MessageRole? role,
    String? text,
    DateTime? timestamp,
    String? attachedFileName,
  }) =>
      ChatMessage(
        role: role ?? this.role,
        text: text ?? this.text,
        timestamp: timestamp ?? this.timestamp,
      );
}

/// A standard chat message between two users
class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };
}
