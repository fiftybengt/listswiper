// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart'; // Required for Clipboard handling
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const ListScreen(),
    );
  }
}

class ListItem {
  String text;
  bool isCompleted;
  Color color;

  ListItem(this.text, {this.isCompleted = false, required this.color});
}

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  ListScreenState createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen> {
  final List<ListItem> items = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // For automatic focus
  final Random random = Random();
  Color? lastColor;
  int colorIndex = 0;

  final List<Color> pastelColors = const [
    Color(0xFFFFF9C4), // Light Yellow
    Color(0xFFFFECB3), // Light Amber
    Color(0xFFFFCCBC), // Light Red
    Color(0xFFCFD8DC), // Light Blue-Grey
    Color(0xFFC8E6C9), // Light Green
    Color(0xFFB3E5FC), // Light Blue
    Color(0xFFD1C4E9), // Light Purple
    Color(0xFFF8BBD0), // Light Pink
    Color(0xFFFFF176), // Light Lime
    Color(0xFFA5D6A7), // Light Teal
  ];

  @override
  void initState() {
    super.initState();
    _loadList(); // Load saved list
  }

  // Load the list from shared preferences
  Future<void> _loadList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedItems = prefs.getString('items');
    if (savedItems != null) {
      setState(() {
        items.clear();
        List<String> itemStrings = savedItems.split('|');
        items.addAll(itemStrings.map((itemString) {
          List<String> parts = itemString.split(',');
          return ListItem(
            parts[0],
            isCompleted: parts[1] == 'true',
            color: pastelColors[random.nextInt(pastelColors.length)],
          );
        }).toList());
      });
    }
  }

  // Save the list to shared preferences
  Future<void> _saveList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String itemsString = items.map((item) => '${item.text},${item.isCompleted}').join('|');
    await prefs.setString('items', itemsString);
  }

  // Add an item and refocus on the text field
  void _addItem(String item) {
    setState(() {
      Color currentColor = pastelColors[colorIndex];
      items.add(ListItem(item, color: currentColor));
      colorIndex = (colorIndex + 1) % pastelColors.length;
      _saveList(); // Save the list after adding an item
    });
    _controller.clear();
    _focusNode.requestFocus(); // Automatically focus on the text field again
  }

  // Remove an item
  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
      _saveList(); // Save the list after removing an item
    });
  }

  // Toggle item completion and move completed items to the bottom
  void _toggleItemCompletion(int index) {
    setState(() {
      items[index].isCompleted = !items[index].isCompleted;
      ListItem updatedItem = items.removeAt(index);

      if (updatedItem.isCompleted) {
        int firstCompletedIndex = items.indexWhere((item) => item.isCompleted);
        if (firstCompletedIndex == -1) {
          items.add(updatedItem); // No completed items, add to the end
        } else {
          items.insert(firstCompletedIndex, updatedItem); // Insert before first completed item
        }
      } else {
        items.insert(0, updatedItem); // Move unchecked item to the top
      }

      _saveList(); // Save the list after toggling completion
    });
  }

  // Clear all items
  void _clearAllItems() {
    setState(() {
      items.clear();
      _saveList(); // Save the list after clearing
    });
  }

  void _confirmClearAllItems() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Items'),
          content: const Text('Are you sure you want to delete all items?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _clearAllItems();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _generateShareableCode() {
    String itemsString = items
        .map((item) => '${item.text},${item.isCompleted}')
        .join('|');
    return base64Encode(utf8.encode(itemsString));
  }

  void _importList(String code) {
    try {
      String decodedString = utf8.decode(base64Decode(code));
      List<String> itemStrings = decodedString.split('|');
      setState(() {
        items.clear();
        items.addAll(itemStrings.map((itemString) {
          List<String> parts = itemString.split(',');
          Color randomColor;
          do {
            randomColor = pastelColors[random.nextInt(pastelColors.length)];
          } while (randomColor == lastColor);
          lastColor = randomColor;

          return ListItem(parts[0],
              isCompleted: parts[1] == 'true', color: randomColor);
        }).toList());
      });
      _saveList(); // Save after importing
    } catch (e) {
      debugPrint('Error importing list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  void _showShareDialog() {
    String code = _generateShareableCode();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(code),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard!')),
                  );
                },
                child: const Text('Copy Code'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showImportDialog() {
    TextEditingController importController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Import List'),
          content: TextField(
            controller: importController,
            decoration: const InputDecoration(hintText: "Enter the code here"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _importList(importController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Import'),
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
        title: const Text('List swiper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showShareDialog,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showImportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode, // Focus for adding items
              decoration: InputDecoration(
                labelText: 'Add new item',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _addItem(_controller.text);
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addItem(value);
                }
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(items[index].text),
                  background: Container(
                    color: const Color(0xFFCBE2B5),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (direction) {
                    _removeItem(index);
                  },
                  child: GestureDetector(
                    onTap: () => _toggleItemCompletion(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: items[index].isCompleted
                            ? Colors.grey[300]
                            : items[index].color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(
                          items[index].text,
                          style: TextStyle(
                            decoration: items[index].isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: items[index].isCompleted
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _confirmClearAllItems,
        backgroundColor: const Color(0xFFFF938B),
        child: const Icon(Icons.delete),
      ),
    );
  }
}
