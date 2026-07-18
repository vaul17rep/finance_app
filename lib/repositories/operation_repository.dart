import '../database/database_helper.dart';
import '../models/operation.dart';


class OperationRepository {

  final DatabaseHelper _dbHelper =
      DatabaseHelper.instance;



  Future<List<Operation>> getOperations() async {

    final data =
        await _dbHelper.getOperations();


    return data.map((json) {

      return Operation(

        id: json['id'].toString(),

        type: json['type'].toString(),

        amount:
            (json['amount'] as num).toDouble(),

        comment:
            json['comment'] ?? '',

        date:
            DateTime.parse(
              json['date'].toString(),
            ),

        shop:
            json['shop'] as String?,

        article:
            json['article'] as String?,

        category:
            json['category'] as String?,

        receiptId:
            json['receiptId'] as String?,

      );

    }).toList();

  }




  Future<void> insertOperation(
      Operation operation,
  ) async {


    await _dbHelper.insertOperation({

      'id': operation.id,

      'type': operation.type,

      'amount': operation.amount,

      'comment': operation.comment,

      'date':
          operation.date.toIso8601String(),

      'shop': operation.shop,

      'article': operation.article,

      'category': operation.category,

      'receiptId': operation.receiptId,

    });


  }

}