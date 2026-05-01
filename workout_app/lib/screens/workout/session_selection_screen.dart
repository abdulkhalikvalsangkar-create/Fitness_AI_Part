import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/blueprint_models.dart';
import '../../providers/current_session_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/programs_provider.dart';
import '../../providers/settings_provider.dart';

class SessionSelectionScreen extends ConsumerWidget {
  const SessionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final programsAsync = ref.watch(programsProvider);
    final currentSession = ref.watch(currentSessionProvider);

    // If there's an active session, redirect to it
    if (currentSession.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/workout/active');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        centerTitle: false,
      ),
      body: programsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (programs) {
          final activeProgram = settings.activeProgramId != null
              ? programs.cast<ProgramBlueprint?>().firstWhere(
                    (p) => p?.id == settings.activeProgramId,
                    orElse: () => null,
                  )
              : null;

          if (activeProgram == null) {
            return _NoProgram(onGoToSettings: () => context.go('/settings'));
          }

          return _ProgramView(program: activeProgram);
        },
      ),
    );
  }
}

class _NoProgram extends StatelessWidget {
  final VoidCallback onGoToSettings;
  const _NoProgram({required this.onGoToSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              'No active program',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a program in Settings to get started.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGoToSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramView extends ConsumerWidget {
  final ProgramBlueprint program;
  const _ProgramView({required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Program',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      program.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Sessions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...program.sessions.map((session) {
          return _SessionCard(
            session: session,
            onStart: () {
              final history = ref.read(historyProvider).value ?? [];
              ref.read(currentSessionProvider.notifier).startSession(
                    session,
                    settings.weightUnit,
                    history: history,
                  );
              context.go('/workout/active');
            },
          );
        }),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionBlueprint session;
  final VoidCallback onStart;

  const _SessionCard({required this.session, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weightedCount =
        session.exercises.whereType<WeightedExerciseBlueprint>().length;
    final cardioCount =
        session.exercises.whereType<CardioExerciseBlueprint>().length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton(
                  onPressed: onStart,
                  child: const Text('Start'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (weightedCount > 0)
                  Chip(
                    label: Text('$weightedCount weighted'),
                    avatar: const Icon(Icons.fitness_center, size: 16),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                if (cardioCount > 0)
                  Chip(
                    label: Text('$cardioCount cardio'),
                    avatar: const Icon(Icons.directions_run, size: 16),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (session.exercises.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...session.exercises.take(4).map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          e.isWeighted
                              ? Icons.fitness_center
                              : Icons.directions_run,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          e.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        if (e is WeightedExerciseBlueprint)
                          Text(
                            ' · ${e.sets}×${e.reps}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                      ],
                    ),
                  )),
              if (session.exercises.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${session.exercises.length - 4} more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
