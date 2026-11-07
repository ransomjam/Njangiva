import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/savings_goal_model.dart';
import '../utils/formatters.dart';

class WithdrawalEligibility {
  const WithdrawalEligibility({
    required this.canWithdrawNormally,
    required this.canRequestEarlyRelease,
    required this.statusTitle,
    required this.explanation,
  });

  final bool canWithdrawNormally;
  final bool canRequestEarlyRelease;
  final String statusTitle;
  final String explanation;
}

class SavingsLockPolicySection {
  const SavingsLockPolicySection({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

/// Abstract service defining savings lock rules and financial safety conditions.
///
/// Note: The Flutter interface displays commitment status, while actual fund
/// custody and withdrawal restrictions are enforced by the backend and licensed
/// payment/financial partners.
abstract interface class SavingsLockService {
  WithdrawalEligibility evaluateWithdrawal(
    SavingsGoal goal, {
    DateTime? currentDate,
  });

  List<SavingsLockPolicySection> getLockPolicySections();

  String getCustodyDisclosure();
}

class DefaultSavingsLockService implements SavingsLockService {
  const DefaultSavingsLockService();

  @override
  WithdrawalEligibility evaluateWithdrawal(
    SavingsGoal goal, {
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final isMatured = goal.isMaturedAt(now);

    if (goal.amountSaved <= 0) {
      return const WithdrawalEligibility(
        canWithdrawNormally: false,
        canRequestEarlyRelease: false,
        statusTitle: 'No Verified Funds Available',
        explanation:
            'Make a verified deposit first before requesting a Njangi payout.',
      );
    }

    if (!goal.lockStatus.isRestricted || isMatured) {
      return WithdrawalEligibility(
        canWithdrawNormally: true,
        canRequestEarlyRelease: false,
        statusTitle: isMatured
            ? 'Contribution Matured — Ready for Release'
            : 'Flexible Goal — Withdrawal Permitted',
        explanation: isMatured
            ? 'Your Njangi contribution date (${AppFormatters.formatDate(goal.dueDate)}) has been reached. You can now release your ${AppFormatters.formatCurrency(goal.amountSaved)} to your mobile money account.'
            : 'This goal is set to flexible mode. You may release your saved funds to your mobile money account at any time.',
      );
    }

    return WithdrawalEligibility(
      canWithdrawNormally: false,
      canRequestEarlyRelease: true,
      statusTitle: 'Locked Until ${AppFormatters.formatDate(goal.dueDate)}',
      explanation:
          'Your committed funds (${AppFormatters.formatCurrency(goal.amountSaved)}) are restricted until your agreed Njangi contribution date on ${AppFormatters.formatDate(goal.dueDate)}. Standard payouts unlock automatically on the due date.',
    );
  }

  @override
  List<SavingsLockPolicySection> getLockPolicySections() {
    return const [
      SavingsLockPolicySection(
        title: '1. When Funds Become Restricted',
        description:
            'When "Lock my savings" is enabled on a goal, every verified deposit made toward that goal is committed until the contribution due date.',
      ),
      SavingsLockPolicySection(
        title: '2. When Funds Can Be Released',
        description:
            'Funds automatically become eligible for payout on 00:00 of your selected Njangi contribution date, even if you have not yet reached 100% of your target amount.',
      ),
      SavingsLockPolicySection(
        title: '3. Early Withdrawal & Cancelled Njangi Rules',
        description:
            'Standard early withdrawals are restricted to protect your Njangi discipline. If your Njangi group cancels or postpones a round, you may submit a Goal Cancellation request for backend verification and principal release.',
      ),
      SavingsLockPolicySection(
        title: '4. Platform Fees & Refund Conditions',
        description:
            'The tier-based platform fee is displayed transparently and separately from your savings target. Verified principal deposits are never silently reduced by hidden fees.',
      ),
    ];
  }

  @override
  String getCustodyDisclosure() {
    return 'Financial Safety Disclosure: Locking a goal in NjangiSave records a binding commitment rule on your account. Actual fund custody, settlement, and payout enforcement are executed server-side through our verified payment integration and licensed financial partners.';
  }
}

final savingsLockServiceProvider = Provider<SavingsLockService>((ref) {
  return const DefaultSavingsLockService();
});
