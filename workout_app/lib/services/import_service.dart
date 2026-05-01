import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/session_models.dart';
import '../models/blueprint_models.dart';
import 'export_service.dart';

class ImportResult {
  final List<Session> sessions;
  final Map<String, ProgramBlueprint> programs;
  final String? activeProgramId;

  const ImportResult({
    required this.sessions,
    required this.programs,
    required this.activeProgramId,
  });
}

class ImportService {
  static ImportService? _instance;
  ImportService._();
  static ImportService get instance {
    _instance ??= ImportService._();
    return _instance!;
  }

  /// Returns null if user cancelled or file is invalid.
  Future<ImportResult?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.first.bytes;
    if (bytes == null) return null;
    return _parse(bytes);
  }

  ImportResult? _parse(Uint8List bytes) {
    final uuid = Uuid();
    final data = ExportService.parseBackupBytes(bytes);
    if (data == null) return null;

    // Sessions
    final rawSessions = data['sessions'] as List<dynamic>? ?? [];
    final sessions = rawSessions
        .map((e) {
          try {
            final map = e as Map<String, dynamic>;

            return Session.fromJson(
              map,
              map['id'] ?? uuid.v4(),
            );
            // return Session.fromJson(e as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Session>()
        .toList();
    // Programs
    final rawPrograms = data['savedPrograms'] as Map<String, dynamic>? ?? {};
    final programs = <String, ProgramBlueprint>{};
    for (final entry in rawPrograms.entries) {
      try {
        programs[entry.key] =
            ProgramBlueprint.fromJson(entry.value as Map<String, dynamic>);
      } catch (_) {}
    }
    final activeProgramId = data['activeProgramId'] as String?;
    return ImportResult(
      sessions: sessions,
      programs: programs,
      activeProgramId: activeProgramId,
    );
  }
}
