import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/savings_lock_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/njangi_logo.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../models/savings_goal_model.dart';
import '../notifications/notifications_controller.dart';
import '../savings_goals/goals_controller.dart';

/// Home Dashboard matching the Njangiva reference UI end-to-end:
/// - Header: Njangiva ribbon logo + "Njangiva / Save. Prepare. Contribute." +
///   Notifications squircle (with red unread dot) + Profile squircle
/// - Demonstration Mode Banner with "Switch to Live" pink pill button
/// - Total Savings Card: Total savings (180,000 FCFA), Eye visibility toggle,
///   3D Glossy Red Logo Coin Stack illustration, Active goals count (3 Goals Active),
///   and Locked balance (180,000 FCFA Locked for Njangi)
/// - Quick Actions: New Goal (red gradient card), Deposit, Withdraw, History
/// - My Njangi Goals section with "View All >", crimson gradient progress bars,
///   percentage labels, and red completion check badges.
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  void _showWithdrawSheet(
    BuildContext context,
    WidgetRef ref,
    List<SavingsGoal> goals,
  ) {
    final lockService = ref.read(savingsLockServiceProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Withdraw / Release Njangi Funds',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(PhosphorIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Committed Njangi funds remain restricted until their contribution date. Select a goal below to check payout eligibility:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (goals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No savings goals available yet.'),
                  )
                else
                  ...goals.take(4).map((g) {
                    final eval = lockService.evaluateWithdrawal(g);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.softBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            eval.canWithdrawNormally
                                ? PhosphorIcons.lockOpen
                                : PhosphorIcons.lockKey,
                            color: eval.canWithdrawNormally
                                ? AppColors.successGreen
                                : AppColors.primaryRed,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${AppFormatters.formatCurrency(g.amountSaved)} • ${eval.statusTitle}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              context.push('/goals/${g.id}');
                            },
                            child: const Text('Inspect'),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsControllerProvider);
    final notifications = ref.watch(notificationsControllerProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final visibleGoals = goalsState.visibleGoals;
    final textTheme = Theme.of(context).textTheme;

    return NjangiBackground(
      maxContentWidth: 680,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header: Njangiva Brand Logo + Notifications Squircle + Profile Squircle
          Row(
            children: [
              const NjangiBrandHeader(fontSize: 25, badgeSize: 52),
              const Spacer(),
              // Notifications Squircle Button with red unread dot
              _HeaderSquircleAction(
                icon: PhosphorIcons.bell,
                showBadge: unreadCount > 0,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: 10),
              // Profile Avatar Squircle Button
              _HeaderSquircleAction(
                icon: PhosphorIcons.userFill,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Demonstration Mode Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFEF3F4), Color(0xFFFCEBEC)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF7D8DC)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  PhosphorIcons.info,
                  size: 22,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goalsState.isSampleDataMode
                            ? "You're in demonstration mode"
                            : "You're in live account mode",
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 13.5,
                          color: AppColors.darkNavy,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goalsState.isSampleDataMode
                            ? 'Explore Njangiva with sample data'
                            : 'Showing verified live account goals only',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(goalsControllerProvider.notifier)
                          .setSampleDataMode(!goalsState.isSampleDataMode);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softPinkPill,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        goalsState.isSampleDataMode
                            ? 'Switch to Live'
                            : 'Show Demo Data',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xFFA61022),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Total Savings Hero Card with 3D Glossy Red Logo Coin Stack
          _TotalSavingsHeroCard(
            totalSavings: goalsState.totalSavingsFcfa,
            activeGoalsCount: goalsState.activeGoalsCount,
            lockedSavings: goalsState.lockedSavingsFcfa,
            hideBalances: goalsState.hideBalances,
            onToggleVisibility: () =>
                ref.read(goalsControllerProvider.notifier).toggleHideBalances(),
          ),
          const SizedBox(height: 18),

          // 4. Quick Actions Row: New Goal, Deposit, Withdraw, History
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  label: 'New Goal',
                  icon: PhosphorIcons.plusBold,
                  onTap: () => context.push('/goals/create'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  label: 'Deposit',
                  icon: PhosphorIcons.wallet,
                  onTap: () => context.push('/deposits/create'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  label: 'Withdraw',
                  icon: PhosphorIcons.uploadSimple,
                  onTap: () => _showWithdrawSheet(context, ref, visibleGoals),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  label: 'History',
                  icon: PhosphorIcons.clock,
                  onTap: () => context.go('/transactions'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 5. "My Njangi Goals" Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Njangi Goals',
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                  letterSpacing: -0.3,
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/goals'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 14.5,
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        PhosphorIcons.caretRightBold,
                        size: 14,
                        color: AppColors.primaryRed,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 6. Goal Cards List
          if (visibleGoals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    PhosphorIcons.target,
                    size: 40,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No active Njangi goals yet',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create your first savings goal to prepare for your next Njangi contribution.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            ...visibleGoals
                .take(3)
                .map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NjangiGoalListCard(
                      goal: goal,
                      hideBalances: goalsState.hideBalances,
                      onTap: () => context.push('/goals/${goal.id}'),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _HeaderSquircleAction extends StatelessWidget {
  const _HeaderSquircleAction({
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 21,
                color: AppColors.darkNavy,
              ),
              if (showBadge)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 8.5,
                    height: 8.5,
                    decoration: BoxDecoration(
                      color: AppColors.brightRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalSavingsHeroCard extends StatelessWidget {
  const _TotalSavingsHeroCard({
    required this.totalSavings,
    required this.activeGoalsCount,
    required this.lockedSavings,
    required this.hideBalances,
    required this.onToggleVisibility,
  });

  final int totalSavings;
  final int activeGoalsCount;
  final int lockedSavings;
  final bool hideBalances;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.totalSavingsCardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.34),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Internal decorative 3D crimson wave overlay
            Positioned.fill(
              child: CustomPaint(painter: _SavingsCardWavePainter()),
            ),
            // 3D Glossy Red Logo Coin Stack positioned on the right above the divider
            Positioned(
              right: 8,
              top: 32,
              child: IgnorePointer(
                child: Image.asset(
                  AppConstants.coinStackAsset,
                  width: 140,
                  height: 95,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Savings',
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 15.5,
                          color: AppColors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onToggleVisibility,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              hideBalances
                                  ? PhosphorIcons.eyeSlash
                                  : PhosphorIcons.eye,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 120),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: hideBalances
                                  ? '•••••• '
                                  : '${AppFormatters.formatNumber(totalSavings)} ',
                              style: textTheme.displayLarge?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                                letterSpacing: -0.8,
                              ),
                            ),
                            TextSpan(
                              text: 'FCFA',
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Subtle horizontal divider with warm highlight under coin stack
                  Container(
                    height: 1,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.white.withValues(alpha: 0.14),
                          AppColors.white.withValues(alpha: 0.24),
                          AppColors.white.withValues(alpha: 0.45),
                          AppColors.white.withValues(alpha: 0.18),
                        ],
                        stops: const [0.0, 0.5, 0.78, 1.0],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Bottom metrics row inside card
                  Row(
                    children: [
                      // Left: 3 Goals Active
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              PhosphorIcons.target,
                              color: AppColors.white,
                              size: 27,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$activeGoalsCount ${activeGoalsCount == 1 ? 'Goal' : 'Goals'}',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontSize: 15,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Active',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 12.5,
                                    color: AppColors.white.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: AppColors.white.withValues(alpha: 0.22),
                      ),
                      const SizedBox(width: 16),
                      // Right: 180,000 FCFA Locked for Njangi
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              PhosphorIcons.lock,
                              color: AppColors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hideBalances
                                        ? '•••••• FCFA'
                                        : AppFormatters.formatCurrency(
                                            lockedSavings,
                                          ),
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontSize: 15,
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Locked for Njangi',
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: 12.5,
                                      color: AppColors.white.withValues(
                                        alpha: 0.85,
                                      ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsCardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left bright crimson glow
    final topWave = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.65, 0)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.36,
        0,
        size.height * 0.48,
      )
      ..close();

    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE61A30).withValues(alpha: 0.45),
          const Color(0xFFB80A1D).withValues(alpha: 0.05),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(topWave, topPaint);

    // Center-right sweeping dark ruby curve
    final midWave = Path()
      ..moveTo(size.width * 0.35, 0)
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.35,
        size.width,
        size.height * 0.18,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.35,
        size.width * 0.35,
        0,
      )
      ..close();

    final midPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF800310).withValues(alpha: 0.35),
          const Color(0xFF5E010B).withValues(alpha: 0.50),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(midWave, midPaint);

    // Bottom-right bright crimson swoosh
    final bottomRightSwoosh = Path()
      ..moveTo(size.width * 0.62, size.height)
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.76,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..close();

    final bottomRightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE6182F).withValues(alpha: 0.35),
          const Color(0xFFB3081A).withValues(alpha: 0.20),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(bottomRightSwoosh, bottomRightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkNavy.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primaryRed, size: 25),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable Savings Goal Card matching the Njangiva reference UI:
/// - Soft pink squircle icon box on the left with crimson group icon
/// - Goal title on top (with red check circle at top-right if completed)
/// - Calendar icon + relative due date on left, bold saved / target amount + chevron on right
/// - Crimson gradient progress bar at the bottom + bold percentage text on the right
class NjangiGoalListCard extends StatelessWidget {
  const NjangiGoalListCard({
    super.key,
    required this.goal,
    required this.onTap,
    this.hideBalances = false,
  });

  final SavingsGoal goal;
  final VoidCallback onTap;
  final bool hideBalances;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isCompleted = goal.isTargetReached;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkNavy.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left rounded blush-pink group icon container
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.lightRed,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      PhosphorIcons.usersThreeFill,
                      color: AppColors.primaryRed,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),

                  // Center & Right details + progress bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Goal Name + Completed Red Check Badge (if completed)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                goal.name,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  PhosphorIcons.checkBold,
                                  color: AppColors.white,
                                  size: 13,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Row 2: Due date + Saved / Target FCFA + Right Chevron
                        Row(
                          children: [
                            const Icon(
                              PhosphorIcons.calendarBlank,
                              size: 14,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                AppFormatters.formatDueRelative(goal.dueDate),
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12.5,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: hideBalances
                                        ? '••••'
                                        : AppFormatters.formatNumber(
                                            goal.amountSaved,
                                          ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                  TextSpan(
                                    text: hideBalances
                                        ? ' / •••• FCFA'
                                        : ' / ${AppFormatters.formatCurrency(goal.targetAmount)}',
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              PhosphorIcons.caretRightBold,
                              color: AppColors.secondaryText,
                              size: 13,
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),

                        // Row 3: Crimson Gradient Progress Bar + Percentage text
                        Row(
                          children: [
                            Expanded(
                              child: _CrimsonProgressBar(
                                progress: goal.progress,
                              ),
                            ),
                            if (!isCompleted) ...[
                              const SizedBox(width: 10),
                              Text(
                                '${goal.progressPercent}%',
                                style: textTheme.labelMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrimsonProgressBar extends StatelessWidget {
  const _CrimsonProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return Container(
      height: 8.5,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.progressBarGradient,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
