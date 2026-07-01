import 'package:hive/hive.dart';
import 'chat_message.dart';

part 'chat_session.g.dart';

@HiveType(typeId: 1)
class ChatSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  List<ChatMessage> messages;

  // MEMORY LAYER: Compact summary of the chat session
  @HiveField(3)
  String? summary;

  // MEMORY LAYER: Timestamp of when the summary was last generated
  @HiveField(4)
  DateTime? lastSummarized;

  ChatSession({required this.id, required this.title, required this.messages, this.summary, this.lastSummarized});
}
