class MedicalReportData {
  final String userId;
  final DateTime date;

  final String bloodGroup;

  final double bmi;

  final int bloodPressureSystolic;
  final int bloodPressureDiastolic;

  final double fastingBloodGlucose;
  final double hba1c;
  final double hemoglobin;

  final double vitaminDLevel;
  final double vitaminB12Level;

  final double cholesterolTotal;
  final double hdl;
  final double ldl;
  final double triglycerides;

  final String liverFunctionStatus;
  final String kidneyFunctionStatus;
  final String thyroidStatus;

  final String inflammationMarker;
  final String allergyFlag;
  final String chronicCondition;

  final String physicianRiskLevel;
  final String reportSummary;

  const MedicalReportData({
    required this.userId,
    required this.date,
    required this.bloodGroup,
    required this.bmi,
    required this.bloodPressureSystolic,
    required this.bloodPressureDiastolic,
    required this.fastingBloodGlucose,
    required this.hba1c,
    required this.hemoglobin,
    required this.vitaminDLevel,
    required this.vitaminB12Level,
    required this.cholesterolTotal,
    required this.hdl,
    required this.ldl,
    required this.triglycerides,
    required this.liverFunctionStatus,
    required this.kidneyFunctionStatus,
    required this.thyroidStatus,
    required this.inflammationMarker,
    required this.allergyFlag,
    required this.chronicCondition,
    required this.physicianRiskLevel,
    required this.reportSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String(),
      'blood_group': bloodGroup,
      'bmi': bmi,
      'blood_pressure_systolic': bloodPressureSystolic,
      'blood_pressure_diastolic': bloodPressureDiastolic,
      'fasting_blood_glucose': fastingBloodGlucose,
      'hba1c': hba1c,
      'hemoglobin': hemoglobin,
      'vitamin_d_level': vitaminDLevel,
      'vitamin_b12_level': vitaminB12Level,
      'cholesterol_total': cholesterolTotal,
      'hdl': hdl,
      'ldl': ldl,
      'triglycerides': triglycerides,
      'liver_function_status': liverFunctionStatus,
      'kidney_function_status': kidneyFunctionStatus,
      'thyroid_status': thyroidStatus,
      'inflammation_marker': inflammationMarker,
      'allergy_flag': allergyFlag,
      'chronic_condition': chronicCondition,
      'physician_risk_level': physicianRiskLevel,
      'report_summary': reportSummary,
    };
  }
}