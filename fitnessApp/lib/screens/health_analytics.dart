// import 'package:chatbotscreeen/helpers/glass_container.dart';
// import 'package:chatbotscreeen/services/healthconnect.dart';
// import 'package:flutter/material.dart';
// import 'package:health/health.dart';
// import 'package:percent_indicator/percent_indicator.dart';

// class HealthDataScreen extends StatefulWidget {
//   const HealthDataScreen({super.key});

//   @override
//   State<HealthDataScreen> createState() => _HealthDataScreenstate();
// }

// class _HealthDataScreenstate extends State<HealthDataScreen> {
//   final HealthService _healthService = HealthService();
//   List<HealthDataPoint> healthData = [];
//   bool _loading = true;
//   @override
//   void initState() {
//     super.initState();
//     loadHealthData();
//   }

//   Future<void> loadHealthData() async {
//     List<HealthDataPoint> data = await _healthService.fetchAllHealthData();
//     // print("Healthdata fetched ${data}");
//     healthtypefilter(data);
//     if (mounted) {
//       setState(() {
//         healthData = data;
//         _loading = false;
//       });
//     }
//   }

//   Future<void> healthtypefilter(List<HealthDataPoint> data) async {
//     final nutritions = data
//         .where((e) => e.value is NutritionHealthValue)
//         .toList();
//     final steps = data.where((e) => e.type == HealthDataType.STEPS).toList();
//     final sleep = data.where((e) => e.type == HealthDataType.SLEEP_ASLEEP);
//     final heart = data.where((e) => e.type == HealthDataType.HEART_RATE);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         if (_loading)
//           const Center(child: CircularProgressIndicator())
//         else
//           Expanded(
//             child: ListView.builder(
//               itemCount: healthData.length,
//               itemBuilder: (context, index) {
//                 final point = healthData[index];
//                 debugPrint("${point.value.toString()}");

//                 return FakeFakeGlassContainer(
//                   child: ListTile(
//                     title: Text(
//                       point.type.name.toString(),
//                       style: TextStyle(color: Colors.white38),
//                     ),

//                     subtitle: Text(() {
//                       if (point.value is NutritionHealthValue) {
//                         final nutrition = point.value as NutritionHealthValue;
//                         return "Fat: ${nutrition.fat}";
//                       } else if (point.value is NumericHealthValue) {
//                         final value =
//                             (point.value as NumericHealthValue).numericValue;
//                         return "$value ${point.unitString}";
//                       } else {
//                         return point.value.toString();
//                       }
//                     }()),
//                     // subtitle: Text(
//                     //   point.value is NumericHealthValue
//                     //       ? "${(point.value as NumericHealthValue).numericValue} ${point.unitString}\n${point.dateFrom}"
//                     //       : point.value.toString(),
//                     // ),
//                   ),
//                 );
//               },
//             ),
//           ),
//       ],
//     );
//   }
// }

// class HeaderSection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: const [
//         Text(
//           "Today, 18 February",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class RecoveryCard extends StatelessWidget {
//   // final
//   // const RecoveryCard({super.key, this.});
//   recoverycal() {
//     int recoveryscore = (992 + 22 / 32).round();
//     return recoveryscore;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FakeFakeGlassContainer(
//       colors: [],
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text("Recovery", style: TextStyle(color: Colors.white70)),
//               const SizedBox(height: 8),
//               Text(
//                 recoverycal().toString(),
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text("Ready", style: TextStyle(color: Colors.green)),
//             ],
//           ),
//           CircularPercentIndicator(
//             radius: 50,
//             lineWidth: 8,
//             percent: 0.78,
//             center: const Text("78%", style: TextStyle(color: Colors.white)),
//             progressColor: Colors.green,
//             backgroundColor: Colors.white10,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class DietCard extends StatelessWidget {
//   final double calories;
//   final double protein;
//   final double carbs;
//   final double fats;

//   const DietCard({
//     required this.calories,
//     required this.protein,
//     required this.carbs,
//     required this.fats,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return FakeFakeGlassContainer(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text("Diet", style: TextStyle(color: Colors.white)),
//           const SizedBox(height: 10),

//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text("Calories", style: TextStyle(color: Colors.white70)),
//               Text(
//                 "$calories kcal",
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ],
//           ),

//           const SizedBox(height: 10),

//           nutrientBar("Protein", protein, Colors.blue),
//           nutrientBar("Carbs", carbs, Colors.orange),
//           nutrientBar("Fats", fats, Colors.red),
//         ],
//       ),
//     );
//   }

//   Widget nutrientBar(String name, double value, Color color) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 70,
//             child: Text(name, style: TextStyle(color: Colors.white70)),
//           ),
//           Expanded(
//             child: LinearProgressIndicator(
//               value: value / 100,
//               color: color,
//               backgroundColor: Colors.white10,
//             ),
//           ),
//           SizedBox(width: 10),
//           Text("${value.toInt()}g", style: TextStyle(color: Colors.white)),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:FitnessApp/widgets/glass_container.dart';
import 'package:FitnessApp/models/health_global.dart';
import 'package:FitnessApp/models/session_models.dart';
import 'package:FitnessApp/services/firestore_service.dart';
import 'package:FitnessApp/services/healthconnect.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:health/health.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import 'package:FitnessApp/services/csv_health_service.dart';
import 'package:FitnessApp/services/food_csv_service.dart';
import 'package:FitnessApp/services/medical_csv_service.dart';
import 'package:FitnessApp/models/dashboard_filter.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  final HealthService _healthService = HealthService();
  final CsvHealthService _csvHealthService = CsvHealthService();
  final FoodCsvService _foodCsvService = FoodCsvService();
  final MedicalCsvService _medicalCsvService = MedicalCsvService();
  late List<HealthDataPoint> todayData;
  late List<HealthDataPoint> healthData;
  Duration sleepDuration = Duration.zero;
  double strain = 0;
  int stress = 0;
  int steps = 0;
  final int stepGoal = 10000;
  double calories = 0;
  double protein = 0;
  double carbs = 0;
  double fats = 0;
  int heartRate = 0;
  int restingHR = 0;
  List<Session> sessions = [];
  double recoveryPercent = 0;
  Timer? _updateTimer;
  DateTime? selectedRecordDate;
  DashboardFilter selectedFilter = DashboardFilter.day;

  @override
  void initState() {
    super.initState();
    loadHealthData();
    // if (mounted) {
    //   loadSessions();
    //   _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
    //     loadHealthData();
    //     loadSessions();
    //   });
    // }
    // initHealth();
  }

  @override
  void dispose() {
    _updateTimer?.cancel(); // Stop the periodic calls
    super.dispose();
  }

  // Future<void> loadHealthData() async {
  //   try {
  //     final now = DateTime.now();
  //     final start = DateTime(now.year, now.month, now.day);
  //     final end = start.add(const Duration(days: 1));
  //
  //     final data = await _healthService.fetchAllHealthData(
  //       startTime: start,
  //       endTime: end,
  //     );
  //     if (data.isEmpty) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text("Health data unavailable")));
  //       }
  //     }
  //     if (mounted) {
  //       setState(() {
  //         healthData = data;
  //         filterTodayData();
  //         aggregateData();
  //         calculateStrainStress();
  //         calculateRecovery();
  //       });
  //     }
  //   } catch (e) {
  //     print("Error in loadHealthData: $e");
  //   }
  // }

  Future<void> loadHealthData() async {
    try {
      // final food = await _foodCsvService.getCurrentUserFoodData();
      //
      // final medical = await _medicalCsvService.getCurrentUserMedicalData();
      //
      // print("============= FOOD DATA =============");
      // print(food?.toJson());
      //
      // print("============= MEDICAL DATA =============");
      // print(medical?.toJson());
      final csvData = await _csvHealthService.getLatestUserData();

      if (csvData != null) {
        setState(() {
          selectedRecordDate = csvData.date;
          recoveryPercent = csvData.recoveryScore / 100;

          strain = csvData.strain;

          sleepDuration = Duration(
            minutes: (csvData.sleepHours * 60).round(),
          );

          calories = csvData.caloriesBurned;

          steps = csvData.steps;

          heartRate = csvData.heartRate.round();

          restingHR = csvData.restingHeartRate.round();

          globalWeight = csvData.weight;
        });

        return;
      }

      // -------------------------
      // Fallback to Health Connect
      // -------------------------

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      final data = await _healthService.fetchAllHealthData(
        startTime: start,
        endTime: end,
      );

      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Health data unavailable"),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          healthData = data;
          filterTodayData();
          aggregateData();
          calculateStrainStress();
          calculateRecovery();
        });
      }
    } catch (e) {
      print("Error in loadHealthData: $e");
    }
  }

  String _getDashboardDateText() {
    final date = selectedRecordDate ?? DateTime.now();

    switch (selectedFilter) {
      case DashboardFilter.day:
        return DateFormat('EEEE, d MMMM yyyy').format(date);

      case DashboardFilter.month:
        return DateFormat('MMMM yyyy').format(date);

      case DashboardFilter.year:
        return DateFormat('yyyy').format(date);
    }
  }

  Future<void> loadSessions() async {
    final data = await StorageService.instance.getSessions();

    setState(() {
      sessions = data;
    });
    // print("Sessions count ${sessions.length}");
  }

  void filterTodayData() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    todayData = healthData.where((d) {
      return d.dateFrom.isAfter(start.subtract(Duration(seconds: 1))) &&
          d.dateFrom.isBefore(end);
    }).toList();
  }

  void aggregateData() {
    sleepDuration = Duration.zero;
    for (var d in todayData.where(
      (e) => e.type == HealthDataType.SLEEP_ASLEEP,
    )) {
      sleepDuration += d.dateTo.difference(d.dateFrom);
    }

    steps = todayData
        .where((e) => e.type == HealthDataType.STEPS)
        .map((e) => (e.value as NumericHealthValue).numericValue.toInt())
        .fold(0, (prev, element) => prev + element);

    calories = 0;
    protein = 0;
    carbs = 0;
    fats = 0;
    for (var point in todayData.where(
      (e) => e.type == HealthDataType.NUTRITION,
    )) {
      final nutrition = point.value as NutritionHealthValue;
      protein += nutrition.protein ?? 0;
      carbs += nutrition.carbs ?? 0;
      fats += nutrition.fat ?? 0;
      calories += nutrition.calories ?? 0;
      print("THIS IS NUTRITION DATA $nutrition");
    }

    final heartPoints = todayData
        .where((e) => e.type == HealthDataType.HEART_RATE)
        .toList();
    if (heartPoints.isNotEmpty) {
      heartRate = (heartPoints.last.value as double).round();
      restingHR = heartPoints
          .map((e) => (e.value as double).round())
          .reduce((a, b) => a < b ? a : b);
    } else {
      heartRate = 138;
      restingHR = 52;
    }
    final weights = healthData
        .where((e) => e.type == HealthDataType.WEIGHT)
        .toList();

    if (weights.isNotEmpty) {
      final val = weights.last.value as NumericHealthValue;
      globalWeight = val.numericValue.toDouble();
    }
  }

  void calculateStrainStress() {
    // Strain: less sleep means higher strain, scale [0, 20]
    final sleepHours = sleepDuration.inMinutes / 60;
    strain = (sleepHours < 8) ? (20 * (1 - (sleepHours / 8))).clamp(0, 20) : 0;

    // Stress: fewer steps means higher stress, scale [0, 100]
    stress = ((1 - (steps / stepGoal)) * 100).clamp(0, 100).round();
  }

  void calculateRecovery() {
    double sleepScore = (sleepDuration.inMinutes / (8 * 60)).clamp(0, 1);
    double stepScore = (steps / stepGoal).clamp(0, 1);
    double strainScore = (1 - (strain / 20)).clamp(0, 1);
    double stressScore = (1 - (stress / 100)).clamp(0, 1);
    double dietScore = (calories / 2200).clamp(0, 1);

    recoveryPercent =
        (sleepScore * 0.35) +
        (stepScore * 0.25) +
        (dietScore * 0.20) +
        (strainScore * 0.10) +
        (stressScore * 0.10);
    recoveryPercent = recoveryPercent.clamp(0, 1);
    globalRecovery = recoveryPercent;
  }

  String recoveryStatus() {
    if (recoveryPercent >= 0.75) return "Ready";
    if (recoveryPercent >= 0.5) return "Moderate";
    return "Low";
  }

  Color recoveryColor() {
    if (recoveryPercent >= 0.75) return Colors.green;
    if (recoveryPercent >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final percentText = (recoveryPercent * 100).round();

    return Padding(
      // padding: const EdgeInsets.all(12),
      padding: const EdgeInsets.only(top: 16, left: 12, right: 12, bottom: 0),

      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            refreshTriggerPullDistance: 120,
            refreshIndicatorExtent: 90,

            onRefresh: () async {
              await Future.wait([loadHealthData(), loadSessions()]);
            },
          ),

          SliverPadding(
            // padding: EdgeInsets.all(12),
            padding: EdgeInsets.zero,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // physics: const BouncingScrollPhysics(
                //   parent: AlwaysScrollableScrollPhysics(),
                // ),
                // children: [
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getDashboardDateText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedRecordDate ?? DateTime.now(),
                          firstDate: DateTime(2023, 1, 1),
                          lastDate: DateTime(2023, 12, 31),
                        );

                        if (picked == null) return;

                        _csvHealthService.selectedDate = picked;
                        _csvHealthService.selectedFilter = selectedFilter;
                        await loadHealthData();
                      },
                    ),
                  ],
                ),
                // Row(
                //   spacing: 50,
                //   children: [
                //     Text(
                //       DateFormat('EEEE, d MMMM yyyy').format(
                //         selectedRecordDate ?? DateTime.now(),
                //       ),
                //       style: const TextStyle(
                //         color: Colors.white,
                //         fontSize: 22,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //     // IconButton(
                //     //   onPressed: () async {
                //     //     //   final health = Health();
                //
                //     //     //   await health.configure();
                //
                //     //     //   final has = await health.hasPermissions([
                //     //     //     HealthDataType.WORKOUT,
                //     //     //   ]);
                //
                //     //     //   if (has == true) {
                //     //     //     print("Already has permission ✅");
                //
                //     //     //     await HealthService().getWorkout(); // proceed directly
                //     //     //   } else {
                //     //     //     final granted = await health.requestAuthorization([
                //     //     //       HealthDataType.WORKOUT,
                //     //     //     ]);
                //
                //     //     //     if (granted) {
                //     //     //       await HealthService().getWorkout();
                //     //     //     } else {
                //     //     //       print("Permission denied ❌");
                //     //     //     }
                //     //     //   }
                //     //   },
                //     //   icon: Icon(Icons.refresh),
                //     // ),
                //   ],
                // ),

                const SizedBox(height: 12),

                Row(
                  children: [

                    ChoiceChip(
                      label: const Text("Day"),
                      selected: selectedFilter == DashboardFilter.day,
                      onSelected: (_) async {
                        setState(() {
                          selectedFilter = DashboardFilter.day;
                        });

                        _csvHealthService.selectedFilter = selectedFilter;

                        await loadHealthData();
                      },
                    ),

                    const SizedBox(width: 10),

                    ChoiceChip(
                      label: const Text("Month"),
                      selected: selectedFilter == DashboardFilter.month,
                      onSelected: (_) async {
                        setState(() {
                          selectedFilter = DashboardFilter.month;
                        });

                        _csvHealthService.selectedFilter = selectedFilter;

                        await loadHealthData();
                      },
                    ),

                    const SizedBox(width: 10),

                    ChoiceChip(
                      label: const Text("Year"),
                      selected: selectedFilter == DashboardFilter.year,
                      onSelected: (_) async {
                        setState(() {
                          selectedFilter = DashboardFilter.year;
                        });

                        _csvHealthService.selectedFilter = selectedFilter;

                        await loadHealthData();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 15),
                // Recovery Card
                glassCard(
                  // padding: const EdgeInsets.all(16),
                  // borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Texts
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Recovery",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$percentText%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            recoveryStatus(),
                            style: TextStyle(
                              color: recoveryColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // Circular progress
                      CircularPercentIndicator(
                        radius: 55,
                        lineWidth: 10,
                        percent: recoveryPercent,
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: const Color(0xFF2BE070),
                        backgroundColor: Colors.white10,
                        center: Text(
                          "$percentText%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Sleep, Strain, Stress cards row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _smallInfoCard(
                      title: "Sleep",
                      value:
                          "${sleepDuration.inHours}h ${sleepDuration.inMinutes % 60}m",
                      status: "Good",
                      statusColor: Colors.green,
                    ),
                    _smallInfoCard(
                      title: "Strain",
                      value: strain.toStringAsFixed(1),
                      status: "Moderate",
                      statusColor: Colors.orangeAccent,
                    ),
                    _smallInfoCard(
                      title: "Stress",
                      value: stress.toString(),
                      status: "Elevated",
                      statusColor: Colors.orangeAccent,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Heart card
                glassCard(
                  // padding: const EdgeInsets.all(16),
                  // borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Heart",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$heartRate bpm",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Resting HR $restingHR bpm",
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: SizedBox(
                              height: 80,
                              child: SfCartesianChart(
                                primaryXAxis: CategoryAxis(
                                  labelStyle: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                  axisLine: const AxisLine(width: 0),
                                  majorGridLines: const MajorGridLines(
                                    width: 0,
                                  ),
                                ),
                                primaryYAxis: NumericAxis(isVisible: false),
                                plotAreaBorderWidth: 0,
                                series: <CartesianSeries>[
                                  LineSeries<_HeartData, String>(
                                    dataSource: [
                                      _HeartData("12pm", heartRate - 20),
                                      _HeartData("6am", restingHR),
                                      _HeartData("6pm", heartRate),
                                    ],
                                    xValueMapper: (_HeartData hr, _) => hr.time,
                                    yValueMapper: (_HeartData hr, _) =>
                                        hr.value,
                                    color: const Color(0xFFFFB020),
                                    width: 3,
                                    markerSettings: const MarkerSettings(
                                      isVisible: true,
                                      color: const Color(0xFFFFB020),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Steps card
                glassCard(
                  // padding: const EdgeInsets.all(16),
                  // borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Steps",
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$steps steps of $stepGoal Goal",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${(stepGoal - steps).clamp(0, stepGoal)} step${stepGoal - steps == 1 ? '' : 's'} remaining",
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 45,
                        lineWidth: 7,
                        percent: (steps / stepGoal).clamp(0, 1),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: const Color(0xFFFFB020),
                        backgroundColor: Colors.white10,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${((steps / stepGoal) * 100).round()}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Today",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Diet card
                glassCard(
                  // colors: [
                  //   Colors.white.withOpacity(0.05),
                  //   const Color.fromARGB(255, 109, 99, 99).withOpacity(0.15),
                  // ],
                  // padding: const EdgeInsets.all(16),
                  // borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Diet",
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Calories",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "${calories.toInt()} / 2200 Kcal",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _nutrientBar("Protein", protein, Colors.blue),
                      _nutrientBar("Carbs", carbs, Colors.orange),
                      _nutrientBar("Fats", fats, Colors.red),
                    ],
                  ),
                ),
                SizedBox(height: 14),
                ...(sessions.isEmpty
                    ? [
                        glassCard(
                          // padding: const EdgeInsets.all(16),
                          child: const Text(
                            "No workouts yet",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ]
                    : sessions
                          .take(3)
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: WorkoutCard(session: s),
                            ),
                          )
                          .toList()),
                // Daily Insights
                glassCard(
                  // padding: const EdgeInsets.all(16),
                  // borderRadius: BorderRadius.circular(16),
                  child: const Text(
                    "Your recovery improved 8% compared to yesterday",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfoCard({
    required String title,
    required String value,
    required String status,
    required Color statusColor,
  }) {
    return glassCard(
      // width: 105,
      // borderRadius: 22,
      // padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            // width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutrientBar(String name, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(name, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (value / 300).clamp(0, 1),
                color: color,
                backgroundColor: Colors.white10,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${value.toInt()}g",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class WorkoutCard extends StatefulWidget {
  final Session session;

  const WorkoutCard({super.key, required this.session});

  @override
  State<WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<WorkoutCard>
    with TickerProviderStateMixin {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final duration = session.duration;
    final minutes = duration?.inMinutes ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: glassCard(
        // padding: const EdgeInsets.all(16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Workout",
                    style: TextStyle(color: Colors.white70),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0, // 180° rotate
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              /// Title
              Text(
                "$minutes min • ${session.blueprint.name}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "${session.recordedExercises.length} Exercises",
                style: const TextStyle(color: Colors.white54),
              ),

              /// EXPANDABLE SECTION
              if (isExpanded) ...[
                const Divider(color: Colors.white24, height: 20),

                const Text("Exercise", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),

                ...session.recordedExercises.map((e) {
                  final isWeighted = e is RecordedWeightedExercise;
                  final isCardio = e is RecordedCardioExercise;

                  final sets = isWeighted
                      ? e.potentialSets.length
                      : isCardio
                      ? e.recordedSets.length
                      : 0;

                  String setDetails = "";

                  if (isWeighted) {
                    setDetails = e.potentialSets
                        .map((set) {
                          final weightKg = set.weight.toKilograms().value;
                          final reps = set.reps ?? "-";

                          return "${weightKg.toStringAsFixed(0)}kg x $reps";
                        })
                        .join(", ");
                  } else if (isCardio) {
                    setDetails = e.recordedSets
                        .map((set) {
                          final duration = set.duration?.inMinutes ?? 0;
                          final distance = set.distanceKm ?? 0;

                          return "${duration}min ${distance > 0 ? "- ${distance}km" : ""}";
                        })
                        .join(", ");
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${e.name} - $sets sets",
                          style: const TextStyle(color: Colors.white54),
                        ),

                        if (setDetails.isNotEmpty)
                          Text(
                            setDetails,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeartData {
  final String time;
  final int value;
  _HeartData(this.time, this.value);
}

// class GlassContainer extends StatelessWidget {
//   final Widget child;
//   final EdgeInsets? padding;
//   final BorderRadius? borderRadius;
//   final List<Color>? colors;

//   const GlassContainer({
//     Key? key,
//     required this.child,
//     this.padding,
//     this.borderRadius,
//     this.colors,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: padding ?? const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         borderRadius: borderRadius ?? BorderRadius.circular(12),
//         gradient: LinearGradient(
//           colors:
//               colors ??
//               [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.15)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
//       ),
//       child: child,
//     );
//   }
// }
