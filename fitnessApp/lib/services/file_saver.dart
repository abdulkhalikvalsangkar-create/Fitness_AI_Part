import 'dart:io';
import 'package:FitnessApp/helpers/file_picker_util.dart';
import 'package:FitnessApp/models/file_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// MODIFIED: Enhanced file picker and saver that supports all Phase 1 document types
/// Supports: pdf, doc, docx, txt, md, pptx
/// Previous support for jpg, png removed (out of scope for Phase 1)

Future<FileModel?> pickAndSave() async {
  // 1. Pick file using FilePickerUtil (which now supports all document types)
  final filePickerUtil = FilePickerUtil();
  final result = await filePickerUtil.pickFile();
  
  if (result == null) return null;

  final file = result;

  // 2. Validate path
  if (file.path == null) return null;

  // 3. Generate unique fileId
  final fileId = DateTime.now().millisecondsSinceEpoch.toString();

  // 4. Copy file to app directory
  final savedPath = await _saveToAppDir(file, fileId);

  // 5. MODIFIED: Enhanced type detection for all supported document types
  final extension = (file.extension ?? "").toLowerCase();
  final type = _detectFileType(extension);

  // 6. Create FileModel with all required fields
  // Now includes fileExtension for easier type detection later
  final fileModel = FileModel(
    path: savedPath,
    name: file.name,
    type: type,
    fileId: fileId,
    uploadDate: DateTime.now(),
    fileExtension: extension,
  );

  // 7. Save to Hive (use fileId as key)
  await Hive.box<FileModel>('files').put(fileId, fileModel);

  return fileModel;
}

/// MODIFIED: Enhanced file type detection that supports all Phase 1 document types
/// Maps file extensions to readable type names for the UI
String _detectFileType(String extension) {
  switch (extension.toLowerCase()) {
    case 'pdf':
      return 'pdf';
    case 'docx':
      return 'docx';
    case 'doc':
      return 'doc';
    case 'txt':
      return 'txt';
    case 'md':
      return 'md';
    case 'pptx':
      return 'pptx';
    default:
      return 'document';
  }
}

Future<String> _saveToAppDir(PlatformFile file, String fileId) async {
  final dir = await getApplicationDocumentsDirectory();

  // Prevent name conflicts with unique fileId prefix
  final extension = file.extension ?? "";
  final newPath = '${dir.path}/file_$fileId.$extension';

  final newFile = File(newPath);

  // Copy the picked file to app's document directory
  await File(file.path!).copy(newPath);

  return newPath;
}
