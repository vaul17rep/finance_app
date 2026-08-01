/// Хелпер для работы с SQLite базой данных.
///
/// Отвечает за создание, миграцию и CRUD операции.
///
/// Версия БД: 2 (добавлены переводы).
///
/// Связанные документы:
/// - 05_Database_Specification — структура таблиц
/// - 02_Architecture — Data Layer

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/receipt.dart';
import '../../models/receipt_item.dart';
import '../../models/account.dart';
import '../../core/debug/debug_logger.dart';

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
    DebugLogger().logDatabase(
      'Инициализация БД, путь: $path',
      level: LogLevel.info,
    );

    print("DATABASE PATH: $path");

    if (Platform.isWindows) {
      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
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
        version: 2,
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  balance REAL NOT NULL DEFAULT 0,
  initialBalance REAL NOT NULL DEFAULT 0,
  isMain INTEGER NOT NULL DEFAULT 0,
  type TEXT NOT NULL DEFAULT 'other',
  position INTEGER DEFAULT 0
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
  processed INTEGER DEFAULT 0,
  transferId TEXT
)
''');

    await db.execute('''
CREATE TABLE card_color_settings (
  id TEXT PRIMARY KEY,
  cardLightStart INTEGER,
  cardLightEnd INTEGER,
  cashLightStart INTEGER,
  cashLightEnd INTEGER,
  creditLightStart INTEGER,
  creditLightEnd INTEGER,
  otherLightStart INTEGER,
  otherLightEnd INTEGER,
  cardDarkStart INTEGER,
  cardDarkEnd INTEGER,
  cashDarkStart INTEGER,
  cashDarkEnd INTEGER,
  creditDarkStart INTEGER,
  creditDarkEnd INTEGER,
  otherDarkStart INTEGER,
  otherDarkEnd INTEGER,
  custom1Name TEXT DEFAULT '',
  custom1LightStart INTEGER DEFAULT 0xFFB3C6E7,
  custom1LightEnd INTEGER DEFAULT 0xFF8BA7D4,
  custom1DarkStart INTEGER DEFAULT 0xFF2D3A5A,
  custom1DarkEnd INTEGER DEFAULT 0xFF1E2A44,
  custom2Name TEXT DEFAULT '',
  custom2LightStart INTEGER DEFAULT 0xFFB3C6E7,
  custom2LightEnd INTEGER DEFAULT 0xFF8BA7D4,
  custom2DarkStart INTEGER DEFAULT 0xFF2D3A5A,
  custom2DarkEnd INTEGER DEFAULT 0xFF1E2A44,
  custom3Name TEXT DEFAULT '',
  custom3LightStart INTEGER DEFAULT 0xFFB3C6E7,
  custom3LightEnd INTEGER DEFAULT 0xFF8BA7D4,
  custom3DarkStart INTEGER DEFAULT 0xFF2D3A5A,
  custom3DarkEnd INTEGER DEFAULT 0xFF1E2A44,
  custom4Name TEXT DEFAULT '',
  custom4LightStart INTEGER DEFAULT 0xFFB3C6E7,
  custom4LightEnd INTEGER DEFAULT 0xFF8BA7D4,
  custom4DarkStart INTEGER DEFAULT 0xFF2D3A5A,
  custom4DarkEnd INTEGER DEFAULT 0xFF1E2A44,
  custom5Name TEXT DEFAULT '',
  custom5LightStart INTEGER DEFAULT 0xFFB3C6E7,
  custom5LightEnd INTEGER DEFAULT 0xFF8BA7D4,
  custom5DarkStart INTEGER DEFAULT 0xFF2D3A5A,
  custom5DarkEnd INTEGER DEFAULT 0xFF1E2A44
)
''');

    await db.execute('''
CREATE TABLE receipts (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  time TEXT,
  shop TEXT NOT NULL,
  address TEXT,
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
  FOREIGN KEY(receiptId) REFERENCES receipts(id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE transfers (
  id TEXT PRIMARY KEY,
  createdAt TEXT NOT NULL,
  status TEXT DEFAULT 'active'
)
''');

    await db.execute('''
CREATE INDEX idx_operations_transferId ON operations(transferId)
''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    DebugLogger().logDatabase(
      'Миграция БД с версии $oldVersion на $newVersion',
      level: LogLevel.info,
    );

    if (oldVersion < 2) {
      try {
        // 1. Проверяем и создаём таблицу transfers
        final transfersExist = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='transfers'",
        );

        if (transfersExist.isEmpty) {
          await db.execute('''
            CREATE TABLE transfers (
              id TEXT PRIMARY KEY,
              createdAt TEXT NOT NULL,
              status TEXT DEFAULT 'active'
            )
          ''');
          DebugLogger().logDatabase(
            'Таблица transfers создана',
            level: LogLevel.info,
          );
        } else {
          DebugLogger().logDatabase(
            'Таблица transfers уже существует, пропускаем создание',
            level: LogLevel.debug,
          );
        }

        // 2. Проверяем и добавляем колонку transferId в operations
        final columns = await db.rawQuery("PRAGMA table_info(operations)");
        final hasTransferId = columns.any((col) => col['name'] == 'transferId');

        if (!hasTransferId) {
          await db.execute('ALTER TABLE operations ADD COLUMN transferId TEXT');
          DebugLogger().logDatabase(
            'Колонка transferId добавлена в operations',
            level: LogLevel.info,
          );
        } else {
          DebugLogger().logDatabase(
            'Колонка transferId уже существует, пропускаем добавление',
            level: LogLevel.debug,
          );
        }

        // 3. Проверяем и создаём индекс
        final indexExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_operations_transferId'",
        );

        if (indexExists.isEmpty) {
          await db.execute(
            'CREATE INDEX idx_operations_transferId ON operations(transferId)',
          );
          DebugLogger().logDatabase(
            'Индекс idx_operations_transferId создан',
            level: LogLevel.info,
          );
        } else {
          DebugLogger().logDatabase(
            'Индекс idx_operations_transferId уже существует, пропускаем создание',
            level: LogLevel.debug,
          );
        }

        DebugLogger().logDatabase(
          'Миграция на версию 2 успешно завершена',
          level: LogLevel.info,
        );
      } catch (e, stack) {
        DebugLogger().logDatabase(
          'Ошибка миграции БД',
          level: LogLevel.error,
          error: e,
          stackTrace: stack,
        );
        rethrow;
      }
    }
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
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.insert('operations', operation);
      });
      DebugLogger().logDatabase(
        'Операция вставлена: ${operation['id']}',
        level: LogLevel.debug,
      );
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка вставки операции',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
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

    await db.transaction((txn) async {
      final result = await txn.query(
        'operations',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        return;
      }

      await txn.delete('operations', where: 'id = ?', whereArgs: [id]);
    });
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
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(total) as total FROM receipt_items WHERE receiptId = ?',
        [receiptId],
      );
      final total = (result.first['total'] as num?)?.toDouble() ?? 0;
      await db.update(
        'receipts',
        {'amount': total},
        where: 'id = ?',
        whereArgs: [receiptId],
      );
      DebugLogger().logDatabase(
        'Пересчитана сумма чека $receiptId: $total',
        level: LogLevel.debug,
      );
      return total;
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка пересчёта чека $receiptId',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
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
    try {
      final db = await database;
      await db.update(
        'receipts',
        receipt.toMap(),
        where: 'id = ?',
        whereArgs: [receipt.id],
      );
      DebugLogger().logDatabase(
        'Чек обновлён: ${receipt.id}',
        level: LogLevel.debug,
      );
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка обновления чека ${receipt.id}',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
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
    try {
      final db = await database;
      await db.update(
        'receipt_items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      DebugLogger().logDatabase(
        'Товар обновлён: ${item.id}',
        level: LogLevel.debug,
      );
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка обновления товара ${item.id}',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    try {
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
      DebugLogger().logDatabase(
        'Чек удалён: $receiptId',
        level: LogLevel.debug,
      );
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка удаления чека $receiptId',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> insertReceiptWithItems(
    Receipt receipt,
    List<ReceiptItem> items,
  ) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.insert('receipts', receipt.toMap());
        for (final item in items) {
          await txn.insert('receipt_items', item.toMap());
        }
      });
      DebugLogger().logDatabase(
        'Чек с товарами сохранён: ${receipt.id}, товаров=${items.length}',
        level: LogLevel.info,
      );
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка сохранения чека ${receipt.id}',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ============================================
  // Transfer (переводы)
  // ============================================

  /// Получение всех записей о переводах.
  Future<List<Map<String, dynamic>>> getTransfers() async {
    try {
      final db = await database;
      return await db.query('transfers', orderBy: 'createdAt DESC');
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка получения списка переводов',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Получение операций по списку transferId (один запрос).
  Future<List<Map<String, dynamic>>> getOperationsByTransferIds(
    List<String> transferIds,
  ) async {
    try {
      if (transferIds.isEmpty) return [];

      final db = await database;
      final placeholders = transferIds.map((_) => '?').join(',');
      return await db.rawQuery(
        'SELECT * FROM operations WHERE transferId IN ($placeholders)',
        transferIds,
      );
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка получения операций по transferIds',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Вставка записи о переводе.
  Future<void> insertTransfer(Map<String, dynamic> transfer) async {
    try {
      final db = await database;
      await db.insert('transfers', transfer);
      DebugLogger().logDatabase(
        'Перевод сохранён: ${transfer['id']}',
        level: LogLevel.debug,
      );
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка сохранения перевода ${transfer['id']}',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Получение записи о переводе по ID.
  Future<Map<String, dynamic>?> getTransfer(String id) async {
    try {
      final db = await database;
      final result = await db.query(
        'transfers',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка получения перевода $id',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Удаление записи о переводе.
  Future<void> deleteTransfer(String id) async {
    try {
      final db = await database;
      await db.delete('transfers', where: 'id = ?', whereArgs: [id]);
      DebugLogger().logDatabase('Перевод удалён: $id', level: LogLevel.debug);
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка удаления перевода $id',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Получение операций по transferId.
  Future<List<Map<String, dynamic>>> getOperationsByTransferId(
    String transferId,
  ) async {
    try {
      final db = await database;
      return await db.query(
        'operations',
        where: 'transferId = ?',
        whereArgs: [transferId],
      );
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка получения операций по transferId $transferId',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Атомарная вставка нескольких операций в одной транзакции.
  Future<void> insertOperations(List<Map<String, dynamic>> operations) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        for (final op in operations) {
          await txn.insert('operations', op);
        }
      });
      DebugLogger().logDatabase(
        'Вставлено ${operations.length} операций атомарно',
        level: LogLevel.debug,
      );
    } catch (e, stack) {
      DebugLogger().logDatabase(
        'Ошибка атомарной вставки операций',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
