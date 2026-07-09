import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// SERVER MIGRATION: Central client for the Fitness AI backend.
///
/// All model/OpenAI calls now go through fitness.moveneticsdigital.com instead
/// of calling OpenAI directly from the device. The backend holds the OpenAI
/// key, runs the model + tool-calling loop, and returns the reply. The app only
/// gathers on-device context and forwards it, so the reply the user sees stays
/// exactly the same as before.
///
/// Backend contract (single endpoint, POST /):
///   Request:  {
///     "messages": [ { "role": "...", "content": "..." }, ... ],   // required
///     "context": {                                                // optional
///       "user_profile": { ... },
///       "csv_health_data": [ { ... }, ... ],   // health history (stays on device)
///       "memory": "long-term memory summary",
///       "documents": "combined text of attached documents"
///     },
///     "update_memory": true                                       // optional
///   }
///   Response: {
///     "success": true,
///     "assistant_message": { "role": "assistant", "content": "..." },
///     "updated_memory_summary": "..."   // only when update_memory was true
///   }
///
/// NOTE: If your backend uses different key names inside `context`, adjust them
/// where the context object is built (see OpenAIService.sendMessageWithContext).
/// The `messages` array is what drives the reply, so chat keeps working even if
/// a context key name differs.
class ChatApiResult {
  final String reply;
  final String? updatedMemorySummary;

  ChatApiResult({required this.reply, this.updatedMemorySummary});
}

class ApiService {
  /// Base URL of the backend. Defaults to the production host, but can be
  /// overridden by adding BACKEND_URL to the .env file (e.g. for staging).
  static String get baseUrl {
    final configured = dotenv.env['BACKEND_URL'];
    final url = (configured != null && configured.isNotEmpty)
        ? configured
        : 'https://fitness.moveneticsdigital.com';
    // Strip a trailing slash so we can append the endpoint cleanly.
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static Uri get _chatEndpoint => Uri.parse('$baseUrl/');
  static Uri get _ocrEndpoint => Uri.parse('$baseUrl/api/ocr/process-image');

  /// Send a chat request to the backend and return the assistant reply.
  static Future<ChatApiResult> chat({
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? context,
    bool updateMemory = false,
    String model = "openai",
  }) async {
    final body = <String, dynamic>{
      'messages': messages,
      'model': model,
    };
    if (context != null && context.isNotEmpty) {
      body['context'] = context;
    }
    if (updateMemory) {
      body['update_memory'] = true;
    }

    print('[ApiService] POST $_chatEndpoint (updateMemory: $updateMemory)');

    final response = await http.post(
      _chatEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print('[ApiService] Backend error ${response.statusCode}: ${response.body}');
      throw Exception('Backend error (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['success'] == false) {
      print('[ApiService] Backend returned success=false: ${response.body}');
      throw Exception('Backend returned success=false');
    }

    // assistant_message may be an object { role, content } or a plain string.
    String reply = '';
    final assistant = data['assistant_message'];
    if (assistant is Map) {
      reply = (assistant['content'] ?? '').toString();
    } else if (assistant is String) {
      reply = assistant;
    }

    final updatedMemory = data['updated_memory_summary'];
    return ChatApiResult(
      reply: reply,
      updatedMemorySummary: (updatedMemory is String && updatedMemory.isNotEmpty)
          ? updatedMemory
          : null,
    );
  }

  /// Send an image to OCR endpoint and return extracted text.
  static Future<String> processImageOCR({
    required String filePath,
    required String fileName,
  }) async {
    print('[ApiService] POST $_ocrEndpoint for file: $fileName');

    final request = http.MultipartRequest('POST', _ocrEndpoint);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    request.fields['return_type'] = 'text';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print('[ApiService] OCR error ${response.statusCode}: ${response.body}');
      throw Exception('OCR error (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == false) {
      print('[ApiService] OCR returned success=false: ${response.body}');
      throw Exception('OCR failed: ${data['error']}');
    }

    return data['data'] as String;
  }
}
