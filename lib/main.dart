import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
      theme: ThemeData(
        primaryColor: const Color(0xFF28DF99),
        accentColor: Colors.greenAccent,
      ),
    ));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  List _toDoList = [];

  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;

  Map<String, dynamic> _lastEdited;
  int _lastEditedPos;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    if (_toDoController.text.isEmpty) return;

    if (_isEditing) {
      setState(() {
        _lastEdited['title'] = _toDoController.text;
        _toDoList.insert(_lastEditedPos, _lastEdited);
        _toDoController.text = '';
        _isEditing = false;
        _saveData();
      });
    } else {
      setState(() {
        var newToDo = <String, dynamic>{};
        newToDo['title'] = _toDoController.text;
        _toDoController.text = '';
        newToDo['ok'] = false;
        _toDoList.add(newToDo);
        _saveData();
      });
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a['ok'] && !b['ok']) {
          return 1;
        } else if (!a['ok'] && b['ok']) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
    return null;
  }

  static const _defaultColor = Color(0xFF28DF99);
  static const _errorColor = Color(0xFFF9A825);
  static const _lightColor = Color(0xFFF9FCFB);
  static const _textColor = Color(0xFF333333);

  final kLabelStyle = TextStyle(color: _defaultColor, fontSize: 24);
  final kLightLabelStyle = TextStyle(color: _lightColor, fontSize: 24);
  final kTextLabelStyle = TextStyle(color: _textColor, fontSize: 18);
  final kTextOkStyle = TextStyle(
      color: _textColor, fontSize: 18, decoration: TextDecoration.lineThrough);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo List', style: kLightLabelStyle),
        backgroundColor: _defaultColor,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            color: _lightColor,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    style: kTextLabelStyle,
                    decoration: InputDecoration(
                      labelText: 'Add New ToDo',
                      labelStyle: kLabelStyle,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: _defaultColor,
                      size: 36,
                    ),
                    onPressed: _addToDo,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Visibility(
                    visible: _isEditing,
                    child: IconButton(
                      icon: Icon(
                        Icons.cancel,
                        color: _errorColor,
                        size: 36,
                      ),
                      onPressed: _cancelEditing,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 16.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem),
          )),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.95, 0.0),
          child: Icon(Icons.delete, color: Colors.white, size: 36),
        ),
      ),
      secondaryBackground: Container(
        color: Colors.green,
        child: Align(
          alignment: Alignment(0.95, 0.0),
          child: Icon(Icons.edit, color: Colors.white, size: 36),
        ),
      ),
      child: CheckboxListTile(
        activeColor: _defaultColor,
        title: Text(_toDoList[index]['title'],
            style: _toDoList[index]['ok'] ? kTextOkStyle : kTextLabelStyle),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Icon(
            _toDoList[index]['ok'] ? Icons.done : Icons.error,
            color: _toDoList[index]['ok'] ? _defaultColor : _errorColor,
            size: 36,
          ),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]['ok'] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPos = index;
            _toDoList.removeAt(index);
            _saveData();
            final snack = SnackBar(
              duration: Duration(seconds: 5),
              backgroundColor: _defaultColor,
              content: Text(
                'Tarefa \'${_lastRemoved['title']}\' removida.',
                style: kLightLabelStyle,
              ),
              action: SnackBarAction(
                label: 'Desfazer',
                textColor: _lightColor,
                onPressed: _cancelDeleting,
              ),
            );
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(snack);
          });
        } else {
          setState(() {
            _lastEdited = Map.from(_toDoList[index]);
            _lastEditedPos = index;
            _toDoController.text = _lastEdited['title'];
            _toDoList.removeAt(index);
            _saveData();
            _isEditing = true;

            final snack = SnackBar(
              duration: Duration(seconds: 7),
              backgroundColor: _defaultColor,
              content: Text(
                'Tarefa em edição.',
                style: kLightLabelStyle,
              ),
            );
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(snack);
          });
        }
      },
    );
  }

  void _cancelEditing() {
    setState(() {
      _toDoList.insert(_lastEditedPos, _lastEdited);
      _saveData();

      _toDoController.text = '';
      _isEditing = false;
    });
  }

  void _cancelDeleting() {
    setState(() {
      _toDoList.insert(_lastRemovedPos, _lastRemoved);
      _saveData();
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    var data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return null;
    }
  }
}
