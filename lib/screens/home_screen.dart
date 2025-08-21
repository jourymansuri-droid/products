// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:products/models/models.dart';
import 'package:products/providers/theme_notifier.dart';
import 'package:products/screens/analytics_screen.dart';
import 'package:products/screens/dashboard_screen.dart';
import 'package:products/screens/product_list_screen.dart';
import 'package:products/screens/settings_screen.dart';
import 'package:products/screens/shopping_list_screen.dart';
import 'package:products/services/firebase_services.dart';
import 'package:products/services/storage_services.dart';

class HomePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const HomePage({super.key, required this.themeNotifier});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final firebaseService = FirebaseService();
  final storageService = StorageService();

  List<Category> categories = [];
  Map<String, dynamic> settings = {'expiringSoonDays': 7};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    final loadedCats = await firebaseService.loadCategoriesWithProducts();
    final loadedSettings = await storageService.loadSettings();
    if (!mounted) return;
    setState(() {
      categories = loadedCats;
      settings = loadedSettings;
      isLoading = false;
    });
  }

  Future<void> saveSettings(Map<String, dynamic> newSettings) async {
    await storageService.saveSettings(newSettings);
    loadData();
  }

  Future<void> resetApp() async {
    final user = FirebaseAuth.instance.currentUser;

    await firebaseService.clearAllProducts();

    if (user != null) {
      await storageService.clearUserShoppingList(user.uid);
    }

    await storageService.clearLocalSettings();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        categories: categories,
        settings: settings,
        onNavigateToCategory: navigateToProductList,
      ),
      AnalyticsScreen(categories: categories),
      ShoppingListScreen(storageService: storageService),
      SettingsScreen(
        settings: settings,
        onSettingsChanged: saveSettings,
        onResetApp: resetApp,
        themeNotifier: widget.themeNotifier,
        storageService: storageService,
      ),
    ];

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void navigateToProductList(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductListScreen(
          category: category,
          firebaseService: firebaseService,
        ),
      ),
    ).then((_) => loadData());
  }
}
