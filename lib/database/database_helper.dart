import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/receipt.dart';
import '../models/receipt_item.dart';


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

          version: 4,

          onCreate: _createDB,
          onUpgrade: _upgradeDB,

          onOpen: (db) async {
    await db.execute(
      'PRAGMA foreign_keys = ON',
    );
  },

        ),

      );

    } else {

  return await openDatabase(

    path,

    version: 4,

    onCreate: _createDB,  
    onUpgrade: _upgradeDB,

    onOpen: (db) async {
      await db.execute(
        'PRAGMA foreign_keys = ON',
      );
    },

  );
  };
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
          paymentType TEXT,
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

        time TEXT,

        shop TEXT NOT NULL,

        paymentType TEXT,

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

        total REAL NOT NULL,

        priceBeforeDiscount REAL,

        comment TEXT,

        FOREIGN KEY(receiptId) 
          REFERENCES receipts(id)
          ON DELETE CASCADE

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
    Future<void> insertReceipt(
      Receipt receipt,
  ) async {

    final db = await database;


    await db.insert(
      'receipts',
      receipt.toMap(),
    );

  }

    Future<List<Receipt>> getReceipts() async {

    final db = await database;


    final data = await db.query(
      'receipts',
      orderBy: 'date DESC',
    );


    return data
        .map(
          (json) => Receipt.fromMap(json),
        )
        .toList();

  }

    Future<void> insertReceiptItem(
      ReceiptItem item,
  ) async {

    final db = await database;


    await db.insert(
      'receipt_items',
      item.toMap(),
    );

  }

    Future<void> insertReceiptItems(
      List<ReceiptItem> items,
  ) async {

    final db = await database;


    final batch = db.batch();


    for (final item in items) {

      batch.insert(
        'receipt_items',
        item.toMap(),
      );

    }


    await batch.commit();

  }

    Future<List<ReceiptItem>> getReceiptItems(
      String receiptId,
  ) async {

    final db = await database;


    final data = await db.query(
      'receipt_items',
      where: 'receiptId = ?',
      whereArgs: [
        receiptId,
      ],
    );


    return data
        .map(
          (json) => ReceiptItem.fromMap(json),
        )
        .toList();

  }

    Future<void> deleteReceipt(
      String receiptId,
  ) async {

    final db = await database;


    await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [
        receiptId,
      ],
    );

  }

    Future<void> insertReceiptWithItems(
      Receipt receipt,
      List<ReceiptItem> items,
  ) async {


    final db = await database;


    await db.transaction((txn) async {


      await txn.insert(
        'receipts',
        receipt.toMap(),
      );



      for (final item in items) {


        await txn.insert(
          'receipt_items',
          item.toMap(),
        );


      }


    });


  }

}