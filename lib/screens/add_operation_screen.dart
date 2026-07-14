import 'package:flutter/material.dart';
import '../models/operation.dart';

class AddOperationScreen extends StatefulWidget {
  const AddOperationScreen({super.key});

  @override
  State<AddOperationScreen> createState() =>
      _AddOperationScreenState();
}


class _AddOperationScreenState extends State<AddOperationScreen> {

  final amountController = TextEditingController();
  final commentController = TextEditingController();

  String type = 'Расход';


  void saveOperation() {

    final amount = double.tryParse(
      amountController.text,
    );

    if (amount == null) {
      return;
    }


    final operation = Operation(

      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),

      date: DateTime.now(),

      type: type,

      amount: amount,

      comment: commentController.text,

    );


    Navigator.pop(
      context,
      operation,
    );
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Добавить операцию',
        ),
      ),


      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          children: [


            TextField(

              controller: amountController,

              keyboardType:
                  TextInputType.number,

              decoration: const InputDecoration(
                labelText: 'Сумма',
                suffixText: '₽',
              ),

            ),


            const SizedBox(height: 16),


            DropdownButton<String>(

              value: type,

              items: const [

                DropdownMenuItem(
                  value: 'Расход',
                  child: Text('Расход'),
                ),

                DropdownMenuItem(
                  value: 'Доход',
                  child: Text('Доход'),
                ),

              ],


              onChanged: (value) {

                if (value != null) {

                  setState(() {
                    type = value;
                  });

                }

              },

            ),


            const SizedBox(height: 16),


            TextField(

              controller: commentController,

              decoration: const InputDecoration(
                labelText: 'Комментарий',
              ),

            ),


            const SizedBox(height: 30),


            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed: saveOperation,

                child: const Text(
                  'Сохранить',
                ),

              ),

            ),


          ],

        ),

      ),

    );

  }

}