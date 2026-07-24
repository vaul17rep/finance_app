class Account {
  final String id;
  final String name;
  final double? balance;
  final double initialBalance;
  final bool isMain;
  final String type;
  final int position;

  Account({
    required this.id,
    required this.name,
    this.balance,
    this.initialBalance = 0,
    required this.isMain,
    this.type = 'other',
    this.position = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'initialBalance': initialBalance,
      'isMain': isMain ? 1 : 0,
      'type': type,
      'position': position,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: map['balance'] == null
    ? null
    : (map['balance'] as num).toDouble(),
      initialBalance: (map['initialBalance'] ?? map['balance'] ?? 0).toDouble(),
      isMain: (map['isMain'] ?? 0) == 1,
      type: map['type'] as String? ?? 'other',
      position: map['position'] ?? 0,
    );
  }

  Account copyWith({
    String? id,
    String? name,
    double? balance,
    double? initialBalance,
    bool? isMain,
    String? type,
    int? position,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      isMain: isMain ?? this.isMain,
      type: type ?? this.type,
      position: position ?? this.position,
    );
  }
}
