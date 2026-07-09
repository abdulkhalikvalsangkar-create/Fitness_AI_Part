class FoodData {
  final String userId;
  final DateTime date;

  final double totalCalories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double saturatedFat;
  final double transFat;
  final double sugar;
  final double fiber;

  final double cholesterol;
  final double calcium;
  final double iron;

  final double vitaminC;
  final double vitaminD;
  final double vitaminB12;
  final double selenium;

  final double sodium;
  final double potassium;

  final int artificialSweetenerServings;

  final double waterIntake;

  final int mealsLogged;

  final double dietQualityScore;

  const FoodData({
    required this.userId,
    required this.date,
    required this.totalCalories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.saturatedFat,
    required this.transFat,
    required this.sugar,
    required this.fiber,
    required this.cholesterol,
    required this.calcium,
    required this.iron,
    required this.vitaminC,
    required this.vitaminD,
    required this.vitaminB12,
    required this.selenium,
    required this.sodium,
    required this.potassium,
    required this.artificialSweetenerServings,
    required this.waterIntake,
    required this.mealsLogged,
    required this.dietQualityScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String(),
      'total_calories_kcal': totalCalories,
      'protein_g': protein,
      'carbohydrates_g': carbohydrates,
      'fat_g': fat,
      'saturated_fat_g': saturatedFat,
      'trans_fat_g': transFat,
      'sugar_g': sugar,
      'fiber_g': fiber,
      'cholesterol_mg': cholesterol,
      'calcium_mg': calcium,
      'iron_mg': iron,
      'vitamin_c_mg': vitaminC,
      'vitamin_d_iu': vitaminD,
      'vitamin_b12_mcg': vitaminB12,
      'selenium_mcg': selenium,
      'sodium_mg': sodium,
      'potassium_mg': potassium,
      'artificial_sweetener_servings':
      artificialSweetenerServings,
      'water_intake_liters': waterIntake,
      'meals_logged': mealsLogged,
      'diet_quality_score': dietQualityScore,
    };
  }
}