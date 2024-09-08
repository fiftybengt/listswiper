import 'package:flutter/material.dart';
import 'dart:convert';

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

  ListItem(this.text, {this.isCompleted = false});
}

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<ListItem> items = [];
  TextEditingController _controller = TextEditingController();

  void _addItem(String item) {
    setState(() {
      items.add(ListItem(item));
    });
    _controller.clear();
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

  String _generateShareableCode() {
    String itemsString = items.map((item) => '${item.text},${item.isCompleted}').join('|');
    return base64Encode(utf8.encode(itemsString));
  }

  void _importList(String code) {
    try {
      String decodedString = utf8.decode(base64Decode(code));
      List<String> itemStrings = decodedString.split('|');
      setState(() {
        items = itemStrings.map((itemString) {
          List<String> parts = itemString.split(',');
          return ListItem(parts[0], isCompleted: parts[1] == 'true');
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
          content: SelectableText(code),
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

  Color _getCompletedColor(int index) {
    List<Color> pastelColors = [
      Colors.yellow[100]!,
      Colors.pink[100]!,
      const Color.fromRGBO(200, 230, 201, 1)!,
    ];
    return pastelColors[index % pastelColors.length];
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
                    color: const Color.fromARGB(253, 128, 209, 131),
                    child: Icon(Icons.check, color: Colors.white),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20),
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
                            ? _getCompletedColor(index)
                            : null,
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
    );
  }
}