  import 'package:sqflite/sqflite.dart';
  import 'package:path/path.dart';

  class DBHelper {
    DBHelper._private();
    static final DBHelper instance = DBHelper._private();

    static Database? _db;
    Future<Database> get database async => _db ??= await initDB();

    Future<Database> initDB() async {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'locations.db');

      return await openDatabase(path, version: 1, onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      });
    }

    Future<int> insertLocation(Map<String, dynamic> row) async {
      final db = await database;
      return await db.insert('locations', row);
    }

    // Get locations by date and optional email filter
    Future<List<Map<String, dynamic>>> getLocationsByDate(String date, {String? email}) async {
      final db = await database;
      if (email == null) {
        return await db.query(
          'locations',
          where: 'date = ?',
          whereArgs: [date],
          orderBy: 'timestamp ASC',
        );
      } else {
        return await db.query(
          'locations',
          where: 'date = ? AND email = ?',
          whereArgs: [date, email],
          orderBy: 'timestamp ASC',
        );
      }
    }

    Future<void> clearAll() async {
      final db = await database;
      await db.delete('locations');
    }
  }
