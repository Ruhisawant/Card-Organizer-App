import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Folder App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CardFolderScreen(),
    );
  }
}

class CardFolderScreen extends StatefulWidget {
  @override
  _CardFolderScreenState createState() => _CardFolderScreenState();
}

class _CardFolderScreenState extends State<CardFolderScreen> {
  int? _selectedFolderId = 1; // For this example, we assume the selected folder is 1
  List<Map<String, dynamic>> _cards = []; // Cards in the selected folder

  @override
  void initState() {
    super.initState();
    _loadCards(_selectedFolderId!);
  }

  // Mock database helper to simulate card operations
  final List<Map<String, dynamic>> _mockDatabase = [];

  // Load cards from the selected folder
  void _loadCards(int folderId) {
    setState(() {
      _cards = _mockDatabase.where((card) => card['folder_id'] == folderId).toList();
    });
  }

  // Add card to the selected folder
  Future<void> _addCardToFolder() async {
    final cardNameController = TextEditingController();
    final cardSuitController = TextEditingController();
    final cardImageController = TextEditingController();
    final cardUrlController = TextEditingController(text: 'https://en.wikipedia.org/wiki/Diamonds_(suit)');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Card to Folder'),
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
              onPressed: () {
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
                  _mockDatabase.add(newCard);
                  _loadCards(_selectedFolderId!);  // Reload cards after insertion
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

  // Update card details
  Future<void> _updateCard(int cardId) async {
    final cardNameController = TextEditingController();
    final cardSuitController = TextEditingController();
    final cardImageController = TextEditingController();
    final cardUrlController = TextEditingController();

    final card = _mockDatabase.firstWhere((card) => card['id'] == cardId);

    cardNameController.text = card['name'];
    cardSuitController.text = card['suit'];
    cardImageController.text = card['image_url'] ?? '';
    cardUrlController.text = card['resource_url'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Card'),
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
              onPressed: () {
                if (cardNameController.text.isNotEmpty &&
                    cardSuitController.text.isNotEmpty) {
                  final updatedCard = {
                    'name': cardNameController.text,
                    'suit': cardSuitController.text,
                    'image_url': cardImageController.text.isEmpty
                        ? null
                        : cardImageController.text,
                    'resource_url': cardUrlController.text,
                  };
                  _mockDatabase[_mockDatabase.indexWhere((card) => card['id'] == cardId)] = updatedCard;
                  _loadCards(_selectedFolderId!);  // Reload cards after update
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Delete card from folder
  Future<void> _deleteCard(int cardId) async {
    setState(() {
      _mockDatabase.removeWhere((card) => card['id'] == cardId);
    });
    _loadCards(_selectedFolderId!);  // Reload cards after deletion
  }

  // Build card widget with delete option
  Widget _buildCardWidget(Map<String, dynamic> card) {
    return Card(
      child: ListTile(
        title: Text(card['name']),
        subtitle: Text('Suit: ${card['suit']}'),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            _deleteCard(card['id']);
          },
        ),
        onTap: () {
          _updateCard(card['id']);
        },
      ),
    );
  }

  // Display cards in the selected folder
  Widget _buildFolderCards(List<Map<String, dynamic>> cards) {
    return ListView.builder(
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return _buildCardWidget(cards[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Folder: $_selectedFolderId'),
      ),
      body: _cards.isEmpty
          ? Center(child: Text('No cards in this folder.'))
          : _buildFolderCards(_cards),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCardToFolder,
        child: Icon(Icons.add),
      ),
    );
  }
}