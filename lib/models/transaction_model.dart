enum TransactionType {
  deposit,
  withdrawal,
  platformFee;

  String get label => switch (this) {
    TransactionType.deposit => 'Deposit',
    TransactionType.withdrawal => 'Payout / Withdrawal',
    TransactionType.platformFee => 'Platform Fee',
  };
}

enum TransactionStatus {
  successful,
  pending,
  failed,
  expired;

  String get label => switch (this) {
    TransactionStatus.successful => 'Completed',
    TransactionStatus.pending => 'Pending Verification',
    TransactionStatus.failed => 'Failed',
    TransactionStatus.expired => 'Expired',
  };

  String get fapshiStatusCode => switch (this) {
    TransactionStatus.successful => 'SUCCESSFUL',
    TransactionStatus.pending => 'PENDING',
    TransactionStatus.failed => 'FAILED',
    TransactionStatus.expired => 'EXPIRED',
  };

  static TransactionStatus fromFapshiStatus(String? raw) {
    return switch ((raw ?? '').toUpperCase().trim()) {
      'SUCCESSFUL' => TransactionStatus.successful,
      'FAILED' => TransactionStatus.failed,
      'EXPIRED' => TransactionStatus.expired,
      _ => TransactionStatus.pending,
    };
  }
}

/// Represents a NjangiSave financial transaction processed via Fapshi.
///
/// Exact integer FCFA amounts are used throughout.
/// Only `TransactionStatus.successful` deposits with `credited == true`
/// contribute to a goal's `amountSaved`.
class NjangiTransaction {
  const NjangiTransaction({
    required this.id,
    required this.goalId,
    required this.goalName,
    required this.amount,
    required this.type,
    required this.status,
    required this.reference,
    required this.createdAt,
    this.externalId = '',
    this.paymentMethod = 'MTN Mobile Money',
    this.payerPhone = '+237 6 70 12 34 56',
    this.credited = false,
    this.isSampleData = false,
  });

  final String id;
  final String goalId;
  final String goalName;
  final int amount;
  final TransactionType type;
  final TransactionStatus status;

  /// Fapshi transaction reference (`transId`, 8-10 alphanumeric characters).
  final String reference;

  /// Client/Server idempotency UUID (`externalId`).
  final String externalId;
  final String paymentMethod;
  final String payerPhone;
  final DateTime createdAt;

  /// Idempotency latch (reused from AfroDocs): ensures a verified Fapshi
  /// transaction credits the goal balance at most once.
  final bool credited;
  final bool isSampleData;

  NjangiTransaction copyWith({
    String? id,
    String? goalId,
    String? goalName,
    int? amount,
    TransactionType? type,
    TransactionStatus? status,
    String? reference,
    String? externalId,
    String? paymentMethod,
    String? payerPhone,
    DateTime? createdAt,
    bool? credited,
    bool? isSampleData,
  }) {
    return NjangiTransaction(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      externalId: externalId ?? this.externalId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payerPhone: payerPhone ?? this.payerPhone,
      createdAt: createdAt ?? this.createdAt,
      credited: credited ?? this.credited,
      isSampleData: isSampleData ?? this.isSampleData,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'goalId': goalId,
    'goalName': goalName,
    'amount': amount,
    'type': type.name,
    'status': status.name,
    'reference': reference,
    'externalId': externalId,
    'paymentMethod': paymentMethod,
    'payerPhone': payerPhone,
    'createdAt': createdAt.toIso8601String(),
    'credited': credited,
    'isSampleData': isSampleData,
  };

  factory NjangiTransaction.fromJson(Map<String, dynamic> json) {
    return NjangiTransaction(
      id: (json['id'] as String?) ?? '',
      goalId: (json['goalId'] as String?) ?? '',
      goalName: (json['goalName'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.deposit,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      reference: (json['reference'] as String?) ?? '',
      externalId: (json['externalId'] as String?) ?? '',
      paymentMethod: (json['paymentMethod'] as String?) ?? 'MTN Mobile Money',
      payerPhone: (json['payerPhone'] as String?) ?? '+237 6 70 12 34 56',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      credited: (json['credited'] as bool?) ?? false,
      isSampleData: (json['isSampleData'] as bool?) ?? false,
    );
  }
}
