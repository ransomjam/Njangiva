import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../models/notification_model.dart';

class NotificationsController extends StateNotifier<List<AppNotification>> {
  NotificationsController() : super(_initialNotifications());

  static List<AppNotification> _initialNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'notif_01',
        title: 'Small Njangi Goal Reached! 🎉',
        body:
            'Your Small Njangi target of 20,000 FCFA is 100% funded and ready for your upcoming contribution.',
        createdAt: now.subtract(const Duration(hours: 3)),
        type: AppNotificationType.goalMatured,
        isRead: false,
      ),
      AppNotification(
        id: 'notif_02',
        title: 'Fapshi Deposit Verified',
        body:
            '35,000 FCFA deposit toward Monthly Njangi was verified (Ref: FP89K2M1A).',
        createdAt: now.subtract(const Duration(days: 2)),
        type: AppNotificationType.depositVerified,
        isRead: false,
      ),
      AppNotification(
        id: 'notif_03',
        title: 'Weekly Njangi Reminder',
        body:
            'Save little by little today! A weekly deposit of 2,600 FCFA keeps your Monthly Njangi on track.',
        createdAt: now.subtract(const Duration(days: 5)),
        type: AppNotificationType.reminder,
        isRead: true,
      ),
    ];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  void markAllRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void markRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  void addDepositNotification({
    required String goalName,
    required int amountFcfa,
    required String transId,
  }) {
    final item = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Fapshi Deposit Verified ✓',
      body:
          '${AppFormatters.formatCurrency(amountFcfa)} added to "$goalName" (Fapshi Ref: $transId).',
      createdAt: DateTime.now(),
      type: AppNotificationType.depositVerified,
      isRead: false,
    );
    state = [item, ...state];
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, List<AppNotification>>((
      ref,
    ) {
      return NotificationsController();
    });
