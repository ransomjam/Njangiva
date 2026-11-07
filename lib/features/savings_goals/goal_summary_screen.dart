import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/services/pricing_tier_service.dart';
import '../../core/services/savings_calculator_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/njangi_logo.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../core/widgets/primary_gradient_button.dart';
import 'goals_controller.dart';

/// H. Goal Summary Screen (Matches Reference Image 5 closely)
///
/// Displays:
/// - Goal name & "Contribution goal" header card
/// - Contribution amount & Due date + remaining duration
/// - Suggested savings plan (per month, per week, per day)
/// - Savings lock status ("Enabled ✓" pill badge)
/// - Platform fee (calculated by PricingTierService, displayed separately)
/// - Actions: "Confirm Goal ->" and "Edit Details"
class GoalSummaryScreen extends ConsumerWidget {
  const GoalSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsControllerProvider);
    final calculator = ref.watch(savingsCalculatorServiceProvider);
    final pricingService = ref.watch(pricingTierServiceProvider);
    final textTheme = Theme.of(context).textTheme;

    final draft =
        goalsState.pendingDraft ??
        GoalDraft(
          name: 'Monthly Njangi',
          targetAmount: 50000,
          dueDate: DateTime(2026, 12, 25),
          lockSavings: true,
          platformFee: pricingService.calculatePlatformFee(50000),
        );

    final plan = calculator.calculatePlan(
      amountToSave: draft.targetAmount,
      dueDate: draft.dueDate,
    );
    final feeTier = pricingService.resolveTier(draft.targetAmount);

    return Scaffold(
      body: NjangiBackground(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar: Back button + Centered "Goal Summary" title
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: NjangiBackButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/goals/create');
                      }
                    },
                  ),
                ),
                Text(
                  'Goal Summary',
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 1. Header Card: Goal name + "Contribution goal"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.softBlueCardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.9),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIcons.usersThreeFill,
                      color: AppColors.primaryBlue,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.name,
                          style: textTheme.headlineLarge?.copyWith(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Contribution goal',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Contribution amount & Due date card (Matches Image 5)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Left: Contribution amount
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Contribution amount',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${AppFormatters.formatNumber(draft.targetAmount)} ',
                                  style: textTheme.displaySmall?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                                TextSpan(
                                  text: 'FCFA',
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: AppColors.border,
                    ),
                    // Right: Due date
                    Expanded(
                      flex: 5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              PhosphorIcons.calendarBlank,
                              color: AppColors.primaryBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Due date',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  AppFormatters.formatDate(draft.dueDate),
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '(in ${plan.durationLabel})',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Suggested savings plan Card (3 columns: per month, per week, per day)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(19),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          PhosphorIcons.target,
                          color: AppColors.primaryBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Suggested savings plan',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _SuggestedPlanColumn(
                              amount: plan.monthlyAmount,
                              periodLabel: 'per month',
                            ),
                          ),
                          Container(width: 1, color: AppColors.border),
                          Expanded(
                            child: _SuggestedPlanColumn(
                              amount: plan.weeklyAmount,
                              periodLabel: 'per week',
                            ),
                          ),
                          Container(width: 1, color: AppColors.border),
                          Expanded(
                            child: _SuggestedPlanColumn(
                              amount: plan.dailyAmount,
                              periodLabel: 'per day',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Savings lock status Card (Matches Image 5)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      PhosphorIcons.lock,
                      color: AppColors.primaryBlue,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savings lock',
                          style: textTheme.headlineSmall?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          draft.lockSavings
                              ? 'Your money will be locked until the due date.'
                              : 'Flexible mode: funds can be withdrawn anytime.',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: draft.lockSavings
                          ? AppColors.successGreenLight
                          : AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          draft.lockSavings ? 'Enabled' : 'Flexible',
                          style: textTheme.labelSmall?.copyWith(
                            color: draft.lockSavings
                                ? AppColors.successGreen
                                : AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (draft.lockSavings) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            PhosphorIcons.checkBold,
                            size: 12,
                            color: AppColors.successGreen,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Platform fee Card (Configurable PricingTierService, separate from target)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.softBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      PhosphorIcons.coins,
                      color: AppColors.secondaryText,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform fee',
                          style: textTheme.headlineSmall?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Service fee (${feeTier.label}) • Never deducted from savings',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppFormatters.formatCurrency(draft.platformFee),
                    style: textTheme.headlineSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Confirm Goal Button
            PrimaryGradientButton(
              label: 'Confirm Goal',
              showTrailingArrow: true,
              onPressed: () {
                ref
                    .read(goalsControllerProvider.notifier)
                    .confirmAndCreateGoal();
                context.go('/goals/created');
              },
            ),
            const SizedBox(height: 10),

            // Edit Details Action
            Center(
              child: TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/goals/create');
                  }
                },
                child: Text(
                  'Edit Details',
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

class _SuggestedPlanColumn extends StatelessWidget {
  const _SuggestedPlanColumn({required this.amount, required this.periodLabel});

  final int amount;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            PhosphorIcons.calendarBlank,
            color: AppColors.primaryBlue,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.formatCurrency(amount),
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            periodLabel,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
