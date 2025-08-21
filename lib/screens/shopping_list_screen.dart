import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:products/models/models.dart';
import 'package:products/services/storage_services.dart';

class ShoppingListScreen extends StatefulWidget {
  final StorageService storageService;
  const ShoppingListScreen({super.key, required this.storageService});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingListItem> _items = [];
  final _textController = TextEditingController();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _items = await widget.storageService.loadShoppingList(_userId!);
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (_userId != null) await widget.storageService.saveShoppingList(_items, _userId!);
  }

  void _addItem() {
    if (_textController.text.isEmpty) return;
    _items.insert(0, ShoppingListItem(id: DateTime.now().toIso8601String(), name: _textController.text));
    _textController.clear();
    _save();
    setState(() {});
  }

  void _toggleItem(int index) {
    _items[index].isChecked = !_items[index].isChecked;
    _save();
    setState(() {});
  }

  void _removeItem(int index) {
    _items.removeAt(index);
    _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Add an item...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text("Your shopping list is empty."))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: Key(item.id),
                        onDismissed: (_) => _removeItem(index),
                        background: Container(
                          color: Colors.red.shade300,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            item.name,
                            style: TextStyle(
                                decoration: item.isChecked ? TextDecoration.lineThrough : null),
                          ),
                          value: item.isChecked,
                          onChanged: (_) => _toggleItem(index),
                          controlAffinity: ListTileControlAffinity.leading,
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
