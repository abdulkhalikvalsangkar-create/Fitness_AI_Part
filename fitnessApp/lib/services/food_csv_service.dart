import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../models/food_data.dart';
import 'package:FitnessApp/services/user_profile_mapper.dart';

class FoodCsvService {
  static const String _assetPath =
      'assests/dataset/food_intake_dataset.csv';

  List<FoodData>? _cache;
  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  Future<List<FoodData>> _loadDataset() async {
    if (_cache != null) return _cache!;

    final csvString = await rootBundle.loadString(_assetPath);

    final lines = csvString.trim().split('\n');

    if (lines.length <= 1) {
      _cache = [];
      return _cache!;
    }

    final headers = lines.first.split(',');

    final records = <FoodData>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      final values = line.split(',');

      if (values.length != headers.length) continue;

      final row = <String, String>{};

      for (int j = 0; j < headers.length; j++) {
        row[headers[j].trim()] = values[j].trim();
      }

      records.add(
        FoodData(
          userId: row['user_id'] ?? '',
          date: _dateFormat.parse(
            row['date'] ?? '01-01-2000',
          ),

          totalCalories:
          double.tryParse(row['total_calories_kcal'] ?? '0') ?? 0,

          protein:
          double.tryParse(row['protein_g'] ?? '0') ?? 0,

          carbohydrates:
          double.tryParse(row['carbohydrates_g'] ?? '0') ?? 0,

          fat:
          double.tryParse(row['fat_g'] ?? '0') ?? 0,

          saturatedFat:
          double.tryParse(row['saturated_fat_g'] ?? '0') ?? 0,

          transFat:
          double.tryParse(row['trans_fat_g'] ?? '0') ?? 0,

          sugar:
          double.tryParse(row['sugar_g'] ?? '0') ?? 0,

          fiber:
          double.tryParse(row['fiber_g'] ?? '0') ?? 0,

          cholesterol:
          double.tryParse(row['cholesterol_mg'] ?? '0') ?? 0,

          calcium:
          double.tryParse(row['calcium_mg'] ?? '0') ?? 0,

          iron:
          double.tryParse(row['iron_mg'] ?? '0') ?? 0,

          vitaminC:
          double.tryParse(row['vitamin_c_mg'] ?? '0') ?? 0,

          vitaminD:
          double.tryParse(row['vitamin_d_iu'] ?? '0') ?? 0,

          vitaminB12:
          double.tryParse(row['vitamin_b12_mcg'] ?? '0') ?? 0,

          selenium:
          double.tryParse(row['selenium_mcg'] ?? '0') ?? 0,

          sodium:
          double.tryParse(row['sodium_mg'] ?? '0') ?? 0,

          potassium:
          double.tryParse(row['potassium_mg'] ?? '0') ?? 0,

          artificialSweetenerServings:
          int.tryParse(row['artificial_sweetener_servings'] ?? '0') ?? 0,

          waterIntake:
          double.tryParse(row['water_intake_liters'] ?? '0') ?? 0,

          mealsLogged:
          int.tryParse(row['meals_logged'] ?? '0') ?? 0,

          dietQualityScore:
          double.tryParse(row['diet_quality_score'] ?? '0') ?? 0,
        ),
      );
    }

    _cache = records;

    print("=================================");
    print("Food Dataset Loaded");
    print("Total Rows : ${records.length}");
    print("Unique Users : ${records.map((e) => e.userId).toSet().length}");
    print("=================================");

    return _cache!;
  }

  Future<List<FoodData>> getAllData() async {
    return await _loadDataset();
  }

  Future<FoodData?> getCurrentUserFoodData() async {
    final csvUserId = await UserProfileMapper.getCsvUserId();

    if (csvUserId == null) return null;

    final data = await _loadDataset();

    final userData =
    data.where((e) => e.userId == csvUserId).toList();

    if (userData.isEmpty) return null;

    userData.sort((a, b) => a.date.compareTo(b.date));

    return userData.last;
  }

  Future<List<FoodData>> getUserHistory(String userId) async {
    final data = await _loadDataset();

    return data.where((e) => e.userId == userId).toList();
  }
}