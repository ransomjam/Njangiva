import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../core/widgets/primary_gradient_button.dart';
import '../home/home_dashboard_screen.dart';
import 'goals_controller.dart';

/// Goals Tab Screen listing all active and completed Njangi savings goals.
class GoalsListScreen extends ConsumerWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsControllerProvider);
    final visibleGoals = goalsState.visibleGoals;
    final textTheme = Theme.of(context).textTheme;

    return NjangiBackground(
      maxContentWidth: 680,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Njangi Goals',
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your progress toward every upcoming Njangi contribution.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              IconButton.filledTonal(
                onPressed: () => context.push('/goals/create'),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightBlue,
                  foregroundColor: AppColors.primaryBlue,
                ),
                icon: const Icon(PhosphorIcons.plusBold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (visibleGoals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    PhosphorIcons.target,
                    size: 46,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Njangi Savings Goals Yet',
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a savings goal and save gradually at your own pace.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            ...visibleGoals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: NjangiGoalListCard(
                  goal: goal,
                  hideBalances: goalsState.hideBalances,
                  onTap: () => context.push('/goals/${goal.id}'),
                ),
              ),
            ),

          const SizedBox(height: 14),
          PrimaryGradientButton(
            label: 'Create a Savings Goal',
            leadingIcon: PhosphorIcons.plusBold,
            onPressed: () => context.push('/goals/create'),
          ),
        ],
      ),
    );
  }
}
