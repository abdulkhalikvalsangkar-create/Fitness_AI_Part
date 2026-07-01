import 'package:hive/hive.dart';

part 'user_memory.g.dart';

@HiveType(typeId: 3)
class UserMemory extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String summary;

  @HiveField(2)
  DateTime lastUpdated;

  UserMemory({
    required this.userId,
    required this.summary,
    required this.lastUpdated,
  });
}
