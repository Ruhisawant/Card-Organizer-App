import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'card_organizer.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Create folders table
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create cards table with foreign key reference to folders
    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders (id)
          ON DELETE CASCADE
      )
    ''');

    // Insert default folders for each suit
    int heartsId = await db.insert('folders', {'name': 'Hearts Collection', 'suit': 'Hearts'});
    int spadesId = await db.insert('folders', {'name': 'Spades Collection', 'suit': 'Spades'});
    int diamondsId = await db.insert('folders', {'name': 'Diamonds Collection', 'suit': 'Diamonds'});
    int clubsId = await db.insert('folders', {'name': 'Clubs Collection', 'suit': 'Clubs'});

    // Prepopulate the Cards table with standard cards for each suit
    await _prepopulateCards(db, heartsId, spadesId, diamondsId, clubsId);
  }

  Future<void> _prepopulateCards(Database db, int heartsId, int spadesId, int diamondsId, int clubsId) async {
    // Card names
    final List<String> cardNames = [
      'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
    ];

    // Create cards for Hearts
    for (var cardName in cardNames) {
      await db.insert('cards', {
        'name': cardName,
        'suit': 'Hearts',
        'image_url': 'assets/images/cards/${cardName.toLowerCase()}_of_hearts.png',
        'folder_id': heartsId
      });
    }

    // Create cards for Spades
    for (var cardName in cardNames) {
      await db.insert('cards', {
        'name': cardName,
        'suit': 'Spades',
        'image_url': 'assets/images/cards/${cardName.toLowerCase()}_of_spades.png',
        'folder_id': spadesId
      });
    }

    // Create cards for Diamonds
    for (var cardName in cardNames) {
      await db.insert('cards', {
        'name': cardName,
        'suit': 'Diamonds',
        'image_url': 'assets/images/cards/${cardName.toLowerCase()}_of_diamonds.png',
        'folder_id': diamondsId
      });
    }

    // Create cards for Clubs
    for (var cardName in cardNames) {
      await db.insert('cards', {
        'name': cardName,
        'suit': 'Clubs',
        'image_url': 'assets/images/cards/${cardName.toLowerCase()}_of_clubs.png',
        'folder_id': clubsId
      });
    }
  }

  // Basic CRUD operations for folders
  Future<int> insertFolder(Map<String, dynamic> folder) async {
    final db = await database;
    return await db.insert('folders', folder);
  }

  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    return await db.query('folders');
  }

  Future<int> updateFolder(Map<String, dynamic> folder) async {
    final db = await database;
    return await db.update(
      'folders',
      folder,
      where: 'id = ?',
      whereArgs: [folder['id']],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await database;
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Basic CRUD operations for cards
  Future<int> insertCard(Map<String, dynamic> card) async {
    final db = await database;
    return await db.insert('cards', card);
  }

  Future<List<Map<String, dynamic>>> getCards() async {
    final db = await database;
    return await db.query('cards');
  }

  Future<List<Map<String, dynamic>>> getCardsByFolder(int folderId) async {
    final db = await database;
    return await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  Future<int> updateCard(Map<String, dynamic> card) async {
    final db = await database;
    return await db.update(
      'cards',
      card,
      where: 'id = ?',
      whereArgs: [card['id']],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}