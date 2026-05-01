import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/session_models.dart';
import '../../models/weight.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';

enum _TimePeriod { month, threeMonths, year, all }

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  _TimePeriod _period = _TimePeriod.month;
  String? _selectedExercise;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        centerTitle: false,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allSessions) {
          final cutoff = _cutoffDate(_period);
          final sessions = cutoff == null
              ? allSessions
              : allSessions
                  .where((s) => s.date.isAfter(cutoff))
                  .toList();

          if (allSessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart, size: 64),
                    SizedBox(height: 16),
                    Text('Complete some workouts to see stats here.'),
                  ],
                ),
              ),
            );
          }

          // Collect all exercise names from history
          final exerciseNames = allSessions
              .expand((s) => s.recordedExercises
                  .whereType<RecordedWeightedExercise>())
              .map((e) => e.blueprint.name)
              .toSet()
              .toList()
            ..sort();

          if (_selectedExercise == null && exerciseNames.isNotEmpty) {
            _selectedExercise = exerciseNames.first;
          }

          final overallStats = _computeStats(sessions);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Time period selector
              SegmentedButton<_TimePeriod>(
                segments: const [
                  ButtonSegment(value: _TimePeriod.month, label: Text('1M')),
                  ButtonSegment(value: _TimePeriod.threeMonths, label: Text('3M')),
                  ButtonSegment(value: _TimePeriod.year, label: Text('1Y')),
                  ButtonSegment(value: _TimePeriod.all, label: Text('All')),
                ],
                selected: {_period},
                onSelectionChanged: (s) =>
                    setState(() => _period = s.first),
              ),
              const SizedBox(height: 16),

              // Summary cards
              _SummaryGrid(stats: overallStats, sessions: sessions,
                  weightUnit: settings.weightUnit),

              const SizedBox(height: 24),

              // Exercise selector
              if (exerciseNames.isNotEmpty) ...[
                Text('Exercise Progress',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedExercise,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: exerciseNames
                      .map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedExercise = v),
                ),
                const SizedBox(height: 16),
                if (_selectedExercise != null)
                  _ExerciseChart(
                    sessions: sessions,
                    exerciseName: _selectedExercise!,
                    weightUnit: settings.weightUnit,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  DateTime? _cutoffDate(_TimePeriod period) {
    final now = DateTime.now();
    return switch (period) {
      _TimePeriod.month => now.subtract(const Duration(days: 30)),
      _TimePeriod.threeMonths => now.subtract(const Duration(days: 90)),
      _TimePeriod.year => now.subtract(const Duration(days: 365)),
      _TimePeriod.all => null,
    };
  }

  _Stats _computeStats(List<Session> sessions) {
    int totalSets = 0;
    double totalVolume = 0;
    double? maxWeight;

    for (final session in sessions) {
      for (final exercise in session.recordedExercises
          .whereType<RecordedWeightedExercise>()) {
        for (final set in exercise.potentialSets.where((s) => s.completed)) {
          totalSets++;
          final weightKg = set.weight.toKilograms().value;
          totalVolume += (set.reps ?? 0) * weightKg;
          if (maxWeight == null || weightKg > maxWeight) {
            maxWeight = weightKg;
          }
        }
      }
    }

    return _Stats(
      sessionCount: sessions.length,
      totalSets: totalSets,
      totalVolumeKg: totalVolume,
      maxWeightKg: maxWeight,
    );
  }
}

class _Stats {
  final int sessionCount;
  final int totalSets;
  final double totalVolumeKg;
  final double? maxWeightKg;

  const _Stats({
    required this.sessionCount,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.maxWeightKg,
  });
}

class _SummaryGrid extends StatelessWidget {
  final _Stats stats;
  final List<Session> sessions;
  final WeightUnit weightUnit;
  const _SummaryGrid(
      {required this.stats,
      required this.sessions,
      required this.weightUnit});

  @override
  Widget build(BuildContext context) {
    final isPounds = weightUnit == WeightUnit.pounds;
    final unitLabel = isPounds ? 'lbs' : 'kg';
    // 1 kg = 2.20462 lbs
    final factor = isPounds ? 2.20462 : 1.0;
    final volume = stats.totalVolumeKg * factor;
    final maxW = (stats.maxWeightKg ?? 0) * factor;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          label: 'Workouts',
          value: '${stats.sessionCount}',
          icon: Icons.fitness_center,
        ),
        _StatCard(
          label: 'Total Sets',
          value: '${stats.totalSets}',
          icon: Icons.check_circle_outline,
        ),
        _StatCard(
          label: 'Total Volume',
          value: volume >= 1000
              ? '${(volume / 1000).toStringAsFixed(1)}k $unitLabel'
              : '${volume.toStringAsFixed(0)} $unitLabel',
          icon: Icons.bar_chart,
        ),
        _StatCard(
          label: 'Max Weight',
          value: stats.maxWeightKg != null
              ? '${maxW.toStringAsFixed(1)} $unitLabel'
              : '-',
          icon: Icons.emoji_events_outlined,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseChart extends StatelessWidget {
  final List<Session> sessions;
  final String exerciseName;
  final dynamic weightUnit;

  const _ExerciseChart({
    required this.sessions,
    required this.exerciseName,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    // Collect (date, maxWeight) pairs for this exercise
    final dataPoints = <({DateTime date, double weight})>[];
    for (final session in sessions) {
      for (final exercise in session.recordedExercises
          .whereType<RecordedWeightedExercise>()) {
        if (exercise.blueprint.name != exerciseName) continue;
        final completed = exercise.potentialSets.where((s) => s.completed);
        if (completed.isEmpty) continue;
        final maxKg = completed
            .map((s) => s.weight.toKilograms().value)
            .reduce((a, b) => a > b ? a : b);
        dataPoints.add((date: session.date, weight: maxKg));
      }
    }
    dataPoints.sort((a, b) => a.date.compareTo(b.date));

    if (dataPoints.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No data for this exercise yet.')),
        ),
      );
    }

    final minY = dataPoints.map((d) => d.weight).reduce((a, b) => a < b ? a : b);
    final maxY = dataPoints.map((d) => d.weight).reduce((a, b) => a > b ? a : b);
    final yPad = (maxY - minY) * 0.1 + 5;

    final spots = dataPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                'Max Weight (kg)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: (minY - yPad).clamp(0, double.infinity),
                  maxY: maxY + yPad,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: dataPoints.length <= 8,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= dataPoints.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('M/d').format(dataPoints[i].date),
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: dataPoints.length <= 20,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
