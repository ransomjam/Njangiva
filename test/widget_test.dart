import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:njangisave/app/theme/app_theme.dart';
import 'package:njangisave/core/services/pricing_tier_service.dart';
import 'package:njangisave/core/services/savings_calculator_service.dart';
import 'package:njangisave/core/services/savings_lock_service.dart';
import 'package:njangisave/features/home/home_dashboard_screen.dart';
import 'package:njangisave/features/onboarding/welcome_screen.dart';
import 'package:njangisave/features/savings_goals/create_goal_screen.dart';
import 'package:njangisave/features/savings_goals/goal_summary_screen.dart';
import 'package:njangisave/features/savings_goals/goals_controller.dart';
import 'package:njangisave/features/transactions/transactions_controller.dart';
import 'package:njangisave/models/savings_goal_model.dart';
import 'package:njangisave/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SavingsCalculatorService Unit Tests', () {
    const calculator = SavingsCalculatorService();

    test(
      'calculates remaining days, weeks, months and suggested savings plan accurately',
      () {
        final now = DateTime(2026, 9, 25);
        final dueDate = DateTime(2026, 12, 24); // 90 days later
        final plan = calculator.calculatePlan(
          amountToSave: 50000,
          dueDate: dueDate,
          referenceDate: now,
        );

        expect(plan.targetAmount, 50000);
        expect(plan.remainingDays, 90);
        expect(plan.remainingWeeks, closeTo(12.857, 0.01));
        // 50,000 / ~2.967 months -> ~16,853 FCFA
        expect(plan.monthlyAmount, greaterThan(16000));
        // 50,000 / 90 days = 555.55 -> ceil = 556 FCFA
        expect(plan.dailyAmount, 556);
      },
    );

    test('returns zero suggested amounts when amountToSave is zero', () {
      final plan = calculator.calculatePlan(
        amountToSave: 0,
        dueDate: DateTime(2026, 12, 25),
        referenceDate: DateTime(2026, 11, 1),
      );

      expect(plan.targetAmount, 0);
      expect(plan.dailyAmount, 0);
      expect(plan.weeklyAmount, 0);
      expect(plan.monthlyAmount, 0);
    });

    test('validates goal inputs properly', () {
      final now = DateTime(2026, 11, 4);
      final shortName = calculator.validateGoalInput(
        name: 'A',
        targetAmount: 50000,
        dueDate: DateTime(2026, 12, 25),
        now: now,
      );
      expect(shortName.isValid, isFalse);
      expect(shortName.nameError, isNotNull);

      final lowAmount = calculator.validateGoalInput(
        name: 'Monthly Njangi',
        targetAmount: 1000, // below 5,000 FCFA minimum
        dueDate: DateTime(2026, 12, 25),
        now: now,
      );
      expect(lowAmount.isValid, isFalse);
      expect(lowAmount.amountError, isNotNull);

      final pastDate = calculator.validateGoalInput(
        name: 'Monthly Njangi',
        targetAmount: 50000,
        dueDate: DateTime(2026, 11, 1), // in the past
        now: now,
      );
      expect(pastDate.isValid, isFalse);
      expect(pastDate.dateError, isNotNull);

      final valid = calculator.validateGoalInput(
        name: 'Monthly Njangi',
        targetAmount: 50000,
        dueDate: DateTime(2026, 12, 25),
        now: now,
      );
      expect(valid.isValid, isTrue);
    });
  });

  group('PricingTierService Unit Tests', () {
    test('calculates platform fee across all 4 default FCFA tiers', () {
      const service = PricingTierService();

      // Tier 1: 5,000 - 50,000 FCFA -> 1,000 FCFA
      expect(service.calculatePlatformFee(5000), 1000);
      expect(service.calculatePlatformFee(50000), 1000);

      // Tier 2: 50,001 - 150,000 FCFA -> 1,500 FCFA
      expect(service.calculatePlatformFee(50001), 1500);
      expect(service.calculatePlatformFee(100000), 1500);
      expect(service.calculatePlatformFee(150000), 1500);

      // Tier 3: 150,001 - 500,000 FCFA -> 2,500 FCFA
      expect(service.calculatePlatformFee(150001), 2500);
      expect(service.calculatePlatformFee(300000), 2500);
      expect(service.calculatePlatformFee(500000), 2500);

      // Tier 4: Above 500,000 FCFA -> 5,000 FCFA
      expect(service.calculatePlatformFee(500001), 5000);
      expect(service.calculatePlatformFee(1000000), 5000);
    });

    test(
      'supports configurable custom pricing tiers without hardcoded UI constants',
      () {
        const customService = PricingTierService(
          tiers: [
            PricingTier(
              minTargetFcfa: 5000,
              maxTargetFcfa: null,
              feeFcfa: 500,
              label: 'Promo Tier',
            ),
          ],
        );
        expect(customService.calculatePlatformFee(50000), 500);
      },
    );
  });

  group('SavingsLockService Unit Tests', () {
    const lockService = DefaultSavingsLockService();

    test(
      'enforces lock rules until contribution date and unlocks on maturity',
      () {
        final now = DateTime(2026, 11, 4);
        final lockedGoal = SavingsGoal(
          id: 'goal_test_1',
          name: 'Locked Njangi',
          targetAmount: 100000,
          amountSaved: 50000,
          platformFee: 1500,
          dueDate: DateTime(2026, 12, 25),
          createdAt: now,
          lockStatus: SavingsLockStatus.locked,
          status: SavingsGoalStatus.active,
        );

        final beforeMaturity = lockService.evaluateWithdrawal(
          lockedGoal,
          currentDate: now,
        );
        expect(beforeMaturity.canWithdrawNormally, isFalse);
        expect(beforeMaturity.canRequestEarlyRelease, isTrue);

        final onMaturityDate = lockService.evaluateWithdrawal(
          lockedGoal,
          currentDate: DateTime(2026, 12, 25),
        );
        expect(onMaturityDate.canWithdrawNormally, isTrue);
        expect(onMaturityDate.canRequestEarlyRelease, isFalse);
      },
    );
  });

  group('Fapshi Verification & Idempotency Tests', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'credits savings goal ONLY once when Fapshi status transitions to SUCCESSFUL (idempotent)',
      () async {
        final txCtrl = container.read(transactionsControllerProvider.notifier);

        final initialGoal = container
            .read(goalsControllerProvider)
            .findById('goal_monthly_01')!;
        final initialSaved = initialGoal.amountSaved;

        // 1. Record an initiated deposit (creates a PENDING transaction; balance must NOT change yet)
        final tx = txCtrl.recordInitiatedDeposit(
          goalId: initialGoal.id,
          goalName: initialGoal.name,
          amount: 10000,
          transId: 'FP99TEST01',
          externalId: 'ext-test-001',
          paymentMethod: 'MTN Mobile Money',
          payerPhone: '+237 670 12 34 56',
        );

        final afterInitiateGoal = container
            .read(goalsControllerProvider)
            .findById('goal_monthly_01')!;
        expect(tx.status, TransactionStatus.pending);
        expect(tx.credited, isFalse);
        expect(afterInitiateGoal.amountSaved, initialSaved);

        // 2. Verify payment as PENDING -> must NOT credit goal balance
        final pendingResult = await txCtrl.verifyTransaction(
          tx.reference,
          simulatedSandboxOutcome: TransactionStatus.pending,
        );
        final afterPendingGoal = container
            .read(goalsControllerProvider)
            .findById('goal_monthly_01')!;
        expect(pendingResult.status, TransactionStatus.pending);
        expect(afterPendingGoal.amountSaved, initialSaved);

        // 3. Verify payment as SUCCESSFUL -> credits 10,000 FCFA once
        final verifiedFirst = await txCtrl.verifyTransaction(
          tx.reference,
          simulatedSandboxOutcome: TransactionStatus.successful,
        );
        final afterFirstVerifyGoal = container
            .read(goalsControllerProvider)
            .findById('goal_monthly_01')!;
        expect(verifiedFirst.status, TransactionStatus.successful);
        expect(afterFirstVerifyGoal.amountSaved, initialSaved + 10000);

        // 4. Replay verification / webhook for the exact same transaction -> must NOT double-credit
        final verifiedSecond = await txCtrl.verifyTransaction(
          tx.reference,
          simulatedSandboxOutcome: TransactionStatus.successful,
        );
        final afterSecondVerifyGoal = container
            .read(goalsControllerProvider)
            .findById('goal_monthly_01')!;
        expect(verifiedSecond.status, TransactionStatus.successful);
        expect(afterSecondVerifyGoal.amountSaved, initialSaved + 10000);
      },
    );
  });

  group('Widget & Screen Tests', () {
    testWidgets(
      'WelcomeScreen renders branding, headline, feature badges and CTA buttons',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const WelcomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Prepare for your Njangi', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Get Started'), findsOneWidget);
        expect(find.text('I already have an account'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Plan'), findsOneWidget);
        expect(find.text('Stay safe'), findsOneWidget);
      },
    );

    testWidgets(
      'CreateGoalScreen renders fields, lock switch and live savings preview',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CreateGoalScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Goal name'), findsOneWidget);
        expect(find.text('Contribution amount'), findsOneWidget);
        expect(find.text('Lock my savings'), findsOneWidget);
        expect(find.text('Create Goal'), findsOneWidget);
      },
    );

    testWidgets(
      'GoalSummaryScreen displays contribution amount separately from platform fee',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const GoalSummaryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Goal Summary'), findsOneWidget);
        expect(find.text('Suggested savings plan'), findsOneWidget);
        expect(find.text('Savings lock'), findsOneWidget);
        expect(find.text('Platform fee'), findsOneWidget);
        expect(find.text('Confirm Goal'), findsOneWidget);
      },
    );

    testWidgets(
      'HomeDashboardScreen renders Njangiva branding, demo banner, 180,000 FCFA total savings, quick actions and goals',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: HomeDashboardScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Njangiva'), findsOneWidget);
        expect(find.text('Save. Prepare. Contribute.'), findsOneWidget);
        expect(find.text("You're in demonstration mode"), findsOneWidget);
        expect(find.text('Explore Njangiva with sample data'), findsOneWidget);
        expect(find.text('Switch to Live'), findsOneWidget);
        expect(find.text('Total Savings'), findsOneWidget);
        expect(find.text('180,000 FCFA'), findsOneWidget);
        expect(find.text('New Goal'), findsOneWidget);
        expect(find.text('Deposit'), findsOneWidget);
        expect(find.text('Withdraw'), findsOneWidget);
        expect(find.text('History'), findsOneWidget);
        expect(find.text('My Njangi Goals'), findsOneWidget);
        expect(find.text('Monthly Njangi'), findsOneWidget);
        expect(find.text('Small Njangi'), findsOneWidget);
        expect(find.text('Family Njangi'), findsOneWidget);
        expect(find.text('80%'), findsOneWidget);
        expect(find.text('53%'), findsOneWidget);
      },
    );
  });
}
