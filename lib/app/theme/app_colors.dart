import 'package:flutter/material.dart';

/// Official Njangiva Design System Colour Palette.
///
/// Follows the rich crimson, ruby & soft blush palette from the Njangiva UI design:
/// - Primary crimson: `#C8102E`
/// - Deep ruby: `#8E0515`
/// - Bright red: `#E6182F`
/// - Soft blush / light red: `#FDE8EB`
/// - Soft background: `#FAF7F8`
/// - White: `#FFFFFF`
/// - Dark charcoal text: `#14161C`
/// - Secondary text: `#525866`
/// - Success green: `#16A34A`
/// - Border: `#EFE4E6`
abstract final class AppColors {
  // Primary Njangiva Red / Crimson tokens (also aliased to legacy names for seamless app-wide theming)
  static const Color primaryRed = Color(0xFFC8102E);
  static const Color deepRed = Color(0xFF8E0515);
  static const Color brightRed = Color(0xFFE6182F);
  static const Color lightRed = Color(0xFFFDE8EB);
  static const Color softPinkPill = Color(0xFFF9D5D9);

  static const Color primaryBlue = primaryRed;
  static const Color deepBlue = deepRed;
  static const Color cyan = brightRed;
  static const Color lightBlue = lightRed;

  static const Color softBackground = Color(0xFFFAF7F8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkNavy = Color(0xFF14161C);
  static const Color secondaryText = Color(0xFF525866);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successGreenLight = Color(0xFFE8F8EE);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberLight = Color(0xFFFEF3C7);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorRedLight = Color(0xFFFEE2E2);
  static const Color border = Color(0xFFEDE2E5);
  static const Color inputFill = Color(0xFFFCF9FA);
  static const Color progressTrack = Color(0xFFE5E4EC);

  /// Bright-to-Deep Crimson vertical gradient used on primary CTA buttons,
  /// the "New Goal" quick action card, and the active Bottom Navigation pill.
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE6182F), Color(0xFF9E0616)],
  );

  /// Rich Ruby-to-Crimson gradient used on the Home Dashboard Total Savings card.
  static const LinearGradient totalSavingsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC80C22), Color(0xFF9B0819), Color(0xFF7A0310)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Progress bar crimson gradient matching the Njangiva goal progress bars.
  static const LinearGradient progressBarGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF9E0616), Color(0xFFE6182F)],
  );

  /// Soft blush card gradient used on summary headers and quick action highlights.
  static const LinearGradient softBlueCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDECEF), Color(0xFFFAD8DD)],
  );
}
