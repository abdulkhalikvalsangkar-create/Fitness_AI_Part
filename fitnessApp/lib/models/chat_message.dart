import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String role;

  @HiveField(1)
  String? content;

  @HiveField(2)
  String type;

  @HiveField(3)
  String? fileId;

  @HiveField(4)
  DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.type,
    this.content,
    this.fileId,
    required this.timestamp,
  });
}
