import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart'; // Required for Clipboard handling

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: ListScreen(),
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
  @override
  _ListScreenState createState() => _ListScreenState();
  int colorIndex = 0;
}

class _ListScreenState extends State<ListScreen> {
  List<ListItem> items = [];
  TextEditingController _controller = TextEditingController();
  Random random = Random();
  Color? lastColor; // Keep track of the last color used

  // Add this line below your existing variables
  int colorIndex = 0; // Track which color to use next

  List<Color> pastelColors = [
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
    // Use the current color from the list
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
          title: Text('Clear All Items'),
          content: Text('Are you sure you want to delete all items?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _clearAllItems();
                Navigator.of(context).pop();
              },
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
        items = itemStrings.map((itemString) {
          List<String> parts = itemString.split(',');
          Color randomColor;
          do {
            randomColor = pastelColors[random.nextInt(pastelColors.length)];
          } while (randomColor == lastColor);
          lastColor = randomColor;

          return ListItem(parts[0],
              isCompleted: parts[1] == 'true', color: randomColor);
        }).toList();
      });
    } catch (e) {
      print('Error importing list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  void _showShareDialog() {
    String code = _generateShareableCode();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Share List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(code),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Code copied to clipboard!')),
                  );
                },
                child: Text('Copy Code'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
          title: Text('Import List'),
          content: TextField(
            controller: importController,
            decoration: InputDecoration(hintText: "Enter the code here"),
            autofocus: true, // Automatically focus on text input
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Import'),
              onPressed: () {
                _importList(importController.text);
                Navigator.of(context).pop();
              },
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
        title: Text('List swiper'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _showShareDialog,
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _showImportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Add new item',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
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
                    color: const Color(0xFFCBE2B5), // Updated swipe color
                    child: Icon(Icons.check, color: Colors.white),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20),
                  ),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (direction) {
                    _removeItem(index); // Immediately remove the item from the list
                  },
                  child: GestureDetector(
                    onTap: () => _toggleItemCompletion(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: items[index].isCompleted
                            ? Colors.grey[300] // Light gray when clicked
                            : items[index].color, // Default item color
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                            ? Icon(Icons.check, color: Colors.green)
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
        child: Icon(Icons.delete),
        backgroundColor: const Color(0xFFFF938B),
      ),
    );
  }
}
