import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/fapshi_payment_service.dart';
import '../../models/transaction_model.dart';
import '../notifications/notifications_controller.dart';
import '../savings_goals/goals_controller.dart';

class TransactionsState {
  const TransactionsState({
    required this.transactions,
    this.typeFilter,
    this.statusFilter,
    this.isVerifying = false,
  });

  final List<NjangiTransaction> transactions;
  final TransactionType? typeFilter;
  final TransactionStatus? statusFilter;
  final bool isVerifying;

  List<NjangiTransaction> filtered({required bool includeSampleData}) {
    return transactions.where((tx) {
      if (!includeSampleData && tx.isSampleData) return false;
      if (typeFilter != null && tx.type != typeFilter) return false;
      if (statusFilter != null && tx.status != statusFilter) return false;
      return true;
    }).toList();
  }

  List<NjangiTransaction> forGoal(String goalId) {
    return transactions.where((tx) => tx.goalId == goalId).toList();
  }

  TransactionsState copyWith({
    List<NjangiTransaction>? transactions,
    TransactionType? typeFilter,
    bool clearTypeFilter = false,
    TransactionStatus? statusFilter,
    bool clearStatusFilter = false,
    bool? isVerifying,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      isVerifying: isVerifying ?? this.isVerifying,
    );
  }
}

/// Manages Fapshi transactions, verification, and idempotency controls.
///
/// Reuses AfroDocs' idempotency latch (`credited == true`) so duplicate webhook
/// callbacks or repeated manual verification calls never double-credit a goal.
class TransactionsController extends StateNotifier<TransactionsState> {
  TransactionsController({
    required FapshiPaymentService fapshiService,
    required GoalsController goalsController,
    required NotificationsController notificationsController,
  }) : _fapshiService = fapshiService,
       _goalsController = goalsController,
       _notificationsController = notificationsController,
       super(TransactionsState(transactions: _buildSampleTransactions()));

  final FapshiPaymentService _fapshiService;
  final GoalsController _goalsController;
  final NotificationsController _notificationsController;

  static List<NjangiTransaction> _buildSampleTransactions() {
    return [
      NjangiTransaction(
        id: 'tx_demo_01',
        goalId: 'goal_monthly_01',
        goalName: 'Monthly Njangi',
        amount: 35000,
        type: TransactionType.deposit,
        status: TransactionStatus.successful,
        reference: 'FP89K2M1A',
        externalId: 'ext-demo-001',
        paymentMethod: 'MTN Mobile Money',
        createdAt: DateTime(2026, 11, 3, 5, 31),
        credited: true,
        isSampleData: true,
      ),
      NjangiTransaction(
        id: 'tx_demo_02',
        goalId: 'goal_monthly_01',
        goalName: 'Monthly Njangi',
        amount: 35000,
        type: TransactionType.deposit,
        status: TransactionStatus.successful,
        reference: 'FP74L9P3B',
        externalId: 'ext-demo-002',
        paymentMethod: 'Orange Money',
        createdAt: DateTime(2026, 10, 27, 5, 31),
        credited: true,
        isSampleData: true,
      ),
      NjangiTransaction(
        id: 'tx_demo_03',
        goalId: 'goal_small_02',
        goalName: 'Small Njangi',
        amount: 20000,
        type: TransactionType.deposit,
        status: TransactionStatus.successful,
        reference: 'FP52W8C4X',
        externalId: 'ext-demo-003',
        paymentMethod: 'MTN Mobile Money',
        createdAt: DateTime(2026, 10, 22, 5, 31),
        credited: true,
        isSampleData: true,
      ),
      NjangiTransaction(
        id: 'tx_demo_04',
        goalId: 'goal_small_02',
        goalName: 'Small Njangi',
        amount: 1000,
        type: TransactionType.platformFee,
        status: TransactionStatus.successful,
        reference: 'FP52FEE01',
        externalId: 'ext-demo-004',
        paymentMethod: 'MTN Mobile Money',
        createdAt: DateTime(2026, 10, 22, 5, 31),
        credited: true,
        isSampleData: true,
      ),
      NjangiTransaction(
        id: 'tx_demo_05',
        goalId: 'goal_family_03',
        goalName: 'Family Njangi',
        amount: 80000,
        type: TransactionType.deposit,
        status: TransactionStatus.successful,
        reference: 'FP91Q4N7Z',
        externalId: 'ext-demo-005',
        paymentMethod: 'MTN Mobile Money',
        createdAt: DateTime(2026, 10, 20, 5, 31),
        credited: true,
        isSampleData: true,
      ),
    ];
  }

  void setTypeFilter(TransactionType? type) {
    state = state.copyWith(typeFilter: type, clearTypeFilter: type == null);
  }

  void setStatusFilter(TransactionStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
  }

  /// Records a newly initiated Fapshi deposit as `PENDING` (`credited: false`).
  /// Does NOT update the goal's `amountSaved` until `verifyTransaction` confirms
  /// `TransactionStatus.successful`.
  NjangiTransaction recordInitiatedDeposit({
    required String goalId,
    required String goalName,
    required int amount,
    required String transId,
    required String externalId,
    required String paymentMethod,
    required String payerPhone,
  }) {
    // Prevent duplicate transaction entries with the same Fapshi transId
    for (final existing in state.transactions) {
      if (existing.reference == transId) {
        return existing;
      }
    }

    final tx = NjangiTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      goalId: goalId,
      goalName: goalName,
      amount: amount,
      type: TransactionType.deposit,
      status: TransactionStatus.pending,
      reference: transId,
      externalId: externalId,
      paymentMethod: paymentMethod,
      payerPhone: payerPhone,
      createdAt: DateTime.now(),
      credited: false,
      isSampleData: false,
    );

    state = state.copyWith(transactions: [tx, ...state.transactions]);
    return tx;
  }

  /// Verifies a transaction with Fapshi (`payment_status`) and applies AfroDocs'
  /// idempotency latch (`credited == true`) so duplicate webhook/manual calls
  /// never credit the same deposit twice.
  Future<FapshiVerificationResult> verifyTransaction(
    String transId, {
    TransactionStatus? simulatedSandboxOutcome,
  }) async {
    state = state.copyWith(isVerifying: true);

    try {
      final targetIndex = state.transactions.indexWhere(
        (t) => t.reference == transId,
      );
      if (targetIndex == -1) {
        state = state.copyWith(isVerifying: false);
        return FapshiVerificationResult(
          transId: transId,
          status: TransactionStatus.failed,
          amount: 0,
          verifiedByServer: false,
          message: 'Transaction $transId not found.',
        );
      }

      final currentTx = state.transactions[targetIndex];

      // Idempotency guard: if already SUCCESSFUL and credited, return immediately
      // without crediting the goal balance a second time!
      if (currentTx.status == TransactionStatus.successful &&
          currentTx.credited) {
        state = state.copyWith(isVerifying: false);
        return FapshiVerificationResult(
          transId: transId,
          status: TransactionStatus.successful,
          amount: currentTx.amount,
          verifiedByServer: true,
          message:
              'Idempotency guard: Transaction $transId was already verified and credited.',
        );
      }

      final result = await _fapshiService.verifyTransactionStatus(
        transId: transId,
        simulatedSandboxOutcome: simulatedSandboxOutcome,
      );

      final shouldCredit =
          result.verifiedByServer &&
          result.status == TransactionStatus.successful &&
          !currentTx.credited &&
          currentTx.type == TransactionType.deposit;

      final updatedTx = currentTx.copyWith(
        status: result.status,
        credited: currentTx.credited || shouldCredit,
      );

      final updatedList = [...state.transactions];
      updatedList[targetIndex] = updatedTx;
      state = state.copyWith(transactions: updatedList, isVerifying: false);

      if (shouldCredit) {
        _goalsController.creditVerifiedDeposit(
          goalId: currentTx.goalId,
          verifiedAmountFcfa: currentTx.amount,
        );
        _notificationsController.addDepositNotification(
          goalName: currentTx.goalName,
          amountFcfa: currentTx.amount,
          transId: currentTx.reference,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(isVerifying: false);
      return FapshiVerificationResult(
        transId: transId,
        status: TransactionStatus.pending,
        amount: 0,
        verifiedByServer: false,
        message: 'Verification deferred: $e',
      );
    }
  }

  /// Initiates and verifies an authorised Fapshi payout for a matured/unlocked goal.
  Future<FapshiPayoutResult> executeAuthorisedPayout({
    required String goalId,
    required String goalName,
    required int amountFcfa,
    required String recipientPhone,
    required FapshiPaymentMedium medium,
  }) async {
    final result = await _fapshiService.initiateAuthorisedPayout(
      goalId: goalId,
      goalName: goalName,
      amountFcfa: amountFcfa,
      recipientPhone: recipientPhone,
      medium: medium,
    );

    final payoutTx = NjangiTransaction(
      id: 'tx_payout_${DateTime.now().millisecondsSinceEpoch}',
      goalId: goalId,
      goalName: goalName,
      amount: amountFcfa,
      type: TransactionType.withdrawal,
      status: result.status,
      reference: result.transId,
      paymentMethod: medium.displayName,
      payerPhone: recipientPhone,
      createdAt: DateTime.now(),
      credited: result.success,
      isSampleData: false,
    );

    state = state.copyWith(transactions: [payoutTx, ...state.transactions]);

    if (result.success && result.status == TransactionStatus.successful) {
      _goalsController.recordVerifiedPayout(
        goalId: goalId,
        payoutAmountFcfa: amountFcfa,
      );
    }
    return result;
  }
}

final transactionsControllerProvider =
    StateNotifierProvider<TransactionsController, TransactionsState>((ref) {
      return TransactionsController(
        fapshiService: ref.watch(fapshiPaymentServiceProvider),
        goalsController: ref.watch(goalsControllerProvider.notifier),
        notificationsController: ref.watch(
          notificationsControllerProvider.notifier,
        ),
      );
    });
