import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/storage/local_cache_service.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/njangi_logo.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../core/widgets/primary_gradient_button.dart';

/// B & C. Onboarding Screens 1 and 2
///
/// - Page 1: "Save for your Njangi contributions" with 3 feature rows:
///   1. Set your goal.
///   2. Save at your pace.
///   3. Keep your money secure.
/// - Page 2: "Your money, ready when it's time" with process illustration:
///   Set goal → Save gradually → Use for your Njangi.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_currentPage < 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(localCacheServiceProvider).setOnboardingCompleted(true);
    if (mounted) {
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: NjangiBackground(
        scrollable: false,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          children: [
            // Top bar with Back and Skip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NjangiBackButton(
                  onPressed: () {
                    if (_currentPage > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                      );
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/welcome');
                    }
                  },
                ),
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: const [
                  SingleChildScrollView(child: _OnboardingPageOne()),
                  SingleChildScrollView(child: _OnboardingPageTwo()),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                final isSelected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),

            // Next / Get Started CTA
            PrimaryGradientButton(
              label: _currentPage == 0 ? 'Next' : 'Get Started',
              showTrailingArrow: true,
              onPressed: _handleNext,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// B. Onboarding Screen 1
class _OnboardingPageOne extends StatelessWidget {
  const _OnboardingPageOne();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 8),
        const NjangiHeroBadge(size: 74, iconSize: 38),
        const SizedBox(height: 22),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: textTheme.displaySmall?.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
            children: const [
              TextSpan(
                text: 'Save for your ',
                style: TextStyle(color: AppColors.darkNavy),
              ),
              TextSpan(
                text: 'Njangi contributions',
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Set a target, save gradually, and be ready when it's time to contribute.",
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 28),
        const _OnboardingFeatureRow(
          icon: PhosphorIcons.target,
          title: 'Set your goal.',
          subtitle:
              'Enter your Njangi contribution amount and deadline in FCFA.',
        ),
        const SizedBox(height: 14),
        const _OnboardingFeatureRow(
          icon: PhosphorIcons.handCoins,
          title: 'Save at your pace.',
          subtitle:
              'Deposit smaller amounts daily, weekly, or whenever you have cash.',
        ),
        const SizedBox(height: 14),
        const _OnboardingFeatureRow(
          icon: PhosphorIcons.lockKey,
          title: 'Keep your money secure.',
          subtitle:
              'Restrict withdrawals until your Njangi due date so you stay disciplined.',
        ),
      ],
    );
  }
}

/// C. Onboarding Screen 2
class _OnboardingPageTwo extends StatelessWidget {
  const _OnboardingPageTwo();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 8),
        NjangiHeroBadge(
          size: 74,
          customChild: const Icon(
            PhosphorIcons.shieldCheckFill,
            size: 38,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 22),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: textTheme.displaySmall?.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
            children: const [
              TextSpan(
                text: 'Your money, ',
                style: TextStyle(color: AppColors.darkNavy),
              ),
              TextSpan(
                text: "ready when it's time",
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your savings stay locked until your Njangi contribution date, then you can use it for your payment.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 28),

        // Process illustration: Set goal → Save gradually → Use for your Njangi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            children: [
              _ProcessStepRow(
                stepNumber: '1',
                icon: PhosphorIcons.target,
                title: 'Set goal',
                subtitle: 'Choose your contribution target & due date.',
                accentColor: AppColors.primaryBlue,
                showConnectorDown: true,
              ),
              _ProcessStepRow(
                stepNumber: '2',
                icon: PhosphorIcons.coins,
                title: 'Save gradually',
                subtitle: 'Deposit via MTN MoMo or Orange Money via Fapshi.',
                accentColor: AppColors.cyan,
                showConnectorDown: true,
              ),
              _ProcessStepRow(
                stepNumber: '3',
                icon: PhosphorIcons.checkCircleFill,
                title: 'Use for your Njangi',
                subtitle:
                    'Funds unlock on your contribution date ready for payout.',
                accentColor: AppColors.successGreen,
                showConnectorDown: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingFeatureRow extends StatelessWidget {
  const _OnboardingFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessStepRow extends StatelessWidget {
  const _ProcessStepRow({
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.showConnectorDown,
  });

  final String stepNumber;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool showConnectorDown;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              if (showConnectorDown)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnectorDown ? 18 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Step $stepNumber',
                          style: textTheme.labelSmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
