import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/babies/presentation/screens/baby_edit_screen.dart';
import '../features/babies/presentation/screens/baby_profile_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/doctor/presentation/screens/doctor_summary_screen.dart';
import '../features/growth/presentation/screens/growth_add_screen.dart';
import '../features/growth/presentation/screens/growth_screen.dart';
import '../features/health/medicine/presentation/screens/medicine_add_screen.dart';
import '../features/health/medicine/presentation/screens/medicine_screen.dart';
import '../features/health/presentation/screens/health_screen.dart';
import '../features/health/vaccine/presentation/screens/vaccine_add_screen.dart';
import '../features/health/vaccine/presentation/screens/vaccine_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/timeline/presentation/screens/timeline_screen.dart';
import '../features/tracking/presentation/screens/diaper_log_screen.dart';
import '../features/tracking/presentation/screens/feeding_log_screen.dart';
import '../features/tracking/presentation/screens/sleep_log_screen.dart';
import 'shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ShellScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/timeline',
              builder: (context, state) => const TimelineScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/baby',
              builder: (context, state) => const BabyProfileScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/health',
              builder: (context, state) => const HealthScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/feeding',
      builder: (context, state) => const FeedingLogScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/sleep',
      builder: (context, state) => const SleepLogScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/diaper',
      builder: (context, state) => const DiaperLogScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/baby/edit',
      builder: (context, state) => const BabyEditScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/growth',
      builder: (context, state) => const GrowthScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/growth/add',
      builder: (context, state) => const GrowthAddScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/doctor-summary',
      builder: (context, state) => const DoctorSummaryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/health/medicine',
      builder: (context, state) => const MedicineScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/health/medicine/add',
      builder: (context, state) => const MedicineAddScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/health/vaccines',
      builder: (context, state) => const VaccineScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/health/vaccines/add',
      builder: (context, state) => const VaccineAddScreen(),
    ),
  ],
);
