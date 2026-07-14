import 'receipt.dart';
import 'receipt_item.dart';

class ReceiptResult {
  final Receipt receipt;
  final List<ReceiptItem> items;

  ReceiptResult({
    required this.receipt,
    required this.items,
  });
}