import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/receipt.dart';
import '../repositories/receipt_repository.dart';
import '../services/openrouter_service.dart';
import '../secrets.dart';
import '../services/photo_storage_service.dart';


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

Future<ImageSource?> selectImageSource() async {

  return await showModalBottomSheet<ImageSource>(

    context: context,

    builder: (context) {

      return SafeArea(

        child: Wrap(

          children: [

            ListTile(

              leading: const Icon(Icons.camera_alt),

              title: const Text(
                'Камера',
              ),

              onTap: () {

                Navigator.pop(
                  context,
                  ImageSource.camera,
                );

              },

            ),


            ListTile(

              leading: const Icon(Icons.photo),

              title: const Text(
                'Галерея',
              ),

              onTap: () {

                Navigator.pop(
                  context,
                  ImageSource.gallery,
                );

              },

            ),

          ],

        ),

      );

    },

  );

}

Future<void> addReceipt() async {


  final source =
    await selectImageSource();


if(source == null){
  return;
}


final XFile? image =
    await picker.pickImage(
      source: source,
    );


  if(image == null){
    return;
  }

  final savedPhotoPath =
    await PhotoStorageService.savePhoto(
      File(image.path),
    );


  final bytes =
      await File(image.path).readAsBytes();


  final base64 =
    "data:image/jpeg;base64,${base64Encode(bytes)}";



  final service =
      OpenRouterService(
        apiKey: Secrets.openRouterApiKey,
      );


  try {


  final result =
      await service.analyzeReceipt(base64);



  print("МАГАЗИН:");
  print(result.shop);


  print("ТОВАРОВ:");
  print(result.items.length);



  final receipt = Receipt(

    id:
      'CHK-${DateTime.now().millisecondsSinceEpoch}',

    date:
      result.date ?? DateTime.now(),

    time:
      result.time, 

    shop:
      result.shop,

    amount:
      result.items.fold(
        0,
        (sum, item) => sum + item.total,
      ),

    photoPath:
      savedPhotoPath,

    status:
      'DONE',

    comment:
      result.paymentType,

  );


  await repository.insertReceipt(receipt);


  await loadReceipts();


}
catch(e){

  print(
    "ОШИБКА: $e",
  );

}


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