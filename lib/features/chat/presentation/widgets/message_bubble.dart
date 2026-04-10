import 'package:flutter/material.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/models/message.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DoctorMessageBubble — renders a single [Message] as a styled chat bubble
/// for the doctor-patient conversation.
///
/// - Sent by patient (isMine = true)  → right-aligned, teal gradient, white text.
/// - Sent by doctor  (isMine = false) → left-aligned, white card, dark text.
///
/// File messages (content starting with `[FILE:`) are detected automatically
/// and rendered with a file icon + filename chip instead of plain text.
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

  /// Detects `[FILE: filename.ext]` pattern in message content.
  static final _filePattern = RegExp(r'^\[FILE:\s*(.+)\]$');

  @override
  Widget build(BuildContext context) {
    final fileMatch = _filePattern.firstMatch(message.content);
    final isFile = fileMatch != null;
    final fileName = isFile ? fileMatch.group(1)!.trim() : null;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
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
            // ── Bubble ──────────────────────────────────────────────────
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
              child: isFile
                  ? _buildFileContent(fileName!, isMine)
                  : Text(
                      message.content,
                      style: TextStyle(
                        color: isMine ? Colors.white : AppColors.textPrimary,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
            ),

            const SizedBox(height: 4),

            // ── Timestamp + Read indicator ──────────────────────────────
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
      ),
    );
  }

  /// Renders a file attachment chip inside the bubble.
  Widget _buildFileContent(String fileName, bool isMine) {
    final iconColor = isMine ? Colors.white : AppColors.primaryDark;
    final textColor = isMine ? Colors.white : AppColors.textPrimary;
    final subColor =
        isMine ? Colors.white.withAlpha(180) : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isMine
                ? Colors.white.withAlpha(30)
                : AppColors.primaryDark.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _fileIcon(fileName),
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _fileExtLabel(fileName),
                style: TextStyle(
                  color: subColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Returns an appropriate icon for the file extension.
  static IconData _fileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  /// Returns a human-readable label for the file type.
  static String _fileExtLabel(String fileName) {
    final ext = fileName.split('.').last.toUpperCase();
    return '$ext File';
  }

  /// Formats a [DateTime] as HH:mm (12-hour).
  static String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}
