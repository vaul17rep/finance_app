import 'receipt_item.dart';

class ParsedReceipt {
  final DateTime? date;
  final String? time;
  final String shop;
  final String paymentType;
  final List<ReceiptItem> items;
  final double totalAmount;

  ParsedReceipt({
    required this.date,
    required this.time,
    required this.shop,
    required this.paymentType,
    required this.items,
    required this.totalAmount,
  });
}