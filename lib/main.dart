import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cards Folders',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CardFolderScreen(),
    );
  }
}

class CardFolderScreen extends StatefulWidget {
  const CardFolderScreen({super.key});

  @override
  _CardFolderScreenState createState() => _CardFolderScreenState();
}

class _CardFolderScreenState extends State<CardFolderScreen> {
  int? _selectedFolderId;
  List<Map<String, dynamic>> _folders = [];
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  // Load folders from database
  void _loadFolders() async {
    final folders = await DatabaseHelper.getFolders();
    setState(() {
      _folders = folders;
    });
  }

  // Load cards from a selected folder
  void _loadCards(int folderId) async {
    final cards = await DatabaseHelper.getCards(folderId);
    setState(() {
      _selectedFolderId = folderId;
      _cards = cards;
    });
  }

  // Add card to a selected folder
  Future<void> _addCardToFolder() async {
    final cardNameController = TextEditingController();
    final cardSuitController = TextEditingController();
    final cardImageController = TextEditingController();
    final cardUrlController = TextEditingController();

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
                  await DatabaseHelper.addCard(newCard);
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

  // Build folder widget
  Widget _buildFolderWidget(Map<String, dynamic> folder) {
    return Card(
      child: ListTile(
        title: Text(folder['name']),
        onTap: () {
          _loadCards(folder['id']);
        },
      ),
    );
  }

  // Build card widget
  Widget _buildCardWidget(Map<String, dynamic> card) {
    return Card(
      child: ListTile(
        title: Text(card['name']),
        subtitle: Text('Suit: ${card['suit']}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            _deleteCard(card['id']);
          },
        ),
        onTap: () {
          _updateCard(card['id']);
        },
        leading: card['image_url'] != null
            ? Image.network(card['image_url'])
            : null,  // Display the card image from the URL
      ),
    );
  }

  // Update card details
  Future<void> _updateCard(int cardId) async {
    // Implementation for updating card details
  }

  // Delete card from folder
  Future<void> _deleteCard(int cardId) async {
    await DatabaseHelper.deleteCard(cardId);  // Delete the card from the database
    _loadCards(_selectedFolderId!);  // Reload the cards after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cards Folders'),
      ),
      body: _folders.isEmpty
          ? const Center(child: Text('No folders available.'))
          : ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                return _buildFolderWidget(_folders[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCardToFolder,
        child: const Icon(Icons.add),
      ),
    );
  }
}