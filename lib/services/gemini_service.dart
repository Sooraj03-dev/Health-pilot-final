import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:health_pilot/models/health_metric.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// System prompt sent with every Gemini request.
///
/// Defines the assistant's persona, scope, and legal disclaimer.
const String kSystemInstruction = '''
You are Health Pilot AI, a medical assistant.

You are NOT a doctor. Do not diagnose or prescribe.
Always assume: This is not a substitute for professional medical advice.

Use user symptoms and provided vitals (heart rate, SpO2).
If vitals missing, say: Limited biometric data available.

Respond in this format:

Summary:
Brief explanation of possible issue.

Observations:
- Mention abnormal vitals (normal HR: 60–100 bpm, SpO2: 95–100%)

Possible Causes:
- 2–3 likely reasons (no diagnosis)

Suggestions:
- Simple actions (rest, hydration, monitor)

Seek Help:
- When to consult a doctor

Rules:
- Be calm, clear, concise
- No medical claims like "you have"
- Use "may" or "could"
''';

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class GeminiService {
  // Lazily-initialised model — created once per service instance.
  GenerativeModel? _model;

  /// Initialise (or re-initialise) the Gemini model.
  ///
  /// Throws a [StateError] if the API key is missing from `.env`.
  GenerativeModel _getModel() {
    if (_model != null) return _model!;

    final apiKey = dotenv.env['GEMINI_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'your-gemini-api-key') {
      throw StateError(
        'GEMINI_KEY is not set in .env — add a valid API key to enable AI.',
      );
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      systemInstruction: Content.system(kSystemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 500,
      ),
    );
    return _model!;
  }

  // ── Supabase ───────────────────────────────────────────────────────────────

  /// Fetches the latest 3 [HealthMetric] rows for the current user.
  ///
  /// Returns an empty list if the user is not signed in or no data exists.
  Future<List<HealthMetric>> fetchLatestVitals() async {
    try {
      final userId =
          Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return [];

      final rows = await Supabase.instance.client
          .from('health_metrics')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(3);

      return rows.map((r) => HealthMetric.fromJson(r)).toList();
    } catch (e) {
      debugPrint('[GeminiService] fetchLatestVitals error: $e');
      return [];
    }
  }

  // ── Prompt composition ────────────────────────────────────────────────────

  /// Builds the vitals context block injected into each message.
  String _buildVitalsContext(List<HealthMetric> vitals) {
    if (vitals.isEmpty) {
      return '\n\nLimited biometric data available.\n';
    }
    final buffer = StringBuffer('\n\n--- Latest vitals ---\n');
    for (final m in vitals) {
      buffer.writeln(
        '• ${m.recordedAt.toLocal().toString().substring(0, 16)}  '
        'HR: ${m.heartRate.toStringAsFixed(0)} bpm  '
        'SpO2: ${m.spo2.toStringAsFixed(1)}%'
        '${m.sleepDurationMinutes != null ? '  Sleep: ${m.formattedSleep}' : ''}',
      );
    }
    buffer.write('---\n');
    return buffer.toString();
  }

  // ── Single-shot response ──────────────────────────────────────────────────

  /// Sends [userText] plus vitals context and returns the full response string.
  ///
  /// Pass [vitals] from [fetchLatestVitals]; pass an empty list if unavailable.
  /// Pass [fileBytes] + [mimeType] + [fileName] to include an uploaded report.
  Future<String> sendMessage(
    String userText, {
    List<HealthMetric> vitals = const [],
    Uint8List? fileBytes,
    String? mimeType,
    String? fileName,
  }) async {
    try {
      final model = _getModel();
      final vitalsBlock = _buildVitalsContext(vitals);
      final fullPrompt = 'Patient: $userText$vitalsBlock';

      final parts = <Part>[TextPart(fullPrompt)];
      if (fileBytes != null && mimeType != null) {
        parts.add(DataPart(mimeType, fileBytes));
      }

      final response = await model.generateContent([Content('user', parts)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return 'I could not generate a response. Please try again.';
      }
      return text;
    } on StateError catch (e) {
      return '⚠️ ${e.message}';
    } catch (e) {
      debugPrint('[GeminiService] sendMessage error: $e');
      return 'An error occurred while contacting the AI. Please check your '
          'connection and try again.';
    }
  }

  // ── Medical Record Summarization ──────────────────────────────────────────

  static const String kRecordSummaryPrompt = '''
You are a medical scribe assisting a doctor. Summarize the provided medical record/report.
Focus on:
1. Patient Info (Name, Date of Birth if visible).
2. Key Clinical Findings/Observations.
3. Medications prescribed or mentioned.
4. Abnormal lab results or red flags (highlight these!).
5. Recommended follow-up actions.

Format the output clearly with headings. Keep it professional and concise.
Disclaimer: Include "AI-generated summary - verify with original document" at the end.
''';

  /// Summarizes a medical record (PDF, Image, or Text).
  Future<String> summarizeMedicalRecord({
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    try {
      final model = _getModel();
      final parts = <Part>[
        DataPart(mimeType, fileBytes),
        TextPart(kRecordSummaryPrompt),
      ];

      final response = await model.generateContent([Content('user', parts)]);
      final text = response.text?.trim();
      
      if (text == null || text.isEmpty) {
        return 'The AI could not generate a summary for this document. Please check the file content and try again.';
      }
      return text;
    } on StateError catch (e) {
      return '⚠️ ${e.message}';
    } catch (e) {
      debugPrint('[GeminiService] summarizeMedicalRecord error: $e');
      return 'An error occurred while summarizing the record. Ensure the file format is supported (PDF, JPEG, PNG, or TXT).';
    }
  }

  // ── Streaming response ────────────────────────────────────────────────────

  /// Same as [sendMessage] but returns a [Stream<String>] of text chunks.
  ///
  /// Each yielded string is an incremental piece of the response.
  /// On error the stream yields an error string and closes.
  Stream<String> sendMessageStream(
    String userText, {
    List<HealthMetric> vitals = const [],
    Uint8List? fileBytes,
    String? mimeType,
    String? fileName,
  }) async* {
    try {
      final model = _getModel();
      final vitalsBlock = _buildVitalsContext(vitals);
      final fullPrompt = 'Patient: $userText$vitalsBlock';

      final parts = <Part>[TextPart(fullPrompt)];
      if (fileBytes != null && mimeType != null) {
        parts.add(DataPart(mimeType, fileBytes));
      }

      final stream = model.generateContentStream([Content('user', parts)]);
      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) yield text;
      }
    } on StateError catch (e) {
      yield '⚠️ ${e.message}';
    } catch (e) {
      debugPrint('[GeminiService] sendMessageStream error: $e');
      yield 'An error occurred while contacting the AI. Please check your '
          'connection and try again.';
    }
  }
}
