import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/session_models.dart';
import '../../models/weight.dart';
import '../../providers/current_session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/rest_timer_widget.dart';
import '../../widgets/weight_editor_dialog.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  // exerciseIndex -> setIndex that triggered the rest timer
  ({int exercise, int set})? _restFor;

  void _onSetCompleted(int exerciseIndex, int setIndex, Duration rest) {
    ref
        .read(currentSessionProvider.notifier)
        .toggleSetCompleted(exerciseIndex, setIndex);
    if (rest.inSeconds > 0) {
      setState(() => _restFor = (exercise: exerciseIndex, set: setIndex));
    }
  }

  Future<bool> _confirmDiscard() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Discard workout?'),
            content: const Text('All progress for this session will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.error),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(currentSessionProvider);
    final settings = ref.watch(settingsProvider);
    final session = sessionState.session;

    if (session == null || !sessionState.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/workout'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) {
          ref.read(currentSessionProvider.notifier).discardSession();
          context.go('/workout');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(session.blueprint.name),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final discard = await _confirmDiscard();
              if (discard && context.mounted) {
                ref.read(currentSessionProvider.notifier).discardSession();
                context.go('/workout');
              }
            },
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                await ref
                    .read(currentSessionProvider.notifier)
                    .saveSession();
                if (context.mounted) context.go('/workout');
              },
              child: const Text('Finish'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            if (_restFor != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: RestTimerWidget(
                  duration: _getRestDuration(session, _restFor!.exercise),
                  onDismiss: () => setState(() => _restFor = null),
                ),
              ),
            ],
            if (settings.showBodyweight)
              _BodyweightRow(
                bodyweight: session.bodyweight,
                weightUnit: settings.weightUnit,
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: session.recordedExercises.length,
                itemBuilder: (context, index) {
                  final exercise = session.recordedExercises[index];
                  return switch (exercise) {
                    RecordedWeightedExercise e => _WeightedExerciseCard(
                        exercise: e,
                        exerciseIndex: index,
                        weightUnit: settings.weightUnit,
                        notesExpandedByDefault:
                            settings.notesExpandedByDefault,
                        onSetToggled: (setIndex) => _onSetCompleted(
                            index, setIndex, e.blueprint.restDuration),
                        onAddSet: () => ref
                            .read(currentSessionProvider.notifier)
                            .addSet(index),
                        onRemoveSet: (setIndex) => ref
                            .read(currentSessionProvider.notifier)
                            .removeSet(index, setIndex),
                        onWeightEdit: (setIndex, weight) => ref
                            .read(currentSessionProvider.notifier)
                            .updateSetWeight(index, setIndex, weight),
                        onRepsEdit: (setIndex, reps) => ref
                            .read(currentSessionProvider.notifier)
                            .updateSetReps(index, setIndex, reps),
                        onNotesChanged: (notes) => ref
                            .read(currentSessionProvider.notifier)
                            .updateExerciseNotes(index, notes),
                      ),
                    RecordedCardioExercise e => _CardioExerciseCard(
                        exercise: e,
                        exerciseIndex: index,
                        notesExpandedByDefault:
                            settings.notesExpandedByDefault,
                        onNotesChanged: (notes) => ref
                            .read(currentSessionProvider.notifier)
                            .updateExerciseNotes(index, notes),
                      ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration _getRestDuration(Session session, int exerciseIndex) {
    final exercise = session.recordedExercises[exerciseIndex];
    if (exercise is RecordedWeightedExercise) {
      return exercise.blueprint.restDuration;
    }
    return Duration.zero;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BodyweightRow extends ConsumerStatefulWidget {
  final Weight? bodyweight;
  final WeightUnit weightUnit;

  const _BodyweightRow({required this.bodyweight, required this.weightUnit});

  @override
  ConsumerState<_BodyweightRow> createState() => _BodyweightRowState();
}

class _BodyweightRowState extends ConsumerState<_BodyweightRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 18),
          const SizedBox(width: 8),
          Text('Bodyweight: ',
              style: Theme.of(context).textTheme.bodyMedium),
          TextButton(
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            onPressed: () => showWeightEditor(
              context,
              initial: widget.bodyweight ??
                  Weight(value: 70, unit: widget.weightUnit),
              onChanged: (w) =>
                  ref.read(currentSessionProvider.notifier).updateBodyweight(w),
            ),
            child: Text(
              widget.bodyweight?.format() ?? 'Tap to add',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WeightedExerciseCard extends StatefulWidget {
  final RecordedWeightedExercise exercise;
  final int exerciseIndex;
  final WeightUnit weightUnit;
  final bool notesExpandedByDefault;
  final ValueChanged<int> onSetToggled;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final void Function(int setIndex, Weight weight) onWeightEdit;
  final void Function(int setIndex, int reps) onRepsEdit;
  final ValueChanged<String> onNotesChanged;

  const _WeightedExerciseCard({
    required this.exercise,
    required this.exerciseIndex,
    required this.weightUnit,
    required this.notesExpandedByDefault,
    required this.onSetToggled,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onWeightEdit,
    required this.onRepsEdit,
    required this.onNotesChanged,
  });

  @override
  State<_WeightedExerciseCard> createState() => _WeightedExerciseCardState();
}

class _WeightedExerciseCardState extends State<_WeightedExerciseCard> {
  late bool _notesExpanded;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesExpanded = widget.notesExpandedByDefault || (widget.exercise.notes?.isNotEmpty ?? false);
    _notesCtrl = TextEditingController(text: widget.exercise.notes ?? '');
  }

  @override
  void didUpdateWidget(_WeightedExerciseCard old) {
    super.didUpdateWidget(old);
    if (widget.exercise.notes != old.exercise.notes &&
        widget.exercise.notes != _notesCtrl.text) {
      _notesCtrl.text = widget.exercise.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final restLabel = _formatDuration(ex.blueprint.restDuration);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ex.blueprint.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text('Rest $restLabel'),
                  avatar: const Icon(Icons.timer_outlined, size: 14),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 40),
                const SizedBox(width: 32, child: Center(child: Text('#', style: TextStyle(fontSize: 12)))),
                const SizedBox(width: 8),
                Expanded(child: Center(child: Text('Reps', style: TextStyle(fontSize: 12)))),
                const SizedBox(width: 8),
                Expanded(child: Center(child: Text('Weight', style: TextStyle(fontSize: 12)))),
                const SizedBox(width: 32),
              ],
            ),
            const Divider(height: 8),
            ...ex.potentialSets.asMap().entries.map((entry) {
              final i = entry.key;
              final set = entry.value;
              return _SetRow(
                setNumber: i + 1,
                set: set,
                weightUnit: widget.weightUnit,
                onToggle: () => widget.onSetToggled(i),
                onWeightTap: (w) => widget.onWeightEdit(i, w),
                onRepsTap: (r) => widget.onRepsEdit(i, r),
                onRemove: ex.potentialSets.length > 1
                    ? () => widget.onRemoveSet(i)
                    : null,
              );
            }),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: widget.onAddSet,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add set'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
            // Notes
            const Divider(height: 16),
            InkWell(
              onTap: () => setState(() => _notesExpanded = !_notesExpanded),
              child: Row(
                children: [
                  Icon(
                    _notesExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (!_notesExpanded && (ex.notes?.isNotEmpty ?? false)) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ex.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_notesExpanded) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add notes...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                maxLines: 3,
                onChanged: widget.onNotesChanged,
              ),
            ],
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

// ─────────────────────────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  final int setNumber;
  final PotentialSet set;
  final WeightUnit weightUnit;
  final VoidCallback onToggle;
  final ValueChanged<Weight> onWeightTap;
  final ValueChanged<int> onRepsTap;
  final VoidCallback? onRemove;

  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.weightUnit,
    required this.onToggle,
    required this.onWeightTap,
    required this.onRepsTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final completed = set.completed;
    final colorScheme = Theme.of(context).colorScheme;
    final dimColor = colorScheme.onSurface.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: completed,
              onChanged: (_) => onToggle(),
            ),
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '$setNumber',
                style: TextStyle(
                  color: completed ? dimColor : null,
                  decoration:
                      completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _EditableValue(
              value: '${set.reps ?? '-'}',
              completed: completed,
              onTap: () async {
                final result = await _showIntDialog(context, 'Reps', set.reps ?? 0);
                if (result != null) onRepsTap(result);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _EditableValue(
              value: set.weight.convertTo(weightUnit).format(),
              completed: completed,
              onTap: () async {
                final w = set.weight.convertTo(weightUnit);
                if (context.mounted) {
                  showWeightEditor(
                    context,
                    initial: w,
                    onChanged: onWeightTap,
                  );
                }
              },
            ),
          ),
          SizedBox(
            width: 32,
            child: onRemove != null
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    color: dimColor,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Future<int?> _showIntDialog(BuildContext context, String label, int initial) {
    final controller = TextEditingController(text: initial.toString());
    return showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) =>
              Navigator.pop(context, int.tryParse(v)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
                context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _EditableValue extends StatelessWidget {
  final String value;
  final bool completed;
  final VoidCallback onTap;

  const _EditableValue({
    required this.value,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: completed
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              color: completed
                  ? colorScheme.onSurface.withValues(alpha: 0.4)
                  : colorScheme.onSurface,
              decoration:
                  completed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CardioExerciseCard extends ConsumerStatefulWidget {
  final RecordedCardioExercise exercise;
  final int exerciseIndex;
  final bool notesExpandedByDefault;
  final ValueChanged<String> onNotesChanged;

  const _CardioExerciseCard({
    required this.exercise,
    required this.exerciseIndex,
    required this.notesExpandedByDefault,
    required this.onNotesChanged,
  });

  @override
  ConsumerState<_CardioExerciseCard> createState() =>
      _CardioExerciseCardState();
}

class _CardioExerciseCardState extends ConsumerState<_CardioExerciseCard> {
  late bool _notesExpanded;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesExpanded = widget.notesExpandedByDefault ||
        (widget.exercise.notes?.isNotEmpty ?? false);
    _notesCtrl = TextEditingController(text: widget.exercise.notes ?? '');
  }

  @override
  void didUpdateWidget(_CardioExerciseCard old) {
    super.didUpdateWidget(old);
    if (widget.exercise.notes != old.exercise.notes &&
        widget.exercise.notes != _notesCtrl.text) {
      _notesCtrl.text = widget.exercise.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final idx = widget.exerciseIndex;
    final set = ex.recordedSets.isNotEmpty
        ? ex.recordedSets.first
        : const CardioExerciseRecordedSet();
    final bp = ex.blueprint;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_run, size: 18),
                const SizedBox(width: 8),
                Text(bp.name, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (bp.trackDuration)
                  _CardioField(
                    label: 'Duration',
                    value: set.duration != null
                        ? _formatDuration(set.duration!)
                        : '--:--',
                    onTap: () => _editDuration(context, set, idx),
                  ),
                if (bp.trackDistance)
                  _CardioField(
                    label: 'Distance (km)',
                    value: set.distanceKm?.toStringAsFixed(2) ?? '-',
                    onTap: () => _editDouble(context, 'Distance (km)',
                        set.distanceKm ?? 0,
                        (v) => ref
                            .read(currentSessionProvider.notifier)
                            .updateCardioSet(idx, 0, set.copyWith(distanceKm: v))),
                  ),
                if (bp.trackResistance)
                  _CardioField(
                    label: 'Resistance',
                    value: '${set.resistanceLevel ?? '-'}',
                    onTap: () => _editInt(context, 'Resistance Level',
                        set.resistanceLevel ?? 0,
                        (v) => ref
                            .read(currentSessionProvider.notifier)
                            .updateCardioSet(idx, 0, set.copyWith(resistanceLevel: v))),
                  ),
                if (bp.trackIncline)
                  _CardioField(
                    label: 'Incline (%)',
                    value: set.inclinePercent?.toStringAsFixed(1) ?? '-',
                    onTap: () => _editDouble(context, 'Incline (%)',
                        set.inclinePercent ?? 0,
                        (v) => ref
                            .read(currentSessionProvider.notifier)
                            .updateCardioSet(idx, 0, set.copyWith(inclinePercent: v))),
                  ),
              ],
            ),
            // Notes
            const Divider(height: 16),
            InkWell(
              onTap: () => setState(() => _notesExpanded = !_notesExpanded),
              child: Row(
                children: [
                  Icon(
                    _notesExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text('Notes',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                  if (!_notesExpanded && (ex.notes?.isNotEmpty ?? false)) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ex.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_notesExpanded) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add notes...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                maxLines: 3,
                onChanged: widget.onNotesChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _editDuration(
      BuildContext context, CardioExerciseRecordedSet set, int idx) async {
    final controller = TextEditingController(
        text: set.duration != null
            ? '${set.duration!.inMinutes}:${(set.duration!.inSeconds % 60).toString().padLeft(2, '0')}'
            : '');
    final result = await showDialog<Duration>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Duration (mm:ss)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: '30:00', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final parts = controller.text.split(':');
              final minutes = int.tryParse(parts[0]) ?? 0;
              final seconds =
                  parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
              Navigator.pop(
                  context, Duration(minutes: minutes, seconds: seconds));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      ref
          .read(currentSessionProvider.notifier)
          .updateCardioSet(idx, 0, set.copyWith(duration: result));
    }
  }

  Future<void> _editDouble(BuildContext context, String label,
      double initial, void Function(double) onSave) async {
    final controller =
        TextEditingController(text: initial.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) onSave(result);
  }

  Future<void> _editInt(BuildContext context, String label,
      int initial, void Function(int) onSave) async {
    final controller = TextEditingController(text: initial.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) onSave(result);
  }
}

class _CardioField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _CardioField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
