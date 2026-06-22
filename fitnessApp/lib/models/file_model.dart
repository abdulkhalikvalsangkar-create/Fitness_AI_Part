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

  // MODIFIED: Added fullText field to store complete extracted text from documents
  // This enables better context for chatbot across all document types
  @HiveField(6)
  String? fullText;

  // MODIFIED: Added fileExtension field for clearer file type detection
  // Supports: pdf, doc, docx, txt, md, pptx
  @HiveField(7)
  String? fileExtension;

  FileModel({
    required this.path,
    required this.name,
    required this.type,
    required this.fileId,
    required this.uploadDate,
    this.contentsummary,
    this.fullText,
    this.fileExtension,
  });
}
