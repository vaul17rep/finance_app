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
    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Создаём таблицу embeddings
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
    // Индексы для быстрого поиска по источнику
    await db.execute(
      'CREATE INDEX idx_embeddings_source ON embeddings(sourceType, sourceId)',
    );
    // Индекс для сортировки по updatedAt (для статуса)
    await db.execute(
      'CREATE INDEX idx_embeddings_updated ON embeddings(updatedAt)',
    );
  }

  // --- CRUD для embeddings ---

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

  // Получить количество записей (для статуса)
  Future<int> countEmbeddings() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM embeddings',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Получить количество источников, которые имеют embedding (уникальные пары sourceType, sourceId)
  Future<int> countIndexedSources() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT sourceType || sourceId) as count FROM embeddings',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
