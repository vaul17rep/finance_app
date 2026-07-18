import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/home_screen.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();


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




















  