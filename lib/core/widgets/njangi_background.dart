import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Renders the clean Njangiva background without decorative corner waves.
///
/// Full-screen on mobile, and cleanly centered with a responsive max width on
/// tablet and desktop web.
class NjangiBackground extends StatelessWidget {
  const NjangiBackground({
    super.key,
    required this.child,
    this.maxContentWidth = 520,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.scrollable = true,
  });

  final Widget child;
  final double maxContentWidth;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(padding: padding, child: child),
      ),
    );

    return ColoredBox(
      color: AppColors.softBackground,
      child: SizedBox.expand(
        child: SafeArea(
          child: scrollable
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}
