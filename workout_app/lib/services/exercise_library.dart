import '../models/blueprint_models.dart';
import '../models/weight.dart';

class ExerciseTemplate {
  final String name;
  final String category;
  final int defaultSets;
  final int defaultReps;
  final int defaultRestSeconds;
  final double defaultWeightKg;
  final bool isCardio;

  const ExerciseTemplate({
    required this.name,
    required this.category,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultRestSeconds = 90,
    this.defaultWeightKg = 20,
    this.isCardio = false,
  });

  WeightedExerciseBlueprint toWeightedBlueprint(WeightUnit unit) {
    return WeightedExerciseBlueprint(
      name: name,
      sets: defaultSets,
      reps: defaultReps,
      restDuration: Duration(seconds: defaultRestSeconds),
      initialWeight: Weight(value: defaultWeightKg, unit: WeightUnit.kilograms)
          .convertTo(unit),
    );
  }

  CardioExerciseBlueprint toCardioBlueprint() {
    return CardioExerciseBlueprint(
      name: name,
      trackDuration: true,
      trackDistance: name == 'Treadmill' ||
          name == 'Rowing Machine' ||
          name == 'Cycling' ||
          name == 'Running',
      trackResistance:
          name == 'Stationary Bike' || name == 'Elliptical' || name == 'Rowing Machine',
      trackIncline: name == 'Treadmill',
    );
  }
}

const List<ExerciseTemplate> exerciseLibrary = [
  // ── Chest ────────────────────────────────────────────────────────────────
  ExerciseTemplate(name: 'Bench Press', category: 'Chest', defaultSets: 4, defaultReps: 8, defaultRestSeconds: 180, defaultWeightKg: 60),
  ExerciseTemplate(name: 'Incline Bench Press', category: 'Chest', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 150, defaultWeightKg: 50),
  ExerciseTemplate(name: 'Decline Bench Press', category: 'Chest', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 150, defaultWeightKg: 55),
  ExerciseTemplate(name: 'Dumbbell Bench Press', category: 'Chest', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 120, defaultWeightKg: 24),
  ExerciseTemplate(name: 'Incline Dumbbell Press', category: 'Chest', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 120, defaultWeightKg: 20),
  ExerciseTemplate(name: 'Dumbbell Fly', category: 'Chest', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 14),
  ExerciseTemplate(name: 'Cable Fly', category: 'Chest', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 10),
  ExerciseTemplate(name: 'Push-ups', category: 'Chest', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Chest Dips', category: 'Chest', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 120, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Machine Chest Press', category: 'Chest', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 50),
  ExerciseTemplate(name: 'Pec Deck', category: 'Chest', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 40),

  // ── Back ─────────────────────────────────────────────────────────────────
  ExerciseTemplate(name: 'Deadlift', category: 'Back', defaultSets: 3, defaultReps: 5, defaultRestSeconds: 300, defaultWeightKg: 80),
  ExerciseTemplate(name: 'Barbell Row', category: 'Back', defaultSets: 4, defaultReps: 8, defaultRestSeconds: 180, defaultWeightKg: 60),
  ExerciseTemplate(name: 'Dumbbell Row', category: 'Back', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90, defaultWeightKg: 28),
  ExerciseTemplate(name: 'Pull-ups', category: 'Back', defaultSets: 3, defaultReps: 8, defaultRestSeconds: 120, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Chin-ups', category: 'Back', defaultSets: 3, defaultReps: 8, defaultRestSeconds: 120, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Lat Pulldown', category: 'Back', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 50),
  ExerciseTemplate(name: 'Seated Cable Row', category: 'Back', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 50),
  ExerciseTemplate(name: 'T-Bar Row', category: 'Back', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 150, defaultWeightKg: 40),
  ExerciseTemplate(name: 'Face Pulls', category: 'Back', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 15),
  ExerciseTemplate(name: 'Hyperextension', category: 'Back', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Rack Pull', category: 'Back', defaultSets: 3, defaultReps: 5, defaultRestSeconds: 240, defaultWeightKg: 100),

  // ── Shoulders ─────────────────────────────────────────────────────────────
  ExerciseTemplate(name: 'Overhead Press', category: 'Shoulders', defaultSets: 4, defaultReps: 8, defaultRestSeconds: 180, defaultWeightKg: 40),
  ExerciseTemplate(name: 'Dumbbell Shoulder Press', category: 'Shoulders', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 120, defaultWeightKg: 18),
  ExerciseTemplate(name: 'Arnold Press', category: 'Shoulders', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 16),
  ExerciseTemplate(name: 'Lateral Raises', category: 'Shoulders', defaultSets: 4, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 8),
  ExerciseTemplate(name: 'Front Raises', category: 'Shoulders', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60, defaultWeightKg: 8),
  ExerciseTemplate(name: 'Rear Delt Fly', category: 'Shoulders', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 6),
  ExerciseTemplate(name: 'Upright Row', category: 'Shoulders', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 30),
  ExerciseTemplate(name: 'Shrugs', category: 'Shoulders', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 40),
  ExerciseTemplate(name: 'Machine Shoulder Press', category: 'Shoulders', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 40),

  // ── Arms — Biceps ─────────────────────────────────────────────────────────
  ExerciseTemplate(name: 'Bicep Curls', category: 'Biceps', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60, defaultWeightKg: 14),
  ExerciseTemplate(name: 'Hammer Curls', category: 'Biceps', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60, defaultWeightKg: 14),
  ExerciseTemplate(name: 'Barbell Curl', category: 'Biceps', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90, defaultWeightKg: 30),
  ExerciseTemplate(name: 'Preacher Curl', category: 'Biceps', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 20),
  ExerciseTemplate(name: 'Cable Curl', category: 'Biceps', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 15),
  ExerciseTemplate(name: 'Concentration Curl', category: 'Biceps', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60, defaultWeightKg: 10),
  ExerciseTemplate(name: 'Incline Dumbbell Curl', category: 'Biceps', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60, defaultWeightKg: 10),

  // ── Arms — Triceps ────────────────────────────────────────────────────────
  ExerciseTemplate(name: 'Tricep Pushdowns', category: 'Triceps', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60, defaultWeightKg: 20),
  ExerciseTemplate(name: 'Skull Crushers', category: 'Triceps', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 25),
  ExerciseTemplate(name: 'Tricep Dips', category: 'Triceps', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Overhead Tricep Extension', category: 'Triceps', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60, defaultWeightKg: 20),
  ExerciseTemplate(name: 'Close-Grip Bench Press', category: 'Triceps', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 120, defaultWeightKg: 50),
  ExerciseTemplate(name: 'Rope Pushdown', category: 'Triceps', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 18),
  ExerciseTemplate(name: 'Diamond Push-ups', category: 'Triceps', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 0),

  // ── Legs ──────────────────────────────────────────────────────────────────
  ExerciseTemplate(name: 'Squat', category: 'Legs', defaultSets: 4, defaultReps: 8, defaultRestSeconds: 240, defaultWeightKg: 60),
  ExerciseTemplate(name: 'Front Squat', category: 'Legs', defaultSets: 3, defaultReps: 8, defaultRestSeconds: 180, defaultWeightKg: 50),
  ExerciseTemplate(name: 'Romanian Deadlift', category: 'Legs', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 150, defaultWeightKg: 60),
  ExerciseTemplate(name: 'Leg Press', category: 'Legs', defaultSets: 4, defaultReps: 12, defaultRestSeconds: 120, defaultWeightKg: 100),
  ExerciseTemplate(name: 'Leg Extension', category: 'Legs', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 40),
  ExerciseTemplate(name: 'Leg Curl', category: 'Legs', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 35),
  ExerciseTemplate(name: 'Calf Raises', category: 'Legs', defaultSets: 4, defaultReps: 20, defaultRestSeconds: 60, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Seated Calf Raises', category: 'Legs', defaultSets: 4, defaultReps: 20, defaultRestSeconds: 60, defaultWeightKg: 20),
  ExerciseTemplate(name: 'Lunges', category: 'Legs', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 20),
  ExerciseTemplate(name: 'Bulgarian Split Squat', category: 'Legs', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 120, defaultWeightKg: 20),
  ExerciseTemplate(name: 'Hip Thrust', category: 'Legs', defaultSets: 4, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 60),
  ExerciseTemplate(name: 'Good Morning', category: 'Legs', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90, defaultWeightKg: 30),
  ExerciseTemplate(name: 'Hack Squat', category: 'Legs', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 150, defaultWeightKg: 80),
  ExerciseTemplate(name: 'Goblet Squat', category: 'Legs', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 90, defaultWeightKg: 24),
  ExerciseTemplate(name: 'Step-ups', category: 'Legs', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60, defaultWeightKg: 0),

  // ── Core ──────────────────────────────────────────────────────────────────
  ExerciseTemplate(name: 'Plank', category: 'Core', defaultSets: 3, defaultReps: 1, defaultRestSeconds: 60, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Crunches', category: 'Core', defaultSets: 3, defaultReps: 20, defaultRestSeconds: 45, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Sit-ups', category: 'Core', defaultSets: 3, defaultReps: 20, defaultRestSeconds: 45, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Russian Twists', category: 'Core', defaultSets: 3, defaultReps: 20, defaultRestSeconds: 45, defaultWeightKg: 5),
  ExerciseTemplate(name: 'Cable Crunch', category: 'Core', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60, defaultWeightKg: 20),
  ExerciseTemplate(name: 'Ab Wheel Rollout', category: 'Core', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Leg Raises', category: 'Core', defaultSets: 3, defaultReps: 15, defaultRestSeconds: 45, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Hanging Knee Raises', category: 'Core', defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Dead Bug', category: 'Core', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 45, defaultWeightKg: 0),
  ExerciseTemplate(name: 'Bird Dog', category: 'Core', defaultSets: 3, defaultReps: 10, defaultRestSeconds: 45, defaultWeightKg: 0),

  // ── Cardio ────────────────────────────────────────────────────────────────
  ExerciseTemplate(name: 'Treadmill', category: 'Cardio', defaultSets: 1, defaultReps: 1, defaultRestSeconds: 0, defaultWeightKg: 0, isCardio: true),
  ExerciseTemplate(name: 'Stationary Bike', category: 'Cardio', defaultSets: 1, defaultReps: 1, defaultRestSeconds: 0, defaultWeightKg: 0, isCardio: true),
  ExerciseTemplate(name: 'Rowing Machine', category: 'Cardio', defaultSets: 1, defaultReps: 1, defaultRestSeconds: 0, defaultWeightKg: 0, isCardio: true),
  ExerciseTemplate(name: 'Elliptical', category: 'Cardio', defaultSets: 1, defaultReps: 1, defaultRestSeconds: 0, defaultWeightKg: 0, isCardio: true),
  ExerciseTemplate(name: 'Cycling', category: 'Cardio', defaultSets: 1, defaultReps: 1, defaultRestSeconds: 0, defaultWeightKg: 0, isCardio: true),
  ExerciseTemplate(name: 'Running', category: 'Cardio', defaultSets: 1, defaultReps: 1, defaultRestSeconds: 0, defaultWeightKg: 0, isCardio: true),
  ExerciseTemplate(name: 'Jump Rope', category: 'Cardio', defaultSets: 3, defaultReps: 1, defaultRestSeconds: 60, defaultWeightKg: 0, isCardio: true),
  ExerciseTemplate(name: 'Stair Climber', category: 'Cardio', defaultSets: 1, defaultReps: 1, defaultRestSeconds: 0, defaultWeightKg: 0, isCardio: true),
  ExerciseTemplate(name: 'Swimming', category: 'Cardio', defaultSets: 1, defaultReps: 1, defaultRestSeconds: 0, defaultWeightKg: 0, isCardio: true),
];

/// All unique category names in the library.
List<String> get exerciseCategories =>
    exerciseLibrary.map((e) => e.category).toSet().toList();

/// Search exercises by name (case-insensitive).
List<ExerciseTemplate> searchExercises(String query) {
  if (query.trim().isEmpty) return exerciseLibrary;
  final lower = query.toLowerCase();
  return exerciseLibrary
      .where((e) => e.name.toLowerCase().contains(lower) ||
          e.category.toLowerCase().contains(lower))
      .toList();
}

/// Filter exercises by category. Null returns all.
List<ExerciseTemplate> filterByCategory(String? category) {
  if (category == null) return exerciseLibrary;
  return exerciseLibrary.where((e) => e.category == category).toList();
}
