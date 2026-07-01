import 'dart:math';

import 'package:FitnessApp/models/file_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';

class FilePickerUtil {
  // MODIFIED: Updated to support all Phase 1 document types: pdf, doc, txt, md
  Future<PlatformFile?> pickFile() async {
    print("DEBUG: New file picker called");

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md', 'pptx'],
    );

    print("DEBUG: Picker result = $result");

    if (result != null) {
      print(
        "DEBUG: Selected file = ${result.files.first.name}",
      );
      return result.files.first;
    }

    print("DEBUG: No file selected");
    return null;
  }

  static Future<Map<String, dynamic>> getSavedFiles(
    String? query,
    int? days,
  ) async {
    final box = Hive.box<FileModel>('files');

    // Calculate cutoff date from number of past days
    DateTime? cutoffDate;
    if (days != null && days > 0) {
      cutoffDate = DateTime.now().subtract(Duration(days: days));
    }

    final files = box.values
        .where((file) {
          /// Query filter
          bool matchesQuery = true;

          if (query != null && query.isNotEmpty) {
            final q = query.toLowerCase();

            matchesQuery =
                file.name.toLowerCase().contains(q) ||
                (file.contentsummary?.toLowerCase().contains(q) ?? false);
          }

          /// Days filter
          bool matchesDate = true;

          if (cutoffDate != null && file.uploadDate != null) {
            matchesDate = file.uploadDate!.isAfter(cutoffDate);
          }

          return matchesQuery && matchesDate;
        })
        .take(5)
        .map(
          (file) => {
            "fileId": file.fileId,
            "name": file.name,
            "summary":
                file.contentsummary?.length != null &&
                    file.contentsummary!.length > 150
                ? file.contentsummary!.substring(0, 150)
                : file.contentsummary,
            "date": file.uploadDate?.toIso8601String(),
          },
        )
        .toList();

    return {"files": files};
  }
}
