class DashboardData {
  final String userId;
  final DateTime date;

  final double recoveryScore;
  final double strain;

  final double sleepHours;
  final double sleepEfficiency;

  final int steps;
  final double caloriesBurned;

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
}