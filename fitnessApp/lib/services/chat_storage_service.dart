import 'dart:ui';

import 'package:FitnessApp/models/file_model.dart';
import 'package:hive/hive.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';

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
        // title: _getChatTitle(message),
        title: generateChatTitle(message.content),
        messages: [],
      );

      _box.put(chatId, chat);
    }

    chat.messages.add(message);

    /// Set title from first message
    if (chat.messages.length == 1) {
      // chat.title = _getChatTitle(message);
      chat.title = generateChatTitle(message.content);
    }
    chat.save();
  }

  static String _getChatTitle(ChatMessage message) {
    //   if (message.content != null && message.content?.isNotEmpty) {
    //     if (message.filepath!.isNotEmpty) {
    //       return message.filepath!.split('/').last;
    //     }
    //     return message.content!;
    //   }
    //   return 'New Chat';
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
    return getChat(_lastChatId!); // assuming you already have this
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
    if (file != null) {
      // Delete the message if found
      await file.delete();
      print('File with id ${file.fileId} has been deleted');
    } else {
      print('File with id ${file.fileId} not found');
    }
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

    // Words that are common but useless in YOUR domain
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
        ) // Replace non-alphanumeric with space
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize multiple spaces
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
      counts[phrase] = (counts[phrase] ?? 0) + 2; // phrases > words
    }

    if (counts.isEmpty) return "New Chat";

    // 4. Sort by importance (descending frequency)
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    // 5. Take best 2–3 items (ensure relevance)
    final title = sorted.take(3).join(' ');

    // 6. Capitalize properly
    return title
        .split(' ')
        .map((w) {
          // Capitalize only the first letter of each word that is not a stop word
          if (w.length > 3 && !stopWords.contains(w)) {
            return w[0].toUpperCase() + w.substring(1);
          } else {
            return w;
          }
        })
        .join(' ');
  }
}
