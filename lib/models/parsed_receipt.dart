import 'package:finance_app/models/receipt.dart';
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




  // ============================================
  // Создание Receipt из результата AI
  // ============================================

  Receipt toReceipt({

    required String id,

    String? photoPath,

  }) {

    return Receipt(

      id: id,

      date: date ?? DateTime.now(),

      time: time,

      shop: shop,

      amount: totalAmount,

      photoPath: photoPath,

      status: 'DONE',

      comment: paymentType,

    );

  }




  // ============================================
  // Получение товаров чека
  // ============================================

  List<ReceiptItem> toItems({

    required String receiptId,

  }) {

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

        priceBeforeDiscount:
            item.priceBeforeDiscount,

        comment: item.comment,

      );

    }).toList();

  }


}