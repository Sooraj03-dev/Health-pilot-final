import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_pilot/models/health_metric.dart';
import 'package:health_pilot/models/message.dart';
import 'package:health_pilot/services/gemini_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;

  /// True while a Gemini response is in flight.
  final bool isLoading;

  /// Accumulates streaming chunks before the final bubble is committed.
  final String streamingText;

  /// Non-null when the last API call failed.
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.streamingText = '',
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? streamingText,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      streamingText: streamingText ?? this.streamingText,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState()) {
    _addWelcome();
  }

  final GeminiService _gemini = GeminiService();

  // ── Initialisation ──────────────────────────────────────────────────────

  /// Adds the initial greeting from the AI pilot on first load.
  void _addWelcome() {
    state = state.copyWith(
      messages: [
        ChatMessage.assistant(
          'Hello! I\'m Health AI Pilot 🩺\n\n'
          'I can help you understand your symptoms and biometric data. '
          'You can also upload a medical report for me to summarise.\n\n'
          'Responses are for informational purposes only and do not '
          'constitute medical advice.',
        ),
      ],
    );
  }

  // ── Send text message ────────────────────────────────────────────────────

  /// Sends [text] to Gemini (streaming) and appends bubbles to [messages].
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Append user bubble immediately.
    final userMsg = ChatMessage.user(text.trim());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      streamingText: '',
      clearError: true,
    );

    // 2. Fetch vitals for context.
    final vitals = await _gemini.fetchLatestVitals();

    // 3. Stream response chunks.
    final buffer = StringBuffer();
    bool hadError = false;

    await for (final chunk
        in _gemini.sendMessageStream(text.trim(), vitals: vitals)) {
      buffer.write(chunk);
      if (mounted) {
        state = state.copyWith(streamingText: buffer.toString());
      }
    }

    // 4. Commit final assistant bubble.
    if (!mounted) return;
    final finalText = buffer.toString().trim();

    if (finalText.startsWith('⚠️') ||
        finalText.startsWith('An error occurred')) {
      hadError = true;
    }

    state = state.copyWith(
      messages: [
        ...state.messages,
        hadError
            ? ChatMessage.error(finalText)
            : ChatMessage.assistant(finalText),
      ],
      isLoading: false,
      streamingText: '',
      error: hadError ? finalText : null,
    );
  }

  // ── File upload ──────────────────────────────────────────────────────────

  /// Opens the system file picker, lets the user choose a PDF / image,
  /// appends a user bubble, then sends the file bytes to Gemini for analysis.
  Future<void> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final Uint8List? bytes = file.bytes;
    final String fileName = file.name;
    final String mimeType = _mimeType(file.extension ?? '');

    // Append a user bubble indicating the upload.
    final userMsg = ChatMessage.user(
      'I\'ve uploaded a medical report for analysis.',
      fileName: fileName,
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      streamingText: '',
      clearError: true,
    );

    final vitals = await _gemini.fetchLatestVitals();

    final buffer = StringBuffer();
    await for (final chunk in _gemini.sendMessageStream(
      'Please analyse this medical report and summarise the key findings in '
      'plain language, highlighting anything that may need attention.',
      vitals: vitals,
      fileBytes: bytes,
      mimeType: mimeType,
      fileName: fileName,
    )) {
      buffer.write(chunk);
      if (mounted) state = state.copyWith(streamingText: buffer.toString());
    }

    if (!mounted) return;
    final finalText = buffer.toString().trim();
    final hadError = finalText.startsWith('⚠️') ||
        finalText.startsWith('An error occurred');

    state = state.copyWith(
      messages: [
        ...state.messages,
        hadError
            ? ChatMessage.error(finalText)
            : ChatMessage.assistant(finalText),
      ],
      isLoading: false,
      streamingText: '',
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearError: true);

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

// Helper to watch the latest vitals for the Live Vitals bottom sheet.
final latestVitalsProvider = FutureProvider<List<HealthMetric>>((ref) {
  return GeminiService().fetchLatestVitals();
});
