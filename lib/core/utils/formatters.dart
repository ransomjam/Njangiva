import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Formatting utilities for FCFA currency, dates, and Njangi durations.
abstract final class AppFormatters {
  static final NumberFormat _numberFormat = NumberFormat('#,###', 'en_US');
  static final DateFormat _shortDateFormat = DateFormat('d MMM yyyy', 'en_US');
  static final DateFormat _dateTimeFormat = DateFormat(
    'd MMM yyyy, HH:mm',
    'en_US',
  );

  /// Formats an integer FCFA amount as `180,000` (without currency suffix).
  static String formatNumber(int amount) {
    return _numberFormat.format(amount);
  }

  /// Formats an integer FCFA amount as `180,000 FCFA`.
  static String formatCurrency(
    int amount, {
    String currency = AppConstants.defaultCurrency,
  }) {
    return '${_numberFormat.format(amount)} $currency';
  }

  /// Formats a DateTime as `25 Dec 2026`.
  static String formatDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Formats a DateTime as `25 Dec 2026, 14:30`.
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Formats remaining days into a friendly duration string such as
  /// `3 weeks`, `1 week`, `4 weeks`, `3 months`, or `10 days`.
  static String formatDurationFromDays(int days) {
    if (days <= 0) return 'Due today';
    if (days == 1) return '1 day';
    if (days <= 30 && days % 7 == 0) {
      final weeks = days ~/ 7;
      return weeks == 1 ? '1 week' : '$weeks weeks';
    }
    if (days < 28) {
      if (days >= 7) {
        final weeks = (days / 7).round();
        return weeks == 1 ? '1 week' : '$weeks weeks';
      }
      return '$days days';
    }
    final months = (days / 30.4375).round();
    if (months <= 1) return '1 month';
    return '$months months';
  }

  /// Formats a relative due string such as `Due in 3 weeks` or `Due in 3 months`.
  static String formatDueRelative(DateTime dueDate, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diffDays = dueDay.difference(today).inDays;

    if (diffDays < 0) {
      return 'Matured (${diffDays.abs()}d ago)';
    }
    if (diffDays == 0) {
      return 'Due today';
    }
    return 'Due in ${formatDurationFromDays(diffDays)}';
  }
}
