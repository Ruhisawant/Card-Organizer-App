import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Card Organizer App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _folders = [];
  List<Map<String, dynamic>> _cards = [];
  int? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    // Initialize the database and load initial data
    await _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await _dbHelper.getFolders();
    setState(() {
      _folders = folders;
      if (folders.isNotEmpty) {
        _selectedFolderId = folders[0]['id'];
        _loadCards(_selectedFolderId!);
      }
    });
  }

  Future<void> _loadCards(int folderId) async {
    final cards = await _dbHelper.getCardsByFolder(folderId);
    setState(() {
      _cards = cards;
      _selectedFolderId = folderId;
    });
  }

  // Add a new card with URL resource
  Future<void> _addCard() async {
    final cardNameController = TextEditingController();
    final cardSuitController = TextEditingController();
    final cardImageController = TextEditingController();
    final cardUrlController = TextEditingController(text: 'https://en.wikipedia.org/wiki/Diamonds_(suit)'); // Default URL

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardNameController,
                decoration: const InputDecoration(labelText: 'Card Name'),
              ),
              TextField(
                controller: cardSuitController,
                decoration: const InputDecoration(labelText: 'Suit'),
              ),
              TextField(
                controller: cardImageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              TextField(
                controller: cardUrlController,
                decoration: const InputDecoration(labelText: 'Resource URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (cardNameController.text.isNotEmpty &&
                    cardSuitController.text.isNotEmpty) {
                  final newCard = {
                    'name': cardNameController.text,
                    'suit': cardSuitController.text,
                    'image_url': cardImageController.text.isEmpty
                        ? null
                        : cardImageController.text,
                    'folder_id': _selectedFolderId,
                    'resource_url': cardUrlController.text,
                  };
                  await _dbHelper.insertCard(newCard);
                  _loadCards(_selectedFolderId!);  // Reload cards after insert
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }


  // Update an existing card
  Future<void> _updateCard(int cardId) async {
    final cardNameController = TextEditingController();
    final cardSuitController = TextEditingController();
    final cardImageController = TextEditingController();

    final card = _cards.firstWhere((card) => card['id'] == cardId);
    cardNameController.text = card['name'];
    cardSuitController.text = card['suit'];
    cardImageController.text = card['image_url'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardNameController,
                decoration: const InputDecoration(labelText: 'Card Name'),
              ),
              TextField(
                controller: cardSuitController,
                decoration: const InputDecoration(labelText: 'Suit'),
              ),
              TextField(
                controller: cardImageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final updatedCard = {
                  'id': cardId,
                  'name': cardNameController.text,
                  'suit': cardSuitController.text,
                  'image_url': cardImageController.text.isEmpty
                      ? null
                      : cardImageController.text,
                  'folder_id': _selectedFolderId,
                };
                await _dbHelper.updateCard(updatedCard);
                _loadCards(_selectedFolderId!);  // Reload cards after update
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Delete a card
  Future<void> _deleteCard(int cardId) async {
    await _dbHelper.deleteCard(cardId);
    _loadCards(_selectedFolderId!);  // Reload cards after delete
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Display folders
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Folders: ${_folders.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final isSelected = folder['id'] == _selectedFolderId;
                return GestureDetector(
                  onTap: () {
                    _loadCards(folder['id']);
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          folder['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          folder['suit'],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Display cards
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Cards in Selected Folder: ${_cards.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _selectedFolderId == null
                ? const Center(child: Text('Select a folder to view cards'))
                : GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      final card = _cards[index];
                      return Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                card['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Suit: ${card['suit']}'),
                              if (card['image_url'] != null && card['image_url'].toString().isNotEmpty)
                                Expanded(
                                  child: Center(
                                    child: Image.asset(
                                      card['image_url'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              // Edit/Delete options
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    onPressed: () => _updateCard(card['id']),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteCard(card['id']),
                                    icon: const Icon(Icons.delete),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,  // Trigger adding a new card
        child: const Icon(Icons.add),
      ),
    );
  }
}
