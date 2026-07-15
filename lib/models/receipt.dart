class Receipt {
  final String id;

  final DateTime date;

  final String? time;

  final String shop;

  final String? paymentType;

  final double amount;

  final String? photoPath;

  final String status;

  final String? comment;


  Receipt({
    required this.id,
    required this.date,
    required this.time,
    required this.shop,
    this.paymentType,
    required this.amount,
    this.photoPath,
    required this.status,
    this.comment,
  });



  // ============================================
  // Преобразование модели в Map для SQLite
  // ============================================

  Map<String, dynamic> toMap() {

    return {

      'id': id,

      'date': date.toIso8601String(),

      'time': time,

      'shop': shop,

      'paymentType': paymentType,

      'amount': amount,

      'photoPath': photoPath,

      'status': status,

      'comment': comment,

    };

  }



  // ============================================
  // Создание модели из данных SQLite
  // ============================================

  factory Receipt.fromMap(
      Map<String, dynamic> map,
  ) {

    return Receipt(

      id: map['id'] as String,

      date: DateTime.parse(
        map['date'] as String,
      ),

      time: map['time'] as String?,

      shop: map['shop'] as String,

      paymentType:
        map['paymentType'] as String?,

      amount: (map['amount'] as num).toDouble(),

      photoPath: map['photoPath'] as String?,

      status: map['status'] as String,

      comment: map['comment'] as String?,

    );

  }



  // ============================================
  // Создание копии с изменением отдельных полей
  // ============================================

  Receipt copyWith({

    String? id,

    DateTime? date,

    String? time,

    String? shop,

    String? paymentType,

    double? amount,

    String? photoPath,

    String? status,

    String? comment,

  }) {

    return Receipt(

      id: id ?? this.id,

      date: date ?? this.date,

      time: time ?? this.time,

      shop: shop ?? this.shop,

      paymentType:
        paymentType ?? this.paymentType,

      amount: amount ?? this.amount,

      photoPath: photoPath ?? this.photoPath,

      status: status ?? this.status,

      comment: comment ?? this.comment,

    );

  }

}