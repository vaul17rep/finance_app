
import 'package:finance_app/data/database/memory_database.dart';
import 'package:finance_app/features/memory/models/memory_note.dart';

class MemoryNoteRepository {
  final MemoryDatabase db;

  MemoryNoteRepository(this.db);

  Future<void> insertNote(MemoryNote note) async {
    final db = await this.db.database;
    await db.insert('memory_notes', note.toMap());
  }

  Future<void> updateNote(MemoryNote note) async {
    final db = await this.db.database;
    await db.update(
      'memory_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await this.db.database;
    await db.delete('memory_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<MemoryNote?> getNote(String id) async {
    final db = await this.db.database;
    final maps = await db.query(
      'memory_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MemoryNote.fromMap(maps.first);
  }

  Future<List<MemoryNote>> getAllNotes() async {
    final db = await this.db.database;
    final maps = await db.query('memory_notes', orderBy: 'createdAt DESC');
    return maps.map((map) => MemoryNote.fromMap(map)).toList();
  }

  Future<List<MemoryNote>> getNotesByCategory(String category) async {
    final db = await this.db.database;
    final maps = await db.query(
      'memory_notes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => MemoryNote.fromMap(map)).toList();
  }
}
