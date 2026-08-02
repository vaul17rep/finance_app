
import 'receipt.dart';
import 'receipt_item.dart';

class ParsedReceipt {
  final DateTime? date;

  final String? time;

  final String shop;

  final String? address;

  final String paymentType;

  final String comment;

  final List<ReceiptItem> items;

  final double totalAmount;

  ParsedReceipt({
    required this.date,

    required this.time,

    required this.shop,

    required this.address,

    required this.paymentType,

    required this.comment,

    required this.items,

    required this.totalAmount,
  });

  // ============================================
  // Создание Receipt из результата AI
  // ============================================

  Receipt toReceipt({required String id, String? photoPath}) {
    return Receipt(
      id: id,

      date: date ?? DateTime.now(),

      time: time,

      shop: shop,

      address: address,

      paymentType: paymentType,

      amount: totalAmount,

      photoPath: photoPath,

      status: 'DONE',
    );
  }

  // ============================================
  // Получение товаров чека
  // ============================================

  List<ReceiptItem> toItems({required String receiptId}) {
    return items.map((item) {
      return ReceiptItem(
        id: item.id,

        receiptId: receiptId,

        name: item.name,

        category: item.category,

        quantity: item.quantity,

        unit: item.unit,

        price: item.price,

        total: item.total,

        priceBeforeDiscount: item.priceBeforeDiscount,

        comment: item.comment,
      );
    }).toList();
  }
}
