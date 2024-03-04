import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_http/data/categories.dart';
import 'package:shopping_list_http/models/grocery_item.dart';
import 'package:shopping_list_http/widgets/new_item.dart';

import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() {
    return _GroceryListState();
  }
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  String? _errString;

  void _loadItems() async {
    var url = Uri.https(
        "flutter-prep-ec334-default-rtdb.firebaseio.com", "shopping_list.json");

    try {
      var response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _errString = "ERROR Occurred: Database loading Faild";
        });
      }

      // if no data in backend then firebase returns 'null'.
      // it is different for different backend
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);

      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final category = categories.entries.firstWhere(
            (catItem) => catItem.value.title == item.value["category"]);
        loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value["name"],
            quantity: item.value["quantity"],
            category: category.value));
      }

      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (err) {
      setState(() {
        _errString = "ERROR Occurred: Can't connect to Database";
      });
    }
  }

  void _addItem() async {
    var newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: ((context) => const NewItem()),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https("flutter-prep-ec334-default-rtdb.firebaseio.com",
        "shopping_list/${item.id}.json");

    var respose = await http.delete(url);

    if (respose.statusCode >= 400) {
      // add data in the list

      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text("No items Added"),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errString != null) {
      content = Center(
        child: Text(_errString!),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          child: ListTile(
            leading: Container(
              width: 20,
              height: 20,
              color: _groceryItems[index].category.color,
            ),
            title: Text(_groceryItems[index].name),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
