import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../models/medical_report_data.dart';
import 'package:FitnessApp/services/user_profile_mapper.dart';

class MedicalCsvService {
  static const String _assetPath =
      'assests/dataset/medical_report_dataset.csv';

  List<MedicalReportData>? _cache;
  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  Future<List<MedicalReportData>> _loadDataset() async {
    if (_cache != null) return _cache!;

    final csvString = await rootBundle.loadString(_assetPath);

    final lines = csvString.trim().split('\n');

    if (lines.length <= 1) {
      _cache = [];
      return _cache!;
    }

    final headers = lines.first.split(',');

    final records = <MedicalReportData>[];

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
        MedicalReportData(
          userId: row['user_id'] ?? '',
          date: _dateFormat.parse(
            row['date'] ?? '01-01-2000',
          ),

          bloodGroup: row['blood_group'] ?? '',

          bmi: double.tryParse(row['bmi'] ?? '0') ?? 0,

          bloodPressureSystolic:
          int.tryParse(row['blood_pressure_systolic'] ?? '0') ?? 0,

          bloodPressureDiastolic:
          int.tryParse(row['blood_pressure_diastolic'] ?? '0') ?? 0,

          fastingBloodGlucose:
          double.tryParse(row['fasting_blood_glucose'] ?? '0') ?? 0,

          hba1c:
          double.tryParse(row['hba1c'] ?? '0') ?? 0,

          hemoglobin:
          double.tryParse(row['hemoglobin'] ?? '0') ?? 0,

          vitaminDLevel:
          double.tryParse(row['vitamin_d_level'] ?? '0') ?? 0,

          vitaminB12Level:
          double.tryParse(row['vitamin_b12_level'] ?? '0') ?? 0,

          cholesterolTotal:
          double.tryParse(row['cholesterol_total'] ?? '0') ?? 0,

          hdl:
          double.tryParse(row['hdl'] ?? '0') ?? 0,

          ldl:
          double.tryParse(row['ldl'] ?? '0') ?? 0,

          triglycerides:
          double.tryParse(row['triglycerides'] ?? '0') ?? 0,

          liverFunctionStatus:
          row['liver_function_status'] ?? '',

          kidneyFunctionStatus:
          row['kidney_function_status'] ?? '',

          thyroidStatus:
          row['thyroid_status'] ?? '',

          inflammationMarker:
          row['inflammation_marker'] ?? '',

          allergyFlag:
          row['allergy_flag'] ?? '',

          chronicCondition:
          row['chronic_condition'] ?? '',

          physicianRiskLevel:
          row['physician_risk_level'] ?? '',

          reportSummary:
          row['report_summary'] ?? '',
        ),
      );
    }

    _cache = records;

    print("=================================");
    print("Medical Dataset Loaded");
    print("Total Rows : ${records.length}");
    print("Unique Users : ${records.map((e) => e.userId).toSet().length}");
    print("=================================");

    return _cache!;
  }

  Future<List<MedicalReportData>> getAllData() async {
    return await _loadDataset();
  }

  Future<MedicalReportData?> getCurrentUserMedicalData() async {
    final csvUserId = await UserProfileMapper.getCsvUserId();

    if (csvUserId == null) return null;

    final data = await _loadDataset();

    final userData =
    data.where((e) => e.userId == csvUserId).toList();

    if (userData.isEmpty) return null;

    userData.sort((a, b) => a.date.compareTo(b.date));

    return userData.last;
  }

  Future<List<MedicalReportData>> getUserHistory(String userId) async {
    final data = await _loadDataset();

    return data.where((e) => e.userId == userId).toList();
  }
}