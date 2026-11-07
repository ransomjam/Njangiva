import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/pricing_tier_service.dart';
import '../../models/savings_goal_model.dart';

/// Draft goal held in memory while navigating from Create Savings Goal (Screen G)
/// to Goal Summary (Screen H) and Goal Created (Screen I).
class GoalDraft {
  const GoalDraft({
    required this.name,
    required this.targetAmount,
    required this.dueDate,
    required this.lockSavings,
    required this.platformFee,
  });

  final String name;
  final int targetAmount;
  final DateTime dueDate;
  final bool lockSavings;
  final int platformFee;
}

class GoalsState {
  const GoalsState({
    required this.goals,
    this.isSampleDataMode = true,
    this.hideBalances = false,
    this.pendingDraft,
    this.lastCreatedGoalId,
  });

  final List<SavingsGoal> goals;
  final bool isSampleDataMode;
  final bool hideBalances;
  final GoalDraft? pendingDraft;
  final String? lastCreatedGoalId;

  /// Filters goals according to whether Sample Demo Mode is active or Live Account Mode.
  List<SavingsGoal> get visibleGoals {
    if (isSampleDataMode) return goals;
    return goals.where((g) => !g.isSampleData).toList();
  }

  /// Total verified savings across visible goals.
  int get totalSavingsFcfa =>
      visibleGoals.fold(0, (sum, g) => sum + g.amountSaved);

  /// Total locked balance across visible goals whose lock is enabled.
  int get lockedSavingsFcfa => visibleGoals
      .where((g) => g.lockStatus.isRestricted)
      .fold(0, (sum, g) => sum + g.amountSaved);

  /// Count of active / ready goals.
  int get activeGoalsCount => visibleGoals
      .where(
        (g) =>
            g.status == SavingsGoalStatus.active ||
            g.status == SavingsGoalStatus.completed,
      )
      .length;

  SavingsGoal? findById(String id) {
    for (final g in goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  GoalsState copyWith({
    List<SavingsGoal>? goals,
    bool? isSampleDataMode,
    bool? hideBalances,
    GoalDraft? pendingDraft,
    String? lastCreatedGoalId,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      isSampleDataMode: isSampleDataMode ?? this.isSampleDataMode,
      hideBalances: hideBalances ?? this.hideBalances,
      pendingDraft: pendingDraft ?? this.pendingDraft,
      lastCreatedGoalId: lastCreatedGoalId ?? this.lastCreatedGoalId,
    );
  }
}

class GoalsController extends StateNotifier<GoalsState> {
  GoalsController({required PricingTierService pricingService})
    : _pricingService = pricingService,
      super(GoalsState(goals: _buildInitialDemoGoals()));

  final PricingTierService _pricingService;

  static List<SavingsGoal> _buildInitialDemoGoals() {
    final now = DateTime.now();
    // Matches Njangiva Reference Design:
    // Total Savings: 180,000 FCFA | 3 Goals Active | 180,000 FCFA Locked for Njangi
    // 1. Monthly Njangi: Due in 3 weeks, 80,000 / 100,000 FCFA (80%)
    // 2. Small Njangi: Due in 1 week, 20,000 / 20,000 FCFA (Completed ✓)
    // 3. Family Njangi: Due in 4 weeks, 80,000 / 150,000 FCFA (53%)
    return [
      SavingsGoal(
        id: 'goal_monthly_01',
        name: 'Monthly Njangi',
        targetAmount: 100000,
        amountSaved: 80000,
        createdAt: now.subtract(const Duration(days: 30)),
        dueDate: now.add(const Duration(days: 21)),
        status: SavingsGoalStatus.active,
        lockStatus: SavingsLockStatus.locked,
        platformFee: 1500,
        isSampleData: true,
      ),
      SavingsGoal(
        id: 'goal_small_02',
        name: 'Small Njangi',
        targetAmount: 20000,
        amountSaved: 20000,
        createdAt: now.subtract(const Duration(days: 20)),
        dueDate: now.add(const Duration(days: 7)),
        status: SavingsGoalStatus.completed,
        lockStatus: SavingsLockStatus.locked,
        platformFee: 1000,
        isSampleData: true,
      ),
      SavingsGoal(
        id: 'goal_family_03',
        name: 'Family Njangi',
        targetAmount: 150000,
        amountSaved: 80000,
        createdAt: now.subtract(const Duration(days: 15)),
        dueDate: now.add(const Duration(days: 28)),
        status: SavingsGoalStatus.active,
        lockStatus: SavingsLockStatus.locked,
        platformFee: 1500,
        isSampleData: true,
      ),
    ];
  }

  void toggleHideBalances() {
    state = state.copyWith(hideBalances: !state.hideBalances);
  }

  void setSampleDataMode(bool enabled) {
    state = state.copyWith(isSampleDataMode: enabled);
  }

  void saveDraft({
    required String name,
    required int targetAmount,
    required DateTime dueDate,
    required bool lockSavings,
  }) {
    final fee = _pricingService.calculatePlatformFee(targetAmount);
    state = state.copyWith(
      pendingDraft: GoalDraft(
        name: name.trim(),
        targetAmount: targetAmount,
        dueDate: dueDate,
        lockSavings: lockSavings,
        platformFee: fee,
      ),
    );
  }

  /// Creates a new Njangi savings goal from the confirmed draft.
  SavingsGoal confirmAndCreateGoal() {
    final draft =
        state.pendingDraft ??
        GoalDraft(
          name: 'Monthly Njangi',
          targetAmount: 50000,
          dueDate: DateTime.now().add(const Duration(days: 90)),
          lockSavings: true,
          platformFee: _pricingService.calculatePlatformFee(50000),
        );

    final newGoal = SavingsGoal(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      name: draft.name,
      targetAmount: draft.targetAmount,
      amountSaved: 0,
      createdAt: DateTime.now(),
      dueDate: draft.dueDate,
      status: SavingsGoalStatus.active,
      lockStatus: draft.lockSavings
          ? SavingsLockStatus.locked
          : SavingsLockStatus.unlocked,
      platformFee: draft.platformFee,
      isSampleData: false,
    );

    state = state.copyWith(
      goals: [newGoal, ...state.goals],
      lastCreatedGoalId: newGoal.id,
    );
    return newGoal;
  }

  /// Credits a goal balance ONLY after a Fapshi deposit transaction is verified
  /// as `SUCCESSFUL`. Never counts pending or failed payments.
  void creditVerifiedDeposit({
    required String goalId,
    required int verifiedAmountFcfa,
  }) {
    if (verifiedAmountFcfa <= 0) return;

    final updated = state.goals.map((g) {
      if (g.id != goalId) return g;
      final newSaved = g.amountSaved + verifiedAmountFcfa;
      final isComplete = newSaved >= g.targetAmount;
      return g.copyWith(
        amountSaved: newSaved,
        status: isComplete
            ? SavingsGoalStatus.completed
            : SavingsGoalStatus.active,
      );
    }).toList();

    state = state.copyWith(goals: updated);
  }

  /// Processes an authorised payout release for a matured or flexible goal.
  void recordVerifiedPayout({
    required String goalId,
    required int payoutAmountFcfa,
  }) {
    final updated = state.goals.map((g) {
      if (g.id != goalId) return g;
      final remainingSaved = (g.amountSaved - payoutAmountFcfa).clamp(
        0,
        g.targetAmount * 10,
      );
      return g.copyWith(
        amountSaved: remainingSaved,
        status: remainingSaved == 0 ? SavingsGoalStatus.withdrawn : g.status,
        lockStatus: SavingsLockStatus.maturedUnlocked,
      );
    }).toList();

    state = state.copyWith(goals: updated);
  }
}

final goalsControllerProvider =
    StateNotifierProvider<GoalsController, GoalsState>((ref) {
      return GoalsController(
        pricingService: ref.watch(pricingTierServiceProvider),
      );
    });
