import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a configurable platform fee tier for NjangiSave.
class PricingTier {
  const PricingTier({
    required this.minTargetFcfa,
    required this.maxTargetFcfa,
    required this.feeFcfa,
    required this.label,
  });

  final int minTargetFcfa;
  final int? maxTargetFcfa;
  final int feeFcfa;
  final String label;

  bool matches(int targetAmount) {
    if (targetAmount < minTargetFcfa) return false;
    if (maxTargetFcfa != null && targetAmount > maxTargetFcfa!) return false;
    return true;
  }
}

/// Configurable platform pricing service.
///
/// Implements the proposed NjangiSave fee tiers:
/// - 5,000–50,000 FCFA -> 1,000 FCFA
/// - 50,001–150,000 FCFA -> 1,500 FCFA
/// - 150,001–500,000 FCFA -> 2,500 FCFA
/// - Above 500,000 FCFA -> 5,000 FCFA
///
/// Platform fees are always displayed separately from the savings target and
/// are never silently deducted from a member's savings.
class PricingTierService {
  const PricingTierService({List<PricingTier>? tiers})
    : _tiers = tiers ?? defaultTiers;

  final List<PricingTier> _tiers;

  static const List<PricingTier> defaultTiers = [
    PricingTier(
      minTargetFcfa: 5000,
      maxTargetFcfa: 50000,
      feeFcfa: 1000,
      label: '5,000 – 50,000 FCFA Tier',
    ),
    PricingTier(
      minTargetFcfa: 50001,
      maxTargetFcfa: 150000,
      feeFcfa: 1500,
      label: '50,001 – 150,000 FCFA Tier',
    ),
    PricingTier(
      minTargetFcfa: 150001,
      maxTargetFcfa: 500000,
      feeFcfa: 2500,
      label: '150,001 – 500,000 FCFA Tier',
    ),
    PricingTier(
      minTargetFcfa: 500001,
      maxTargetFcfa: null,
      feeFcfa: 5000,
      label: 'Above 500,000 FCFA Tier',
    ),
  ];

  List<PricingTier> get tiers => List.unmodifiable(_tiers);

  /// Calculates the platform fee for a given savings target in FCFA.
  int calculatePlatformFee(int targetAmountFcfa) {
    if (targetAmountFcfa <= 0) return 0;
    for (final tier in _tiers) {
      if (tier.matches(targetAmountFcfa)) {
        return tier.feeFcfa;
      }
    }
    if (targetAmountFcfa < _tiers.first.minTargetFcfa) {
      return _tiers.first.feeFcfa;
    }
    return _tiers.last.feeFcfa;
  }

  /// Returns the matching tier description for display on the Goal Summary screen.
  PricingTier resolveTier(int targetAmountFcfa) {
    for (final tier in _tiers) {
      if (tier.matches(targetAmountFcfa)) {
        return tier;
      }
    }
    if (targetAmountFcfa < _tiers.first.minTargetFcfa) {
      return _tiers.first;
    }
    return _tiers.last;
  }
}

final pricingTierServiceProvider = Provider<PricingTierService>((ref) {
  return const PricingTierService();
});
