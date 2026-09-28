import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance =
      DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(
      databasesPath,
      'mr_koko_signal.db',
    );

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            direction TEXT NOT NULL,
            confidence INTEGER NOT NULL,
            rule TEXT NOT NULL,
            timeframe TEXT NOT NULL,
            confirmations TEXT,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertSignal(
    Map<String, dynamic> data,
  ) async {
    final db = await database;

    return db.insert(
      'history',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;

    return db.query(
      'history',
      orderBy: 'id DESC',
    );
  }

  Future<void> clearAll() async {
    final db = await database;

    await db.delete('history');
  }
}
