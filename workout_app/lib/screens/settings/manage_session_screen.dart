import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/blueprint_models.dart';
import '../../models/weight.dart';
import '../../providers/programs_provider.dart';
import '../../providers/settings_provider.dart';

class ManageSessionScreen extends ConsumerWidget {
  final String programId;
  final int sessionIndex;

  const ManageSessionScreen({
    super.key,
    required this.programId,
    required this.sessionIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsProvider);
    final settings = ref.watch(settingsProvider);

    return programsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (programs) {
        // Find program — loop avoids the fragile .cast<>() pattern.
        ProgramBlueprint? found;
        for (final p in programs) {
          if (p.id == programId) { found = p; break; }
        }
        if (found == null || sessionIndex >= found.sessions.length) {
          return const Scaffold(
              body: Center(child: Text('Session not found')));
        }
        // Assign to a new final so closures below get the non-nullable type.
        final program = found;
        final session = program.sessions[sessionIndex];

        return Scaffold(
          appBar: AppBar(
            title: Text(session.name),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _addExercise(context, ref, program, session, settings.weightUnit),
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
          ),
          body: session.exercises.isEmpty
              ? const Center(
                  child: Text('No exercises. Tap + to add one.'))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: session.exercises.length,
                  onReorder: (old, newIdx) =>
                      _reorderExercise(ref, program, session, old, newIdx),
                  itemBuilder: (context, i) {
                    final exercise = session.exercises[i];
                    return _ExerciseTile(
                      key: ValueKey('$i-${exercise.name}'),
                      exercise: exercise,
                      onEdit: () => _editExercise(
                          context, ref, program, session, i, settings.weightUnit),
                      onDelete: () =>
                          _deleteExercise(ref, program, session, i),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _updateSession(WidgetRef ref, ProgramBlueprint program,
      SessionBlueprint updatedSession) async {
    final sessions = List<SessionBlueprint>.from(program.sessions);
    sessions[sessionIndex] = updatedSession;
    await ref.read(programsProvider.notifier).updateProgram(
          program.copyWith(sessions: sessions, lastEdited: DateTime.now()),
        );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref,
      ProgramBlueprint program, SessionBlueprint session,
      WeightUnit weightUnit) async {
    final result = await _showExerciseDialog(context, null, weightUnit);
    if (result == null) return;
    final updated = session.copyWith(
        exercises: [...session.exercises, result]);
    await _updateSession(ref, program, updated);
  }

  Future<void> _editExercise(BuildContext context, WidgetRef ref,
      ProgramBlueprint program, SessionBlueprint session, int index,
      WeightUnit weightUnit) async {
    final result =
        await _showExerciseDialog(context, session.exercises[index], weightUnit);
    if (result == null) return;
    final exercises = List<ExerciseBlueprint>.from(session.exercises);
    exercises[index] = result;
    await _updateSession(ref, program, session.copyWith(exercises: exercises));
  }

  Future<void> _deleteExercise(WidgetRef ref, ProgramBlueprint program,
      SessionBlueprint session, int index) async {
    final exercises = List<ExerciseBlueprint>.from(session.exercises)
      ..removeAt(index);
    await _updateSession(ref, program, session.copyWith(exercises: exercises));
  }

  Future<void> _reorderExercise(WidgetRef ref, ProgramBlueprint program,
      SessionBlueprint session, int old, int newIdx) async {
    final exercises = List<ExerciseBlueprint>.from(session.exercises);
    if (newIdx > old) newIdx -= 1;
    final item = exercises.removeAt(old);
    exercises.insert(newIdx, item);
    await _updateSession(ref, program, session.copyWith(exercises: exercises));
  }

  Future<ExerciseBlueprint?> _showExerciseDialog(
      BuildContext context, ExerciseBlueprint? existing, WeightUnit weightUnit) {
    return showModalBottomSheet<ExerciseBlueprint>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExerciseEditorSheet(
        existing: existing,
        weightUnit: weightUnit,
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseBlueprint exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseTile({
    super.key,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          exercise.isWeighted ? Icons.fitness_center : Icons.directions_run,
        ),
        title: Text(exercise.name),
        subtitle: switch (exercise) {
          WeightedExerciseBlueprint e =>
            Text('${e.sets}×${e.reps} · ${e.initialWeight.format()} · '
                'Rest ${_formatDuration(e.restDuration)}'),
          CardioExerciseBlueprint _ => const Text('Cardio'),
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Theme.of(context).colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

class _ExerciseEditorSheet extends StatefulWidget {
  final ExerciseBlueprint? existing;
  final WeightUnit weightUnit;

  const _ExerciseEditorSheet({this.existing, required this.weightUnit});

  @override
  State<_ExerciseEditorSheet> createState() => _ExerciseEditorSheetState();
}

class _ExerciseEditorSheetState extends State<_ExerciseEditorSheet> {
  bool _isCardio = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _setsCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _restCtrl;
  late TextEditingController _weightCtrl;
  late WeightUnit _weightUnit;

  @override
  void initState() {
    super.initState();
    _weightUnit = widget.weightUnit;
    final existing = widget.existing;
    if (existing is WeightedExerciseBlueprint) {
      _isCardio = false;
      _nameCtrl = TextEditingController(text: existing.name);
      _setsCtrl = TextEditingController(text: existing.sets.toString());
      _repsCtrl = TextEditingController(text: existing.reps.toString());
      _restCtrl =
          TextEditingController(text: existing.restDuration.inSeconds.toString());
      final w = existing.initialWeight.convertTo(_weightUnit);
      _weightCtrl = TextEditingController(
          text: w.value == w.value.roundToDouble()
              ? w.value.toInt().toString()
              : w.value.toStringAsFixed(1));
    } else if (existing is CardioExerciseBlueprint) {
      _isCardio = true;
      _nameCtrl = TextEditingController(text: existing.name);
      _setsCtrl = TextEditingController(text: '1');
      _repsCtrl = TextEditingController(text: '1');
      _restCtrl = TextEditingController(text: '0');
      _weightCtrl = TextEditingController(text: '0');
    } else {
      _nameCtrl = TextEditingController();
      _setsCtrl = TextEditingController(text: '3');
      _repsCtrl = TextEditingController(text: '10');
      _restCtrl = TextEditingController(text: '90');
      _weightCtrl = TextEditingController(text: '20');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _restCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  ExerciseBlueprint _build() {
    if (_isCardio) {
      return CardioExerciseBlueprint(
        name: _nameCtrl.text.trim().isEmpty ? 'Cardio' : _nameCtrl.text.trim(),
        trackDuration: true,
        trackDistance: true,
      );
    }
    return WeightedExerciseBlueprint(
      name: _nameCtrl.text.trim().isEmpty ? 'Exercise' : _nameCtrl.text.trim(),
      sets: int.tryParse(_setsCtrl.text) ?? 3,
      reps: int.tryParse(_repsCtrl.text) ?? 10,
      restDuration:
          Duration(seconds: int.tryParse(_restCtrl.text) ?? 90),
      initialWeight: Weight(
        value: double.tryParse(_weightCtrl.text) ?? 20,
        unit: _weightUnit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.existing == null ? 'Add Exercise' : 'Edit Exercise',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Type toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Weighted'), icon: Icon(Icons.fitness_center)),
                ButtonSegment(value: true, label: Text('Cardio'), icon: Icon(Icons.directions_run)),
              ],
              selected: {_isCardio},
              onSelectionChanged: (s) => setState(() => _isCardio = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                border: OutlineInputBorder(),
              ),
            ),
            if (!_isCardio) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _setsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Sets',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Reps',
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _restCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Rest (seconds)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText:
                            'Starting Weight (${_weightUnit == WeightUnit.kilograms ? 'kg' : 'lbs'})',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _build()),
                child: Text(
                    widget.existing == null ? 'Add Exercise' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
