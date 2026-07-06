class DashboardData {
  final String userId;
  final DateTime date;

  final double recoveryScore;
  final double strain;

  final double sleepHours;
  final double sleepEfficiency;

  final int steps;
  final double caloriesBurned;

  final int age;

  final String gender;

  final double height;

  final double weight;

  final double heartRate;
  final double restingHeartRate;

  final double protein;
  final double carbs;
  final double fat;

  final String activityType;
  final int workoutMinutes;

  const DashboardData({
    required this.userId,
    required this.age,
    required this.gender,
    required this.height,

    required this.date,
    required this.recoveryScore,
    required this.strain,
    required this.sleepHours,
    required this.sleepEfficiency,
    required this.steps,
    required this.caloriesBurned,
    required this.weight,
    required this.heartRate,
    required this.restingHeartRate,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.activityType,
    required this.workoutMinutes,
  });

  /// SERVER MIGRATION: Serialize a record so it can be sent to the backend as
  /// part of `context.csv_health_data`. The CSV itself stays on the device;
  /// only the relevant records travel with each request.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String(),
      'age': age,
      'gender': gender,
      'height_cm': height,
      'weight_kg': weight,
      'recovery_score': recoveryScore,
      'day_strain': strain,
      'sleep_hours': sleepHours,
      'sleep_efficiency': sleepEfficiency,
      'steps': steps,
      'calories_burned': caloriesBurned,
      'avg_heart_rate': heartRate,
      'resting_heart_rate': restingHeartRate,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'activity_type': activityType,
      'activity_duration_min': workoutMinutes,
    };
  }
}