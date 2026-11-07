import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../constants/app_constants.dart';
import 'phosphor_icon.dart';

/// Elevated rounded-square Njangiva hero logo card shown at the top of
/// Create Account, Create Savings Goal, Sign In, and Welcome screens.
class NjangiHeroBadge extends StatelessWidget {
  const NjangiHeroBadge({
    super.key,
    this.size = 76,
    this.iconSize = 42,
    this.customChild,
  });

  final double size;
  final double iconSize;
  final Widget? customChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child:
          customChild ??
          Padding(
            padding: EdgeInsets.all(size * 0.16),
            child: Image.asset(
              AppConstants.logoSymbolAsset,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
    );
  }
}

/// Phone + SMS bubble badge shown on the Verify Phone screen.
class NjangiPhoneVerifyBadge extends StatelessWidget {
  const NjangiPhoneVerifyBadge({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    return NjangiHeroBadge(
      size: size,
      customChild: SizedBox(
        width: size * 0.62,
        height: size * 0.62,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: size * 0.34,
                height: size * 0.52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryRed, width: 2.5),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryButtonGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 3.5,
                      height: 3.5,
                      margin: EdgeInsets.only(right: i < 2 ? 2.5 : 0),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
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

/// Horizontal Njangiva header wordmark + tagline used on the Home Dashboard and Sidebar.
/// Matches the exact top-left header of the Njangiva reference UI:
/// - Glossy red Njangiva ribbon symbol on the left
/// - "Njangiva" bold dark title + "Save. Prepare. Contribute." subtitle on the right
class NjangiBrandHeader extends StatelessWidget {
  const NjangiBrandHeader({
    super.key,
    this.fontSize = 25,
    this.badgeSize = 50,
    this.showTagline = true,
  });

  final double fontSize;
  final double badgeSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          AppConstants.logoSymbolAsset,
          width: badgeSize,
          height: badgeSize * 0.74,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: AppColors.darkNavy,
                letterSpacing: -0.5,
                height: 1.08,
              ),
            ),
            if (showTagline) ...[
              const SizedBox(height: 2),
              Text(
                AppConstants.tagline,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3F4552),
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Soft rounded-square back button matching Njangiva reference screens.
class NjangiBackButton extends StatelessWidget {
  const NjangiBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: Icon(
                PhosphorIcons.caretLeftBold,
                size: 18,
                color: AppColors.darkNavy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
