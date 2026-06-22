import 'dart:math';
import 'dart:ui';

import 'package:FitnessApp/firebase_options.dart';
import 'package:FitnessApp/models/chat_message.dart';
import 'package:FitnessApp/models/chat_session.dart';
import 'package:FitnessApp/models/file_model.dart';
import 'package:FitnessApp/screens/chat_bot_screen.dart';
import 'package:FitnessApp/screens/health_analytics.dart';
import 'package:FitnessApp/screens/profile_screen.dart';
import 'package:FitnessApp/screens/onboarding/login_screen.dart';
import 'package:FitnessApp/screens/thread_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:FitnessApp/services/chat_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: could not load .env file: $e");
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  await Hive.initFlutter();
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ChatSessionAdapter());
  Hive.registerAdapter(FileModelAdapter());

  await Hive.openBox<ChatSession>('chats');
  await Hive.openBox<FileModel>('files');
  await Hive.openBox('auth_session');

  final box = Hive.box('auth_session');
  bool signedIn = box.get('isSignedIn', defaultValue: false) ?? false;
  runApp(MyApp(isSignedIn: signedIn));
}

class MyApp extends StatelessWidget {
  final bool isSignedIn;
  const MyApp({super.key, required this.isSignedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      home: isSignedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenstate();
}

class _HomeScreenstate extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  // late TabController _tabController;

  // @override
  // void initState() {
  //   super.initState();
  //   _tabController = TabController(length: 3, vsync: this);
  // }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        extendBodyBehindAppBar: true,
        drawerEnableOpenDragGesture: false,

        // extendBody: true,
        // appBar: AppBar(
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        //   centerTitle: true,
        //   title: AnimatedBuilder(
        //     animation: _tabController,
        //     builder: (context, _) {
        //       switch (_tabController.index) {
        //         case 1:
        //           return Text("AI", style: TextStyle(color: Colors.white));
        //         case 0:
        //           return Text(
        //             "Analytics",
        //             style: TextStyle(color: Colors.white),
        //           );
        //         case 2:
        //           return Text("Profile", style: TextStyle(color: Colors.white));
        //         default:
        //           return SizedBox();
        //       }
        //     },
        //   ),
        // ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF1C1C1E),
          child: SafeArea(
            child: Column(
              children: [
                /// Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha :0.08),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.white70),
                        hintText: "Search",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                /// New Chat Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        final chat = ChatStorageService.createNewChat();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatthreadScreen(chatId: chat.id),
                          ),
                        );
                      },
                      child: const Text("+ New chat"),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Chat List
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box<ChatSession>(
                      'chats',
                    ).listenable(),
                    builder: (context, box, _) {
                      final chats = box.values.toList();
                      chats.sort((a, b) {
                        // Find the earliest message in each session
                        DateTime earliestA = a.messages
                            .map((message) => message.timestamp)
                            .reduce((a, b) => a.isBefore(b) ? a : b);
                        DateTime earliestB = b.messages
                            .map((message) => message.timestamp)
                            .reduce((a, b) => a.isBefore(b) ? a : b);

                        // Compare the earliest messages' dates
                        return earliestA.compareTo(earliestB);
                      });
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];

                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              chat.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChatthreadScreen(chatId: chat.id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                /// Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        // backgroundImage: NetworkImage(
                        //   // "https://i.pravatar.cc/150?img=5",
                        // ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Anna Kaif",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            // Container(
            //   decoration: BoxDecoration(
            //     gradient: RadialGradient(
            //       center: Alignment.topCenter,
            //       radius: 1.2,
            //       colors: [
            //         Color(0xFF3A2C5A), // purple glow center
            //         Color(0xFF0B0F1A), // dark outer
            //       ],
            //       stops: [0.0, 0.8],
            //     ),
            //   ),
            // ),
            TabBarView(
              // controller: _tabController,
              children: [
                HealthDashboardScreen(),
                Chatbootscreen(
                  openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                ProfileScreen(),
              ],
            ),

            Positioned(
              bottom: 10,
              right: 10,
              left: 10,

              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      // color: const Color(0xFF2A1F3F).withValues(alpha :0.6),
                      color: Colors.grey.withValues(alpha :0.2),
                      border: Border.all(color: Colors.white.withValues(alpha :0.18)),
                    ),

                    child: TabBar(
                      // controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicatorColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      unselectedLabelColor: Colors.white,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: WidgetStateProperty.resolveWith<Color?>((
                        Set<WidgetState> states,
                      ) {
                        return states.contains(WidgetState.focused)
                            ? null
                            : Colors.transparent;
                      }),
                      labelColor: Colors.white70,

                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(60)),

                        // shape: BoxShape.circle,
                        // color: const Color.fromARGB(255, 126, 130, 135),
                        color: Colors.white.withValues(alpha :0.15),
                      ),

                      tabs: [
                        Tab(icon: Icon(Icons.bar_chart)),
                        Tab(icon: Icon(Icons.auto_awesome)),
                        Tab(icon: Icon(Icons.person)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
