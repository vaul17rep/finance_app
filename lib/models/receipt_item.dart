class ReceiptItem {

  final String id;

  final String receiptId;

  final String name;

  final String? category;

  final double quantity;

  final String? unit;

  final double price;

  final double total;

  final double? priceBeforeDiscount;

  final String? comment;



  ReceiptItem({

    required this.id,

    required this.receiptId,

    required this.name,

    this.category,

    required this.quantity,

    this.unit,

    required this.price,

    required this.total,

    this.priceBeforeDiscount,

    this.comment,

  });




  // ============================================
  // Преобразование модели в Map для SQLite
  // ============================================

  Map<String, dynamic> toMap() {

    return {

      'id': id,

      'receiptId': receiptId,

      'name': name,

      'category': category,

      'quantity': quantity,

      'unit': unit,

      'price': price,

      'total': total,

      'priceBeforeDiscount': priceBeforeDiscount,

      'comment': comment,

    };

  }




  // ============================================
  // Создание модели из SQLite
  // ============================================

  factory ReceiptItem.fromMap(
      Map<String, dynamic> map,
  ) {

    return ReceiptItem(

      id: map['id'] as String,

      receiptId: map['receiptId'] as String,

      name: map['name'] as String,

      category: map['category'] as String?,

      quantity: (map['quantity'] as num).toDouble(),

      unit: map['unit'] as String?,

      price: (map['price'] as num).toDouble(),

      total: (map['total'] as num).toDouble(),

      priceBeforeDiscount:
          map['priceBeforeDiscount'] == null
              ? null
              : (map['priceBeforeDiscount'] as num)
                  .toDouble(),

      comment: map['comment'] as String?,

    );

  }




  // ============================================
  // Копирование с изменением отдельных полей
  // ============================================

  ReceiptItem copyWith({

    String? id,

    String? receiptId,

    String? name,

    String? category,

    double? quantity,

    String? unit,

    double? price,

    double? total,

    double? priceBeforeDiscount,

    String? comment,

  }) {

    return ReceiptItem(

      id: id ?? this.id,

      receiptId: receiptId ?? this.receiptId,

      name: name ?? this.name,

      category: category ?? this.category,

      quantity: quantity ?? this.quantity,

      unit: unit ?? this.unit,

      price: price ?? this.price,

      total: total ?? this.total,

      priceBeforeDiscount:
          priceBeforeDiscount ?? this.priceBeforeDiscount,

      comment: comment ?? this.comment,

    );

  }

}