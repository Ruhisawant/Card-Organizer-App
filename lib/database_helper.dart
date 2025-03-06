import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // Get the database instance
  static Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  // Initialize the database
  static Future<Database> _initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cards_db.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE folders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT
        );
      ''');
      await db.execute('''
        CREATE TABLE cards (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          suit TEXT,
          image_url TEXT,
          folder_id INTEGER,
          resource_url TEXT,
          FOREIGN KEY (folder_id) REFERENCES folders (id)
        );
      ''');
    });
  }

  // Method to delete a card by its ID
  static Future<void> deleteCard(int cardId) async {
    final db = await _getDatabase();
    await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  // Method to get all folders
  static Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await _getDatabase();
    return await db.query('folders');
  }

  // Method to get cards from a specific folder
  static Future<List<Map<String, dynamic>>> getCards(int folderId) async {
    final db = await _getDatabase();
    return await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  // Method to add a card
  static Future<void> addCard(Map<String, dynamic> newCard) async {
    final db = await _getDatabase();
    await db.insert('cards', newCard);
  }
}