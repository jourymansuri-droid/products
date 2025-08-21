// lib/screens/product_list_screen_simple.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:products/models/models.dart';
import 'package:products/services/firebase_services.dart';

enum SortType { name, quantity, expiry }

class ProductListScreen extends StatefulWidget {
  final Category category;
  final FirebaseService firebaseService;

  const ProductListScreen({
    super.key,
    required this.category,
    required this.firebaseService,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  TextEditingController searchController = TextEditingController();
  late List<Product> allProducts;
  List<Product> displayedProducts = [];
  String searchText = '';
  SortType currentSort = SortType.expiry;

  @override
  void initState() {
    super.initState();
    allProducts = List.from(widget.category.products);

    searchController.addListener(() {
      setState(() {
        searchText = searchController.text;
      });
      filterAndSort();
    });

    filterAndSort();
  }

  void filterAndSort() {
    List<Product> filtered = allProducts
        .where((p) => p.name.toLowerCase().contains(searchText.toLowerCase()))
        .toList();

    if (currentSort == SortType.name) {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (currentSort == SortType.quantity) {
      filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
    } else {
      filtered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    }

    setState(() {
      displayedProducts = filtered;
    });
  }

  void changeSort(SortType newSort) {
    setState(() {
      currentSort = newSort;
    });
    filterAndSort();
  }

  Future<void> saveProduct(Product p) async {
    await widget.firebaseService.saveProduct(widget.category.name, p);

    int index = allProducts.indexWhere((prod) => prod.id == p.id);
    if (index != -1) {
      allProducts[index] = p;
    } else {
      allProducts.insert(0, p);
    }
    filterAndSort();
  }

  Future<void> deleteProduct(Product p) async {
    int index = allProducts.indexWhere((prod) => prod.id == p.id);
    if (index == -1) return;

    Product removed = allProducts[index];
    setState(() => allProducts.removeAt(index));
    filterAndSort();

    await widget.firebaseService.deleteProduct(widget.category.name, p.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.name} deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            setState(() => allProducts.insert(index, removed));
            filterAndSort();
            await widget.firebaseService.saveProduct(widget.category.name, removed);
          },
        ),
      ),
    );
  }

  void showProductForm({Product? editingProduct}) {
    final nameCtrl = TextEditingController(text: editingProduct?.name);
    final quantityCtrl =
        TextEditingController(text: editingProduct?.quantity.toString());
    DateTime expiry = editingProduct?.expiryDate ?? DateTime.now().add(Duration(days: 7));

    bool isEdit = editingProduct != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'Edit Product' : 'Add Product'),
              SizedBox(height: 10),
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: quantityCtrl,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Expiry: ${DateFormat.yMd().format(expiry)}'),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: expiry,
                        firstDate: DateTime.now().subtract(Duration(days: 365)),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => expiry = picked);
                    },
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  final newProduct = Product(
                    id: editingProduct?.id ?? DateTime.now().toIso8601String(),
                    name: nameCtrl.text,
                    quantity: int.tryParse(quantityCtrl.text) ?? 0,
                    expiryDate: expiry,
                  );
                  saveProduct(newProduct);
                  Navigator.pop(context);
                },
                child: Text(isEdit ? 'Save' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(hintText: 'Search...'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () => changeSort(SortType.expiry),
                  child: Text('Expiry')),
              TextButton(
                  onPressed: () => changeSort(SortType.name), child: Text('Name')),
              TextButton(
                  onPressed: () => changeSort(SortType.quantity),
                  child: Text('Quantity')),
            ],
          ),
          Expanded(
            child: displayedProducts.isEmpty
                ? Center(child: Text(searchText.isEmpty ? 'No Products' : 'No Results'))
                : ListView.builder(
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      final p = displayedProducts[index];
                      int daysLeft = p.expiryDate.difference(DateTime.now()).inDays;
                      String expiryText =
                          daysLeft < 0 ? 'Expired' : 'Expires in $daysLeft days';
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text('Qty: ${p.quantity}\n$expiryText'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deleteProduct(p),
                        ),
                        onTap: () => showProductForm(editingProduct: p),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductForm(),
        child: Icon(Icons.add),
      ),
    );
  }
}
