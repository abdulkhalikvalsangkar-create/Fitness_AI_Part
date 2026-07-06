import 'package:FitnessApp/services/firestore_service.dart';
import 'package:FitnessApp/services/csv_health_service.dart';
import 'package:FitnessApp/services/csv_login_service.dart';
import 'package:FitnessApp/services/chat_storage_service.dart';
import 'package:FitnessApp/services/memory_service.dart';
import 'package:FitnessApp/services/api_service.dart';

// SERVER MIGRATION: OpenAIService is now a thin wrapper over the backend.
//
// The model call, the tool-calling loop (get_step_data, get_nutrition_data,
// get_user_profile, get_exercise_sessions, get_saved_files, ...) and the OpenAI
// API key all live on fitness.moveneticsdigital.com now. This class only gathers
// on-device context (profile, CSV health history, long-term memory, attached
// documents) and forwards it to the backend, then returns the assistant reply so
// the displayed output stays identical to before.
//
// The tool schema and the local tool router that used to live here were removed
// because the backend performs tool calls server-side using the context we send.

class OpenAIService {
  /// Send message with full context: User Profile, CSV Health History,
  /// Long-term Memory and Relevant Documents. The backend runs the model with
  /// this context and returns the reply.
  static Future<String> sendMessageWithContext(
    String chatId,
    List<Map<String, dynamic>> messages,
  ) async {
    print("[OpenAIService] Starting sendMessageWithContext for chatId: $chatId");

    final context = await _buildContext(chatId);

    final result = await ApiService.chat(
      messages: messages,
      context: context.isNotEmpty ? context : null,
    );

    return result.reply;
  }

  /// Plain message send (no gathered context). Used for lightweight calls such
  /// as document summarization. The backend still runs the model.
  static Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    final result = await ApiService.chat(messages: messages);
    return result.reply;
  }

  /// Builds the `context` object sent to the backend. Each section is guarded so
  /// a failure in one does not block the request.
  static Future<Map<String, dynamic>> _buildContext(String chatId) async {
    final context = <String, dynamic>{};

    // 1. User Profile
    try {
      final user = await StorageService.instance.getUserProfile();
      if (user != null) {
        context['user_profile'] = user.toJson();
        print("[OpenAIService] Added user profile to context");
      }
    } catch (e) {
      print("[OpenAIService] Error loading user profile: $e");
    }

    // 2. CSV Health History (stays on device, sent per-request as context)
    try {
      final csvUserId = await CsvLoginService.getLoggedInUser();
      if (csvUserId != null) {
        final history = await CsvHealthService().getUserHistory(csvUserId);
        if (history.isNotEmpty) {
          history.sort((a, b) => a.date.compareTo(b.date));
          // Cap to the most recent records to keep the payload reasonable.
          const maxRecords = 30;
          final recent = history.length > maxRecords
              ? history.sublist(history.length - maxRecords)
              : history;
          context['csv_health_data'] = recent.map((e) => e.toJson()).toList();
          print("[OpenAIService] Added ${recent.length} CSV health records to context");
        }
      }
    } catch (e) {
      print("[OpenAIService] Error loading CSV health data: $e");
    }

    // 3. Long-term Memory
    try {
      final memory = await MemoryService.getUserMemory("default_user");
      if (memory.summary.isNotEmpty) {
        context['memory'] = memory.summary;
        print("[OpenAIService] Added long-term memory to context");
      } else {
        print("[OpenAIService] No long-term memory available");
      }
    } catch (e) {
      print("[OpenAIService] Error loading long-term memory: $e");
    }

    // 4. Relevant Documents
    try {
      final fileContext = ChatStorageService.getCombinedFileContext(chatId);
      if (fileContext.isNotEmpty) {
        context['documents'] = fileContext;
        print("[OpenAIService] Added attached documents to context");
      } else {
        print("[OpenAIService] No attached documents for this chat");
      }
    } catch (e) {
      print("[OpenAIService] Error loading documents: $e");
    }

    return context;
  }
}
