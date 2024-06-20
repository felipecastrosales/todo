import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Home(),
        theme: ThemeData(
          primaryColor: const Color(0xFF28DF99),
        ),
      ),
    );

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  List _toDoList = [];

  Map<String, dynamic> _lastRemoved = {};
  int? _lastRemovedPos;

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
    setState(() {
      if (_toDoController.text.isEmpty) return;
      var newToDo = <String, dynamic>{};
      newToDo['title'] = _toDoController.text;
      _toDoController.text = '';
      newToDo['ok'] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
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
  static const _lightColor = Color(0xFFF9FCFB);
  static const _textColor = Color(0xFF333333);
  static const kLabelStyle = TextStyle(color: _defaultColor, fontSize: 24);
  static const kLightLabelStyle = TextStyle(color: _lightColor, fontSize: 24);
  static const kTextLabelStyle = TextStyle(color: _textColor, fontSize: 18);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ToDo List',
          style: kLightLabelStyle,
        ),
        backgroundColor: _defaultColor,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            color: _lightColor,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    style: kTextLabelStyle,
                    decoration: const InputDecoration(
                      labelText: 'Add New ToDo',
                      labelStyle: kLabelStyle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: IconButton(
                    icon: const Icon(
                      Icons.playlist_add,
                      color: _defaultColor,
                      size: 36,
                    ),
                    onPressed: _addToDo,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 16.0),
                itemCount: _toDoList.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
                    background: Container(
                      color: Colors.red,
                      child: const Align(
                        alignment: Alignment(-0.95, 0.0),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    direction: DismissDirection.startToEnd,
                    child: CheckboxListTile(
                      activeColor: _defaultColor,
                      value: _toDoList[index]['ok'],
                      title: Text(
                        _toDoList[index]['title'],
                        style: kTextLabelStyle,
                      ),
                      secondary: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          _toDoList[index]['ok'] ? Icons.add : Icons.error,
                          color: _defaultColor,
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
                      setState(() {
                        _lastRemoved = Map.from(_toDoList[index]);
                        _lastRemovedPos = index;
                        _toDoList.removeAt(index);
                        _saveData();
                        final snack = SnackBar(
                          duration: const Duration(seconds: 5),
                          backgroundColor: _defaultColor,
                          content: Text(
                            'Tarefa \'${_lastRemoved['title']}\' removida.',
                            style: kLightLabelStyle,
                          ),
                          action: SnackBarAction(
                            label: 'Desfazer',
                            textColor: _lightColor,
                            onPressed: () {
                              if (_lastRemovedPos == null) {
                                return;
                              }

                              setState(() {
                                _toDoList.insert(
                                    _lastRemovedPos!, _lastRemoved);
                                _saveData();
                              });
                            },
                          ),
                        );
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(snack);
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
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
    final file = await _getFile();
    return file.readAsString();
  }
}
