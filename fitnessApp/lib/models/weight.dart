enum WeightUnit { kilograms, pounds }

class Weight {
  final double value;
  final WeightUnit unit;

  const Weight({required this.value, required this.unit});

  static const Weight zero = Weight(value: 0, unit: WeightUnit.kilograms);

  Weight toKilograms() {
    if (unit == WeightUnit.kilograms) return this;
    return Weight(value: value * 0.453592, unit: WeightUnit.kilograms);
  }

  Weight toPounds() {
    if (unit == WeightUnit.pounds) return this;
    return Weight(value: value * 2.20462, unit: WeightUnit.pounds);
  }

  Weight convertTo(WeightUnit targetUnit) {
    if (targetUnit == WeightUnit.kilograms) return toKilograms();
    return toPounds();
  }

  String get unitLabel => unit == WeightUnit.kilograms ? 'kg' : 'lbs';

  String format({int decimals = 1}) {
    final rounded = double.parse(value.toStringAsFixed(decimals));
    final formatted =
        rounded == rounded.roundToDouble() ? rounded.toInt().toString() : rounded.toStringAsFixed(decimals);
    return '$formatted $unitLabel';
  }

  bool operator >(Weight other) {
    return toKilograms().value > other.toKilograms().value;
  }

  @override
  bool operator ==(Object other) =>
      other is Weight && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);

  factory Weight.fromJson(Map<String, dynamic> json) {
    return Weight(
      value: (json['value'] as num).toDouble(),
      unit: WeightUnit.values.firstWhere(
        (u) => u.name == json['unit'],
        orElse: () => WeightUnit.kilograms,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'unit': unit.name,
      };
}
