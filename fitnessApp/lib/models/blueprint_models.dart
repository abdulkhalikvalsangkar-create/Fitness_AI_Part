import 'weight.dart';

// Sealed base — subclasses must be in this file.
// Access name/notes via pattern matching or the extension below.
sealed class ExerciseBlueprint {
  const ExerciseBlueprint();

  static ExerciseBlueprint fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'cardio') {
      return CardioExerciseBlueprint.fromJson(json);
    }
    return WeightedExerciseBlueprint.fromJson(json);
  }

  Map<String, dynamic> toJson();
}

extension ExerciseBlueprintX on ExerciseBlueprint {
  String get name => switch (this) {
    WeightedExerciseBlueprint e => e.name,
    CardioExerciseBlueprint e => e.name,
  };

  String get notes => switch (this) {
    WeightedExerciseBlueprint e => e.notes,
    CardioExerciseBlueprint e => e.notes,
  };

  bool get isWeighted => this is WeightedExerciseBlueprint;
  bool get isCardio => this is CardioExerciseBlueprint;
}

// ---------------------------------------------------------------------------

class WeightedExerciseBlueprint extends ExerciseBlueprint {
  final String name;
  final int sets;
  final int reps;
  final Duration restDuration;
  final String notes;
  final String link;
  final Weight initialWeight;

  /// kg added to weight after a successful session (all sets completed)
  final double weightIncreaseOnSuccess;

  const WeightedExerciseBlueprint({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.restDuration = const Duration(seconds: 90),
    this.notes = '',
    this.link = '',
    this.initialWeight = const Weight(value: 20, unit: WeightUnit.kilograms),
    this.weightIncreaseOnSuccess = 2.5,
  }) : super();

  WeightedExerciseBlueprint copyWith({
    String? name,
    int? sets,
    int? reps,
    Duration? restDuration,
    String? notes,
    String? link,
    Weight? initialWeight,
    double? weightIncreaseOnSuccess,
  }) {
    return WeightedExerciseBlueprint(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restDuration: restDuration ?? this.restDuration,
      notes: notes ?? this.notes,
      link: link ?? this.link,
      initialWeight: initialWeight ?? this.initialWeight,
      weightIncreaseOnSuccess:
          weightIncreaseOnSuccess ?? this.weightIncreaseOnSuccess,
    );
  }

  factory WeightedExerciseBlueprint.fromJson(Map<String, dynamic> json) {
    return WeightedExerciseBlueprint(
      name: json['name'] as String,
      sets: json['sets'] as int? ?? 3,
      reps: json['reps'] as int? ?? 10,
      restDuration: Duration(
        seconds: json['restDurationSeconds'] as int? ?? 90,
      ),
      notes: json['notes'] as String? ?? '',
      link: json['link'] as String? ?? '',
      initialWeight: json['initialWeight'] != null
          ? Weight.fromJson(json['initialWeight'] as Map<String, dynamic>)
          : const Weight(value: 20, unit: WeightUnit.kilograms),
      weightIncreaseOnSuccess:
          (json['weightIncreaseOnSuccess'] as num?)?.toDouble() ?? 2.5,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'weighted',
    'name': name,
    'sets': sets,
    'reps': reps,
    'restDurationSeconds': restDuration.inSeconds,
    'notes': notes,
    'link': link,
    'initialWeight': initialWeight.toJson(),
    'weightIncreaseOnSuccess': weightIncreaseOnSuccess,
  };
}

// ---------------------------------------------------------------------------

class CardioExerciseBlueprint extends ExerciseBlueprint {
  final String name;
  final String notes;
  final String link;
  final bool trackDuration;
  final bool trackDistance;
  final bool trackResistance;
  final bool trackIncline;

  const CardioExerciseBlueprint({
    required this.name,
    this.notes = '',
    this.link = '',
    this.trackDuration = true,
    this.trackDistance = false,
    this.trackResistance = false,
    this.trackIncline = false,
  }) : super();

  CardioExerciseBlueprint copyWith({
    String? name,
    String? notes,
    String? link,
    bool? trackDuration,
    bool? trackDistance,
    bool? trackResistance,
    bool? trackIncline,
  }) {
    return CardioExerciseBlueprint(
      name: name ?? this.name,
      notes: notes ?? this.notes,
      link: link ?? this.link,
      trackDuration: trackDuration ?? this.trackDuration,
      trackDistance: trackDistance ?? this.trackDistance,
      trackResistance: trackResistance ?? this.trackResistance,
      trackIncline: trackIncline ?? this.trackIncline,
    );
  }

  factory CardioExerciseBlueprint.fromJson(Map<String, dynamic> json) {
    return CardioExerciseBlueprint(
      name: json['name'] as String,
      notes: json['notes'] as String? ?? '',
      link: json['link'] as String? ?? '',
      trackDuration: json['trackDuration'] as bool? ?? true,
      trackDistance: json['trackDistance'] as bool? ?? false,
      trackResistance: json['trackResistance'] as bool? ?? false,
      trackIncline: json['trackIncline'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'cardio',
    'name': name,
    'notes': notes,
    'link': link,
    'trackDuration': trackDuration,
    'trackDistance': trackDistance,
    'trackResistance': trackResistance,
    'trackIncline': trackIncline,
  };
}

// ---------------------------------------------------------------------------

class SessionBlueprint {
  final String name;
  final List<ExerciseBlueprint> exercises;
  final String notes;

  const SessionBlueprint({
    required this.name,
    this.exercises = const [],
    this.notes = '',
  });

  SessionBlueprint copyWith({
    String? name,
    List<ExerciseBlueprint>? exercises,
    String? notes,
  }) {
    return SessionBlueprint(
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }

  factory SessionBlueprint.fromJson(Map<String, dynamic> json) {
    return SessionBlueprint(
      name: json['name'] as String,
      notes: json['notes'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => ExerciseBlueprint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'notes': notes,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}

// ---------------------------------------------------------------------------

class ProgramBlueprint {
  final String id;
  final String name;
  final List<SessionBlueprint> sessions;
  final DateTime lastEdited;

  const ProgramBlueprint({
    required this.id,
    required this.name,
    this.sessions = const [],
    required this.lastEdited,
  });

  ProgramBlueprint copyWith({
    String? id,
    String? name,
    List<SessionBlueprint>? sessions,
    DateTime? lastEdited,
  }) {
    return ProgramBlueprint(
      id: id ?? this.id,
      name: name ?? this.name,
      sessions: sessions ?? this.sessions,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }

  factory ProgramBlueprint.fromJson(Map<String, dynamic> json) {
    return ProgramBlueprint(
      id: json['id'] as String,
      name: json['name'] as String,
      lastEdited: DateTime.parse(json['lastEdited'] as String),
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((s) => SessionBlueprint.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lastEdited': lastEdited.toIso8601String(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };
}
