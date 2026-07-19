import 'operation_type.dart';

class Operation {
  final String id;

  final OperationType type;

  final double amount;

  final String comment;

  final DateTime date;

  final String? shop;

  final String? article;

  final String? category;

  final String? receiptId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'type': type.name,

      'amount': amount,

      'comment': comment,

      'date': date.toIso8601String(),

      'shop': shop,

      'article': article,

      'category': category,

      'receiptId': receiptId,
    };
  }

  Operation({
    required this.id,

    required this.type,

    required this.amount,

    required this.comment,

    required this.date,

    this.shop,

    this.article,

    this.category,

    this.receiptId,
  });
}
