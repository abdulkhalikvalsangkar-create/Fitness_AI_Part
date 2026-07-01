import 'dart:convert';
import 'package:FitnessApp/models/user_memory.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

/// MEMORY LAYER: Service to manage cross-chat user memory
/// Handles memory retrieval, updates, and summarization logic
class MemoryService {
  static const int _summarizeMessageThreshold = 03;
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? "";

  static final _memoryBox = Hive.box<UserMemory>('memory');

  /// Get or create user memory
  static Future<UserMemory> getUserMemory(String userId) async {
    print("[MemoryService] Getting memory for userId: $userId");
    UserMemory? existing = _memoryBox.get(userId);
    
    if (existing != null) {
      print("[MemoryService] Found existing memory: ${existing.summary}");
      return existing;
    }
    
    print("[MemoryService] No existing memory found, creating new one");
    // Create new memory with default summary
    final memory = UserMemory(
      userId: userId,
      summary: "",
      lastUpdated: DateTime.now(),
    );
    
    await _memoryBox.put(userId, memory);
    return memory;
  }

  /// Update user memory with new summary
  static Future<void> updateUserMemory(String userId, String summary) async {
    print("[MemoryService] Updating memory for userId: $userId");
    print("[MemoryService] New summary: $summary");
    final memory = await getUserMemory(userId);
    memory.summary = summary;
    memory.lastUpdated = DateTime.now();
    await memory.save();
    print("[MemoryService] Memory updated successfully");
  }

  /// Check if chat session needs summarization
  static bool shouldSummarize(int messageCount) {
    print("[MemoryService] Checking if should summarize: messageCount = $messageCount, threshold = $_summarizeMessageThreshold");
    return messageCount >= _summarizeMessageThreshold;
  }

  /// Generate memory summary from chat messages using OpenAI API
  static Future<String> generateMemorySummary(List<Map<String, dynamic>> messages) async {
    print("[MemoryService] Starting memory summary generation for ${messages.length} messages");
    if (messages.isEmpty) return "";

    // Prepare messages for OpenAI
    final systemPrompt = {
      "role": "system",
      "content": "Summarize the key information from this conversation for long-term memory. Focus on user goals, preferences, health notes, workout plans, diet information, and any important personal details. Keep it concise (max 500 words) and well-organized."
    };

    final conversationForSummary = [systemPrompt, ...messages];

    // Call OpenAI API
    try {
      print("[MemoryService] Calling OpenAI API for summary generation");
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": conversationForSummary,
          "temperature": 0.5,
        }),
      );

      final data = jsonDecode(response.body);
      if (data.containsKey("choices")) {
        final summary = data["choices"][0]["message"]["content"];
        print("[MemoryService] OpenAI API returned summary: $summary");
        return summary;
      } else {
        print("[MemoryService] OpenAI API response missing choices: $data");
      }
    } catch (e) {
      print("[MemoryService] Error generating memory summary: $e");
    }

    // Fallback: simple summary if API fails
    print("[MemoryService] Using fallback summary generation");
    final summaryLines = <String>[];
    for (final msg in messages) {
      final content = msg['content'] as String?;
      if (content != null && content.isNotEmpty) {
        summaryLines.add("• $content");
      }
    }
    final fallbackSummary = summaryLines.join("\n").substring(0, 500);
    print("[MemoryService] Fallback summary: $fallbackSummary");
    return fallbackSummary;
  }

  /// Get recent messages from a session (excluding very old ones)
  static List<Map<String, dynamic>> filterRecentMessages(
    List<Map<String, dynamic>> messages, {
    int limit = 10,
  }) {
    if (messages.length <= limit) return messages;
    return messages.sublist(messages.length - limit);
  }
}
