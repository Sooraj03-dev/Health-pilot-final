import 'package:flutter/material.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/models/message.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DoctorMessageBubble — renders a single [Message] as a styled chat bubble
/// for the doctor-patient conversation.
///
/// - Sent by patient (isMine = true)  → right-aligned, teal gradient, white text.
/// - Sent by doctor  (isMine = false) → left-aligned, white card, dark text.
/// ─────────────────────────────────────────────────────────────────────────────
class DoctorMessageBubble extends StatelessWidget {
  final Message message;

  /// Whether this message was sent by the current user (patient).
  final bool isMine;

  /// Optional: show a small "Read" indicator below sent messages.
  final bool showReadIndicator;

  const DoctorMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showReadIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 56 : 12,
        right: isMine ? 12 : 56,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ── Bubble ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMine
                  ? const LinearGradient(
                      colors: [Color(0xFF1A7A5E), Color(0xFF2E9B7F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isMine ? null : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: isMine
                      ? const Color(0xFF1A7A5E).withAlpha(40)
                      : Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: isMine
                  ? null
                  : Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.textPrimary,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ── Timestamp + Read indicator ────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt.toLocal()),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
              if (isMine && showReadIndicator) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all,
                  size: 14,
                  color: Color(0xFF2E9B7F),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Formats a [DateTime] as HH:mm (12-hour).
  static String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}
