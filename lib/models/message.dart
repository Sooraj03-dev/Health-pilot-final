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
        attachedFileName: attachedFileName ?? this.attachedFileName,
      );
}
