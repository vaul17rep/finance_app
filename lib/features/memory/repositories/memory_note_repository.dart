import 'package:finance_app/data/database/memory_database.dart';
import 'package:finance_app/features/memory/models/memory_note.dart';

class MemoryNoteRepository {
  final MemoryDatabase _db;

  MemoryNoteRepository(this._db);

  Future<void> insertNote(MemoryNote note) async {
    final db = await _db.database;
    await _db.insertMemoryNote(note.toMap());
  }

  Future<void> updateNote(MemoryNote note) async {
    final db = await _db.database;
    await _db.updateMemoryNote(note.toMap());
  }

  Future<void> deleteNote(String id) async {
    final db = await _db.database;
    await _db.deleteMemoryNote(id);
  }

  Future<MemoryNote?> getNote(String id) async {
    final db = await _db.database;
    final map = await _db.getMemoryNote(id);
    if (map == null) return null;
    return MemoryNote.fromMap(map);
  }

  Future<List<MemoryNote>> getAllNotes() async {
    final db = await _db.database;
    final maps = await _db.getAllMemoryNotes();
    return maps.map((map) => MemoryNote.fromMap(map)).toList();
  }

  Future<List<MemoryNote>> getNotesByCategory(String category) async {
    final db = await _db.database;
    final maps = await _db.getMemoryNotesByCategory(category);
    return maps.map((map) => MemoryNote.fromMap(map)).toList();
  }
}
