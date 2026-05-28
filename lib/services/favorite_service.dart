import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class FavoriteService {
  static const String _baseKey = 'favorite_book_ids';
  final String baseUrl = AuthService.baseUrl;

  // Retrieve an account-specific storage key so data doesn't mix between accounts
  Future<String> _getStorageKey() async {
    final authService = AuthService();
    final profile = await authService.getCachedProfile();
    final userId = profile?['id']?.toString() ?? 'guest';
    return '${_baseKey}_$userId';
  }

  // Get all favorite IDs
  Future<List<String>> getFavoriteIds() async {
    final storageKey = await _getStorageKey();

    // 1. Try to fetch from server for sync
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('$baseUrl/users/favorites'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['data'] != null) {
            final List<String> serverFavorites =
                List<String>.from(body['data']);
            // Cache server response locally (account-specific)
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList(storageKey, serverFavorites);
            return serverFavorites;
          }
        } else if (response.statusCode == 404) {
          // Silent fallback: server doesn't support favorites yet
          debugPrint('Favorites sync skipped: Endpoint not found (404)');
        } else {
          debugPrint('Favorites sync failed: Status ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error syncing favorites from server: $e');
    }

    // 2. Fallback to local storage if API is not yet implemented or offline
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(storageKey) ?? [];
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String bookId) async {
    final storageKey = await _getStorageKey();
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(storageKey) ?? [];

    bool isFavorited;
    if (favorites.contains(bookId)) {
      favorites.remove(bookId);
      isFavorited = false;
    } else {
      favorites.add(bookId);
      isFavorited = true;
    }

    // Save locally for instant UI update (account-specific)
    await prefs.setStringList(storageKey, favorites);

    // Sync with server background
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token != null) {
        final response = await http.post(
          Uri.parse('$baseUrl/users/favorites/toggle'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'bookId': bookId}),
        );
        if (response.statusCode != 200 && response.statusCode != 201) {
          debugPrint('Favorite toggle sync failed: Status ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error syncing favorite toggle with server: $e');
    }

    return isFavorited;
  }

  // Check if a book is favorited (Instant UX via local cache)
  Future<bool> isFavorited(String bookId) async {
    final storageKey = await _getStorageKey();
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(storageKey) ?? [];
    return favorites.contains(bookId);
  }
}
