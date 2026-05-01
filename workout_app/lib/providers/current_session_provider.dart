import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/blueprint_models.dart';
import '../models/session_models.dart';
import '../models/weight.dart';
import '../services/storage_service.dart';
import 'history_provider.dart';

class CurrentSessionState {
  final Session? session;
  final bool isActive;

  const CurrentSessionState({this.session, this.isActive = false});

  CurrentSessionState copyWith({Session? session, bool? isActive}) {
    return CurrentSessionState(
      session: session ?? this.session,
      isActive: isActive ?? this.isActive,
    );
  }
}

class CurrentSessionNotifier extends Notifier<CurrentSessionState> {
  @override
  CurrentSessionState build() {
    // Restore any in-progress session on startup
    _tryRestoreSession();
    return const CurrentSessionState();
  }

  // Future<void> _tryRestoreSession() async {
  //   final data = await StorageService.instance.loadActiveSession();
  //   if (data == null) return;
  //   try {
  //     final session = Session.fromJson(data);
  //     state = CurrentSessionState(session: session, isActive: true);
  //   } catch (_) {
  //     await StorageService.instance.clearActiveSession();
  //   }
  // }
  Future<void> _tryRestoreSession() async {
    final data = await StorageService.instance.loadActiveSession();
    if (data == null) return;

    try {
      final session = Session.fromJson(
        data,
        data['id'] ?? 'active_session', // fallback ID
      );

      state = CurrentSessionState(session: session, isActive: true);
    } catch (_) {
      await StorageService.instance.clearActiveSession();
    }
  }

  Future<void> _persist() async {
    final s = state.session;
    if (s != null) {
      await StorageService.instance.saveActiveSession(s.toJson());
    } else {
      await StorageService.instance.clearActiveSession();
    }
  }

  /// Build a map of exercise name -> last recorded weighted exercise
  Map<String, RecordedWeightedExercise> _buildLatestExerciseMap(
      List<Session> history) {
    final map = <String, RecordedWeightedExercise>{};
    // history is newest-first; iterate so older sessions don't overwrite newer
    for (final session in history.reversed) {
      for (final ex
          in session.recordedExercises.whereType<RecordedWeightedExercise>()) {
        map[ex.blueprint.name] = ex;
      }
    }
    return map;
  }

  bool _isSuccessfulSession(RecordedWeightedExercise ex) {
    final completed = ex.potentialSets.where((s) => s.completed).toList();
    if (completed.isEmpty) return false;
    // Success = every set completed with at least the blueprint target reps
    return completed.length >= ex.blueprint.sets &&
        completed.every((s) => (s.reps ?? 0) >= ex.blueprint.reps);
  }

  void startSession(SessionBlueprint blueprint, WeightUnit weightUnit,
      {List<Session> history = const []}) {
    final latestExercises = _buildLatestExerciseMap(history);

    final exercises = blueprint.exercises.map<RecordedExercise>((exercise) {
      return switch (exercise) {
        WeightedExerciseBlueprint e => () {
            final last = latestExercises[e.name];
            Weight baseWeight;
            if (last == null) {
              baseWeight = e.initialWeight.convertTo(weightUnit);
            } else if (_isSuccessfulSession(last)) {
              // Progressive overload: add increment
              final increaseKg = e.weightIncreaseOnSuccess;
              final lastWeightKg = last.potentialSets.isNotEmpty
                  ? last.potentialSets.last.weight.toKilograms().value
                  : e.initialWeight.toKilograms().value;
              baseWeight = Weight(
                value: lastWeightKg + increaseKg,
                unit: WeightUnit.kilograms,
              ).convertTo(weightUnit);
            } else {
              // Keep same weight
              baseWeight = last.potentialSets.isNotEmpty
                  ? last.potentialSets.last.weight.convertTo(weightUnit)
                  : e.initialWeight.convertTo(weightUnit);
            }
            return RecordedWeightedExercise(
              blueprint: e,
              potentialSets: List.generate(
                e.sets,
                (_) => PotentialSet(reps: e.reps, weight: baseWeight),
              ),
            );
          }(),
        CardioExerciseBlueprint e => RecordedCardioExercise(
            blueprint: e,
            recordedSets: const [CardioExerciseRecordedSet()],
          ),
      };
    }).toList();

    final session = Session(
      id: const Uuid().v4(),
      blueprint: blueprint,
      recordedExercises: exercises,
      date: DateTime.now(),
      startTime: DateTime.now(),
    );

    state = CurrentSessionState(session: session, isActive: true);
    unawaited(_persist());
  }

  void _updateExercise(int exerciseIndex, RecordedExercise updated) {
    final session = state.session;
    if (session == null) return;
    final exercises = List<RecordedExercise>.from(session.recordedExercises);
    exercises[exerciseIndex] = updated;
    state =
        state.copyWith(session: session.copyWith(recordedExercises: exercises));
    unawaited(_persist());
  }

  void toggleSetCompleted(int exerciseIndex, int setIndex) {
    final exercise = state.session?.recordedExercises[exerciseIndex];
    if (exercise is! RecordedWeightedExercise) return;
    final sets = List<PotentialSet>.from(exercise.potentialSets);
    sets[setIndex] =
        sets[setIndex].copyWith(completed: !sets[setIndex].completed);
    _updateExercise(exerciseIndex, exercise.copyWith(potentialSets: sets));
  }

  void updateSetReps(int exerciseIndex, int setIndex, int reps) {
    final exercise = state.session?.recordedExercises[exerciseIndex];
    if (exercise is! RecordedWeightedExercise) return;
    final sets = List<PotentialSet>.from(exercise.potentialSets);
    sets[setIndex] = sets[setIndex].copyWith(reps: reps);
    _updateExercise(exerciseIndex, exercise.copyWith(potentialSets: sets));
  }

  void updateSetWeight(int exerciseIndex, int setIndex, Weight weight) {
    final exercise = state.session?.recordedExercises[exerciseIndex];
    if (exercise is! RecordedWeightedExercise) return;
    final sets = List<PotentialSet>.from(exercise.potentialSets);
    sets[setIndex] = sets[setIndex].copyWith(weight: weight);
    _updateExercise(exerciseIndex, exercise.copyWith(potentialSets: sets));
  }

  void addSet(int exerciseIndex) {
    final exercise = state.session?.recordedExercises[exerciseIndex];
    if (exercise is! RecordedWeightedExercise) return;
    final lastSet = exercise.potentialSets.isNotEmpty
        ? exercise.potentialSets.last
        : PotentialSet(
            reps: exercise.blueprint.reps,
            weight: exercise.blueprint.initialWeight,
          );
    final sets = [
      ...exercise.potentialSets,
      PotentialSet(reps: lastSet.reps, weight: lastSet.weight),
    ];
    _updateExercise(exerciseIndex, exercise.copyWith(potentialSets: sets));
  }

  void removeSet(int exerciseIndex, int setIndex) {
    final exercise = state.session?.recordedExercises[exerciseIndex];
    if (exercise is! RecordedWeightedExercise) return;
    final sets = List<PotentialSet>.from(exercise.potentialSets)
      ..removeAt(setIndex);
    _updateExercise(exerciseIndex, exercise.copyWith(potentialSets: sets));
  }

  void updateExerciseNotes(int exerciseIndex, String notes) {
    final exercise = state.session?.recordedExercises[exerciseIndex];
    if (exercise == null) return;
    switch (exercise) {
      case RecordedWeightedExercise e:
        _updateExercise(exerciseIndex, e.copyWith(notes: notes));
      case RecordedCardioExercise e:
        _updateExercise(exerciseIndex, e.copyWith(notes: notes));
    }
  }

  void updateBodyweight(Weight? bodyweight) {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(
      session: bodyweight == null
          ? session.copyWith(clearBodyweight: true)
          : session.copyWith(bodyweight: bodyweight),
    );
    unawaited(_persist());
  }

  void updateCardioSet(
      int exerciseIndex, int setIndex, CardioExerciseRecordedSet updated) {
    final exercise = state.session?.recordedExercises[exerciseIndex];
    if (exercise is! RecordedCardioExercise) return;
    final sets = List<CardioExerciseRecordedSet>.from(exercise.recordedSets);
    sets[setIndex] = updated;
    _updateExercise(exerciseIndex, exercise.copyWith(recordedSets: sets));
  }

  Future<void> saveSession() async {
    final session = state.session;
    if (session == null) return;
    final completed = session.copyWith(endTime: DateTime.now());
    await ref.read(historyProvider.notifier).addSession(completed);
    state = const CurrentSessionState();
    await StorageService.instance.clearActiveSession();
  }

  void discardSession() {
    state = const CurrentSessionState();
    unawaited(StorageService.instance.clearActiveSession());
  }
}

final currentSessionProvider =
    NotifierProvider<CurrentSessionNotifier, CurrentSessionState>(
        CurrentSessionNotifier.new);
