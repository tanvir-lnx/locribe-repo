import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('locribe_vault.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Stores the database securely in the native OS documents directory
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
    CREATE TABLE transcripts (
      id $idType,
      title $textType,
      raw_transcript $textType,
      summary $textType,
      created_at $textType
    )
    ''');
  }

  /// Saves a new transcription session to the vault
  Future<int> saveTranscript(String title, String rawTranscript, String summary) async {
    final db = await instance.database;
    final data = {
      'title': title,
      'raw_transcript': rawTranscript,
      'summary': summary,
      'created_at': DateTime.now().toIso8601String(),
    };
    return await db.insert('transcripts', data);
  }

  /// Retrieves all saved transcripts for the left sidebar
  Future<List<Map<String, dynamic>>> fetchAllTranscripts() async {
    final db = await instance.database;
    return await db.query('transcripts', orderBy: 'created_at DESC');
  }

  /// Deletes a transcript from the vault
  Future<int> deleteTranscript(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transcripts', 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }
}