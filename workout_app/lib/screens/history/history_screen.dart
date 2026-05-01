import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/session_models.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  StartingDayOfWeek _toStartingDayOfWeek(int day) => switch (day) {
        DateTime.monday => StartingDayOfWeek.monday,
        DateTime.saturday => StartingDayOfWeek.saturday,
        _ => StartingDayOfWeek.sunday,
      };

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: false,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          final sessionsByDate = <DateTime, List<Session>>{};
          for (final s in sessions) {
            final key = DateTime(s.date.year, s.date.month, s.date.day);
            sessionsByDate.putIfAbsent(key, () => []).add(s);
          }

          final filtered = _selectedDay == null
              ? sessions
              : (sessionsByDate[DateTime(_selectedDay!.year,
                      _selectedDay!.month, _selectedDay!.day)] ??
                  []);

          return Column(
            children: [
              TableCalendar<Session>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                startingDayOfWeek: _toStartingDayOfWeek(
                    ref.watch(settingsProvider).firstDayOfWeek),
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                eventLoader: (day) =>
                    sessionsByDate[DateTime(day.year, day.month, day.day)] ??
                    [],
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay =
                        isSameDay(selected, _selectedDay) ? null : selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  _focusedDay = focused;
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _selectedDay == null
                              ? 'No workouts recorded yet'
                              : 'No workout on this day',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) =>
                            _SessionTile(session: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  final Session session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEE, MMM d');
    final settings = ref.watch(settingsProvider);

    final weightedExercises =
        session.recordedExercises.whereType<RecordedWeightedExercise>();
    final completedSets = weightedExercises
        .expand((e) => e.potentialSets)
        .where((s) => s.completed)
        .length;
    final totalVolume = session.totalVolume;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.blueprint.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    dateFormat.format(session.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: [
                  if (session.duration != null)
                    _Stat(
                      icon: Icons.timer_outlined,
                      label: _formatDuration(session.duration!),
                    ),
                  if (completedSets > 0)
                    _Stat(
                      icon: Icons.check_circle_outline,
                      label: '$completedSets sets',
                    ),
                  if (totalVolume > 0)
                    _Stat(
                      icon: Icons.bar_chart,
                      label: '${totalVolume.toStringAsFixed(0)} kg vol.',
                    ),
                  if (session.bodyweight != null)
                    _Stat(
                      icon: Icons.person_outline,
                      label: session.bodyweight!
                          .convertTo(settings.weightUnit)
                          .format(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  void _showDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SessionDetailSheet(session: session, ref: ref),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

class _SessionDetailSheet extends StatelessWidget {
  final Session session;
  final WidgetRef ref;
  const _SessionDetailSheet({required this.session, required this.ref});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.blueprint.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(session.date),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete session?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await ref
                            .read(historyProvider.notifier)
                            .deleteSession(session.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: session.recordedExercises.map((exercise) {
                  return switch (exercise) {
                    RecordedWeightedExercise e =>
                      _WeightedExerciseSummary(exercise: e),
                    RecordedCardioExercise e =>
                      _CardioExerciseSummary(exercise: e),
                  };
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WeightedExerciseSummary extends StatelessWidget {
  final RecordedWeightedExercise exercise;
  const _WeightedExerciseSummary({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final completed = exercise.potentialSets.where((s) => s.completed).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.blueprint.name,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          ...completed.asMap().entries.map((entry) {
            final s = entry.value;
            return Text(
              'Set ${entry.key + 1}: ${s.reps ?? '-'} reps × ${s.weight.format()}',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }),
          if (completed.isEmpty)
            Text('No sets completed',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
        ],
      ),
    );
  }
}

class _CardioExerciseSummary extends StatelessWidget {
  final RecordedCardioExercise exercise;
  const _CardioExerciseSummary({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_run, size: 16),
              const SizedBox(width: 4),
              Text(exercise.blueprint.name,
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          ...exercise.recordedSets.map((s) {
            final parts = <String>[];
            if (s.duration != null) {
              final m = s.duration!.inMinutes;
              final sec = s.duration!.inSeconds % 60;
              parts.add('${m}m ${sec}s');
            }
            if (s.distanceKm != null) {
              parts.add('${s.distanceKm!.toStringAsFixed(2)} km');
            }
            return Text(parts.join(' · '),
                style: Theme.of(context).textTheme.bodyMedium);
          }),
        ],
      ),
    );
  }
}
