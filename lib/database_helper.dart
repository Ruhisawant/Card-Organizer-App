import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // Get the database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  // Initialize the database
  static Future<Database> _initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cards_db.db');
    
    return await openDatabase(
      path, 
      version: 1, 
      onCreate: (db, version) async {
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
            FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE CASCADE
          );
        ''');
      },
      onConfigure: (db) async {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // FOLDER OPERATIONS

  // Method to get all folders
  static Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    return await db.query('folders');
  }

  // Method to add a folder
  static Future<int> addFolder(Map<String, dynamic> folder) async {
    final db = await database;
    return await db.insert('folders', folder);
  }

  // Method to update a folder
  static Future<int> updateFolder(int folderId, Map<String, dynamic> folder) async {
    final db = await database;
    return await db.update(
      'folders',
      folder,
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  // Method to delete a folder and all its cards
  static Future<void> deleteFolder(int folderId) async {
    final db = await database;
    await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  // CARD OPERATIONS

  // Method to get all cards from a folder
  static Future<List<Map<String, dynamic>>> getCards(int folderId) async {
    final db = await database;
    return await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  // Method to get the count of cards in a folder
  static Future<int> getCardCount(int folderId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards WHERE folder_id = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Method to get the first card from a folder (for preview)
  static Future<List<Map<String, dynamic>>> getPreviewCard(int folderId) async {
    final db = await database;
    return await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      limit: 1,
    );
  }

  // Method to add a card
  static Future<int> addCard(Map<String, dynamic> card) async {
    final db = await database;
    return await db.insert('cards', card);
  }

  // Method to update a card
  static Future<int> updateCard(int cardId, Map<String, dynamic> card) async {
    final db = await database;
    return await db.update(
      'cards',
      card,
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  // Method to delete a card
  static Future<int> deleteCard(int cardId) async {
    final db = await database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}