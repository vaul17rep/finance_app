//Версия БД увеличена до 3.
//В _onCreate добавлена таблица indexing_state.
//В _onUpgrade добавлена миграция с версии 2 до 3 (создание таблицы).
//Добавлены CRUD-методы для таблицы indexing_state.

import 'dart:typed_data'; // для Uint8List
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/memory/models/embedding_model.dart';

class MemoryDatabase {
  static final MemoryDatabase instance = MemoryDatabase._internal();
  Database? _database;

  MemoryDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'finance_memory.db');
    return await openDatabase(
      dbPath,
      version: 4, // увеличено с 3 до 4
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Создаём таблицу embeddings (основная для Инициативы A)
    await db.execute('''
      CREATE TABLE embeddings (
        id TEXT PRIMARY KEY,
        sourceType TEXT NOT NULL,
        sourceId TEXT NOT NULL,
        content TEXT NOT NULL,
        vector BLOB NOT NULL,
        model TEXT NOT NULL,
        embeddingVersion INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        sourceUpdatedAt TEXT NOT NULL,
        embeddingUpdatedAt TEXT NOT NULL,
        metadata TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_embeddings_source ON embeddings(sourceType, sourceId)',
    );
    await db.execute(
      'CREATE INDEX idx_embeddings_updated ON embeddings(updatedAt)',
    );

    // Пытаемся создать таблицы для sqlite-vec (Инициатива B)
    // Ошибка не должна блокировать запуск приложения
    try {
      await _createVecTable(db);
    } catch (e) {
      print('⚠️ sqlite-vec tables creation failed (not critical): $e');
    }

    // Новая таблица для состояния индексации
    await _createIndexingStateTable(db);

    // Таблица memory_notes
    await _createMemoryNotesTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await _createVecTable(db);
      } catch (e) {
        print('⚠️ sqlite-vec tables upgrade failed (not critical): $e');
      }
    }
    if (oldVersion < 3) {
      await _createIndexingStateTable(db);
    }
    if (oldVersion < 4) {
      await _createMemoryNotesTable(db);
    }
  }

  Future<void> _createVecTable(Database db) async {
    await db.execute('''
    CREATE TABLE embeddings_vec (
      id TEXT PRIMARY KEY,
      sourceType TEXT NOT NULL,
      sourceId TEXT NOT NULL,
      content TEXT NOT NULL,
      vector BLOB NOT NULL,
      model TEXT NOT NULL,
      embeddingVersion INTEGER NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      sourceUpdatedAt TEXT NOT NULL,
      embeddingUpdatedAt TEXT NOT NULL,
      metadata TEXT NOT NULL
    )
  ''');
    await db.execute(
      'CREATE INDEX idx_embeddings_vec_source ON embeddings_vec(sourceType, sourceId)',
    );
    await db.execute('''
    CREATE VIRTUAL TABLE embeddings_vec_index USING vec0(
      id TEXT PRIMARY KEY,
      vector BLOB
    )
  ''');
  }

  Future<void> _createIndexingStateTable(Database db) async {
    await db.execute('''
      CREATE TABLE indexing_state (
        id TEXT PRIMARY KEY,
        sourceType TEXT NOT NULL,
        totalFiles INTEGER NOT NULL,
        processedFiles INTEGER NOT NULL DEFAULT 0,
        skippedFiles INTEGER NOT NULL DEFAULT 0,
        errorFiles INTEGER NOT NULL DEFAULT 0,
        currentFilePath TEXT,
        status TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        resumeToken TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_indexing_state_status ON indexing_state(status)',
    );
  }

  Future<void> _createMemoryNotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE memory_notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_memory_notes_category ON memory_notes(category)',
    );
  }

  // --- CRUD для embeddings (старая таблица) ---

  Future<void> insertEmbedding(EmbeddingModel embedding) async {
    final db = await database;
    await db.insert('embeddings', embedding.toMap());
  }

  Future<void> updateEmbedding(EmbeddingModel embedding) async {
    final db = await database;
    await db.update(
      'embeddings',
      embedding.toMap(),
      where: 'id = ?',
      whereArgs: [embedding.id],
    );
  }

  Future<void> deleteEmbedding(String id) async {
    final db = await database;
    await db.delete('embeddings', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEmbeddingsBySource(
    String sourceType,
    String sourceId,
  ) async {
    final db = await database;
    await db.delete(
      'embeddings',
      where: 'sourceType = ? AND sourceId = ?',
      whereArgs: [sourceType, sourceId],
    );
  }

  Future<EmbeddingModel?> getEmbedding(String id) async {
    final db = await database;
    final maps = await db.query('embeddings', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return EmbeddingModel.fromMap(maps.first);
  }

  Future<EmbeddingModel?> getEmbeddingBySource(
    String sourceType,
    String sourceId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'embeddings',
      where: 'sourceType = ? AND sourceId = ?',
      whereArgs: [sourceType, sourceId],
    );
    if (maps.isEmpty) return null;
    return EmbeddingModel.fromMap(maps.first);
  }

  Future<List<EmbeddingModel>> getAllEmbeddings() async {
    final db = await database;
    final maps = await db.query('embeddings');
    return maps.map((map) => EmbeddingModel.fromMap(map)).toList();
  }

  Future<int> countEmbeddings() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM embeddings',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countIndexedSources() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT sourceType || sourceId) as count FROM embeddings',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- CRUD для embeddings_vec (новая таблица, для Инициативы B) ---

  Future<void> insertEmbeddingVecBatch(List<EmbeddingModel> embeddings) async {
    if (embeddings.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final emb in embeddings) {
        await txn.insert('embeddings_vec', emb.toMap());
        await txn.insert('embeddings_vec_index', {
          'id': emb.id,
          'vector': emb.vector,
        });
      }
    });
  }

  Future<void> insertEmbeddingVec(EmbeddingModel embedding) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('embeddings_vec', embedding.toMap());
      await txn.insert('embeddings_vec_index', {
        'id': embedding.id,
        'vector': embedding.vector,
      });
    });
  }

  Future<void> updateEmbeddingVec(EmbeddingModel embedding) async {
    final db = await database;
    await db.update(
      'embeddings_vec',
      embedding.toMap(),
      where: 'id = ?',
      whereArgs: [embedding.id],
    );
  }

  Future<void> deleteEmbeddingVec(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('embeddings_vec', where: 'id = ?', whereArgs: [id]);
      await txn.delete(
        'embeddings_vec_index',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> deleteEmbeddingsVecBySource(
    String sourceType,
    String sourceId,
  ) async {
    final db = await database;
    final ids = await db.query(
      'embeddings_vec',
      columns: ['id'],
      where: 'sourceType = ? AND sourceId = ?',
      whereArgs: [sourceType, sourceId],
    );
    if (ids.isEmpty) return;
    final idList = ids.map((row) => row['id'] as String).toList();
    final placeholders = idList.map((_) => '?').join(',');
    await db.transaction((txn) async {
      await txn.delete(
        'embeddings_vec',
        where: 'sourceType = ? AND sourceId = ?',
        whereArgs: [sourceType, sourceId],
      );
      await txn.delete(
        'embeddings_vec_index',
        where: 'id IN ($placeholders)',
        whereArgs: idList,
      );
    });
  }

  Future<EmbeddingModel?> getEmbeddingVec(String id) async {
    final db = await database;
    final maps = await db.query(
      'embeddings_vec',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return EmbeddingModel.fromMap(maps.first);
  }

  Future<EmbeddingModel?> getEmbeddingVecBySource(
    String sourceType,
    String sourceId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'embeddings_vec',
      where: 'sourceType = ? AND sourceId = ?',
      whereArgs: [sourceType, sourceId],
    );
    if (maps.isEmpty) return null;
    return EmbeddingModel.fromMap(maps.first);
  }

  Future<List<EmbeddingModel>> getAllEmbeddingsVec() async {
    final db = await database;
    final maps = await db.query('embeddings_vec');
    return maps.map((map) => EmbeddingModel.fromMap(map)).toList();
  }

  Future<int> countEmbeddingsVec() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM embeddings_vec',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<EmbeddingModel>> searchVec(
    Uint8List queryVector, {
    int limit = 10,
  }) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        e.id,
        e.sourceType,
        e.sourceId,
        e.content,
        e.vector,
        e.model,
        e.embeddingVersion,
        e.createdAt,
        e.updatedAt,
        e.sourceUpdatedAt,
        e.embeddingUpdatedAt,
        e.metadata,
        vec_distance_cosine(i.vector, ?) AS distance
      FROM embeddings_vec_index i
      JOIN embeddings_vec e ON i.id = e.id
      ORDER BY distance ASC
      LIMIT ?
    ''',
      [queryVector, limit],
    );

    return result.map((map) => EmbeddingModel.fromMap(map)).toList();
  }

  // --- CRUD для indexing_state ---

  Future<void> insertIndexingState(Map<String, dynamic> state) async {
    final db = await database;
    await db.insert('indexing_state', state);
  }

  Future<void> updateIndexingState(Map<String, dynamic> state) async {
    final db = await database;
    await db.update(
      'indexing_state',
      state,
      where: 'id = ?',
      whereArgs: [state['id']],
    );
  }

  Future<Map<String, dynamic>?> getIndexingState(String sourceType) async {
    final db = await database;
    final result = await db.query(
      'indexing_state',
      where: 'sourceType = ?',
      whereArgs: [sourceType],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<void> deleteIndexingState(String sourceType) async {
    final db = await database;
    await db.delete(
      'indexing_state',
      where: 'sourceType = ?',
      whereArgs: [sourceType],
    );
  }

  // --- CRUD для memory_notes ---

  Future<void> insertMemoryNote(Map<String, dynamic> note) async {
    final db = await database;
    await db.insert('memory_notes', note);
  }

  Future<void> updateMemoryNote(Map<String, dynamic> note) async {
    final db = await database;
    await db.update(
      'memory_notes',
      note,
      where: 'id = ?',
      whereArgs: [note['id']],
    );
  }

  Future<void> deleteMemoryNote(String id) async {
    final db = await database;
    await db.delete('memory_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getMemoryNote(String id) async {
    final db = await database;
    final result = await db.query(
      'memory_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getAllMemoryNotes() async {
    final db = await database;
    return await db.query('memory_notes', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getMemoryNotesByCategory(
    String category,
  ) async {
    final db = await database;
    return await db.query(
      'memory_notes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
  }
}
