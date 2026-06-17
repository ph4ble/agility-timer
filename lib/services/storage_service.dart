import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/training_record.dart';

class StorageService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'training_records.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE training_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL,
            bpm INTEGER NOT NULL,
            signal_count INTEGER NOT NULL,
            mode INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insert(TrainingRecord record) async {
    final db = await database;
    return db.insert('training_records', record.toMap());
  }

  Future<List<TrainingRecord>> getAll() async {
    final db = await database;
    final rows = await db.query('training_records', orderBy: 'date DESC', limit: 100);
    return rows.map((r) => TrainingRecord.fromMap(r)).toList();
  }

  Future<List<TrainingRecord>> getByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.query(
      'training_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return rows.map((r) => TrainingRecord.fromMap(r)).toList();
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('training_records', where: 'id = ?', whereArgs: [id]);
  }
}
