import 'package:http/http.dart' as http;
import '../models/session_models.dart';
import '../models/blueprint_models.dart';
import 'export_service.dart';

enum RemoteBackupStatus { idle, running, success, error }

class RemoteBackupResult {
  final bool success;
  final String? error;
  const RemoteBackupResult.ok() : success = true, error = null;
  const RemoteBackupResult.fail(this.error) : success = false;
}

class RemoteBackupService {
  static RemoteBackupService? _instance;
  RemoteBackupService._();
  static RemoteBackupService get instance {
    _instance ??= RemoteBackupService._();
    return _instance!;
  }

  Future<RemoteBackupResult> backup({
    required String endpoint,
    required String? apiKey,
    required List<Session> sessions,
    required List<ProgramBlueprint> programs,
    required String? activeProgramId,
  }) async {
    if (endpoint.trim().isEmpty) {
      return const RemoteBackupResult.fail('No endpoint configured');
    }
    try {
      final bytes = await ExportService.instance.buildBackupBytes(
        sessions: sessions,
        programs: programs,
        activeProgramId: activeProgramId,
      );
      final headers = <String, String>{
        'Content-Type': 'application/octet-stream',
      };
      if (apiKey != null && apiKey.trim().isNotEmpty) {
        headers['X-Api-Key'] = apiKey.trim();
      }
      final response = await http
          .post(
            Uri.parse(endpoint.trim()),
            headers: headers,
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const RemoteBackupResult.ok();
      }
      return RemoteBackupResult.fail('HTTP ${response.statusCode}');
    } on FormatException {
      return const RemoteBackupResult.fail('Invalid endpoint URL');
    } catch (e) {
      return RemoteBackupResult.fail(e.toString());
    }
  }
}
