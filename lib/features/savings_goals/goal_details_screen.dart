import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/fapshi_payment_service.dart';
import '../../core/services/platform_file_service.dart';
import '../../core/services/savings_calculator_service.dart';
import '../../core/services/savings_lock_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/njangi_logo.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../core/widgets/primary_gradient_button.dart';
import '../../models/savings_goal_model.dart';
import '../../models/transaction_model.dart';
import '../authentication/auth_controller.dart';
import '../transactions/transactions_controller.dart';
import 'goals_controller.dart';

/// J. Goal Details Screen
///
/// Displays:
/// - Goal name, Target amount, Amount saved, Remaining amount, Progress %
/// - Due date, Savings duration, Lock status, Suggested savings plan
/// - Deposit activity list (verified vs pending Fapshi transactions)
/// - Prominent "Deposit" button, Authorised Fapshi Payout action when eligible,
///   and cross-platform Statement Download (`Uint8List` bytes).
class GoalDetailsScreen extends ConsumerWidget {
  const GoalDetailsScreen({super.key, required this.goalId});

  final String goalId;

  Future<void> _handleExportStatement(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
    List<NjangiTransaction> transactions,
  ) async {
    final fileService = ref.read(platformFileServiceProvider);
    final ok = await fileService.exportGoalStatement(
      goal: goal,
      transactions: transactions,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Statement exported for "${goal.name}".'
              : 'Prepared statement bytes for "${goal.name}".',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Future<void> _handlePayoutRelease(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) async {
    final userPhone =
        ref.read(authControllerProvider).user?.phoneNumber ??
        '+237 6 70 12 34 56';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release Njangi Savings via Fapshi'),
        content: Text(
          'Send ${AppFormatters.formatCurrency(goal.amountSaved)} from "${goal.name}" to your verified Mobile Money account ($userPhone)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Payout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(transactionsControllerProvider.notifier)
        .executeAuthorisedPayout(
          goalId: goal.id,
          goalName: goal.name,
          amountFcfa: goal.amountSaved,
          recipientPhone: userPhone,
          medium: FapshiPaymentMedium.mtnMomo,
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ??
              'Fapshi payout (${result.transId}) status: ${result.status.fapshiStatusCode}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success
            ? AppColors.successGreen
            : AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsControllerProvider);
    final goal = goalsState.findById(goalId) ?? goalsState.goals.first;
    final goalTransactions = ref
        .watch(transactionsControllerProvider)
        .forGoal(goal.id);
    final calculator = ref.watch(savingsCalculatorServiceProvider);
    final lockService = ref.watch(savingsLockServiceProvider);

    final plan = calculator.calculatePlan(
      amountToSave: goal.remainingAmount > 0
          ? goal.remainingAmount
          : goal.targetAmount,
      dueDate: goal.dueDate,
    );
    final withdrawalEval = lockService.evaluateWithdrawal(goal);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: NjangiBackground(
        maxContentWidth: 640,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NjangiBackButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                Text(
                  'Goal Details',
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: 'Export Statement',
                  onPressed: () => _handleExportStatement(
                    context,
                    ref,
                    goal,
                    goalTransactions,
                  ),
                  icon: const Icon(
                    PhosphorIcons.downloadSimple,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero Progress Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.totalSavingsCardGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned(
                      right: -6,
                      top: 6,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.24,
                          child: Image.asset(
                            AppConstants.coinStackAsset,
                            width: 120,
                            height: 84,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  PhosphorIcons.usersThreeFill,
                                  color: AppColors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.name,
                                      style: textTheme.headlineLarge?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Due ${AppFormatters.formatDate(goal.dueDate)} • ${plan.durationLabel}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.white.withValues(
                                          alpha: 0.88,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(
                                    alpha: 0.22,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '${goal.progressPercent}%',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: goal.progress,
                              minHeight: 10,
                              backgroundColor: AppColors.white.withValues(
                                alpha: 0.25,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _WhiteMetricColumn(
                                label: 'Amount Saved',
                                value: AppFormatters.formatCurrency(
                                  goal.amountSaved,
                                ),
                              ),
                              _WhiteMetricColumn(
                                label: 'Remaining',
                                value: AppFormatters.formatCurrency(
                                  goal.remainingAmount,
                                ),
                              ),
                              _WhiteMetricColumn(
                                label: 'Target Amount',
                                value: AppFormatters.formatCurrency(
                                  goal.targetAmount,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lock Status & Withdrawal Eligibility Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        goal.lockStatus.isRestricted
                            ? PhosphorIcons.lockKeyFill
                            : PhosphorIcons.lockOpen,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          withdrawalEval.statusTitle,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: goal.lockStatus.isRestricted
                              ? AppColors.successGreenLight
                              : AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          goal.lockStatus.label,
                          style: textTheme.labelSmall?.copyWith(
                            color: goal.lockStatus.isRestricted
                                ? AppColors.successGreen
                                : AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    withdrawalEval.explanation,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (withdrawalEval.canWithdrawNormally &&
                      goal.amountSaved > 0) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _handlePayoutRelease(context, ref, goal),
                        icon: const Icon(PhosphorIcons.uploadSimple, size: 18),
                        label: Text(
                          'Release ${AppFormatters.formatCurrency(goal.amountSaved)} via Fapshi Payout',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Suggested Savings Plan for Remaining Balance
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        PhosphorIcons.target,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Suggested Savings Plan (${plan.remainingDays} days left)',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PlanGuideBadge(
                        label: 'Per Month',
                        amount: plan.monthlyAmount,
                      ),
                      _PlanGuideBadge(
                        label: 'Per Week',
                        amount: plan.weeklyAmount,
                      ),
                      _PlanGuideBadge(
                        label: 'Per Day',
                        amount: plan.dailyAmount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Deposit Button
            PrimaryGradientButton(
              label: 'Deposit Toward ${goal.name}',
              leadingIcon: PhosphorIcons.wallet,
              onPressed: () =>
                  context.push('/deposits/create?goalId=${goal.id}'),
            ),
            const SizedBox(height: 24),

            // Deposit Activity History
            Text(
              'Deposit & Transaction Activity',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (goalTransactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'No deposits yet for this goal. Tap Deposit above to make your first contribution via Fapshi.',
                  style: textTheme.bodyMedium,
                ),
              )
            else
              ...goalTransactions.map(
                (tx) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tx.status == TransactionStatus.successful
                              ? AppColors.successGreenLight
                              : AppColors.warningAmberLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tx.type == TransactionType.withdrawal
                              ? PhosphorIcons.uploadSimple
                              : PhosphorIcons.arrowDownLeft,
                          color: tx.status == TransactionStatus.successful
                              ? AppColors.successGreen
                              : AppColors.warningAmber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tx.type.label} (${tx.paymentMethod})',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Ref: ${tx.reference} • ${AppFormatters.formatDateTime(tx.createdAt)}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.formatCurrency(tx.amount),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          Text(
                            tx.status.label,
                            style: textTheme.labelSmall?.copyWith(
                              color: tx.status == TransactionStatus.successful
                                  ? AppColors.successGreen
                                  : AppColors.warningAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WhiteMetricColumn extends StatelessWidget {
  const _WhiteMetricColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlanGuideBadge extends StatelessWidget {
  const _PlanGuideBadge({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          AppFormatters.formatCurrency(amount),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}
