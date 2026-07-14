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

          version: 3,

          onCreate: _createDB,
          onUpgrade: _upgradeDB,

        ),

      );

    } else {

      return await openDatabase(

        path,

        version: 3,

        onCreate: _createDB,
        onUpgrade: _upgradeDB,

      );

    }

  }




  Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {


    if (oldVersion < 2) {


      await db.execute('''
        CREATE TABLE receipts (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          shop TEXT NOT NULL,
          amount REAL NOT NULL,
          photoPath TEXT,
          status TEXT NOT NULL,
          comment TEXT
        )
      ''');



      await db.execute('''
        CREATE TABLE receipt_items (
          id TEXT PRIMARY KEY,
          receiptId TEXT NOT NULL,
          name TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          price REAL NOT NULL,
          total REAL NOT NULL,
          FOREIGN KEY (receiptId) REFERENCES receipts(id)
        )
      ''');


    }




    if (oldVersion < 3) {


      await db.execute('''
        ALTER TABLE operations
        ADD COLUMN shop TEXT
      ''');


      await db.execute('''
        ALTER TABLE operations
        ADD COLUMN article TEXT
      ''');


      await db.execute('''
        ALTER TABLE operations
        ADD COLUMN category TEXT
      ''');


      await db.execute('''
        ALTER TABLE operations
        ADD COLUMN receiptId TEXT
      ''');


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

        date TEXT NOT NULL,

        shop TEXT,

        article TEXT,

        category TEXT,

        receiptId TEXT

      )

    ''');




    await db.execute('''

      CREATE TABLE receipts (

        id TEXT PRIMARY KEY,

        date TEXT NOT NULL,

        shop TEXT NOT NULL,

        amount REAL NOT NULL,

        photoPath TEXT,

        status TEXT NOT NULL,

        comment TEXT

      )

    ''');





    await db.execute('''

      CREATE TABLE receipt_items (

        id TEXT PRIMARY KEY,

        receiptId TEXT NOT NULL,

        name TEXT NOT NULL,

        quantity REAL NOT NULL,

        unit TEXT,

        price REAL NOT NULL,

        total REAL NOT NULL

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