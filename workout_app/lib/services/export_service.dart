import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/session_models.dart';
import '../models/weight.dart';
import '../models/blueprint_models.dart';

class ExportService {
  static ExportService? _instance;
  ExportService._();
  static ExportService get instance {
    _instance ??= ExportService._();
    return _instance!;
  }

  Future<void> exportJson(List<Session> sessions) async {
    final data = sessions.map((s) => s.toJson()).toList();
    final bytes = utf8.encode(jsonEncode(data));
    await _shareBytes(
      bytes: Uint8List.fromList(bytes),
      filename: _timestampedName('liftlog-export', 'json'),
      mimeType: 'application/json',
    );
  }

  Future<void> exportCsv(List<Session> sessions) async {
    final buf = StringBuffer();
    buf.writeln(
        'SessionId,Date,Exercise,Weight,WeightUnit,Reps,TargetReps,Notes');
    for (final session in sessions) {
      for (final ex in session.recordedExercises) {
        if (ex is RecordedWeightedExercise) {
          for (final set in ex.potentialSets.where((s) => s.completed)) {
            final unit = set.weight.unit == WeightUnit.kilograms ? 'kg' : 'lbs';
            final row = [
              _csv(session.id),
              _csv(session.date.toIso8601String()),
              _csv(ex.blueprint.name),
              set.weight.value.toStringAsFixed(2),
              unit,
              set.reps?.toString() ?? '',
              ex.blueprint.reps.toString(),
              _csv(ex.notes ?? ''),
            ].join(',');
            buf.writeln(row);
          }
        }
      }
    }
    final bytes = utf8.encode(buf.toString());
    await _shareBytes(
      bytes: Uint8List.fromList(bytes),
      filename: _timestampedName('liftlog-export', 'csv'),
      mimeType: 'text/csv',
    );
  }

  Future<void> exportBackup({
    required List<Session> sessions,
    required List<ProgramBlueprint> programs,
    required String? activeProgramId,
  }) async {
    final data = {
      'version': 2,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'savedPrograms': {for (final p in programs) p.id: p.toJson()},
      'activeProgramId': activeProgramId,
    };
    final raw = utf8.encode(jsonEncode(data));
    final gzipped = GZipCodec().encode(raw);
    await _shareBytes(
      bytes: Uint8List.fromList(gzipped),
      filename: _timestampedName('export.liftlogbackup', 'gz'),
      mimeType: 'application/octet-stream',
    );
  }

  Future<Uint8List> buildBackupBytes({
    required List<Session> sessions,
    required List<ProgramBlueprint> programs,
    required String? activeProgramId,
  }) async {
    final data = {
      'version': 2,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'savedPrograms': {for (final p in programs) p.id: p.toJson()},
      'activeProgramId': activeProgramId,
    };
    final raw = utf8.encode(jsonEncode(data));
    return Uint8List.fromList(GZipCodec().encode(raw));
  }

  // Returns null on parse failure
  static Map<String, dynamic>? parseBackupBytes(Uint8List bytes) {
    try {
      Uint8List raw;
      // Try gzip first
      try {
        raw = Uint8List.fromList(GZipCodec().decode(bytes));
      } catch (_) {
        raw = bytes;
      }
      final decoded = jsonDecode(utf8.decode(raw));
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)],
        subject: filename);
  }

  String _csv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  String _timestampedName(String base, String ext) {
    final now = DateTime.now();
    final stamp =
        '${now.year}${_p(now.month)}${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}${_p(now.second)}';
    return '$base.$stamp.$ext';
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}
