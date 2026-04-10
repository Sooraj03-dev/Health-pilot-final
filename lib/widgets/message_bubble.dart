import 'package:flutter/material.dart';
import 'package:health_pilot/models/message.dart';

/// Renders a single [ChatMessage] as a styled chat bubble.
///
/// - User messages: teal gradient, right-aligned.
/// - Assistant messages: white card with green left accent, left-aligned.
/// - Error messages: red-tinted card with error icon, left-aligned.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  /// Whether to show a streaming cursor "▊" at the end (used while streaming).
  final bool isStreaming;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.role) {
      case MessageRole.user:
        return _UserBubble(message: message);
      case MessageRole.assistant:
        return _AssistantBubble(message: message, isStreaming: isStreaming);
      case MessageRole.error:
        return _ErrorBubble(message: message);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User bubble
// ─────────────────────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 16, top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Optional file attachment chip
          if (message.attachedFileName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1A7A5E).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF1A7A5E).withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file,
                      size: 14, color: Color(0xFF1A7A5E)),
                  const SizedBox(width: 4),
                  Text(
                    message.attachedFileName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A7A5E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // Main bubble
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A7A5E), Color(0xFF2E9B7F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A7A5E).withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assistant bubble
// ─────────────────────────────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;
  const _AssistantBubble(
      {required this.message, required this.isStreaming});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 56, top: 6, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2, right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A7A5E), Color(0xFF2E9B7F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.health_and_safety,
                color: Colors.white, size: 18),
          ),
          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: const Border(
                      left: BorderSide(
                          color: Color(0xFF1A7A5E), width: 3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: message.text),
                        if (isStreaming)
                          const TextSpan(
                            text: '▊',
                            style: TextStyle(color: Color(0xFF1A7A5E)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                      fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error bubble
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBubble extends StatelessWidget {
  final ChatMessage message;
  const _ErrorBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 2),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE53935).withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFE53935), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE53935),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: const TextStyle(
                        color: Color(0xFF7F1D1D), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilities
// ─────────────────────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ampm';
}
