import 'weight.dart';
import 'blueprint_models.dart';

class PotentialSet {
  final int? reps;
  final Weight weight;
  final bool completed;

  const PotentialSet({
    this.reps,
    required this.weight,
    this.completed = false,
  });

  PotentialSet copyWith({int? reps, Weight? weight, bool? completed}) {
    return PotentialSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      completed: completed ?? this.completed,
    );
  }

  factory PotentialSet.fromJson(Map<String, dynamic> json) {
    return PotentialSet(
      reps: json['reps'] as int?,
      weight: Weight.fromJson(json['weight'] as Map<String, dynamic>),
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weight': weight.toJson(),
        'completed': completed,
      };
}

// ---------------------------------------------------------------------------

class CardioExerciseRecordedSet {
  final Duration? duration;
  final double? distanceKm;
  final int? resistanceLevel;
  final double? inclinePercent;

  const CardioExerciseRecordedSet({
    this.duration,
    this.distanceKm,
    this.resistanceLevel,
    this.inclinePercent,
  });

  CardioExerciseRecordedSet copyWith({
    Duration? duration,
    double? distanceKm,
    int? resistanceLevel,
    double? inclinePercent,
  }) {
    return CardioExerciseRecordedSet(
      duration: duration ?? this.duration,
      distanceKm: distanceKm ?? this.distanceKm,
      resistanceLevel: resistanceLevel ?? this.resistanceLevel,
      inclinePercent: inclinePercent ?? this.inclinePercent,
    );
  }

  factory CardioExerciseRecordedSet.fromJson(Map<String, dynamic> json) {
    return CardioExerciseRecordedSet(
      duration: json['durationSeconds'] != null
          ? Duration(seconds: json['durationSeconds'] as int)
          : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      resistanceLevel: json['resistanceLevel'] as int?,
      inclinePercent: (json['inclinePercent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'durationSeconds': duration?.inSeconds,
        'distanceKm': distanceKm,
        'resistanceLevel': resistanceLevel,
        'inclinePercent': inclinePercent,
      };
}

// ---------------------------------------------------------------------------

sealed class RecordedExercise {
  const RecordedExercise();

  static RecordedExercise fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'cardio') {
      return RecordedCardioExercise.fromJson(json);
    }
    return RecordedWeightedExercise.fromJson(json);
  }

  Map<String, dynamic> toJson();
}

extension RecordedExerciseX on RecordedExercise {
  String get name => switch (this) {
        RecordedWeightedExercise e => e.blueprint.name,
        RecordedCardioExercise e => e.blueprint.name,
      };

  String? get notes => switch (this) {
        RecordedWeightedExercise e => e.notes,
        RecordedCardioExercise e => e.notes,
      };
}

// ---------------------------------------------------------------------------

class RecordedWeightedExercise extends RecordedExercise {
  final WeightedExerciseBlueprint blueprint;
  final List<PotentialSet> potentialSets;
  final String? notes;

  const RecordedWeightedExercise({
    required this.blueprint,
    required this.potentialSets,
    this.notes,
  }) : super();

  RecordedWeightedExercise copyWith({
    WeightedExerciseBlueprint? blueprint,
    List<PotentialSet>? potentialSets,
    String? notes,
    bool clearNotes = false,
  }) {
    return RecordedWeightedExercise(
      blueprint: blueprint ?? this.blueprint,
      potentialSets: potentialSets ?? this.potentialSets,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  double get totalVolume => potentialSets
      .where((s) => s.completed && s.reps != null)
      .fold(0.0, (sum, s) => sum + s.reps! * s.weight.toKilograms().value);

  double? get maxWeightKg {
    final completed = potentialSets.where((s) => s.completed);
    if (completed.isEmpty) return null;
    return completed
        .map((s) => s.weight.toKilograms().value)
        .reduce((a, b) => a > b ? a : b);
  }

  factory RecordedWeightedExercise.fromJson(Map<String, dynamic> json) {
    return RecordedWeightedExercise(
      blueprint: WeightedExerciseBlueprint.fromJson(
          json['blueprint'] as Map<String, dynamic>),
      potentialSets: (json['potentialSets'] as List<dynamic>? ?? [])
          .map((s) => PotentialSet.fromJson(s as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'weighted',
        'blueprint': blueprint.toJson(),
        'potentialSets': potentialSets.map((s) => s.toJson()).toList(),
        'notes': notes,
      };
}

// ---------------------------------------------------------------------------

class RecordedCardioExercise extends RecordedExercise {
  final CardioExerciseBlueprint blueprint;
  final List<CardioExerciseRecordedSet> recordedSets;
  final String? notes;

  const RecordedCardioExercise({
    required this.blueprint,
    required this.recordedSets,
    this.notes,
  }) : super();

  RecordedCardioExercise copyWith({
    CardioExerciseBlueprint? blueprint,
    List<CardioExerciseRecordedSet>? recordedSets,
    String? notes,
    bool clearNotes = false,
  }) {
    return RecordedCardioExercise(
      blueprint: blueprint ?? this.blueprint,
      recordedSets: recordedSets ?? this.recordedSets,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  factory RecordedCardioExercise.fromJson(Map<String, dynamic> json) {
    return RecordedCardioExercise(
      blueprint: CardioExerciseBlueprint.fromJson(
          json['blueprint'] as Map<String, dynamic>),
      recordedSets: (json['recordedSets'] as List<dynamic>? ?? [])
          .map((s) =>
              CardioExerciseRecordedSet.fromJson(s as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'cardio',
        'blueprint': blueprint.toJson(),
        'recordedSets': recordedSets.map((s) => s.toJson()).toList(),
        'notes': notes,
      };
}

// ---------------------------------------------------------------------------

class Session {
  final String id;
  final SessionBlueprint blueprint;
  final List<RecordedExercise> recordedExercises;
  final DateTime date;
  final Weight? bodyweight;
  final DateTime? startTime;
  final DateTime? endTime;

  const Session({
    required this.id,
    required this.blueprint,
    required this.recordedExercises,
    required this.date,
    this.bodyweight,
    this.startTime,
    this.endTime,
  });

  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  double get totalVolume => recordedExercises
      .whereType<RecordedWeightedExercise>()
      .fold(0.0, (sum, e) => sum + e.totalVolume);

  Session copyWith({
    String? id,
    SessionBlueprint? blueprint,
    List<RecordedExercise>? recordedExercises,
    DateTime? date,
    Weight? bodyweight,
    bool clearBodyweight = false,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Session(
      id: id ?? this.id,
      blueprint: blueprint ?? this.blueprint,
      recordedExercises: recordedExercises ?? this.recordedExercises,
      date: date ?? this.date,
      bodyweight: clearBodyweight ? null : (bodyweight ?? this.bodyweight),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  factory Session.fromJson(Map<String, dynamic> json, String docId) {
    return Session(
      // id: json['id'] as String,
      id: docId,
      blueprint:
          SessionBlueprint.fromJson(json['blueprint'] as Map<String, dynamic>),
      recordedExercises: (json['recordedExercises'] as List<dynamic>? ?? [])
          .map((e) => RecordedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      date: DateTime.parse(json['date'] as String),
      bodyweight: json['bodyweight'] != null
          ? Weight.fromJson(json['bodyweight'] as Map<String, dynamic>)
          : null,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        // 'id': id,
        'blueprint': blueprint.toJson(),
        'recordedExercises': recordedExercises.map((e) => e.toJson()).toList(),
        'date': date.toIso8601String(),
        'bodyweight': bodyweight?.toJson(),
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };
}
