import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/services/savings_calculator_service.dart';
import '../../core/services/savings_lock_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/njangi_logo.dart';
import '../../core/widgets/njangi_text_field.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../core/widgets/primary_gradient_button.dart';
import 'goals_controller.dart';

/// G. Create Savings Goal Screen (Matches Reference Image 4 closely)
///
/// Fields:
/// 1. Goal name (e.g. Monthly Njangi)
/// 2. Contribution amount (FCFA)
/// 3. Contribution date & automatically calculated Saving duration
/// 4. "Lock my savings" toggle card + Financial Safety explanation modal
class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _nameController = TextEditingController(text: 'Monthly Njangi');
  final _amountController = TextEditingController(text: '50,000');

  late DateTime _selectedDueDate;
  bool _lockSavings = true;

  String? _nameError;
  String? _amountError;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final existingDraft = ref.read(goalsControllerProvider).pendingDraft;
    if (existingDraft != null) {
      _nameController.text = existingDraft.name;
      _amountController.text = AppFormatters.formatNumber(
        existingDraft.targetAmount,
      );
      _selectedDueDate = existingDraft.dueDate;
      _lockSavings = existingDraft.lockSavings;
    } else {
      final now = DateTime.now();
      _selectedDueDate = DateTime(now.year, now.month + 3, now.day);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int? get _parsedAmount {
    final digits = _amountController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate.isAfter(now)
          ? _selectedDueDate
          : now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dateError = null;
      });
    }
  }

  void _selectDurationMonths(int months) {
    final now = DateTime.now();
    setState(() {
      _selectedDueDate = DateTime(now.year, now.month + months, now.day);
      _dateError = null;
    });
  }

  void _showLockExplanationSheet() {
    final lockService = ref.read(savingsLockServiceProvider);
    final sections = lockService.getLockPolicySections();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Savings Lock & Financial Safety',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(PhosphorIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...sections.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      lockService.getCustodyDisclosure(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleCreateGoal() {
    final calculator = ref.read(savingsCalculatorServiceProvider);
    final amount = _parsedAmount;
    final validation = calculator.validateGoalInput(
      name: _nameController.text,
      targetAmount: amount,
      dueDate: _selectedDueDate,
    );

    setState(() {
      _nameError = validation.nameError;
      _amountError = validation.amountError;
      _dateError = validation.dateError;
    });

    if (!validation.isValid || amount == null) return;

    ref
        .read(goalsControllerProvider.notifier)
        .saveDraft(
          name: _nameController.text,
          targetAmount: amount,
          dueDate: _selectedDueDate,
          lockSavings: _lockSavings,
        );

    context.push('/goals/summary');
  }

  @override
  Widget build(BuildContext context) {
    final calculator = ref.watch(savingsCalculatorServiceProvider);
    final amount = _parsedAmount ?? 0;
    final plan = calculator.calculatePlan(
      amountToSave: amount,
      dueDate: _selectedDueDate,
    );
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: NjangiBackground(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            NjangiBackButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            const SizedBox(height: 8),

            // Centered Badge + Headline (Matches Image 4)
            const Center(child: NjangiHeroBadge(size: 74, iconSize: 38)),
            const SizedBox(height: 16),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: textTheme.displayMedium?.copyWith(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Create a ',
                      style: TextStyle(color: AppColors.darkNavy),
                    ),
                    TextSpan(
                      text: 'Savings Goal',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Set up your Njangi contribution and start saving.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 1. Goal name
            NjangiTextField(
              label: 'Goal name',
              controller: _nameController,
              hintText: 'e.g. Monthly Njangi',
              prefixIcon: PhosphorIcons.users,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            if (_nameError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _nameError!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 2. Contribution amount (FCFA)
            NjangiTextField(
              label: 'Contribution amount',
              controller: _amountController,
              hintText: '50,000',
              prefixIcon: PhosphorIcons.coins,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
              ],
              textStyle: textTheme.headlineMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
              suffixWidget: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FCFA',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      PhosphorIcons.caretDownBold,
                      size: 13,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),
              ),
              onChanged: (_) {
                setState(() => _amountError = null);
              },
            ),
            if (_amountError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _amountError!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 3. Contribution date & Saving duration (2 columns matching Image 4)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Contribution date
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 8),
                        child: Text(
                          'Contribution date',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _pickDueDate,
                          child: Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  PhosphorIcons.calendarBlank,
                                  size: 19,
                                  color: AppColors.secondaryText,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppFormatters.formatDate(_selectedDueDate),
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  PhosphorIcons.caretDownBold,
                                  size: 13,
                                  color: AppColors.darkNavy,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Right: Saving duration (auto-calculated from date + quick presets)
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 8),
                        child: Text(
                          'Saving duration',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      PopupMenuButton<int>(
                        onSelected: _selectDurationMonths,
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 1, child: Text('1 month')),
                          PopupMenuItem(value: 2, child: Text('2 months')),
                          PopupMenuItem(value: 3, child: Text('3 months')),
                          PopupMenuItem(value: 6, child: Text('6 months')),
                          PopupMenuItem(value: 12, child: Text('12 months')),
                        ],
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                PhosphorIcons.clock,
                                size: 19,
                                color: AppColors.secondaryText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  plan.durationLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                              ),
                              const Icon(
                                PhosphorIcons.caretDownBold,
                                size: 13,
                                color: AppColors.darkNavy,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_dateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _dateError!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Live Suggested Savings Plan Preview Banner
            if (amount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniSuggestedMetric(
                      label: 'Daily guide',
                      amount: plan.dailyAmount,
                    ),
                    Container(width: 1, height: 26, color: AppColors.border),
                    _MiniSuggestedMetric(
                      label: 'Weekly guide',
                      amount: plan.weeklyAmount,
                    ),
                    Container(width: 1, height: 26, color: AppColors.border),
                    _MiniSuggestedMetric(
                      label: 'Monthly guide',
                      amount: plan.monthlyAmount,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // 4. "Lock my savings" Card (Matches Image 4)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkNavy.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          PhosphorIcons.lock,
                          color: AppColors.primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lock my savings',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Keep the money until the contribution date.',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _lockSavings,
                        onChanged: (v) => setState(() => _lockSavings = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _showLockExplanationSheet,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              PhosphorIcons.info,
                              size: 14,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'View withdrawal rules & custody conditions',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Create Goal CTA Button
            PrimaryGradientButton(
              label: 'Create Goal',
              showTrailingArrow: true,
              onPressed: _handleCreateGoal,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _MiniSuggestedMetric extends StatelessWidget {
  const _MiniSuggestedMetric({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          AppFormatters.formatCurrency(amount),
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }
}
