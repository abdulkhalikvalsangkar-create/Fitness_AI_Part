import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app/screens/login/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/workout/session_selection_screen.dart';
import 'screens/workout/active_session_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/program_list_screen.dart';
import 'screens/settings/manage_program_screen.dart';
import 'screens/settings/manage_session_screen.dart';

final authProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isGoingToLogin = state.uri.path == '/login';

      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      if (isLoggedIn && isGoingToLogin) {
        return '/workout';
      }

      return null;
    },
    routes: [
      // 👇 ADD LOGIN HERE (top-level)
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // 👇 KEEP YOUR EXISTING SHELL EXACTLY AS IT IS
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/workout',
              builder: (_, __) => const SessionSelectionScreen(),
              routes: [
                GoRoute(
                  path: 'active',
                  builder: (_, __) => const ActiveSessionScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/history',
              builder: (_, __) => const HistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/stats',
              builder: (_, __) => const StatsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'programs',
                  builder: (_, __) => const ProgramListScreen(),
                  routes: [
                    GoRoute(
                      path: ':programId',
                      builder: (_, state) {
                        final programId =
                            state.pathParameters['programId'] ?? '';
                        return ManageProgramScreen(programId: programId);
                      },
                      routes: [
                        GoRoute(
                          path: 'session/:sessionIndex',
                          builder: (_, state) {
                            final programId =
                                state.pathParameters['programId'] ?? '';
                            final sessionIndex = int.tryParse(
                                    state.pathParameters['sessionIndex'] ??
                                        '') ??
                                0;
                            return ManageSessionScreen(
                              programId: programId,
                              sessionIndex: sessionIndex,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

class LiftLogApp extends ConsumerWidget {
  const LiftLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'LiftLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
