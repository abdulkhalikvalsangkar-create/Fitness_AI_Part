// import 'package:FitnessApp/services/HealthAndroidNative.dart';
import 'package:health/health.dart';

class HealthService {
  final Health health = Health();

  final List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WEIGHT,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.NUTRITION,
    HealthDataType.WORKOUT,
    HealthDataType.HEIGHT,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.WATER,
    HealthDataType.WORKOUT,
    // HealthDataType.EXERCISE_TIME,
  ];

  Future<List<HealthDataPoint>> fetchAllHealthData({
    required DateTime startTime,
    required endTime,
  }) async {
    try {
      await requestHealthPermissions();

      bool available = await health.isHealthConnectAvailable();
      if (!available) {
        return [];
      }

      List<HealthDataPoint> data = await health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: endTime,
        types: types,
      );

      data = health.removeDuplicates(data);
      return data;
    } catch (e) {
      print("Error fetching all health data: $e");
      return [];
    }
  }

  Future<void> requestHealthPermissions() async {
    try {
      await health.configure();

      bool available = await health.isHealthConnectAvailable();
      if (!available) {
        print("Health Connect not available on this device");
        return;
      }

      bool granted = await health.requestAuthorization(types);
      if (!granted) {
        print("Health permissions not granted by user");
        return;
      }
    } catch (e) {
      print("Health permission error: $e");
    }
  }

  Future<double?> getHeight() async {
    try {
      print("GETHEIGHT CALLED");
      await health.requestAuthorization([HealthDataType.HEIGHT]);
      final now = DateTime.now();
      final past = now.subtract(Duration(days: 3650)); // long range

      final healthData = await health.getHealthDataFromTypes(
        startTime: past,
        endTime: now,
        types: [HealthDataType.HEIGHT],
      );

      if (healthData.isNotEmpty) {
        final height = healthData.last.value; // latest value
        if (height is NumericHealthValue) {
          print("This is the height ${height.numericValue.toDouble()}");
        }
      } else {
        print("HEIGHT IS EMPTY");
      }
    } catch (e) {
      print("Error fetching height: $e");
    }
    return null;
  }

  Future<void> checkPermissions(
    Health health,
    List<HealthDataType> types,
  ) async {
    try {
      bool granted = await health.requestAuthorization(types);

      Map<HealthDataType, bool> permissionStatus = {};

      for (var type in types) {
        bool? has = await health.hasPermissions([type]);
        permissionStatus[type] = has ?? false;
      }

      List<HealthDataType> grantedTypes = [];
      List<HealthDataType> deniedTypes = [];

      permissionStatus.forEach((type, isGranted) {
        if (isGranted) {
          grantedTypes.add(type);
        } else {
          deniedTypes.add(type);
        }
      });
    } catch (e) {
      print("Error in checkPermissions: $e");
    }
  }

  static Future<Map<String, dynamic>> getBodyWeight(int days) async {
    try {
      final Health health = Health();

      await health.configure();

      bool available = await health.isHealthConnectAvailable();
      if (!available) {
        return {"range_days": days, "error": "Health Connect not available"};
      }

      final end = DateTime.now();
      final start = end.subtract(Duration(days: days));

      final types = [HealthDataType.WEIGHT, HealthDataType.BODY_FAT_PERCENTAGE];

      final data = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );

      final cleaned = health.removeDuplicates(data);

      Map<String, Map<String, double>> daily = {};

      double? latestWeight;
      double? latestBodyFat;
      DateTime? latestWeightTime;
      DateTime? latestBodyFatTime;

      for (var point in cleaned) {
        if (point.value is! NumericHealthValue) continue;

        final value = (point.value as NumericHealthValue).numericValue.toDouble();

        final date = point.dateFrom;
        final key =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        daily[key] ??= {};

        if (point.type == HealthDataType.WEIGHT) {
          daily[key]!["weight"] = value;

          // track latest
          if (latestWeightTime == null || date.isAfter(latestWeightTime)) {
            latestWeightTime = date;
            latestWeight = value;
          }
        } else if (point.type == HealthDataType.BODY_FAT_PERCENTAGE) {
          daily[key]!["body_fat"] = value;

          if (latestBodyFatTime == null || date.isAfter(latestBodyFatTime)) {
            latestBodyFatTime = date;
            latestBodyFat = value;
          }
        }
      }

      final dailyList =
          daily.entries.map((e) {
            return {"date": e.key, ...e.value.map((k, v) => MapEntry(k, v))};
          }).toList()..sort(
            (a, b) => (a["date"] as String).compareTo(b["date"] as String),
          );

      // Optional stats
      double? minWeight, maxWeight;

      final weightValues = dailyList
          .where((e) => e["weight"] != null)
          .map((e) => (e["weight"] as double))
          .toList();

      if (weightValues.isNotEmpty) {
        minWeight = weightValues.reduce((a, b) => a < b ? a : b);
        maxWeight = weightValues.reduce((a, b) => a > b ? a : b);
      }

      return {
        "range_days": days,

        if (latestWeight != null) "latest_weight": latestWeight,
        if (latestBodyFat != null) "latest_body_fat": latestBodyFat,

        if (dailyList.isNotEmpty) "daily_body_metrics": dailyList,

        if (minWeight != null && maxWeight != null)
          "weight_range": {"min": minWeight, "max": maxWeight},
      };
    } catch (e) {
      print("Error fetching body weight data: $e");
      return {"range_days": days, "error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getSleepData(int days) async {
    try {
      final Health health = Health();

      await health.configure();

      bool available = await health.isHealthConnectAvailable();
      if (!available) {
        return {"days": days, "error": "Health Connect not available"};
      }

      final end = DateTime.now();
      final start = end.subtract(Duration(days: days));

      final data = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.SLEEP_ASLEEP],
      );

      final cleaned = health.removeDuplicates(data);

      final sleepHours = cleaned.map((e) {
        final value = e.value as NumericHealthValue;
        return value.numericValue / 3600;
      }).toList();

      return {"days": days, "sleep_hours": sleepHours};
    } catch (e) {
      print("Error fetching sleep data: $e");
      return {"days": days, "error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStepsData(int days) async {
    try {
      final Health health = Health();

      await health.configure();

      bool available = await health.isHealthConnectAvailable();
      if (!available) {
        return {"range_days": days, "error": "Health Connect not available"};
      }

      final end = DateTime.now();
      final start = end.subtract(Duration(days: days));

      final data = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.STEPS],
      );

      final cleaned = health.removeDuplicates(data);

      double totalSteps = 0;
      Map<String, int> stepsPerDay = {};

      for (var point in cleaned) {
        final value = point.value as NumericHealthValue;
        final steps = value.numericValue.toInt();

        totalSteps += steps;

        final date = point.dateFrom;
        final key =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        stepsPerDay[key] = (stepsPerDay[key] ?? 0) + steps;
      }

      // Convert to sorted list (VERY important for LLM clarity)
      final dailyList =
          stepsPerDay.entries.map((e) {
            return {"date": e.key, "steps": e.value};
          }).toList()..sort(
            (a, b) => (a["date"] as String).compareTo((b["date"] as String)),
          );

      return {
        "range_days": days,
        "total_steps": totalSteps.toInt(),
        "daily_steps": dailyList,
      };
    } catch (e) {
      print("Error fetching steps data: $e");
      return {"range_days": days, "error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getNutritionData(int days) async {
    try {
      final Health health = Health();

      await health.configure();

      bool available = await health.isHealthConnectAvailable();
      if (!available) {
        return {"range_days": days, "error": "Health Connect not available"};
      }

      final end = DateTime.now();
      final start = end.subtract(Duration(days: days));

      final data = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.NUTRITION],
      );

      final cleaned = health.removeDuplicates(data);

      Map<String, Map<String, double>> daily = {};
      Map<String, double> totals = {};
      List<Map<String, dynamic>> foodEntries = [];

      for (var point in cleaned) {
        final n = point.value as NutritionHealthValue;

        final date = point.dateFrom;
        final key =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        daily[key] ??= {};

        void add(String field, double? value) {
          if (value == null || value == 0) return;

          daily[key]![field] = (daily[key]![field] ?? 0) + value;
          totals[field] = (totals[field] ?? 0) + value;
        }

        add("calories", n.calories);
        add("protein", n.protein);
        add("carbs", n.carbs);
        add("fat", n.fat);
        add("fiber", n.fiber);
        add("sugar", n.sugar);

        // ✅ Lightweight food entry for chatbot context
        final entry = <String, dynamic>{"date": key};

        if (n.name != null && n.name!.isNotEmpty) {
          entry["name"] = n.name;
        }

        if (n.mealType != null && n.mealType!.isNotEmpty) {
          entry["meal_type"] = n.mealType;
        }

        if (n.calories != null && n.calories! > 0) {
          entry["calories"] = n.calories!.round();
        }

        if (n.protein != null && n.protein! > 0) {
          entry["protein"] = n.protein!.round();
        }

        if (n.carbs != null && n.carbs! > 0) {
          entry["carbs"] = n.carbs!.round();
        }

        if (n.fat != null && n.fat! > 0) {
          entry["fat"] = n.fat!.round();
        }

        // Only include meaningful entries
        if (entry.length > 1) {
          foodEntries.add(entry);
        }
      }

      final dailyList =
          daily.entries.map((e) {
            return {
              "date": e.key,
              ...e.value.map((k, v) => MapEntry(k, v.round())),
            };
          }).toList()..sort(
            (a, b) => (a["date"] as String).compareTo((b["date"] as String)),
          );

      final roundedTotals = totals.map((k, v) => MapEntry(k, v.round()));

      return {
        "range_days": days,

        if (roundedTotals.isNotEmpty) "totals": roundedTotals,
        if (dailyList.isNotEmpty) "daily_nutrition": dailyList,

        // ✅ Add food context (limit size if needed)
        // if (foodEntries.isNotEmpty) "food_entries": foodEntries.take(50).toList(),
        "note": "Only available nutrition data is included.",
      };
    } catch (e) {
      print("Error fetching nutrition data: $e");
      return {"range_days": days, "error": e.toString()};
    }
  }
}
