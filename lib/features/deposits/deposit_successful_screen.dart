import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/phosphor_icon.dart';

/// Deposit Successful Screen matching exact UI reference (Image 3):
/// - Back button & centered "Deposit Successful" header
/// - Concentric blue circles hero with white checkmark
/// - Details card with: Amount, Savings goal, Transaction reference + copy button,
///   Date & time, Status (✓ Successful)
/// - "Back to Goal" primary button & "View Receipt" outline button
class DepositSuccessfulScreen extends StatelessWidget {
  const DepositSuccessfulScreen({
    super.key,
    this.amountFcfa = 10000,
    this.goalName = 'Monthly Njangi',
    this.fapshiReference = 'FP525A5D1',
    this.dateTimeString = '3 Nov 2026, 09:41',
    this.goalId = 'goal_monthly_01',
  });

  final int amountFcfa;
  final String goalName;
  final String fapshiReference;
  final String dateTimeString;
  final String goalId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: NjangiBackground(
        maxContentWidth: 540,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          children: [
            // 1. Top Bar
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/goals/$goalId');
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          PhosphorIcons.caretLeftBold,
                          size: 20,
                          color: AppColors.darkNavy,
                        ),
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Deposit Successful',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 2. Concentric Circles Hero Illustration
            Container(
              width: 124,
              height: 124,
              decoration: const BoxDecoration(
                color: Color(0xFFFDECEF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 94,
                  height: 94,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAD4DB),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryButtonGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          PhosphorIcons.checkBold,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title & Subtitle
            const Text(
              'Deposit Successful',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Your payment has been verified and added to your savings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.secondaryText,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 3. Details Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: PhosphorIcons.wallet,
                    label: 'Amount',
                    trailing: Text(
                      AppFormatters.formatCurrency(amountFcfa),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  _buildDetailRow(
                    icon: PhosphorIcons.usersThree,
                    label: 'Savings goal',
                    trailing: Text(
                      goalName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  _buildDetailRow(
                    icon: PhosphorIcons.receipt,
                    label: 'Transaction reference',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fapshiReference,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: fapshiReference),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reference copied to clipboard!'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Icon(
                            PhosphorIcons.copy,
                            size: 16,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  _buildDetailRow(
                    icon: PhosphorIcons.calendarBlank,
                    label: 'Date & time',
                    trailing: Text(
                      dateTimeString,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  _buildDetailRow(
                    icon: PhosphorIcons.shieldCheck,
                    label: 'Status',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.check,
                            size: 12,
                            color: AppColors.primaryBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Successful',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // 4. Primary CTA: "Back to Goal"
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/goals/$goalId'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Back to Goal',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 5. Secondary Action: "View Receipt"
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  context.push('/transactions');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.receipt, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'View Receipt',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondaryText),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}
