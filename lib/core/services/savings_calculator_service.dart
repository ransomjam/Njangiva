import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../utils/formatters.dart';

/// Immutable result of calculating a Njangi savings plan from an exact deadline.
class SavingsPlanCalculation {
  const SavingsPlanCalculation({
    required this.targetAmount,
    required this.remainingDays,
    required this.remainingWeeks,
    required this.remainingMonths,
    required this.dailyAmount,
    required this.weeklyAmount,
    required this.monthlyAmount,
    required this.durationLabel,
  });

  final int targetAmount;
  final int remainingDays;
  final double remainingWeeks;
  final double remainingMonths;

  /// Suggested daily savings in integer FCFA.
  final int dailyAmount;

  /// Suggested weekly savings in integer FCFA.
  final int weeklyAmount;

  /// Suggested monthly savings in integer FCFA.
  final int monthlyAmount;

  /// Human-readable duration label (e.g., `3 months` or `45 days`).
  final String durationLabel;
}

class GoalValidationResult {
  const GoalValidationResult({
    required this.isValid,
    this.nameError,
    this.amountError,
    this.dateError,
  });

  final bool isValid;
  final String? nameError;
  final String? amountError;
  final String? dateError;
}

/// Service for accurate Njangi savings plan calculations and validation.
///
/// Always calculates using the actual deadline calendar days rather than
/// assuming every month has 30 days.
class SavingsCalculatorService {
  const SavingsCalculatorService();

  /// Validates the Create Savings Goal inputs.
  GoalValidationResult validateGoalInput({
    required String name,
    required int? targetAmount,
    required DateTime? dueDate,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);

    String? nameError;
    String? amountError;
    String? dateError;

    if (name.trim().isEmpty) {
      nameError = 'Please enter a name for your Njangi goal.';
    } else if (name.trim().length < 3) {
      nameError = 'Goal name must be at least 3 characters.';
    }

    if (targetAmount == null || targetAmount <= 0) {
      amountError = 'Please enter a valid positive contribution amount.';
    } else if (targetAmount < AppConstants.minGoalAmountFcfa) {
      amountError =
          'Minimum Njangi goal is ${AppFormatters.formatCurrency(AppConstants.minGoalAmountFcfa)}.';
    }

    if (dueDate == null) {
      dateError = 'Please select your contribution due date.';
    } else {
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (!dueDay.isAfter(today)) {
        dateError = 'Contribution deadline must be in the future.';
      }
    }

    return GoalValidationResult(
      isValid: nameError == null && amountError == null && dateError == null,
      nameError: nameError,
      amountError: amountError,
      dateError: dateError,
    );
  }

  /// Calculates suggested daily, weekly, and monthly savings from the exact
  /// calendar deadline.
  SavingsPlanCalculation calculatePlan({
    required int amountToSave,
    required DateTime dueDate,
    DateTime? referenceDate,
  }) {
    final safeAmount = amountToSave > 0 ? amountToSave : 0;
    final ref = referenceDate ?? DateTime.now();
    final startDay = DateTime(ref.year, ref.month, ref.day);
    final endDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final diffDays = endDay.difference(startDay).inDays;
    final remainingDays = diffDays > 0 ? diffDays : 1;

    // Exact weeks from actual remaining days
    final remainingWeeks = remainingDays / 7.0;

    // Exact calendar months between startDay and endDay
    final rawCalendarMonths =
        (endDay.year - startDay.year) * 12 +
        (endDay.month - startDay.month) +
        ((endDay.day - startDay.day) / 30.4375);
    final remainingMonths = rawCalendarMonths >= 1.0
        ? rawCalendarMonths
        : (remainingDays / 30.4375);

    final dailyAmount = (safeAmount / remainingDays).ceil();
    final weeklyAmount = remainingWeeks >= 1.0
        ? (safeAmount / remainingWeeks).ceil()
        : safeAmount;
    final monthlyAmount = remainingMonths >= 1.0
        ? (safeAmount / remainingMonths).ceil()
        : safeAmount;

    return SavingsPlanCalculation(
      targetAmount: safeAmount,
      remainingDays: remainingDays,
      remainingWeeks: remainingWeeks,
      remainingMonths: remainingMonths,
      dailyAmount: dailyAmount,
      weeklyAmount: weeklyAmount,
      monthlyAmount: monthlyAmount,
      durationLabel: AppFormatters.formatDurationFromDays(remainingDays),
    );
  }
}

final savingsCalculatorServiceProvider = Provider<SavingsCalculatorService>((
  ref,
) {
  return const SavingsCalculatorService();
});
