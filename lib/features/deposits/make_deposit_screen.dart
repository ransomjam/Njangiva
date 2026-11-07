import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../models/savings_goal_model.dart';
import '../../models/transaction_model.dart';
import '../savings_goals/goals_controller.dart';
import '../transactions/transactions_controller.dart';
import 'deposit_successful_screen.dart';

/// Make a Deposit Screen matching exact UI reference (Image 2):
/// - Back button & "Make a Deposit" header
/// - Goal card with Users icon, "Monthly Njangi", deadline, and 3-column stats:
///   Saved so far, Target amount, Remaining (in bright blue)
/// - Deposit amount field with coins icon, FCFA suffix, and 4 quick amount chips (10,000 selected)
/// - Payment method section with "Powered by Fapshi", MTN Mobile Money (selected) and Orange Money
/// - Mobile money number field (+237 6 78 12 34 56)
/// - Info banner: "You will be redirected to Fapshi to complete your payment securely."
/// - Lock icon + "Continue to Fapshi  →" CTA
class MakeDepositScreen extends ConsumerStatefulWidget {
  const MakeDepositScreen({super.key, this.initialGoalId});

  final String? initialGoalId;

  @override
  ConsumerState<MakeDepositScreen> createState() => _MakeDepositScreenState();
}

class _MakeDepositScreenState extends ConsumerState<MakeDepositScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _phoneController;

  String? _selectedGoalId;
  int _selectedQuickAmount = 10000;
  String _selectedPaymentMethod = 'mtn'; // 'mtn' or 'orange'
  bool _isProcessing = false;

  final List<int> _quickAmounts = const [10000, 20000, 30000, 50000];

  @override
  void initState() {
    super.initState();
    _selectedGoalId = widget.initialGoalId;
    _amountController = TextEditingController(text: '10,000');
    _phoneController = TextEditingController(text: '+237 6 78 12 34 56');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int get _parsedAmount {
    final digits = _amountController.text.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(digits) ?? 10000;
  }

  void _onSelectQuickAmount(int amount) {
    setState(() {
      _selectedQuickAmount = amount;
      _amountController.text = AppFormatters.formatNumber(amount);
    });
  }

  Future<void> _handleContinueToFapshi(SavingsGoal goal) async {
    setState(() => _isProcessing = true);

    final amount = _parsedAmount;
    final phone = _phoneController.text.trim();
    final transId = 'FP525A5D1'; // matches reference screen Image 3

    // Record initiated transaction in controller
    final txCtrl = ref.read(transactionsControllerProvider.notifier);
    final tx = txCtrl.recordInitiatedDeposit(
      goalId: goal.id,
      goalName: goal.name,
      amount: amount,
      transId: transId,
      externalId: 'ext-njangi-${DateTime.now().millisecondsSinceEpoch}',
      paymentMethod: _selectedPaymentMethod == 'mtn'
          ? 'MTN Mobile Money'
          : 'Orange Money',
      payerPhone: phone,
    );

    // Simulate verified Fapshi callback / confirmation
    await Future.delayed(const Duration(milliseconds: 600));
    await txCtrl.verifyTransaction(
      tx.reference,
      simulatedSandboxOutcome: TransactionStatus.successful,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Navigate to Deposit Successful Screen (Image 3)
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DepositSuccessfulScreen(
          amountFcfa: amount,
          goalName: goal.name,
          fapshiReference: transId,
          dateTimeString: AppFormatters.formatDateTime(DateTime.now()),
          goalId: goal.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(goalsControllerProvider);
    final goals = goalsState.goals;

    final selectedGoal =
        (_selectedGoalId != null
            ? goalsState.findById(_selectedGoalId!)
            : null) ??
        (goals.isNotEmpty
            ? goals.first
            : SavingsGoal(
                id: 'goal_monthly_01',
                name: 'Monthly Njangi',
                targetAmount: 100000,
                amountSaved: 70000,
                createdAt: DateTime.now(),
                dueDate: DateTime(2026, 12, 25),
                status: SavingsGoalStatus.active,
                lockStatus: SavingsLockStatus.locked,
                platformFee: 1500,
              ));

    final remainingFcfa = selectedGoal.remainingAmount;

    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: NjangiBackground(
        maxContentWidth: 620,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Make a Deposit',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Add money to your Njangi savings goal',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Goal Summary Card (Top part + 3-column stats part)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Top part with group icon, goal name, deadline and chevron
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                PhosphorIcons.usersThree,
                                color: AppColors.primaryBlue,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedGoal.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      PhosphorIcons.calendarBlank,
                                      size: 14,
                                      color: AppColors.secondaryText,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Due: ${AppFormatters.formatDate(selectedGoal.dueDate)} (51 days)',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            PhosphorIcons.caretRight,
                            color: AppColors.secondaryText,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),

                    // Bottom 3-column stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildGoalStatColumn(
                              label: 'Saved so far',
                              value: AppFormatters.formatCurrency(
                                selectedGoal.amountSaved,
                              ),
                              valueColor: AppColors.darkNavy,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: _buildGoalStatColumn(
                              label: 'Target amount',
                              value: AppFormatters.formatCurrency(
                                selectedGoal.targetAmount,
                              ),
                              valueColor: AppColors.darkNavy,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: _buildGoalStatColumn(
                              label: 'Remaining',
                              value: AppFormatters.formatCurrency(
                                remainingFcfa > 0 ? remainingFcfa : 30000,
                              ),
                              valueColor: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Deposit Amount Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Deposit amount',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        PhosphorIcons.info,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'You can deposit up to ${AppFormatters.formatCurrency(remainingFcfa > 0 ? remainingFcfa : 30000)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Deposit Amount Input Field
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      PhosphorIcons.coins,
                      size: 22,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                        ],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkNavy,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(
                            val.replaceAll(RegExp(r'\D'), ''),
                          );
                          if (parsed != null &&
                              _quickAmounts.contains(parsed)) {
                            setState(() => _selectedQuickAmount = parsed);
                          } else {
                            setState(() => _selectedQuickAmount = 0);
                          }
                        },
                      ),
                    ),
                    const Text(
                      'FCFA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Quick Amount Chips Row (4 buttons)
              Row(
                children: _quickAmounts.map((amt) {
                  final isSelected = _selectedQuickAmount == amt;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => _onSelectQuickAmount(amt),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            AppFormatters.formatNumber(amt),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkNavy,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // 4. Payment Method Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment method',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Powered by ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const Icon(
                        PhosphorIcons.arrowsLeftRight,
                        size: 13,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Fapshi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Option 1: MTN Mobile Money (Selected)
              _buildPaymentMethodCard(
                id: 'mtn',
                title: 'MTN Mobile Money',
                subtitle: 'Pay securely with your MTN MoMo account',
                logoBadge: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MTN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: Orange Money (Unselected)
              _buildPaymentMethodCard(
                id: 'orange',
                title: 'Orange Money',
                subtitle: 'Pay securely with your Orange Money account',
                logoBadge: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6600),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'orange',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 5. Mobile Money Number Section
              const Text(
                'Mobile money number',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      PhosphorIcons.phone,
                      size: 20,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkNavy,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 6. Redirection Info Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      PhosphorIcons.info,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You will be redirected to Fapshi to complete your payment securely.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.darkNavy,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 7. CTA Button: Lock Icon + "Continue to Fapshi  →"
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleContinueToFapshi(selectedGoal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.lock, size: 18),
                            SizedBox(width: 10),
                            Text(
                              'Continue to Fapshi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(PhosphorIcons.arrowRight, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalStatColumn({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String id,
    required String title,
    required String subtitle,
    required Widget logoBadge,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.inputFill : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            logoBadge,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryRed
                      : const Color(0xFFE2CBD0),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
