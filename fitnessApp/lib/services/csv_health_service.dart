import 'package:flutter/services.dart' show rootBundle;

import '../models/dashboard_data.dart';
import 'package:FitnessApp/services/user_profile_mapper.dart';
import 'package:FitnessApp/models/dashboard_filter.dart';

class CsvHealthService {
  static const String _assetPath = 'assests/dataset/whoop_fitness_dataset_100k.csv';

  List<DashboardData>? _cache;
  DateTime? selectedDate;
  DashboardFilter selectedFilter = DashboardFilter.day;

  Future<List<DashboardData>> _loadDataset() async {
    if (_cache != null) return _cache!;

    final csvString = await rootBundle.loadString(_assetPath);

    final lines = csvString.trim().split('\n');

    if (lines.length <= 1) {
      _cache = [];
      return _cache!;
    }

    final headers = lines.first.split(',');

    final records = <DashboardData>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      final values = line.split(',');

      if (values.length != headers.length) {
        continue;
      }

      final row = <String, String>{};

      for (int j = 0; j < headers.length; j++) {
        row[headers[j].trim()] = values[j].trim();
      }

      records.add(
        DashboardData(
          userId: row['user_id'] ?? '',

          date: DateTime.tryParse(row['date'] ?? '') ?? DateTime.now(),

          recoveryScore:
          double.tryParse(row['recovery_score'] ?? '0') ?? 0,

          strain:
          double.tryParse(row['day_strain'] ?? '0') ?? 0,

          sleepHours:
          double.tryParse(row['sleep_hours'] ?? '0') ?? 0,

          sleepEfficiency:
          double.tryParse(row['sleep_efficiency'] ?? '0') ?? 0,

          // Dataset doesn't have steps
          steps: 0,

          caloriesBurned:
          double.tryParse(row['calories_burned'] ?? '0') ?? 0,

          weight:
          double.tryParse(row['weight_kg'] ?? '0') ?? 0,

          heartRate:
          double.tryParse(row['avg_heart_rate'] ?? '0') ?? 0,

          restingHeartRate:
          double.tryParse(row['resting_heart_rate'] ?? '0') ?? 0,

          // Dataset doesn't contain nutrition
          protein: 0,

          carbs: 0,

          fat: 0,

          activityType: row['activity_type'] ?? 'Rest Day',

          workoutMinutes:
          int.tryParse(row['activity_duration_min'] ?? '0') ?? 0,
        ),
      );
    }

    _cache = records;
    final uniqueUsers =
    records.map((e) => e.userId).toSet();

    print("=================================");
    print("Total rows : ${records.length}");
    print("Unique users : ${uniqueUsers.length}");
    print("First user : ${uniqueUsers.first}");
    print("Last user : ${uniqueUsers.last}");
    print("=================================");
    return _cache!;
  }

  Future<List<DashboardData>> getAllData() async {
    return await _loadDataset();
  }

  Future<List<String>> getAvailableUserIds() async {
    final data = await _loadDataset();

    final userIds = data
        .map((e) => e.userId)
        .toSet()
        .toList()
      ..sort();

    return userIds;
  }

  // Future<DashboardData?> getLatestUserData() async {
  //   final data = await _loadDataset();
  //
  //   if (data.isEmpty) return null;
  //
  //   final csvUserId = await UserProfileMapper.getCsvUserId();
  //
  //   try {
  //     print("=================================");
  //     print("Firebase mapped CSV User : $csvUserId");
  //
  //     final userHistory =
  //     data.where((e) => e.userId == csvUserId).toList();
  //
  //     print("Records found : ${userHistory.length}");
  //
  //     if (userHistory.isNotEmpty) {
  //       print("Recovery : ${userHistory.first.recoveryScore}");
  //       print("Sleep : ${userHistory.first.sleepHours}");
  //       print("Heart : ${userHistory.first.heartRate}");
  //       print("Calories : ${userHistory.first.caloriesBurned}");
  //     }
  //
  //     print("=================================");
  //     return userHistory.first;
  //   } catch (_) {
  //     return data.first;
  //   }
  // }

  Future<DashboardData?> getLatestUserData() async {
    final data = await _loadDataset();

    if (data.isEmpty) return null;

    final csvUserId = await UserProfileMapper.getCsvUserId();

    // Get all records of this user
    List<DashboardData> userHistory =
    data.where((e) => e.userId == csvUserId).toList();

    if (userHistory.isEmpty) {
      return null;
    }

    // Always sort by date
    userHistory.sort((a, b) => a.date.compareTo(b.date));

    // No filter selected -> latest record
    if (selectedDate == null) {
      final latest = userHistory.last;

      print("=================================");
      print("CSV User : $csvUserId");
      print("Showing latest date : ${latest.date}");
      print("=================================");

      return latest;
    }

    List<DashboardData> filtered = [];

    switch (selectedFilter) {
      case DashboardFilter.day:
        filtered = userHistory.where((e) {
          return e.date.year == selectedDate!.year &&
              e.date.month == selectedDate!.month &&
              e.date.day == selectedDate!.day;
        }).toList();
        break;

      case DashboardFilter.month:
        filtered = userHistory.where((e) {
          return e.date.year == selectedDate!.year &&
              e.date.month == selectedDate!.month;
        }).toList();
        break;

      case DashboardFilter.year:
        filtered = userHistory.where((e) {
          return e.date.year == selectedDate!.year;
        }).toList();
        break;
    }

    if (filtered.isEmpty) {
      return null;
    }

    filtered.sort((a, b) => a.date.compareTo(b.date));

    // DAY -> return exact day's record
    if (selectedFilter == DashboardFilter.day) {
      final latest = filtered.last;

      print("=================================");
      print("CSV User : $csvUserId");
      print("Filter : DAY");
      print("Records Found : ${filtered.length}");
      print("Showing : ${latest.date}");
      print("=================================");

      return latest;
    }

    // MONTH / YEAR -> average values
    double average(double Function(DashboardData e) selector) {
      return filtered.map(selector).reduce((a, b) => a + b) / filtered.length;
    }

    final latest = filtered.last;

    final averaged = DashboardData(
      userId: latest.userId,
      date: latest.date,

      recoveryScore: average((e) => e.recoveryScore),
      strain: average((e) => e.strain),
      sleepHours: average((e) => e.sleepHours),
      sleepEfficiency: average((e) => e.sleepEfficiency),

      caloriesBurned: average((e) => e.caloriesBurned),

      weight: average((e) => e.weight),

      heartRate: average((e) => e.heartRate),

      restingHeartRate: average((e) => e.restingHeartRate),

      protein: latest.protein,
      carbs: latest.carbs,
      fat: latest.fat,
      steps: latest.steps,

      activityType: latest.activityType,
      workoutMinutes: latest.workoutMinutes,
    );

    print("=================================");
    print("CSV User : $csvUserId");
    print("Filter : $selectedFilter");
    print("Selected Date : $selectedDate");
    print("Records Found : ${filtered.length}");
    print("Average Recovery : ${averaged.recoveryScore}");
    print("Average Sleep : ${averaged.sleepHours}");
    print("Average Heart : ${averaged.heartRate}");
    print("Average Calories : ${averaged.caloriesBurned}");
    print("=================================");

    return averaged;
  }

  Future<List<DashboardData>> getUserHistory(String userId) async {
    final data = await _loadDataset();

    return data.where((e) => e.userId == userId).toList();
  }
}