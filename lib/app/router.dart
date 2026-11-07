import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/responsive_shell.dart';
import '../features/authentication/create_account_screen.dart';
import '../features/authentication/phone_verification_screen.dart';
import '../features/authentication/sign_in_screen.dart';
import '../features/deposits/deposit_successful_screen.dart';
import '../features/deposits/make_deposit_screen.dart';
import '../features/home/home_dashboard_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/savings_goals/create_goal_screen.dart';
import '../features/savings_goals/goal_created_screen.dart';
import '../features/savings_goals/goal_details_screen.dart';
import '../features/savings_goals/goal_summary_screen.dart';
import '../features/savings_goals/goals_list_screen.dart';
import '../features/transactions/transactions_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

/// GoRouter configuration supporting:
/// - Clean Path URL strategy (`usePathUrlStrategy()`)
/// - Browser back/forward buttons & deep linking
/// - Query parameters (e.g., `/deposits/create?goalId=...`)
/// - Adaptive ResponsiveShell for primary navigation tabs
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/welcome'),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/verify-phone',
        builder: (context, state) => const PhoneVerificationScreen(),
      ),

      // Primary Adaptive Shell (Home, Goals, Transactions, Profile)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ResponsiveShell(currentLocation: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeDashboardScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsListScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Goal Creation & Details Flows
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/goals/create',
        builder: (context, state) => const CreateGoalScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/goals/summary',
        builder: (context, state) => const GoalSummaryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/goals/created',
        builder: (context, state) => const GoalCreatedScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/goals/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'goal_monthly_01';
          return GoalDetailsScreen(goalId: id);
        },
      ),

      // Deposit Flow (supports ?goalId=...)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/deposits/create',
        builder: (context, state) {
          final goalId = state.uri.queryParameters['goalId'];
          return MakeDepositScreen(initialGoalId: goalId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/deposits/success',
        builder: (context, state) {
          final amount =
              int.tryParse(state.uri.queryParameters['amount'] ?? '10000') ??
              10000;
          final goalName =
              state.uri.queryParameters['goalName'] ?? 'Monthly Njangi';
          final refCode = state.uri.queryParameters['ref'] ?? 'FP525A5D1';
          final goalId =
              state.uri.queryParameters['goalId'] ?? 'goal_monthly_01';
          return DepositSuccessfulScreen(
            amountFcfa: amount,
            goalName: goalName,
            fapshiReference: refCode,
            goalId: goalId,
          );
        },
      ),

      // Notifications
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
