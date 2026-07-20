import 'operation_type.dart';

class Operation {
  final String id;

  final OperationType type;

  final double amount;

  final String comment;

  final DateTime date;

  final String? shop;

  final String? article;

  final String? categoryId;

  final String? paymentType;

  final String? receiptId;

  final String? accountId;

  final String? regularity;

  final bool? workDay;

  final double? plannedAmount;

  final bool processed;

  Operation({
    required this.id,
    required this.type,
    required this.amount,
    required this.comment,
    required this.date,
    this.shop,
    this.article,
    this.categoryId,
    this.paymentType,
    this.receiptId,
    this.accountId,
    this.regularity,
    this.workDay,
    this.plannedAmount,
    this.processed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'comment': comment,
      'date': date.toIso8601String(),
      'shop': shop,
      'article': article,
      'categoryId': categoryId,
      'paymentType': paymentType,
      'receiptId': receiptId,
      'accountId': accountId,
      'regularity': regularity,
      'workDay': workDay == null ? null : (workDay! ? 1 : 0),
      'plannedAmount': plannedAmount,
      'processed': processed ? 1 : 0,
    };
  }

  factory Operation.fromMap(Map<String, dynamic> map) {
    return Operation(
      id: map['id'] as String,
      type: OperationType.values.firstWhere((e) => e.name == map['type']),
      amount: (map['amount'] as num).toDouble(),
      comment: map['comment'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      shop: map['shop'] as String?,
      article: map['article'] as String?,
      categoryId: map['categoryId'] as String?,
      paymentType: map['paymentType'] as String?,
      receiptId: map['receiptId'] as String?,
      accountId: map['accountId'] as String?,
      regularity: map['regularity'] as String?,
      workDay: map['workDay'] == null ? null : (map['workDay'] as int) == 1,
      plannedAmount: map['plannedAmount'] == null
          ? null
          : (map['plannedAmount'] as num).toDouble(),
      processed: (map['processed'] ?? 0) == 1,
    );
  }

  Operation copyWith({
    String? id,
    OperationType? type,
    double? amount,
    String? comment,
    DateTime? date,
    String? shop,
    String? article,
    String? categoryId,
    String? paymentType,
    String? receiptId,
    String? accountId,
    String? regularity,
    bool? workDay,
    double? plannedAmount,
    bool? processed,
  }) {
    return Operation(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      comment: comment ?? this.comment,
      date: date ?? this.date,
      shop: shop ?? this.shop,
      article: article ?? this.article,
      categoryId: categoryId ?? this.categoryId,
      paymentType: paymentType ?? this.paymentType,
      receiptId: receiptId ?? this.receiptId,
      accountId: accountId ?? this.accountId,
      regularity: regularity ?? this.regularity,
      workDay: workDay ?? this.workDay,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      processed: processed ?? this.processed,
    );
  }
}
