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
                                    child: Text('Image placeholder'),
                                  ),
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
        onPressed: () {
          // This would open a dialog to add a new card in a more complete implementation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add card functionality would go here')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}