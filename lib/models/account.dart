class Account {
  final String id;

  final String name;

  final double balance;

  final bool isMain;

  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.isMain,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'isMain': isMain ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      isMain: (map['isMain'] ?? 0) == 1,
    );
  }

  Account copyWith({String? id, String? name, double? balance, bool? isMain}) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isMain: isMain ?? this.isMain,
    );
  }
}
