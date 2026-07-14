import '../database/database_helper.dart';
import 'package:finance_app/models/receipt.dart';
import '../models/receipt_item.dart';


class ReceiptRepository {

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;



  Future<void> insertReceipt(Receipt receipt) async {

    final db = await _dbHelper.database;


    await db.insert(
      'receipts',
      {
        'id': receipt.id,
        'date': receipt.date.toIso8601String(),
        'shop': receipt.shop,
        'amount': receipt.amount,
        'photoPath': receipt.photoPath,
        'status': receipt.status,
        'comment': receipt.comment,
      },
    );

  }




  Future<List<Receipt>> getReceipts() async {

    final db = await _dbHelper.database;


    final data = await db.query(
      'receipts',
      orderBy: 'date DESC',
    );


    return data.map<Receipt>((json) {

  return Receipt(

    id: json['id'].toString(),

    date: DateTime.parse(
      json['date'].toString(),
    ),

    time: json['time']?.toString(),

    shop: json['shop'].toString(),

    amount: (json['amount'] as num).toDouble(),

    photoPath: json['photoPath']?.toString(),

    status: json['status'].toString(),

    comment: json['comment']?.toString(),

  );

}).toList();

  }




  Future<void> insertReceiptItem(ReceiptItem item) async {

    final db = await _dbHelper.database;


    await db.insert(
      'receipt_items',
      {
        'id': item.id,
        'receiptId': item.receiptId,
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'price': item.price,
        'total': item.total,
      },
    );

  }




  Future<List<ReceiptItem>> getReceiptItems(
      String receiptId,
  ) async {

    final db = await _dbHelper.database;


    final data = await db.query(
      'receipt_items',
      where: 'receiptId = ?',
      whereArgs: [receiptId],
    );


    return data.map((json) {

      return ReceiptItem(
        id: json['id'].toString(),
        receiptId: json['receiptId'].toString(),
        name: json['name'].toString(),
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'].toString(),
        price: (json['price'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );

    }).toList();

  }

}