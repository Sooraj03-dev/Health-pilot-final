import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/services/gemini_service.dart';
import 'package:http/http.dart' as http;

/// Handles the state of an AI-generated summary for a specific medical record.
/// 
/// [path] is the full path to the file in Supabase Storage (e.g. 'userId/Category/filename.pdf').
class RecordSummaryNotifier extends StateNotifier<AsyncValue<String>> {
  final String path;
  final GeminiService _geminiService = GeminiService();

  RecordSummaryNotifier(this.path) : super(const AsyncValue.data(''));

  /// Fetches the file from Supabase and requests a summary from Gemini.
  Future<void> summarize() async {
    state = const AsyncValue.loading();

    try {
      // 1. Get signed URL for the file
      final signedUrl = await supabase.storage
          .from('medical-docs')
          .createSignedUrl(path, 120);

      // 2. Download the file bytes
      final response = await http.get(Uri.parse(signedUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file (Status: ${response.statusCode})');
      }

      final bytes = response.bodyBytes;
      final mimeType = _getMimeType(path);

      // 3. Request summary from Gemini
      final summary = await _geminiService.summarizeMedicalRecord(
        fileBytes: bytes,
        mimeType: mimeType,
      );

      state = AsyncValue.data(summary);
    } catch (e, stack) {
      debugPrint('[RecordSummaryNotifier] summarize error: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reset the summary to idle state.
  void clear() {
    state = const AsyncValue.data('');
  }

  String _getMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }
}

/// Provider family for record summaries.
/// 
/// Access as: `ref.watch(recordSummaryProvider(fullPath))`
final recordSummaryProvider = StateNotifierProvider.family<RecordSummaryNotifier, AsyncValue<String>, String>((ref, path) {
  return RecordSummaryNotifier(path);
});
