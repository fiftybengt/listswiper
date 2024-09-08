// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart'; // Required for Clipboard handling

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Added super.key

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
  const ListScreen({super.key}); // Added super.key

  @override
  ListScreenState createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen> {
  final List<ListItem> items = []; // Declared as final
  final TextEditingController _controller = TextEditingController();
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

  void _addItem(String item) {
    setState(() {
      Color currentColor = pastelColors[colorIndex];

      // Add the new item with the current color
      items.add(ListItem(item, color: currentColor));

      // Update the color index, looping back to 0 if we reach the end of the list
      colorIndex = (colorIndex + 1) % pastelColors.length;
    });

    _controller.clear();
    FocusScope.of(context).requestFocus(FocusNode()); // Remove focus from the text field
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _toggleItemCompletion(int index) {
    setState(() {
      items[index].isCompleted = !items[index].isCompleted;
    });
  }

  void _clearAllItems() {
    setState(() {
      items.clear();
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
        items.clear(); // Clear the existing items first
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
    } catch (e) {
      debugPrint('Error importing list: $e'); // Use debugPrint instead of print
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

  // The missing build method is added here
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
