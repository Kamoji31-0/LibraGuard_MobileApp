import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class BookItem {
  final String id;
  final String title;
  final String author;
  final String genre;
  final bool isAvailable;
  bool isFavorite;
  final String? imageUrl;
  final String description;

  BookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.isAvailable,
    this.isFavorite = false,
    this.imageUrl,
    this.description = '',
  });

  factory BookItem.fromJson(Map<String, dynamic> json) {
    return BookItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Title',
      author: json['author'] ?? 'Unknown Author',
      genre: json['category'] ?? json['genre'] ?? 'Other',
      isAvailable: json['available'] ?? json['isAvailable'] ?? true,
      imageUrl: json['image'] ?? json['imageUrl'] ?? json['coverImage'],
      description: json['description'] ?? json['publicationDescription'] ?? '',
    );
  }
}

class BookService {
  final String baseUrl = AuthService.baseUrl;

  Future<List<BookItem>> fetchBooks() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/books'), 
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => BookItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching books: $e');
      return [];
    }
  }

  Future<List<BookItem>> searchBooks(String query) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/books?search=$query'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => BookItem.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<BookItem>> fetchBooksByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/books?ids=${ids.join(',')}'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => BookItem.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
