import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_http/data/categories.dart';
import 'package:shopping_list_http/models/category.dart';
import 'package:shopping_list_http/models/grocery_item.dart';

import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formkey = GlobalKey<FormState>();
  var _enteredTitle = '';
  var _enteredAmount = 1;
  var _enteredCategory = categories[Categories.dairy]!;
  bool _isSending = false;

  void _saveItem() async {
    if (_formkey.currentState!.validate()) {
      _formkey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      var url = Uri.https("flutter-prep-ec334-default-rtdb.firebaseio.com",
          "shopping_list.json");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(
          {
            "name": _enteredTitle,
            "quantity": _enteredAmount,
            "category": _enteredCategory.title
          },
        ),
      );

      // checking for error generally error codes above 400
      // Navigator.of(context).pop(GroceryItem(
      //     id: DateTime.now().toString(),
      //     name: _enteredTitle,
      //     quantity: _enteredAmount,
      //     category: _enteredCategory));

      final Map<String, dynamic> resData = json.decode(response.body);

      // this condition checks if this widget is not mounted in widget tree then return
      // pop this widget if the widget is still in widget tree
      // this is to use navigator function in async block
      if (!context.mounted) {
        return;
      }

      //below code will give warning if we use the code without the above condition
      Navigator.of(context).pop(GroceryItem(
          id: resData["name"],
          name: _enteredTitle,
          quantity: _enteredAmount,
          category: _enteredCategory));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add new Item"),
      ),
      body: Form(
        key: _formkey,
        child: Column(
          children: [
            TextFormField(
              maxLength: 50,
              onSaved: (value) {
                _enteredTitle = value!;
              },
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    value.trim().length <= 1 ||
                    value.trim().length > 50) {
                  return "Enter title with length between 2 to 50";
                }
                return null;
              },
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    maxLength: 50,
                    initialValue: '1',
                    decoration: const InputDecoration(label: Text("Quantity")),
                    onSaved: (value) {
                      _enteredAmount = int.parse(value!);
                    },
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null ||
                          int.tryParse(value)! <= 0) {
                        return "Enter positive quantity number";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: DropdownButtonFormField(
                      value: _enteredCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  color: category.value.color,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(category.value.title)
                              ],
                            ),
                          )
                      ],
                      onChanged: (value) {
                        setState(() {
                          _enteredCategory = value!;
                        });
                      }),
                )
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                //if null is input in onPressed then button is blocked
                TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _formkey.currentState!.reset();
                          },
                    child: const Text("Reset")),
                TextButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: Text(_isSending ? "Sending..." : "Add Item"))
              ],
            )
          ],
        ),
      ),
    );
  }
}
