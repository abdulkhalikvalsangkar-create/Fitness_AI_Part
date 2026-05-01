import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/blueprint_models.dart';
import '../../models/weight.dart';
import '../../providers/history_provider.dart';
import '../../providers/programs_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/export_service.dart';
import '../../services/import_service.dart';
import '../../services/remote_backup_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final programsAsync = ref.watch(programsProvider);

    final activeId = settings.activeProgramId;
    final activeProgram = activeId == null
        ? null
        : programsAsync.value?.fold<ProgramBlueprint?>(
            null, (found, p) => p.id == activeId ? p : found);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: ListView(
        children: [
          // ── Program ──────────────────────────────────────────────────────
          _SectionHeader('Program'),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Active Program'),
            subtitle: Text(activeProgram?.name ?? 'None selected'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/programs'),
          ),

          // ── Units & Display ───────────────────────────────────────────────
          const Divider(),
          _SectionHeader('Units & Display'),
          ListTile(
            leading: const Icon(Icons.scale),
            title: const Text('Weight Unit'),
            trailing: SegmentedButton<WeightUnit>(
              segments: const [
                ButtonSegment(value: WeightUnit.kilograms, label: Text('kg')),
                ButtonSegment(value: WeightUnit.pounds, label: Text('lbs')),
              ],
              selected: {settings.weightUnit},
              onSelectionChanged: (s) =>
                  ref.read(settingsProvider.notifier).setWeightUnit(s.first),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Week starts on'),
            trailing: DropdownButton<int>(
              value: settings.firstDayOfWeek,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                DropdownMenuItem(
                    value: DateTime.sunday, child: Text('Sunday')),
                DropdownMenuItem(
                    value: DateTime.saturday, child: Text('Saturday')),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsProvider.notifier).setFirstDayOfWeek(v);
                }
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.person_outline),
            title: const Text('Track Bodyweight'),
            subtitle: const Text('Show bodyweight field during workouts'),
            value: settings.showBodyweight,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setShowBodyweight(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notes),
            title: const Text('Notes Expanded by Default'),
            subtitle: const Text('Show exercise notes open in active session'),
            value: settings.notesExpandedByDefault,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setNotesExpandedByDefault(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.screen_lock_portrait),
            title: const Text('Keep Screen Awake'),
            subtitle: const Text('Prevent screen from sleeping during workouts'),
            value: settings.keepScreenAwake,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setKeepScreenAwake(v),
          ),

          // ── Export ────────────────────────────────────────────────────────
          const Divider(),
          _SectionHeader('Export'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export as CSV'),
            subtitle: const Text('Share workout history as spreadsheet'),
            onTap: () => _exportCsv(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Export as JSON'),
            subtitle: const Text('Share workout history as JSON'),
            onTap: () => _exportJson(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Export Backup'),
            subtitle: const Text('Full backup (programs + sessions)'),
            onTap: () => _exportBackup(context, ref),
          ),

          // ── Import ────────────────────────────────────────────────────────
          const Divider(),
          _SectionHeader('Import'),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore from a .liftlogbackup.gz file'),
            onTap: () => _importBackup(context, ref),
          ),

          // ── Remote Backup ─────────────────────────────────────────────────
          const Divider(),
          _SectionHeader('Remote Backup'),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Configure Remote Backup'),
            subtitle: Text(settings.remoteBackup.endpoint.isEmpty
                ? 'Not configured'
                : settings.remoteBackup.endpoint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRemoteBackupDialog(context, ref, settings),
          ),
          if (settings.remoteBackup.endpoint.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.cloud_done),
              title: const Text('Backup Now'),
              onTap: () => _runRemoteBackup(context, ref),
            ),

          // ── About ─────────────────────────────────────────────────────────
          const Divider(),
          _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('LiftLog Flutter'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final sessions = ref.read(historyProvider).value ?? [];
    try {
      await ExportService.instance.exportCsv(sessions);
    } catch (e) {
      if (context.mounted) _snack(context, 'Export failed: $e');
    }
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final sessions = ref.read(historyProvider).value ?? [];
    try {
      await ExportService.instance.exportJson(sessions);
    } catch (e) {
      if (context.mounted) _snack(context, 'Export failed: $e');
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final sessions = ref.read(historyProvider).value ?? [];
    final programs = ref.read(programsProvider).value ?? [];
    final activeProgramId = ref.read(settingsProvider).activeProgramId;
    try {
      await ExportService.instance.exportBackup(
        sessions: sessions,
        programs: programs,
        activeProgramId: activeProgramId,
      );
    } catch (e) {
      if (context.mounted) _snack(context, 'Export failed: $e');
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup'),
        content: const Text(
            'Importing will merge sessions and programs. Existing data with the same ID will be overwritten. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ImportService.instance.pickAndImport();
    if (result == null) {
      if (context.mounted) _snack(context, 'Import failed or cancelled');
      return;
    }
    await ref.read(historyProvider.notifier).upsertSessions(result.sessions);
    await ref.read(programsProvider.notifier).upsertPrograms(result.programs);
    if (result.activeProgramId != null) {
      await ref
          .read(settingsProvider.notifier)
          .setActiveProgram(result.activeProgramId);
    }
    if (context.mounted) {
      _snack(context,
          'Restored ${result.sessions.length} sessions, ${result.programs.length} programs');
    }
  }

  void _showRemoteBackupDialog(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    final endpointCtrl =
        TextEditingController(text: settings.remoteBackup.endpoint);
    final apiKeyCtrl =
        TextEditingController(text: settings.remoteBackup.apiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remote Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: endpointCtrl,
              decoration: const InputDecoration(
                labelText: 'Endpoint URL',
                hintText: 'https://your-server.com/backup',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: apiKeyCtrl,
              decoration: const InputDecoration(
                labelText: 'API Key (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setRemoteBackup(
                    RemoteBackupSettings(
                      endpoint: endpointCtrl.text,
                      apiKey: apiKeyCtrl.text,
                    ),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _runRemoteBackup(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final sessions = ref.read(historyProvider).value ?? [];
    final programs = ref.read(programsProvider).value ?? [];

    _snack(context, 'Backing up...');
    final result = await RemoteBackupService.instance.backup(
      endpoint: settings.remoteBackup.endpoint,
      apiKey: settings.remoteBackup.apiKey,
      sessions: sessions,
      programs: programs,
      activeProgramId: settings.activeProgramId,
    );
    if (context.mounted) {
      _snack(context, result.success ? 'Backup successful!' : result.error!);
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
