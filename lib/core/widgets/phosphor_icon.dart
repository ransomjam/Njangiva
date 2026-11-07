import 'package:flutter/material.dart';

/// Vector IconData definitions mapped directly from the workspace `phosphor-icons`
/// TTF font families (`PhosphorRegular`, `PhosphorFill`, `PhosphorBold`).
abstract final class PhosphorIcons {
  static const String _reg = 'PhosphorRegular';
  static const String _fill = 'PhosphorFill';
  static const String _bold = 'PhosphorBold';

  // Navigation & Core
  static const IconData house = IconData(0xe2c2, fontFamily: _reg);
  static const IconData houseFill = IconData(0xe2c2, fontFamily: _fill);
  static const IconData target = IconData(0xe47c, fontFamily: _reg);
  static const IconData targetFill = IconData(0xe47c, fontFamily: _fill);
  static const IconData targetBold = IconData(0xe47c, fontFamily: _bold);
  static const IconData arrowsLeftRight = IconData(0xe0a0, fontFamily: _reg);
  static const IconData arrowsLeftRightBold = IconData(
    0xe0a0,
    fontFamily: _bold,
  );
  static const IconData arrowsDownUp = IconData(0xe098, fontFamily: _reg);
  static const IconData user = IconData(0xe4c2, fontFamily: _reg);
  static const IconData userFill = IconData(0xe4c2, fontFamily: _fill);
  static const IconData users = IconData(0xe4d6, fontFamily: _reg);
  static const IconData usersFill = IconData(0xe4d6, fontFamily: _fill);
  static const IconData usersThree = IconData(0xe68e, fontFamily: _reg);
  static const IconData usersThreeFill = IconData(0xe68e, fontFamily: _fill);

  // Actions & Finance
  static const IconData bell = IconData(0xe0ce, fontFamily: _reg);
  static const IconData bellFill = IconData(0xe0ce, fontFamily: _fill);
  static const IconData eye = IconData(0xe220, fontFamily: _reg);
  static const IconData eyeSlash = IconData(0xe224, fontFamily: _reg);
  static const IconData lock = IconData(0xe2fa, fontFamily: _reg);
  static const IconData lockFill = IconData(0xe2fa, fontFamily: _fill);
  static const IconData lockKey = IconData(0xe2fe, fontFamily: _reg);
  static const IconData lockKeyFill = IconData(0xe2fe, fontFamily: _fill);
  static const IconData lockOpen = IconData(0xe306, fontFamily: _reg);
  static const IconData plus = IconData(0xe3d4, fontFamily: _reg);
  static const IconData plusBold = IconData(0xe3d4, fontFamily: _bold);
  static const IconData wallet = IconData(0xe68a, fontFamily: _reg);
  static const IconData walletFill = IconData(0xe68a, fontFamily: _fill);
  static const IconData uploadSimple = IconData(0xe4c0, fontFamily: _reg);
  static const IconData uploadSimpleBold = IconData(0xe4c0, fontFamily: _bold);
  static const IconData trayArrowUp = IconData(0xee52, fontFamily: _reg);
  static const IconData downloadSimple = IconData(0xe20c, fontFamily: _reg);
  static const IconData clock = IconData(0xe19a, fontFamily: _reg);
  static const IconData clockCounterClockwise = IconData(
    0xe1a0,
    fontFamily: _reg,
  );
  static const IconData calendar = IconData(0xe108, fontFamily: _reg);
  static const IconData calendarBlank = IconData(0xe10a, fontFamily: _reg);
  static const IconData calendarCheck = IconData(0xe712, fontFamily: _reg);
  static const IconData coins = IconData(0xe78e, fontFamily: _reg);
  static const IconData coinsFill = IconData(0xe78e, fontFamily: _fill);
  static const IconData money = IconData(0xe588, fontFamily: _reg);
  static const IconData bank = IconData(0xe0b4, fontFamily: _reg);
  static const IconData piggyBank = IconData(0xea04, fontFamily: _reg);
  static const IconData piggyBankFill = IconData(0xea04, fontFamily: _fill);
  static const IconData handCoins = IconData(0xea8c, fontFamily: _reg);
  static const IconData receipt = IconData(0xe3ec, fontFamily: _reg);
  static const IconData creditCard = IconData(0xe1d2, fontFamily: _reg);

  // Security & Status
  static const IconData shieldCheck = IconData(0xe40c, fontFamily: _reg);
  static const IconData shieldCheckFill = IconData(0xe40c, fontFamily: _fill);
  static const IconData shield = IconData(0xe40a, fontFamily: _reg);
  static const IconData check = IconData(0xe182, fontFamily: _reg);
  static const IconData checkBold = IconData(0xe182, fontFamily: _bold);
  static const IconData checkCircle = IconData(0xe184, fontFamily: _reg);
  static const IconData checkCircleFill = IconData(0xe184, fontFamily: _fill);
  static const IconData warningCircle = IconData(0xe4e2, fontFamily: _reg);
  static const IconData warningCircleFill = IconData(0xe4e2, fontFamily: _fill);
  static const IconData info = IconData(0xe2ce, fontFamily: _reg);

  // Arrows & Carets
  static const IconData caretLeft = IconData(0xe138, fontFamily: _reg);
  static const IconData caretLeftBold = IconData(0xe138, fontFamily: _bold);
  static const IconData caretRight = IconData(0xe13a, fontFamily: _reg);
  static const IconData caretRightBold = IconData(0xe13a, fontFamily: _bold);
  static const IconData caretDown = IconData(0xe136, fontFamily: _reg);
  static const IconData caretDownBold = IconData(0xe136, fontFamily: _bold);
  static const IconData caretUp = IconData(0xe13c, fontFamily: _reg);
  static const IconData arrowRight = IconData(0xe06c, fontFamily: _reg);
  static const IconData arrowRightBold = IconData(0xe06c, fontFamily: _bold);
  static const IconData arrowLeft = IconData(0xe058, fontFamily: _reg);
  static const IconData arrowUpRight = IconData(0xe092, fontFamily: _reg);
  static const IconData arrowDownLeft = IconData(0xe040, fontFamily: _reg);
  static const IconData arrowsClockwise = IconData(0xe094, fontFamily: _reg);

  // Auth, Profile & Misc
  static const IconData envelope = IconData(0xe214, fontFamily: _reg);
  static const IconData envelopeSimple = IconData(0xe218, fontFamily: _reg);
  static const IconData phone = IconData(0xe3b8, fontFamily: _reg);
  static const IconData key = IconData(0xe2d6, fontFamily: _reg);
  static const IconData chatCircleDots = IconData(0xe16c, fontFamily: _reg);
  static const IconData chatCircleDotsFill = IconData(
    0xe16c,
    fontFamily: _fill,
  );
  static const IconData deviceMobile = IconData(0xe1e0, fontFamily: _reg);
  static const IconData gear = IconData(0xe270, fontFamily: _reg);
  static const IconData signOut = IconData(0xe42a, fontFamily: _reg);
  static const IconData question = IconData(0xe3e8, fontFamily: _reg);
  static const IconData fileText = IconData(0xe23a, fontFamily: _reg);
  static const IconData funnel = IconData(0xe266, fontFamily: _reg);
  static const IconData stack = IconData(0xe452, fontFamily: _reg);
  static const IconData stackFill = IconData(0xe452, fontFamily: _fill);
  static const IconData magnifyingGlass = IconData(0xe30c, fontFamily: _reg);
  static const IconData sparkle = IconData(0xe6a2, fontFamily: _reg);
  static const IconData pencilSimple = IconData(0xe3b4, fontFamily: _reg);
  static const IconData copy = IconData(0xe1ca, fontFamily: _reg);
  static const IconData trash = IconData(0xe4a6, fontFamily: _reg);
  static const IconData x = IconData(0xe4f6, fontFamily: _reg);
  static const IconData xCircle = IconData(0xe4f8, fontFamily: _reg);
  static const IconData googleLogo = IconData(0xe292, fontFamily: _bold);
  static const IconData facebookLogo = IconData(0xe226, fontFamily: _fill);
}

/// Renders a Phosphor PNG icon from `assets/icons/phosphor/<name>.png`
/// with optional color tinting, matching AfroDocs' `PhosphorIcon` pattern.
class PhosphorAssetIcon extends StatelessWidget {
  const PhosphorAssetIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
    this.fallbackIcon,
  });

  final String name;
  final double size;
  final Color? color;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/phosphor/$name.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (fallbackIcon != null) {
          return Icon(fallbackIcon, size: size, color: color);
        }
        return SizedBox(width: size, height: size);
      },
    );
  }
}
