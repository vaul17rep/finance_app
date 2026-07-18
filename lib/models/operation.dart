class Operation {

  final String id;

  final String type;

  final double amount;

  final String comment;

  final DateTime date;

  final String? shop;

  final String? article;

  final String? category;

  final String? receiptId;


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