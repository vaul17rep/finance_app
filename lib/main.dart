import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database/database_helper.dart';
import 'models/operation.dart';
import 'screens/add_operation_screen.dart';
import 'screens/receipts_screen.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

await DatabaseHelper.instance.testDatabase();

  if (Platform.isWindows) {

    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;

  }


  runApp(const FinanceApp());

}



class FinanceApp extends StatelessWidget {

  const FinanceApp({super.key});


  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'Мои финансы',

      debugShowCheckedModeBanner: false,


      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),

        useMaterial3: true,

      ),


      home: const HomeScreen(),

    );

  }

}






class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});


  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();

}






class _HomeScreenState extends State<HomeScreen> {


  List<Operation> operations = [];



  @override
  void initState() {

    super.initState();

    loadOperations();

  }






  Future<void> loadOperations() async {


    final data =
        await DatabaseHelper.instance.getOperations();



    final loaded =
        data.map((json) {


          return Operation(


            id: json['id'].toString(),


            type: json['type'].toString(),


            amount: (json['amount'] as num).toDouble(),


            comment: json['comment'] ?? '',


            date: DateTime.parse(
              json['date'].toString(),
            ),


          );


        }).toList();



    setState(() {

      operations = loaded;

    });


  }








  double get balance {


    double total = 0;



    for (var operation in operations) {


      if (operation.type == 'Доход') {


        total += operation.amount;


      } else {


        total -= operation.amount;


      }

    }



    return total;


  }








  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title: const Text(
          'Мои финансы',
        ),

      ),




      body: Padding(

        padding: const EdgeInsets.all(16),


        child: Column(


          crossAxisAlignment:
              CrossAxisAlignment.start,



          children: [


            const Text(

              'Баланс',

              style: TextStyle(
                fontSize: 18,
              ),

            ),



            const SizedBox(height: 8),



            Text(

              '${balance.toStringAsFixed(0)} ₽',

              style: const TextStyle(

                fontSize: 36,

                fontWeight:
                    FontWeight.bold,

              ),

            ),





            const SizedBox(height: 32),


ElevatedButton.icon(

  onPressed: () {

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (context) =>
            const ReceiptsScreen(),

      ),

    );

  },

  icon: const Icon(Icons.receipt),

  label: const Text(
    'Чеки',
  ),

),


const SizedBox(height: 32),


const Text(

  'Последние операции',

              style: TextStyle(

                fontSize: 20,

                fontWeight:
                    FontWeight.bold,

              ),

            ),





            const SizedBox(height: 16),





            Expanded(


              child: operations.isEmpty


                  ? const Center(

                      child: Text(
                        'Операций пока нет',
                      ),

                    )



                  : ListView.builder(


                      itemCount:
                          operations.length,



                      itemBuilder:
                          (context, index) {



                        final op =
                            operations[index];



                        return ListTile(


                          title: Text(

                            op.comment.isEmpty

                                ? op.type

                                : op.comment,

                          ),



                          subtitle: Text(

                            op.type,

                          ),



                          trailing: Text(


                            '${op.type == "Расход" ? "-" : "+"}'
                            '${op.amount.toStringAsFixed(0)} ₽',


                          ),


                        );


                      },


                    ),


            ),


          ],


        ),


      ),






      floatingActionButton:

          FloatingActionButton(


            onPressed: () async {



              final result =

                  await Navigator.push<Operation>(



                context,



                MaterialPageRoute(


                  builder: (context) =>

                      const AddOperationScreen(),


                ),



              );






              if (result != null) {


                await DatabaseHelper.instance.insertOperation({

                  'id': result.id,

                  'type': result.type,

                  'amount': result.amount,

                  'comment': result.comment,

                  'date': result.date.toIso8601String(),

                });




                setState(() {


                  operations.insert(

                    0,

                    result,

                  );


                });


              }


            },



            child: const Icon(

              Icons.add,

            ),


          ),


    );

  }

}