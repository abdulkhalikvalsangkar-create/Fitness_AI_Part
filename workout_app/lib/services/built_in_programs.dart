import '../models/blueprint_models.dart';
import '../models/weight.dart';

final List<ProgramBlueprint> builtInPrograms = [
  ProgramBlueprint(
    id: 'stronglifts-5x5',
    name: 'StrongLifts 5×5',
    lastEdited: DateTime(2024, 1, 1),
    sessions: [
      SessionBlueprint(
        name: 'Workout A',
        exercises: [
          WeightedExerciseBlueprint(
            name: 'Squat',
            sets: 5,
            reps: 5,
            restDuration: const Duration(minutes: 3),
            initialWeight: const Weight(value: 20, unit: WeightUnit.kilograms),
          ),
          WeightedExerciseBlueprint(
            name: 'Bench Press',
            sets: 5,
            reps: 5,
            restDuration: const Duration(minutes: 3),
            initialWeight: const Weight(value: 20, unit: WeightUnit.kilograms),
          ),
          WeightedExerciseBlueprint(
            name: 'Barbell Row',
            sets: 5,
            reps: 5,
            restDuration: const Duration(minutes: 3),
            initialWeight: const Weight(value: 20, unit: WeightUnit.kilograms),
          ),
        ],
      ),
      SessionBlueprint(
        name: 'Workout B',
        exercises: [
          WeightedExerciseBlueprint(
            name: 'Squat',
            sets: 5,
            reps: 5,
            restDuration: const Duration(minutes: 3),
            initialWeight: const Weight(value: 20, unit: WeightUnit.kilograms),
          ),
          WeightedExerciseBlueprint(
            name: 'Overhead Press',
            sets: 5,
            reps: 5,
            restDuration: const Duration(minutes: 3),
            initialWeight: const Weight(value: 20, unit: WeightUnit.kilograms),
          ),
          WeightedExerciseBlueprint(
            name: 'Deadlift',
            sets: 1,
            reps: 5,
            restDuration: const Duration(minutes: 5),
            initialWeight: const Weight(value: 40, unit: WeightUnit.kilograms),
          ),
        ],
      ),
    ],
  ),
  ProgramBlueprint(
    id: 'ppl',
    name: 'Push Pull Legs',
    lastEdited: DateTime(2024, 1, 1),
    sessions: [
      SessionBlueprint(
        name: 'Push Day',
        exercises: [
          WeightedExerciseBlueprint(name: 'Bench Press', sets: 4, reps: 8),
          WeightedExerciseBlueprint(
              name: 'Overhead Press', sets: 3, reps: 10),
          WeightedExerciseBlueprint(
              name: 'Incline Dumbbell Press', sets: 3, reps: 12),
          WeightedExerciseBlueprint(
              name: 'Lateral Raises', sets: 3, reps: 15),
          WeightedExerciseBlueprint(
              name: 'Tricep Pushdowns', sets: 3, reps: 12),
        ],
      ),
      SessionBlueprint(
        name: 'Pull Day',
        exercises: [
          WeightedExerciseBlueprint(
              name: 'Deadlift',
              sets: 3,
              reps: 5,
              initialWeight:
                  const Weight(value: 40, unit: WeightUnit.kilograms)),
          WeightedExerciseBlueprint(
              name: 'Pull-ups',
              sets: 3,
              reps: 8,
              initialWeight: const Weight(value: 0, unit: WeightUnit.kilograms)),
          WeightedExerciseBlueprint(name: 'Barbell Row', sets: 4, reps: 8),
          WeightedExerciseBlueprint(name: 'Face Pulls', sets: 3, reps: 15),
          WeightedExerciseBlueprint(name: 'Bicep Curls', sets: 3, reps: 12),
        ],
      ),
      SessionBlueprint(
        name: 'Legs Day',
        exercises: [
          WeightedExerciseBlueprint(name: 'Squat', sets: 4, reps: 8),
          WeightedExerciseBlueprint(
              name: 'Romanian Deadlift', sets: 3, reps: 10),
          WeightedExerciseBlueprint(name: 'Leg Press', sets: 3, reps: 12),
          WeightedExerciseBlueprint(name: 'Leg Curl', sets: 3, reps: 12),
          WeightedExerciseBlueprint(name: 'Calf Raises', sets: 4, reps: 20),
        ],
      ),
    ],
  ),
  ProgramBlueprint(
    id: '5-3-1',
    name: '5/3/1 (Wendler)',
    lastEdited: DateTime(2024, 1, 1),
    sessions: [
      SessionBlueprint(
        name: 'Squat Day',
        exercises: [
          WeightedExerciseBlueprint(
              name: 'Squat',
              sets: 3,
              reps: 5,
              restDuration: const Duration(minutes: 4),
              initialWeight:
                  const Weight(value: 60, unit: WeightUnit.kilograms)),
          WeightedExerciseBlueprint(
              name: 'Romanian Deadlift', sets: 3, reps: 10),
          WeightedExerciseBlueprint(name: 'Leg Press', sets: 3, reps: 15),
        ],
      ),
      SessionBlueprint(
        name: 'Bench Day',
        exercises: [
          WeightedExerciseBlueprint(
              name: 'Bench Press',
              sets: 3,
              reps: 5,
              restDuration: const Duration(minutes: 4)),
          WeightedExerciseBlueprint(name: 'Dumbbell Row', sets: 3, reps: 10),
          WeightedExerciseBlueprint(
              name: 'Tricep Extensions', sets: 3, reps: 15),
        ],
      ),
      SessionBlueprint(
        name: 'Deadlift Day',
        exercises: [
          WeightedExerciseBlueprint(
              name: 'Deadlift',
              sets: 3,
              reps: 5,
              restDuration: const Duration(minutes: 5),
              initialWeight:
                  const Weight(value: 80, unit: WeightUnit.kilograms)),
          WeightedExerciseBlueprint(name: 'Leg Curl', sets: 3, reps: 10),
          WeightedExerciseBlueprint(name: 'Calf Raises', sets: 4, reps: 20),
        ],
      ),
      SessionBlueprint(
        name: 'Press Day',
        exercises: [
          WeightedExerciseBlueprint(
              name: 'Overhead Press',
              sets: 3,
              reps: 5,
              restDuration: const Duration(minutes: 4),
              initialWeight:
                  const Weight(value: 40, unit: WeightUnit.kilograms)),
          WeightedExerciseBlueprint(name: 'Pull-ups', sets: 3, reps: 8,
              initialWeight: const Weight(value: 0, unit: WeightUnit.kilograms)),
          WeightedExerciseBlueprint(name: 'Bicep Curls', sets: 3, reps: 12),
        ],
      ),
    ],
  ),
  ProgramBlueprint(
    id: 'full-body-3day',
    name: 'Full Body 3-Day',
    lastEdited: DateTime(2024, 1, 1),
    sessions: [
      SessionBlueprint(
        name: 'Day A',
        exercises: [
          WeightedExerciseBlueprint(name: 'Squat', sets: 3, reps: 8),
          WeightedExerciseBlueprint(name: 'Bench Press', sets: 3, reps: 8),
          WeightedExerciseBlueprint(name: 'Barbell Row', sets: 3, reps: 8),
          WeightedExerciseBlueprint(name: 'Overhead Press', sets: 2, reps: 10),
          WeightedExerciseBlueprint(name: 'Bicep Curls', sets: 2, reps: 12),
        ],
      ),
      SessionBlueprint(
        name: 'Day B',
        exercises: [
          WeightedExerciseBlueprint(name: 'Deadlift', sets: 3, reps: 5,
              initialWeight: const Weight(value: 60, unit: WeightUnit.kilograms)),
          WeightedExerciseBlueprint(name: 'Incline Press', sets: 3, reps: 8),
          WeightedExerciseBlueprint(name: 'Pull-ups', sets: 3, reps: 6,
              initialWeight: const Weight(value: 0, unit: WeightUnit.kilograms)),
          WeightedExerciseBlueprint(name: 'Lateral Raises', sets: 3, reps: 15),
          WeightedExerciseBlueprint(name: 'Tricep Dips', sets: 2, reps: 12,
              initialWeight: const Weight(value: 0, unit: WeightUnit.kilograms)),
        ],
      ),
    ],
  ),
];
