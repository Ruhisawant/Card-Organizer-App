import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
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
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const FoldersScreen(),
    );
  }
}

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Map<String, dynamic>> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize the app
    _initializeApp();
  }

  // Initialize the app and load folders
  Future<void> _initializeApp() async {
    try {
      await _initializeDefaultFolders();
    } catch (e) {
      print('Error initializing app: $e');
      // If there's an error, still set isLoading to false to show the UI
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Initialize default folders if they don't exist
  Future<void> _initializeDefaultFolders() async {
    try {
      // Check if default folders exist
      final existingFolders = await DatabaseHelper.getFolders();
      
      if (existingFolders.isEmpty) {
        // Create default folders
        await DatabaseHelper.addFolder({'name': 'Hearts'});
        await DatabaseHelper.addFolder({'name': 'Spades'});
        await DatabaseHelper.addFolder({'name': 'Diamonds'});
        await DatabaseHelper.addFolder({'name': 'Clubs'});
      }
      
      await _loadFolders();
    } catch (e) {
      print('Error initializing folders: $e');
      rethrow;
    }
  }

  // Load folders and card counts
  Future<void> _loadFolders() async {
    try {
      final folders = await DatabaseHelper.getFolders();
      
      // Get preview and card count for each folder
      for (var i = 0; i < folders.length; i++) {
        final cardCount = await DatabaseHelper.getCardCount(folders[i]['id']);
        final previewCard = await DatabaseHelper.getPreviewCard(folders[i]['id']);
        
        folders[i]['cardCount'] = cardCount;
        folders[i]['previewImageUrl'] = previewCard.isNotEmpty 
            ? previewCard.first['image_url'] 
            : null;
      }
      
      if (mounted) {
        setState(() {
          _folders = folders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading folders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add new custom folder
  Future<void> _addFolder() async {
    final nameController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Folder'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await DatabaseHelper.addFolder({'name': nameController.text});
                  Navigator.of(context).pop();
                  _loadFolders();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Rename a folder
  Future<void> _renameFolder(int folderId, String currentName) async {
    final nameController = TextEditingController(text: currentName);
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await DatabaseHelper.updateFolder(
                    folderId, 
                    {'name': nameController.text}
                  );
                  Navigator.of(context).pop();
                  _loadFolders();
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Delete a folder
  Future<void> _deleteFolder(int folderId) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: const Text(
            'This will delete the folder and all its cards. Are you sure?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper.deleteFolder(folderId);
                Navigator.of(context).pop();
                _loadFolders();
              },
              child: const Text(
                'Delete', 
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cards Folders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? const Center(child: Text('No folders available.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    return _buildFolderWidget(folder);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFolder,
        tooltip: 'Add Folder',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build folder widget
  Widget _buildFolderWidget(Map<String, dynamic> folder) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardsScreen(folderId: folder['id'], folderName: folder['name']),
          ),
        ).then((_) => _loadFolders());  // Refresh when returning from cards screen
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: folder['previewImageUrl'] != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              folder['previewImageUrl']!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, obj, st) => const Icon(
                                Icons.broken_image,
                                size: 40,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.folder,
                            size: 40,
                          ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder['name'] ?? 'Unnamed Folder',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Cards: ${folder['cardCount'] ?? 0}',
                          style: TextStyle(
                            color: (folder['cardCount'] ?? 0) < 3 
                                ? Colors.red 
                                : Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
                onSelected: (value) {
                  if (value == 'rename') {
                    _renameFolder(folder['id'], folder['name']);
                  } else if (value == 'delete') {
                    _deleteFolder(folder['id']);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  const CardsScreen({
    required this.folderId, 
    required this.folderName, 
    super.key,
  });

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  // Load cards from database
  Future<void> _loadCards() async {
    try {
      final cards = await DatabaseHelper.getCards(widget.folderId);
      if (mounted) {
        setState(() {
          _cards = cards;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cards: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add a new card to the folder
  Future<void> _addCard() async {
    // Check if folder already has 6 cards
    if (_cards.length >= 6) {
      _showErrorDialog("This folder can only hold 6 cards.");
      return;
    }

    final cardNameController = TextEditingController();
    final cardSuitController = TextEditingController();
    final cardImageController = TextEditingController();
    final cardUrlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Card'),
          content: SingleChildScrollView(
            child: Column(
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
                    'folder_id': widget.folderId,
                    'resource_url': cardUrlController.text,
                  };
                  await DatabaseHelper.addCard(newCard);
                  Navigator.of(context).pop();
                  _loadCards();
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
  Future<void> _updateCard(Map<String, dynamic> card) async {
    final cardNameController = TextEditingController(text: card['name']);
    final cardSuitController = TextEditingController(text: card['suit']);
    final cardImageController = TextEditingController(text: card['image_url'] ?? '');
    final cardUrlController = TextEditingController(text: card['resource_url'] ?? '');
    final int currentFolderId = card['folder_id'];
    
    // Get all folders for reassignment option
    final folders = await DatabaseHelper.getFolders();
    int selectedFolderId = currentFolderId;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Card'),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Reassign to Folder'),
                  value: selectedFolderId,
                  items: folders.map((folder) {
                    return DropdownMenuItem<int>(
                      value: folder['id'],
                      child: Text(folder['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedFolderId = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (cardNameController.text.isNotEmpty &&
                    cardSuitController.text.isNotEmpty) {
                  // Check if trying to move to a folder that already has 6 cards
                  if (selectedFolderId != currentFolderId) {
                    final targetFolderCardCount = 
                        await DatabaseHelper.getCardCount(selectedFolderId);
                    if (targetFolderCardCount >= 6) {
                      Navigator.of(context).pop();
                      _showErrorDialog(
                        "Target folder already has 6 cards. Cannot reassign."
                      );
                      return;
                    }
                  }
                  
                  final updatedCard = {
                    'name': cardNameController.text,
                    'suit': cardSuitController.text,
                    'image_url': cardImageController.text.isEmpty
                        ? null
                        : cardImageController.text,
                    'folder_id': selectedFolderId,
                    'resource_url': cardUrlController.text,
                  };
                  
                  await DatabaseHelper.updateCard(card['id'], updatedCard);
                  Navigator.of(context).pop();
                  
                  if (selectedFolderId != currentFolderId) {
                    // Check if removing this card would leave fewer than 3 cards
                    final remainingCards = _cards.length - 1;
                    if (remainingCards < 3) {
                      _showWarningDialog(
                        "This folder now has fewer than 3 cards."
                      );
                    }
                    // If card was moved to another folder, refresh this folder's cards
                    _loadCards();
                  } else {
                    _loadCards();
                  }
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
    // Check if deleting would leave fewer than 3 cards
    if (_cards.length <= 3) {
      _showErrorDialog(
        "You need at least 3 cards in this folder. Cannot delete."
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Card'),
          content: const Text('Are you sure you want to delete this card?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper.deleteCard(cardId);
                Navigator.of(context).pop();
                _loadCards();
              },
              child: const Text(
                'Delete', 
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show warning dialog
  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folderName} Cards'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(child: Text('No cards in this folder.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    return _buildCardWidget(_cards[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        tooltip: 'Add Card',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build card widget
  Widget _buildCardWidget(Map<String, dynamic> card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  card['image_url'] != null
                      ? Image.network(
                          card['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, obj, st) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 40),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 40),
                        ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      children: [
                        // Edit button
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.7),
                          radius: 16,
                          child: IconButton(
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.edit),
                            onPressed: () => _updateCard(card),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Delete button
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.7),
                          radius: 16,
                          child: IconButton(
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCard(card['id']),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Card details
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['name'] ?? 'Unnamed Card',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Suit: ${card['suit'] ?? 'Unknown'}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}