import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/njangi_logo.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../core/widgets/primary_gradient_button.dart';

/// A. Welcome Screen
///
/// Features Njangiva branding, the 3D Glossy Red Logo Coin Stack hero
/// illustration with floating Njangi feature badges, three feature indicators
/// (Save, Plan, Stay safe), and actions for "Get Started" and "I already have an account".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: NjangiBackground(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Branding Header with Njangiva Ribbon Symbol
            const NjangiHeroBadge(size: 74, iconSize: 44),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                children: const [
                  TextSpan(
                    text: 'Njangi',
                    style: TextStyle(color: AppColors.darkNavy),
                  ),
                  TextSpan(
                    text: 'va',
                    style: TextStyle(color: AppColors.primaryRed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppConstants.tagline,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Main Illustration: 3D Glossy Red Coin Stack, Calendar, Shield & Njangi Group
            const _WelcomeHeroIllustration(),
            const SizedBox(height: 28),

            // Headline
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: textTheme.displayMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                children: const [
                  TextSpan(
                    text: 'Prepare for your ',
                    style: TextStyle(color: AppColors.darkNavy),
                  ),
                  TextSpan(
                    text: 'Njangi',
                    style: TextStyle(color: AppColors.primaryRed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Save gradually and be ready when it's time to contribute.",
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Three small feature indicators: Save • Plan • Stay safe
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Expanded(
                  child: _FeatureIndicatorPill(
                    icon: PhosphorIcons.piggyBank,
                    label: 'Save',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _FeatureIndicatorPill(
                    icon: PhosphorIcons.calendarCheck,
                    label: 'Plan',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _FeatureIndicatorPill(
                    icon: PhosphorIcons.shieldCheck,
                    label: 'Stay safe',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Primary Action: Get Started
            PrimaryGradientButton(
              label: 'Get Started',
              showTrailingArrow: true,
              onPressed: () => context.push('/onboarding'),
            ),
            const SizedBox(height: 14),

            // Secondary Action: I already have an account
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => context.push('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: const BorderSide(color: AppColors.border, width: 1.4),
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'I already have an account',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeroIllustration extends StatelessWidget {
  const _WelcomeHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDECEF), Color(0xFFFFF8F9)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Central 3D Glossy Red Logo Coin Stack showcase
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              gradient: AppColors.totalSavingsCardGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Center(
              child: Image.asset(
                AppConstants.coinStackAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Top-left floating Calendar badge
          const Positioned(
            top: 0,
            left: 14,
            child: _FloatingIllustrationBadge(
              icon: PhosphorIcons.calendarCheck,
              iconColor: AppColors.primaryRed,
              label: 'Due Date',
            ),
          ),

          // Top-right floating Coins badge
          const Positioned(
            top: 4,
            right: 12,
            child: _FloatingIllustrationBadge(
              icon: PhosphorIcons.coinsFill,
              iconColor: AppColors.brightRed,
              label: 'FCFA Coins',
            ),
          ),

          // Bottom-right floating Security Shield badge
          const Positioned(
            bottom: 0,
            right: 18,
            child: _FloatingIllustrationBadge(
              icon: PhosphorIcons.shieldCheckFill,
              iconColor: AppColors.successGreen,
              label: 'Locked Safe',
            ),
          ),

          // Bottom-left floating Njangi Group badge
          const Positioned(
            bottom: 2,
            left: 18,
            child: _FloatingIllustrationBadge(
              icon: PhosphorIcons.usersThreeFill,
              iconColor: AppColors.deepRed,
              label: 'Njangi Ready',
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIllustrationBadge extends StatelessWidget {
  const _FloatingIllustrationBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.darkNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureIndicatorPill extends StatelessWidget {
  const _FeatureIndicatorPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lightRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: AppColors.primaryRed),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }
}
