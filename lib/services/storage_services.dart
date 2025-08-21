// lib/services/storage_service.dart
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:products/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Key for local settings (unchanged)
  static const _settingsKey = 'app_settings';
  static const _themeKey = 'app_theme';

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // MODIFIED: Saves the shopping list to Firebase under the user's unique ID.
  // The method now requires a `userId`.
  Future<void> saveShoppingList(List<ShoppingListItem> items, String userId) async {
    // Encode the list of items into a format that can be stored in Firebase.
    final listAsJson = items.map((item) => item.toJson()).toList();
    // Create a reference to a user-specific path: 'users/<userId>/shopping_list'
    await _database.ref('users/$userId/shopping_list').set(listAsJson);
  }

  // MODIFIED: Loads the shopping list from Firebase using the user's unique ID.
  // The method now requires a `userId`.
  Future<List<ShoppingListItem>> loadShoppingList(String userId) async {
    // Create a reference to the user-specific path.
    final snapshot = await _database.ref('users/$userId/shopping_list').get();
    
    // Check if the data exists at that path.
    if (snapshot.exists && snapshot.value != null) {
      // Firebase returns the data, which needs to be cast and decoded.
      final list = snapshot.value as List;
      return list
          .map((item) => ShoppingListItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    // If no data exists for the user, return an empty list.
    return [];
  }

  // NEW: A method to remove a user's shopping list from Firebase.
  // This is useful for logout or account deletion functionality.
  Future<void> clearUserShoppingList(String userId) async {
    await _database.ref('users/$userId/shopping_list').remove();
  }

  // --- The following methods remain unchanged and use SharedPreferences for device-local settings ---

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_settingsKey);
    if (data == null) return {'expiringSoonDays': 7}; // Default value
    return jsonDecode(data);
  }

  Future<void> saveTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode.name);
  }

  Future<ThemeMode> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? ThemeMode.system.name;
    return ThemeMode.values.firstWhere((e) => e.name == themeName);
  }

  // This method now only clears local settings, as shopping list is on Firebase.
  Future<void> clearLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }
}