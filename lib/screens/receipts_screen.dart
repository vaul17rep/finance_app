import 'package:flutter/material.dart';

import '../repositories/receipt_repository.dart';
import '../models/receipt.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


class ReceiptsScreen extends StatefulWidget {

  const ReceiptsScreen({super.key});


  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();

}



class _ReceiptsScreenState extends State<ReceiptsScreen> {


  final ReceiptRepository repository =
      ReceiptRepository();

  final ImagePicker picker = ImagePicker();

  List<Receipt> receipts = [];


  @override
  void initState() {
    super.initState();

    loadReceipts();
  }



  Future<void> loadReceipts() async {

    final result =
        await repository.getReceipts();


    setState(() {

      receipts = result;

    });

  }

  Future<void> addReceipt() async {

  final XFile? image =
      await picker.pickImage(
        source: ImageSource.camera,
      );


  if (image == null) {
    return;
  }


  final receipt = Receipt(

    id: 'CHK-${DateTime.now().millisecondsSinceEpoch}',

    date: DateTime.now(),

    shop: 'Не определён',

    amount: 0,

    photoPath: image.path,

    status: 'NEW',

    comment: 'Ожидает обработки',

  );


  await repository.insertReceipt(receipt);


  await loadReceipts();


}

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Чеки'),
      ),


      body: receipts.isEmpty

          ? const Center(
              child: Text(
                'Чеков пока нет',
              ),
            )

          : ListView.builder(

              itemCount: receipts.length,

              itemBuilder: (context, index) {

                final receipt = receipts[index];


                return ListTile(

                  title: Text(receipt.shop),

                  subtitle: Text(
                    receipt.date.toString(),
                  ),

                  trailing: Text(
                    '${receipt.amount} ₽',
                  ),

                );

              },

            ),


      floatingActionButton: FloatingActionButton(

  onPressed: addReceipt,

  child: const Icon(Icons.add),

),

    );

  }

}