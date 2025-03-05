import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // Singleton pattern to ensure only one instance of the database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'card_organizer.db');
    return openDatabase(path, onCreate: (db, version) {
      // Create Folders table
      db.execute('''
        CREATE TABLE Folders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        );
      ''');

      // Create Cards table
      db.execute('''
        CREATE TABLE Cards (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          suit TEXT NOT NULL,
          image_url TEXT,
          folder_id INTEGER,
          FOREIGN KEY (folder_id) REFERENCES Folders(id)
        );
      ''');
    }, version: 1);
  }
}