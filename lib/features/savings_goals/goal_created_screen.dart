import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/savings_calculator_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../core/widgets/primary_gradient_button.dart';
import 'goals_controller.dart';

/// I. Goal Created Successfully Screen
///
/// Headline: "Goal Created!"
/// Description: "Your Njangi savings goal has been set up successfully."
/// Summary card: Goal name, Target amount, Due date, Savings duration, Lock status.
/// Actions: "Make First Deposit" and "View Goal".
class GoalCreatedScreen extends ConsumerWidget {
  const GoalCreatedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsControllerProvider);
    final calculator = ref.watch(savingsCalculatorServiceProvider);
    final textTheme = Theme.of(context).textTheme;

    final goal =
        (goalsState.lastCreatedGoalId != null
            ? goalsState.findById(goalsState.lastCreatedGoalId!)
            : null) ??
        goalsState.goals.first;

    final plan = calculator.calculatePlan(
      amountToSave: goal.targetAmount,
      dueDate: goal.dueDate,
    );

    return Scaffold(
      body: NjangiBackground(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Success Illustration with 3D Glossy Red Coin Stack & Check Badge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 108,
                  height: 108,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lightRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    AppConstants.coinStackAsset,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2.5),
                    ),
                    child: const Icon(
                      PhosphorIcons.checkBold,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Headline
            Text(
              'Goal Created!',
              textAlign: TextAlign.center,
              style: textTheme.displayMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Njangi savings goal has been set up successfully.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 26),

            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkNavy.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _SummaryDetailRow(label: 'Goal name', value: goal.name),
                  const Divider(height: 24),
                  _SummaryDetailRow(
                    label: 'Target amount',
                    value: AppFormatters.formatCurrency(goal.targetAmount),
                    highlightValue: true,
                  ),
                  const Divider(height: 24),
                  _SummaryDetailRow(
                    label: 'Due date',
                    value: AppFormatters.formatDate(goal.dueDate),
                  ),
                  const Divider(height: 24),
                  _SummaryDetailRow(
                    label: 'Savings duration',
                    value: '${plan.durationLabel} (${plan.remainingDays} days)',
                  ),
                  const Divider(height: 24),
                  _SummaryDetailRow(
                    label: 'Lock status',
                    value: goal.lockStatus.label,
                    isSuccessBadge: goal.lockStatus.isRestricted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Primary CTA: Make First Deposit
            PrimaryGradientButton(
              label: 'Make First Deposit',
              leadingIcon: PhosphorIcons.wallet,
              onPressed: () =>
                  context.push('/deposits/create?goalId=${goal.id}'),
            ),
            const SizedBox(height: 14),

            // Secondary CTA: View Goal
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => context.go('/goals/${goal.id}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.border, width: 1.4),
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'View Goal',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
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

class _SummaryDetailRow extends StatelessWidget {
  const _SummaryDetailRow({
    required this.label,
    required this.value,
    this.highlightValue = false,
    this.isSuccessBadge = false,
  });

  final String label;
  final String value;
  final bool highlightValue;
  final bool isSuccessBadge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
        ),
        if (isSuccessBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successGreenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$value ✓',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.successGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: highlightValue
                  ? AppColors.primaryBlue
                  : AppColors.darkNavy,
            ),
          ),
      ],
    );
  }
}
