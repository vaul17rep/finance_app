import 'package:flutter/material.dart';

import '../models/operation.dart';
import '../repositories/operation_repository.dart';


class OperationsScreen extends StatefulWidget {

  const OperationsScreen({super.key});


  @override
  State<OperationsScreen> createState() =>
      _OperationsScreenState();

}



class _OperationsScreenState
    extends State<OperationsScreen> {


  final OperationRepository repository =
      OperationRepository();


  List<Operation> operations = [];


  @override
  void initState() {

    super.initState();

    loadOperations();

  }



  Future<void> loadOperations() async {

    final result =
        await repository.getOperations();


    setState(() {

      operations = result;

    });

  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Операции'),
      ),


      body: operations.isEmpty

          ? const Center(
              child: Text(
                'Операций нет',
              ),
            )


          : ListView.builder(

              itemCount: operations.length,


              itemBuilder: (context,index) {


                final operation =
                    operations[index];


                return ListTile(

                  title: Text(
                    operation.shop ?? 'Без магазина',
                  ),


                  subtitle: Text(
                    operation.date.toString(),
                  ),


                  trailing: Text(
                    '-${operation.amount.toStringAsFixed(2)} ₽',
                  ),

                );

              },

            ),

    );

  }

}