import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'phosphor_icon.dart';

/// Pill-shaped cyan-to-blue gradient CTA button matching the NjangiSave design system.
///
/// Includes desktop mouse hover elevation, loading indicator, and optional leading
/// or trailing Phosphor icons.
class PrimaryGradientButton extends StatefulWidget {
  const PrimaryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.showTrailingArrow = false,
    this.leadingIcon,
    this.isLoading = false,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showTrailingArrow;
  final IconData? leadingIcon;
  final bool isLoading;
  final double height;

  @override
  State<PrimaryGradientButton> createState() => _PrimaryGradientButtonState();
}

class _PrimaryGradientButtonState extends State<PrimaryGradientButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: enabled
              ? AppColors.primaryButtonGradient
              : LinearGradient(
                  colors: [
                    AppColors.secondaryText.withValues(alpha: 0.4),
                    AppColors.secondaryText.withValues(alpha: 0.5),
                  ],
                ),
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(
                      alpha: _isHovered ? 0.38 : 0.26,
                    ),
                    blurRadius: _isHovered ? 22 : 16,
                    offset: Offset(0, _isHovered ? 8 : 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.height / 2),
            onTap: enabled ? widget.onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.leadingIcon != null) ...[
                            Icon(
                              widget.leadingIcon,
                              color: AppColors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                            ),
                          ),
                          if (widget.showTrailingArrow) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              PhosphorIcons.arrowRightBold,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
