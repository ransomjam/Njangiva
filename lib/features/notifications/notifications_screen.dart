import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/njangi_logo.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../models/notification_model.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: NjangiBackground(
        maxContentWidth: 620,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NjangiBackButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                Text(
                  'Notifications',
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(notificationsControllerProvider.notifier)
                      .markAllRead(),
                  child: const Text('Mark all read'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...notifications.map((n) {
              final icon = switch (n.type) {
                AppNotificationType.depositVerified =>
                  PhosphorIcons.checkCircleFill,
                AppNotificationType.goalMatured => PhosphorIcons.target,
                AppNotificationType.reminder => PhosphorIcons.clock,
                AppNotificationType.security => PhosphorIcons.shieldCheck,
              };
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: n.isRead ? AppColors.white : AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () => ref
                      .read(notificationsControllerProvider.notifier)
                      .markRead(n.id),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: AppColors.primaryBlue, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(n.body, style: textTheme.bodyMedium),
                            const SizedBox(height: 6),
                            Text(
                              AppFormatters.formatDateTime(n.createdAt),
                              style: textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
