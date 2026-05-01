import 'package:hive/hive.dart';

part 'file_model.g.dart';

@HiveType(typeId: 2)
class FileModel extends HiveObject {
  @HiveField(0)
  String path;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type;

  @HiveField(3)
  String fileId;

  @HiveField(4)
  DateTime uploadDate;

  @HiveField(5)
  String? contentsummary;

  // @HiveField(6)
  // String? fullText;

  FileModel({
    required this.path,
    required this.name,
    required this.type,
    required this.fileId,
    required this.uploadDate,
    this.contentsummary,
    // this.fullText,
  });
}
