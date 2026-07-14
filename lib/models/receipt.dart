class Receipt {

  final String id;

  final DateTime date;

  final String shop;

  final double amount;

  final String? photoPath;

  final String status;

  final String? comment;


  Receipt({

    required this.id,

    required this.date,

    required this.shop,

    required this.amount,

    this.photoPath,

    required this.status,

    this.comment,

  });

}