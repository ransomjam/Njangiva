import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../models/transaction_model.dart';
import '../savings_goals/goals_controller.dart';
import 'transactions_controller.dart';

/// Transactions Screen matching exact UI reference (Image 1):
/// - Top bar with rounded light blue `<` back button, title, subtitle & funnel filter button
/// - Enclosed segmented pill bar: All, Deposits, Withdrawals, Fees
/// - Dual dropdown filter pills: "All statuses" and "All dates"
/// - Pixel-matched transaction cards with type icon, reference, amount & status pill
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int _selectedTabIndex = 0; // 0: All, 1: Deposits, 2: Withdrawals, 3: Fees
  String _selectedStatus = 'All statuses';
  String _selectedDateFilter = 'All dates';

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsControllerProvider);
    final goalsState = ref.watch(goalsControllerProvider);

    // Apply category tab filter
    TransactionType? activeType;
    if (_selectedTabIndex == 1) activeType = TransactionType.deposit;
    if (_selectedTabIndex == 2) activeType = TransactionType.withdrawal;
    if (_selectedTabIndex == 3) activeType = TransactionType.platformFee;

    final allTx = txState.filtered(
      includeSampleData: goalsState.isSampleDataMode,
    );

    final transactions = allTx.where((tx) {
      if (activeType != null && tx.type != activeType) return false;
      if (_selectedStatus == 'Successful' &&
          tx.status != TransactionStatus.successful) {
        return false;
      }
      if (_selectedStatus == 'Pending' &&
          tx.status != TransactionStatus.pending) {
        return false;
      }
      if (_selectedStatus == 'Failed' &&
          tx.status != TransactionStatus.failed) {
        return false;
      }
      return true;
    }).toList();

    return NjangiBackground(
      maxContentWidth: 640,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back Button
              InkWell(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
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
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Verified deposits, payouts and platform fees.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Funnel Button
              InkWell(
                onTap: _showFilterOptionsBottomSheet,
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
                      PhosphorIcons.funnel,
                      size: 20,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Enclosed Segmented Tab Pills: All, Deposits, Withdrawals, Fees
          Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildSegmentTab(0, 'All'),
                _buildSegmentTab(1, 'Deposits'),
                _buildSegmentTab(2, 'Withdrawals'),
                _buildSegmentTab(3, 'Fees'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Dropdown Filter Pills: "All statuses" and "All dates"
          Row(
            children: [
              Expanded(
                child: _buildDropdownPill(
                  label: _selectedStatus,
                  icon: null,
                  onTap: _showStatusPicker,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownPill(
                  label: _selectedDateFilter,
                  icon: PhosphorIcons.calendarBlank,
                  onTap: _showDatePickerDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Transaction Cards List
          if (transactions.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _buildTransactionCard(tx);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownPill({
    required String label,
    required IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.darkNavy),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              PhosphorIcons.caretDown,
              size: 14,
              color: AppColors.darkNavy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(NjangiTransaction tx) {
    // Determine card icon & title based on type
    final IconData iconData;
    final String typeTitle;
    final bool isFee = tx.type == TransactionType.platformFee;
    final bool isWithdrawal = tx.type == TransactionType.withdrawal;

    if (isFee) {
      iconData = PhosphorIcons.coins;
      typeTitle = 'Platform fee — ${tx.goalName}';
    } else if (isWithdrawal) {
      iconData = PhosphorIcons.uploadSimple;
      typeTitle = 'Withdrawal — ${tx.goalName}';
    } else {
      iconData = PhosphorIcons.downloadSimple;
      typeTitle = 'Deposit — ${tx.goalName}';
    }

    final amountSign = (isFee || isWithdrawal) ? '-' : '+';
    final formattedAmount =
        '$amountSign${AppFormatters.formatCurrency(tx.amount)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Icon Box
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Icon(iconData, size: 22, color: AppColors.primaryBlue),
            ),
          ),
          const SizedBox(width: 14),

          // Center Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeTitle,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppFormatters.formatDateTime(tx.createdAt)}  •  Ref: ${tx.reference}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right Amount and Status Pill
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedAmount,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 6),
              _buildStatusPill(tx.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(TransactionStatus status) {
    Color bg = AppColors.lightBlue;
    Color fg = AppColors.primaryBlue;
    String label = 'Successful';
    IconData icon = PhosphorIcons.check;

    if (status == TransactionStatus.pending) {
      bg = const Color(0xFFFFF7E6);
      fg = const Color(0xFFD48806);
      label = 'Pending';
      icon = PhosphorIcons.clock;
    } else if (status == TransactionStatus.failed) {
      bg = const Color(0xFFFFF1F0);
      fg = const Color(0xFFCF1322);
      label = 'Failed';
      icon = PhosphorIcons.x;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(
            PhosphorIcons.arrowsLeftRight,
            size: 40,
            color: AppColors.secondaryText,
          ),
          SizedBox(height: 12),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkNavy,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Transactions will appear here once you make a deposit.',
            style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showStatusPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 12),
              ...['All statuses', 'Successful', 'Pending', 'Failed'].map(
                (status) => ListTile(
                  title: Text(status),
                  trailing: _selectedStatus == status
                      ? const Icon(
                          PhosphorIcons.check,
                          color: AppColors.primaryBlue,
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedStatus = status);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePickerDialog() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDateFilter = AppFormatters.formatDate(picked);
      });
    }
  }

  void _showFilterOptionsBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(PhosphorIcons.downloadSimple),
                title: const Text('Show Deposits Only'),
                onTap: () {
                  setState(() => _selectedTabIndex = 1);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIcons.uploadSimple),
                title: const Text('Show Withdrawals Only'),
                onTap: () {
                  setState(() => _selectedTabIndex = 2);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIcons.coins),
                title: const Text('Show Platform Fees Only'),
                onTap: () {
                  setState(() => _selectedTabIndex = 3);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIcons.arrowsClockwise),
                title: const Text('Reset All Filters'),
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 0;
                    _selectedStatus = 'All statuses';
                    _selectedDateFilter = 'All dates';
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
