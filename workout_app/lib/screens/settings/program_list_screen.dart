import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/blueprint_models.dart';
import '../../providers/programs_provider.dart';
import '../../providers/settings_provider.dart';

class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final notifier = ref.read(programsProvider.notifier);
          final newProgram = notifier.createNewProgram();
          await notifier.addProgram(newProgram);
          if (context.mounted) {
            context.push('/settings/programs/${newProgram.id}');
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Program'),
      ),
      body: programsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (programs) => programs.isEmpty
            ? const Center(child: Text('No programs yet. Create one!'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: programs.length,
                itemBuilder: (context, i) {
                  final program = programs[i];
                  final isActive = program.id == settings.activeProgramId;
                  return _ProgramCard(
                    program: program,
                    isActive: isActive,
                    onActivate: () => ref
                        .read(settingsProvider.notifier)
                        .setActiveProgram(isActive ? null : program.id),
                    onEdit: () =>
                        context.push('/settings/programs/${program.id}'),
                    onDelete: () =>
                        _confirmDelete(context, ref, program),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ProgramBlueprint program) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Program?'),
        content: Text('Delete "${program.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(programsProvider.notifier).deleteProgram(program.id);
      // If it was active, clear the active program
      if (ref.read(settingsProvider).activeProgramId == program.id) {
        await ref.read(settingsProvider.notifier).setActiveProgram(null);
      }
    }
  }
}

class _ProgramCard extends StatelessWidget {
  final ProgramBlueprint program;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProgramCard({
    required this.program,
    required this.isActive,
    required this.onActivate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isActive ? colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: isActive
                                  ? colorScheme.onPrimaryContainer
                                  : null,
                            ),
                      ),
                      Text(
                        '${program.sessions.length} session${program.sessions.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isActive
                                  ? colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.7)
                                  : colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Chip(
                    label: const Text('Active'),
                    backgroundColor: colorScheme.primary,
                    labelStyle:
                        TextStyle(color: colorScheme.onPrimary, fontSize: 12),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Session names
            ...program.sessions.map((s) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• ${s.name}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive
                              ? colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8)
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                )),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onActivate,
                  icon: Icon(
                      isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16),
                  label: Text(isActive ? 'Active' : 'Set Active'),
                  style: isActive
                      ? OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onPrimaryContainer,
                          side: BorderSide(
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.5)),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                IconButton.outlined(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: colorScheme.error),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
