import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/receipt.dart';
import '../models/receipt_item.dart';
import '../models/account.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

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
    print("DATABASE INIT START");
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, fileName);

    print("DATABASE PATH: $path");

    if (Platform.isWindows) {
      return await databaseFactoryFfi.openDatabase(
        path,

        options: OpenDatabaseOptions(
          version: 1,

          onCreate: _createDB,
          onUpgrade: _upgradeDB,

          onOpen: (db) async {
            print("DATABASE OPENED");

            await db.execute('PRAGMA foreign_keys = ON');
          },
        ),
      );
    } else {
      return await openDatabase(
        path,

        version: 1,

        onCreate: _createDB,
        onUpgrade: _upgradeDB,

        onOpen: (db) async {
          print("DATABASE OPENED");

          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    }
  }

  Future<void> debugDatabaseStructure() async {
    final db = await database;

    final result = await db.rawQuery("PRAGMA table_info(operations)");
    await DatabaseHelper.instance.debugDatabaseStructure();

    print("OPERATIONS STRUCTURE:");
    for (final column in result) {
      print(column);
    }
  }

  Future<void> debugOperationsTable() async {
    final db = await database;

    final result = await db.rawQuery("PRAGMA table_info(operations)");

    print("===== OPERATIONS TABLE =====");

    for (final row in result) {
      print(row);
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print("DATABASE UPGRADE $oldVersion -> $newVersion");

    if (oldVersion < 2) {
      await db.execute('''
      ALTER TABLE accounts
      ADD COLUMN type TEXT NOT NULL DEFAULT 'other'
    ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  balance REAL NOT NULL DEFAULT 0,
  initialBalance REAL NOT NULL DEFAULT 0,
  isMain INTEGER NOT NULL DEFAULT 0,
  type TEXT NOT NULL DEFAULT 'other'
)
''');

    await db.execute('''
CREATE TABLE operations (
  id TEXT PRIMARY KEY,
  accountId TEXT,

  type TEXT NOT NULL,
  amount REAL NOT NULL,

  comment TEXT,
  date TEXT NOT NULL,

  shop TEXT,
  article TEXT,
  categoryId TEXT,
  paymentType TEXT,

  receiptId TEXT,
  regularity TEXT,
  workDay INTEGER,

  plannedAmount REAL,
  processed INTEGER DEFAULT 0
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

        category TEXT,

        FOREIGN KEY(receiptId) 
          REFERENCES receipts(id)
          ON DELETE CASCADE

      )

    ''');
  }

  Future<void> debugOperations() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT receiptId, COUNT(*) as count
    FROM operations
    WHERE receiptId IS NOT NULL
    GROUP BY receiptId
    HAVING count > 1
    ''');

    debugPrint(result.toString());
  }

  Future<void> insertOperation(Map<String, dynamic> operation) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert('operations', operation);

      final accountId = operation['accountId'];

      if (accountId == null) {
        return;
      }

      final amount = operation['amount'] as double;
      final type = operation['type'];

      if (type == 'income') {
        await txn.rawUpdate(
          '''
        UPDATE accounts
        SET balance = balance + ?
        WHERE id = ?
        ''',
          [amount, accountId],
        );
      }

      if (type == 'expense') {
        await txn.rawUpdate(
          '''
        UPDATE accounts
        SET balance = balance - ?
        WHERE id = ?
        ''',
          [amount, accountId],
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getOperations() async {
    final db = await database;

    return await db.query('operations', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getOperationsByAccount(
    String accountId,
  ) async {
    final db = await database;

    return await db.query(
      'operations',
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
  }

  Future<void> deleteOperationByReceiptId(String receiptId) async {
    final db = await database;

    await db.delete(
      'operations',
      where: 'receiptId = ?',
      whereArgs: [receiptId],
    );
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await database;

    return await db.query('accounts');
  }

  Future<void> insertAccount(Map<String, dynamic> account) async {
    final db = await database;
    print('INSERT ACCOUNT: $account');
    await db.insert('accounts', account);

    final result = await db.query('accounts');

    print('ALL ACCOUNTS: $result');
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;

    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;

    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteOperation(String id) async {
    final db = await database;

    await db.delete('operations', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // Обновление операции по receiptId
  // ============================================
  Future<void> updateOperationByReceiptId(
    String receiptId,
    double amount,
    String shop,
    DateTime date,
  ) async {
    final db = await database;

    await db.update(
      'operations',
      {'amount': amount, 'shop': shop, 'date': date.toIso8601String()},
      where: 'receiptId = ?',
      whereArgs: [receiptId],
    );
  }

  Future<void> testDatabase() async {
    final db = await database;

    final result = await db.rawQuery("PRAGMA table_info(receipt_items)");

    debugPrint("СТРУКТУРА receipt_items:");

    debugPrint(result.toString());
  }

  Future<double> recalculateReceiptAmount(String receiptId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT SUM(total) as total
    FROM receipt_items
    WHERE receiptId = ?
    ''',
      [receiptId],
    );

    final total = (result.first['total'] as num?)?.toDouble() ?? 0;

    await db.update(
      'receipts',
      {'amount': total},
      where: 'id = ?',
      whereArgs: [receiptId],
    );
    return total;
  }

  Future<void> insertReceipt(Receipt receipt) async {
    final db = await database;

    await db.insert('receipts', receipt.toMap());
  }

  Future<List<Receipt>> getReceipts() async {
    print("DB GET RECEIPTS START");

    final db = await database;

    print("DB OPENED");

    final data = await db.query('receipts', orderBy: 'date DESC');

    print("ROWS: ${data.length}");

    final result = data.map((json) {
      return Receipt.fromMap(json);
    }).toList();

    print("MODELS CREATED");

    return result;
  }

  Future<void> updateOperationAmount(String receiptId, double amount) async {
    final db = await database;

    await db.update(
      'operations',
      {'amount': amount},
      where: 'receiptId = ?',
      whereArgs: [receiptId],
    );
  }

  Future<Receipt?> getReceiptById(String id) async {
    final db = await database;

    final result = await db.query('receipts', where: 'id = ?', whereArgs: [id]);

    if (result.isEmpty) {
      return null;
    }

    return Receipt.fromMap(result.first);
  }

  // ============================================
  // Обновление чека
  // ============================================

  Future<void> updateReceipt(Receipt receipt) async {
    final db = await database;

    await db.update(
      'receipts',

      receipt.toMap(),

      where: 'id = ?',

      whereArgs: [receipt.id],
    );
  }

  Future<void> insertReceiptItem(ReceiptItem item) async {
    final db = await database;

    await db.insert('receipt_items', item.toMap());
  }

  Future<void> insertReceiptItems(List<ReceiptItem> items) async {
    final db = await database;

    final batch = db.batch();

    for (final item in items) {
      batch.insert('receipt_items', item.toMap());
    }

    await batch.commit();
  }

  Future<List<ReceiptItem>> getReceiptItems(String receiptId) async {
    final db = await database;

    final data = await db.query(
      'receipt_items',
      where: 'receiptId = ?',
      whereArgs: [receiptId],
    );

    return data.map((json) => ReceiptItem.fromMap(json)).toList();
  }

  // ============================================
  // Обновление товара чека
  // ============================================

  Future<void> updateReceiptItem(ReceiptItem item) async {
    final db = await database;

    await db.update(
      'receipt_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteReceipt(String receiptId) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'operations',
        where: 'receiptId = ?',
        whereArgs: [receiptId],
      );

      await txn.delete(
        'receipt_items',
        where: 'receiptId = ?',
        whereArgs: [receiptId],
      );

      await txn.delete('receipts', where: 'id = ?', whereArgs: [receiptId]);
    });
  }

  Future<void> insertReceiptWithItems(
    Receipt receipt,
    List<ReceiptItem> items,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert('receipts', receipt.toMap());

      for (final item in items) {
        await txn.insert('receipt_items', item.toMap());
      }
    });
  }
}
