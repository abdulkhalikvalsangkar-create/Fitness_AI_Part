import 'dart:io';
import 'package:FitnessApp/helpers/file_picker_util.dart';
import 'package:FitnessApp/models/file_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_model.dart';

Future<FileModel?> pickAndSave() async {
  // 1. Pick file
  final result = await FilePicker.pickFiles();
  if (result == null) return null;

  final file = result.files.first;

  // 2. Validate path
  if (file.path == null) return null;

  // 3. Generate unique fileId
  final fileId = DateTime.now().millisecondsSinceEpoch.toString();

  // 4. Copy file to app directory
  final savedPath = await _saveToAppDir(file, fileId);

  // 5. Detect type
  final type = (file.extension ?? "").toLowerCase() == "pdf" ? "pdf" : "image";

  // 6. Create FileModel
  final fileModel = FileModel(
    path: savedPath,
    name: file.name,
    type: type,
    fileId: fileId,
    uploadDate: DateTime.now(),
  );

  // 7. Save to Hive (use fileId as key)
  await Hive.box<FileModel>('files').put(fileId, fileModel);

  return fileModel;
}

Future<String> _saveToAppDir(PlatformFile file, String fileId) async {
  final dir = await getApplicationDocumentsDirectory();

  // Prevent name conflicts
  final extension = file.extension ?? "";
  final newPath = '${dir.path}/file_$fileId.$extension';

  final newFile = File(newPath);

  await File(file.path!).copy(newPath);

  return newPath;
}
