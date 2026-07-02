import 'package:FitnessApp/models/UserProfile_model.dart';
import 'package:FitnessApp/models/health_global.dart';
import 'package:FitnessApp/screens/onboarding/login_screen.dart';
import 'package:FitnessApp/screens/reports_screen.dart';
import 'package:FitnessApp/services/firestore_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:FitnessApp/screens/health_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

import '../services/csv_login_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? user;
  Stream<UserProfile?> getUserdataStream() async* {
    final user = await StorageService.instance.getUserProfile();
    yield user;
  }
  // @override
  // void initState() {
  //   super.initState();
  //   getUserdata();
  // }

  // void getUserdata() async {
  //   user = await StorageService.instance.getUserProfile();
  // }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: getUserdataStream(),
      builder: (context, snapshot) {
        //  Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text("No Profile Found")));
        }

        final user = snapshot.data!;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///  Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const Icon(Icons.arrow_back_ios, color: Colors.white),
                    const Text(
                      "Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 12),
                  ],
                ),

                const SizedBox(height: 20),

                ///  Profile Card
                _glassCard(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        // backgroundImage: NetworkImage(
                        //   "https://i.pravatar.cc/150?img=5",
                        // ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user!.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Performance optimizer",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      /// Stats
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                      //   children: [
                      //     _statItem(
                      //       "Recovery",
                      //       "${(globalRecovery * 100).round()}%",
                      //     ),
                      //     const _divider(),
                      //     const _statItem("Weekly", "14.2"),
                      //     const _divider(),
                      //     const _statItem("sleep Avg.", "7h 32m"),
                      //   ],
                      // ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(
                            0.35,
                          ), // 🔹 dark block
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem(
                              "Recovery",
                              "${(globalRecovery * 100).round()}%",
                            ),
                            const _divider(),
                            const _statItem("Weekly", "0"),
                            const _divider(),
                            const _statItem("sleep Avg.", "0h 0m"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                ///  Health Data
                const _sectionTitle("Health Data"),
                _glassCard(
                  child: Column(
                    children: [
                      _listTile("Height", "${user?.height}"),
                      _listTile("Weight", "${user?.weight}"),
                      _listTile("Age", "${user?.age}"),
                      _listTile("Gender", "${user?.gender}"),
                      const _listTile("Goal", "null", showDivider: false),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const _sectionTitle("Reports"),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportsScreen()),
                    );
                  },
                  child: _glassCard(
                    child: Row(
                      children: [
                        Text(
                          "User reports",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                // const SizedBox(height: 20),

                // ///  Devices
                // const _sectionTitle("Devices"),
                // _glassCard(
                //   child: const _listTile(
                //     "Apple Watch",
                //     "Synced 12 min ago",
                //     showArrow: true,
                //     showDivider: false,
                //   ),
                // ),
                const SizedBox(height: 20),

                ///  AI Preferences
                const _sectionTitle("AI Preferences"),
                _glassCard(
                  child: Column(
                    children: const [
                      _SwitchTile("Daily Insight Notifications", true),
                      // _SwitchTile("Voice Assistant Enabled", true),
                      // _SwitchTile("Data Sharing for AI", true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                ///  Logout
                GestureDetector(
                  onTap: () async {
                    SharedPreferences prefs =
                    await SharedPreferences.getInstance();

                    await prefs.setBool('isSignedIn', false);
                    await prefs.setBool('ProfileCompleted', false);

                    // Clear CSV login session
                    await CsvLoginService.logout();

                    final box = Hive.box('auth_session');
                    await box.clear();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                          (route) => false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.08),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Log Out",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  ///  Glass Card
  static Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }
}

///  Section Title
class _sectionTitle extends StatelessWidget {
  final String title;
  const _sectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

///  List Tile
class _listTile extends StatelessWidget {
  final String title;
  final String value;
  final bool showArrow;
  final bool showDivider;

  const _listTile(
    this.title,
    this.value, {
    this.showArrow = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(color: Colors.white)),
            const Spacer(),
            Text(value, style: const TextStyle(color: Colors.white70)),
            if (showArrow)
              const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.1), thickness: 0.5),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }
}

/// Switch Tile
class _SwitchTile extends StatefulWidget {
  final String title;
  final bool initial;

  const _SwitchTile(this.title, this.initial);

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  late bool value;

  @override
  void initState() {
    value = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        CupertinoSwitch(
          value: value,
          // activeThumbColor: Colors.greenAccent,
          onChanged: (v) => setState(() => value = v),
        ),
      ],
    );
  }
}

/// 🔹 Stat Item
class _statItem extends StatelessWidget {
  final String title;
  final String value;

  const _statItem(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

/// 🔹 Divider between stats
class _divider extends StatelessWidget {
  const _divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }
}
