enum SavingsGoalStatus {
  active,
  completed,
  withdrawn,
  cancelled;

  String get label => switch (this) {
    SavingsGoalStatus.active => 'Active',
    SavingsGoalStatus.completed => 'Ready for Njangi',
    SavingsGoalStatus.withdrawn => 'Released',
    SavingsGoalStatus.cancelled => 'Cancelled',
  };
}

enum SavingsLockStatus {
  locked,
  unlocked,
  maturedUnlocked;

  bool get isRestricted => this == SavingsLockStatus.locked;

  String get label => switch (this) {
    SavingsLockStatus.locked => 'Enabled',
    SavingsLockStatus.unlocked => 'Flexible',
    SavingsLockStatus.maturedUnlocked => 'Matured (Unlocked)',
  };
}

/// Represents a Njangi savings commitment.
///
/// All monetary values (`targetAmount`, `amountSaved`, `platformFee`) are stored
/// as exact integer FCFA values to prevent floating-point rounding errors.
/// `amountSaved` only counts verified deposits (`TransactionStatus.successful`).
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.amountSaved,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    required this.lockStatus,
    required this.platformFee,
    this.isSampleData = false,
  });

  final String id;
  final String name;
  final int targetAmount;
  final int amountSaved;
  final DateTime createdAt;
  final DateTime dueDate;
  final SavingsGoalStatus status;
  final SavingsLockStatus lockStatus;
  final int platformFee;
  final bool isSampleData;

  /// Remaining amount needed to reach the full Njangi contribution target.
  int get remainingAmount {
    final diff = targetAmount - amountSaved;
    return diff > 0 ? diff : 0;
  }

  /// Progress fraction clamped between 0.0 and 1.0.
  double get progress {
    if (targetAmount <= 0) return 0;
    final ratio = amountSaved / targetAmount;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  /// Progress percentage (0 to 100).
  int get progressPercent => (progress * 100).round();

  bool get isTargetReached => amountSaved >= targetAmount;

  bool isMaturedAt([DateTime? now]) {
    final ref = now ?? DateTime.now();
    final refDay = DateTime(ref.year, ref.month, ref.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return !refDay.isBefore(dueDay);
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    int? targetAmount,
    int? amountSaved,
    DateTime? createdAt,
    DateTime? dueDate,
    SavingsGoalStatus? status,
    SavingsLockStatus? lockStatus,
    int? platformFee,
    bool? isSampleData,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      amountSaved: amountSaved ?? this.amountSaved,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      lockStatus: lockStatus ?? this.lockStatus,
      platformFee: platformFee ?? this.platformFee,
      isSampleData: isSampleData ?? this.isSampleData,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'amountSaved': amountSaved,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'status': status.name,
    'lockStatus': lockStatus.name,
    'platformFee': platformFee,
    'isSampleData': isSampleData,
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toInt() ?? 0,
      amountSaved: (json['amountSaved'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      dueDate:
          DateTime.tryParse((json['dueDate'] as String?) ?? '') ??
          DateTime.now().add(const Duration(days: 90)),
      status: SavingsGoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SavingsGoalStatus.active,
      ),
      lockStatus: SavingsLockStatus.values.firstWhere(
        (e) => e.name == json['lockStatus'],
        orElse: () => SavingsLockStatus.locked,
      ),
      platformFee: (json['platformFee'] as num?)?.toInt() ?? 1000,
      isSampleData: (json['isSampleData'] as bool?) ?? false,
    );
  }
}
