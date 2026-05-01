import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/blueprint_models.dart';
import '../../providers/programs_provider.dart';

class ManageProgramScreen extends ConsumerStatefulWidget {
  final String programId;
  const ManageProgramScreen({super.key, required this.programId});

  @override
  ConsumerState<ManageProgramScreen> createState() =>
      _ManageProgramScreenState();
}

class _ManageProgramScreenState extends ConsumerState<ManageProgramScreen> {
  late TextEditingController _nameController;
  ProgramBlueprint? _program;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  ProgramBlueprint? _findProgram(List<ProgramBlueprint> programs) {
    for (final p in programs) {
      if (p.id == widget.programId) return p;
    }
    return null;
  }

  Future<void> _save(ProgramBlueprint program) async {
    await ref.read(programsProvider.notifier).updateProgram(
          program.copyWith(
            name: _nameController.text.trim().isEmpty
                ? program.name
                : _nameController.text.trim(),
            lastEdited: DateTime.now(),
          ),
        );
  }

  Future<void> _addSession(ProgramBlueprint program) async {
    final name = await _showNameDialog('New Session', '');
    if (!mounted || name == null || name.trim().isEmpty) return;
    final updated = program.copyWith(
      sessions: [...program.sessions, SessionBlueprint(name: name.trim())],
      lastEdited: DateTime.now(),
    );
    await ref.read(programsProvider.notifier).updateProgram(updated);
  }

  Future<void> _deleteSession(ProgramBlueprint program, int index) async {
    final sessions = List<SessionBlueprint>.from(program.sessions)
      ..removeAt(index);
    await ref.read(programsProvider.notifier).updateProgram(
          program.copyWith(sessions: sessions, lastEdited: DateTime.now()),
        );
  }

  Future<void> _renameSession(ProgramBlueprint program, int index) async {
    final name =
        await _showNameDialog('Rename Session', program.sessions[index].name);
    if (!mounted || name == null || name.trim().isEmpty) return;
    final sessions = List<SessionBlueprint>.from(program.sessions);
    sessions[index] = sessions[index].copyWith(name: name.trim());
    await ref.read(programsProvider.notifier).updateProgram(
          program.copyWith(sessions: sessions, lastEdited: DateTime.now()),
        );
  }

  Future<void> _reorderSessions(
      ProgramBlueprint program, int oldIndex, int newIndex) async {
    final sessions = List<SessionBlueprint>.from(program.sessions);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = sessions.removeAt(oldIndex);
    sessions.insert(newIndex, item);
    await ref.read(programsProvider.notifier).updateProgram(
          program.copyWith(sessions: sessions, lastEdited: DateTime.now()),
        );
  }

  Future<String?> _showNameDialog(String title, String initial) {
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => _NameDialog(title: title, initial: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);

    return programsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (programs) {
        final program = _findProgram(programs);
        if (program == null) {
          return const Scaffold(
              body: Center(child: Text('Program not found')));
        }

        // Update name field after build if this is a different program.
        if (_program?.id != program.id) {
          _program = program;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _nameController.text = program.name;
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Program'),
            actions: [
              TextButton(
                onPressed: () => _save(program),
                child: const Text('Save'),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Program Name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _save(program),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text('Sessions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _addSession(program),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: program.sessions.isEmpty
                    ? const Center(
                        child: Text('No sessions yet. Tap Add to create one.'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: program.sessions.length,
                        onReorder: (old, newIdx) =>
                            _reorderSessions(program, old, newIdx),
                        itemBuilder: (context, i) {
                          final session = program.sessions[i];
                          return Card(
                            key: ValueKey(session.name + i.toString()),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.drag_handle),
                              title: Text(session.name),
                              subtitle: Text(
                                  '${session.exercises.length} exercise${session.exercises.length == 1 ? '' : 's'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    onPressed: () =>
                                        _renameSession(program, i),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16),
                                    onPressed: () => context.push(
                                        '/settings/programs/${program.id}/session/$i'),
                                  ),
                                ],
                              ),
                              onLongPress: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: const Text('Delete Session?'),
                                    content: Text(
                                        'Delete "${session.name}"?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.of(dialogCtx).pop(false),
                                          child: const Text('Cancel')),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(dialogCtx).pop(true),
                                        style: FilledButton.styleFrom(
                                            backgroundColor:
                                                Theme.of(dialogCtx)
                                                    .colorScheme
                                                    .error),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (!mounted || confirm != true) return;
                                await _deleteSession(program, i);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Standalone StatefulWidget so the TextEditingController is properly
// initialised in initState and disposed when the dialog is dismissed.

class _NameDialog extends StatefulWidget {
  final String title;
  final String initial;

  const _NameDialog({required this.title, required this.initial});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    _isEmpty = widget.initial.trim().isEmpty;
    _controller.addListener(() {
      final empty = _controller.text.trim().isEmpty;
      if (empty != _isEmpty) setState(() => _isEmpty = empty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Name',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isEmpty ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
