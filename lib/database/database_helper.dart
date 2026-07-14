import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


class DatabaseHelper {

  static final DatabaseHelper instance =
      DatabaseHelper._init();


  static Database? _database;


  DatabaseHelper._init();



  Future<Database> get database async {

    if (_database != null) {
      return _database!;
    }


    _database = await _initDB('finance.db');


    return _database!;

  }





  Future<Database> _initDB(String fileName) async {


    final dbPath =
        await getDatabasesPath();


    final path =
        join(dbPath, fileName);



    if (Platform.isWindows) {

      return await databaseFactoryFfi.openDatabase(

        path,

        options: OpenDatabaseOptions(

          version: 1,

          onCreate: _createDB,

        ),

      );

    } else {

      return await openDatabase(

        path,

        version: 1,

        onCreate: _createDB,

      );

    }

  }





  Future<void> _createDB(
      Database db,
      int version,
  ) async {


    await db.execute('''

      CREATE TABLE operations (

        id TEXT PRIMARY KEY,

        type TEXT NOT NULL,

        amount REAL NOT NULL,

        comment TEXT,

        date TEXT NOT NULL

      )

    ''');


  }





  Future<void> insertOperation(
      Map<String, dynamic> operation,
  ) async {


    final db = await database;


    await db.insert(

      'operations',

      operation,

    );


  }





  Future<List<Map<String,dynamic>>> getOperations() async {


    final db = await database;


    return await db.query(

      'operations',

      orderBy: 'date DESC',

    );


  }



  Future<void> testDatabase() async {

    final db = await database;


    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );


    debugPrint("Таблицы в базе:");

    debugPrint(result.toString());

  }


}