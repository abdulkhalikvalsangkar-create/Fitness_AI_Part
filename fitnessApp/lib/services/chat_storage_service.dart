import 'dart:ui';

import 'package:FitnessApp/models/file_model.dart';
import 'package:hive/hive.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';

/// MODIFIED: Enhanced ChatStorageService with multi-file per chat support (Phase 1)
/// Now includes methods to retrieve all files attached to a chat session
/// This enables the chatbot to access all uploaded documents for context

class ChatStorageService {
  static String? _lastChatId;
  static final _box = Hive.box<ChatSession>('chats');

  static List<ChatSession> getChats() {
    return _box.values.toList();
  }

  static ChatSession createNewChat() {
    return ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "New Chat",
      messages: [],
    );
  }

  static void saveMessage(String chatId, ChatMessage message) {
    ChatSession? chat = _box.get(chatId);

    if (chat == null) {
      chat = ChatSession(
        id: chatId,
        title: generateChatTitle(message.content),
        messages: [],
      );

      _box.put(chatId, chat);
    }

    chat.messages.add(message);

    /// Set title from first message
    if (chat.messages.length == 1) {
      chat.title = generateChatTitle(message.content);
    }
    chat.save();
  }

  static String _getChatTitle(ChatMessage message) {
    if (message.content != null && message.content!.isNotEmpty) {
      return message.content!;
    }

    // 2. If file message → resolve file from Hive
    if (message.fileId != null) {
      final file = Hive.box<FileModel>('files').get(message.fileId);

      if (file != null) {
        return file.name;
      }
    }
    return 'New Chat';
  }

  static ChatSession? getChat(String id) {
    return _box.get(id);
  }

  static void setLastActiveChat(String chatId) {
    _lastChatId = chatId;
  }

  static ChatSession? getLastActiveChat() {
    if (_lastChatId == null) return null;
    return getChat(_lastChatId!);
  }

  /// NEW (Phase 1): Get all files attached to a specific chat session
  /// Retrieves FileModel objects for all unique fileIds in the chat's messages
  /// This enables the chatbot to access all documents in the current conversation
  static List<FileModel> getChatFiles(String chatId) {
    final chat = getChat(chatId);
    if (chat == null) return [];
    
    final fileBox = Hive.box<FileModel>('files');
    final fileIds = <String>{};
    final files = <FileModel>[];
    
    // Collect all unique fileIds from chat messages
    for (final message in chat.messages) {
      if (message.fileId != null && !fileIds.contains(message.fileId)) {
        fileIds.add(message.fileId!);
        final file = fileBox.get(message.fileId!);
        if (file != null) {
          files.add(file);
        }
      }
    }
    
    return files;
  }

  /// NEW (Phase 1): Attach a file to an existing chat
  /// Allows users to upload documents during an active conversation
  /// Creates a file message to track the attachment in chat history
  static void attachFileToChat(String chatId, FileModel fileModel) {
    ChatSession? chat = getChat(chatId);
    if (chat == null) return;
    
    // Create a file message to record the attachment
    final fileMessage = ChatMessage(
      role: "user",
      type: "file",
      fileId: fileModel.fileId,
      content: "Attached file: ${fileModel.name}. Summary: ${fileModel.contentsummary}",
      timestamp: DateTime.now(),
    );
    
    chat.messages.add(fileMessage);
    chat.save();
  }

  /// NEW (Phase 1): Get extracted text content from all files in a chat
  /// Useful for building context for the chatbot from all attached documents
  /// Returns a combined string of all file contents for AI processing
  static String getCombinedFileContext(String chatId) {
    final files = getChatFiles(chatId);
    if (files.isEmpty) return "";
    
    final contextParts = <String>[];
    
    for (final file in files) {
      // Prefer full text if available, fall back to summary
      final content = file.fullText ?? file.contentsummary ?? "";
      if (content.isNotEmpty) {
        contextParts.add("=== ${file.name} ===\n$content");
      }
    }
    
    return contextParts.join("\n\n");
  }

  /// MEMORY LAYER: Get chat session summary
  /// Returns the compact summary stored in the session
  static String? getSessionSummary(String chatId) {
    final chat = getChat(chatId);
    return chat?.summary;
  }

  /// MEMORY LAYER: Update chat session summary
  /// Stores a compact summary and timestamp in the session
  static void updateSessionSummary(String chatId, String summary) {
    final chat = getChat(chatId);
    if (chat == null) return;
    
    chat.summary = summary;
    chat.lastSummarized = DateTime.now();
    chat.save();
  }

  static Future<void> removeFile({
    required Box<FileModel> box,
    required String fileid,
  }) async {
    var file = box.values.firstWhere(
      (file) => file.fileId == fileid,
      orElse: () {
        throw Exception("File with id $fileid not found");
      },
    );
    // Delete the message if found
    await file.delete();
    print('File with id ${file.fileId} has been deleted');
  }

  static String generateChatTitle(String? text) {
    if (text!.trim().isEmpty) return "New Chat";

    final stopWords = {
      'the',
      'and',
      'is',
      'of',
      'to',
      'in',
      'a',
      'with',
      'for',
      'on',
      'it',
      'this',
      'that',
      'from',
      'are',
      'was',
      'were',
      'be',
    };

    // Words that are common but useless in medical domain
    final ignoreWords = {
      'report',
      'data',
      'file',
      'user',
      'analysis',
      'summary',
      'level',
      'test',
      'value',
      'measurement',
      'patient',
      'range',
    };

    // 1. Clean text
    final cleaned = text
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^\w\s]'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final tokens = cleaned.split(' ');

    // 2. Build bigrams (phrases)
    final phrases = <String>[];
    for (int i = 0; i < tokens.length - 1; i++) {
      final w1 = tokens[i];
      final w2 = tokens[i + 1];

      if (w1.length > 3 &&
          w2.length > 3 &&
          !stopWords.contains(w1) &&
          !stopWords.contains(w2) &&
          !ignoreWords.contains(w1) &&
          !ignoreWords.contains(w2)) {
        phrases.add("$w1 $w2");
      }
    }

    // 3. Count frequencies (words + phrases)
    final counts = <String, int>{};

    for (var word in tokens) {
      if (word.length > 3 &&
          !stopWords.contains(word) &&
          !ignoreWords.contains(word)) {
        counts[word] = (counts[word] ?? 0) + 1;
      }
    }

    for (var phrase in phrases) {
      counts[phrase] = (counts[phrase] ?? 0) + 2;
    }

    if (counts.isEmpty) return "New Chat";

    // 4. Sort by importance
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    // 5. Take best 2–3 items
    final title = sorted.take(3).join(' ');

    // 6. Capitalize properly
    return title
        .split(' ')
        .map((w) {
          if (w.length > 3 && !stopWords.contains(w)) {
            return w[0].toUpperCase() + w.substring(1);
          } else {
            return w;
          }
        })
        .join(' ');
  }
}
