import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  final String publishedIn;
  final String isbn;

  BookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.isAvailable,
    this.isFavorite = false,
    this.imageUrl,
    this.description = '',
    this.publishedIn = 'Unknown Origins',
    this.isbn = 'Not Available',
  });

  String get displayGenre {
    final normalized = genre.toLowerCase().trim().replaceAll('\n', ' ').replaceAll(RegExp(r' +'), ' ');

    final prefixMatch = RegExp(r'^([a-z\.]+)').firstMatch(normalized);
    final prefix = prefixMatch?.group(1)?.trim() ?? '';

    final deweyMatch = RegExp(r'\b(\d{3})\b').firstMatch(normalized);
    final deweyNum = int.tryParse(deweyMatch?.group(1) ?? '') ?? -1;

    if (prefix == 'hrm' || prefix == 'hm') {
      if (deweyNum >= 641 && deweyNum <= 649) return 'Culinary Arts';
      return 'Hospitality Management';
    }

    switch (prefix) {
      case 'fil':   return 'Filipino Studies';
      case 'mid':
      case 'med':   return 'Nursing & Health';
      case 'crim':  return 'Criminology';
      case 'educ':
      case 'bsed':
      case 'beed':  return 'Education';
      case 'ba':
      case 'aba':
      case 'bsba':
      case 'bsa':   return 'Business & Management';
      case 'it':
      case 'bsit':
      case 'bscs':
      case 'bsis':  return 'IT & Programming';
      case 'eng':
      case 'ce':
      case 'i.ed':  return 'Engineering';
      case 'bssw':  return 'Law, Govt & Social';
      case 'bsmath': return 'Mathematics';
    }

    if (deweyNum >= 0) {
      if (deweyNum <= 099)  return 'Others';
      if (deweyNum <= 199)  return 'Psychology';
      if (deweyNum <= 299)  return 'Others';
      if (deweyNum <= 399)  return 'Law, Govt & Social';
      if (deweyNum <= 499)  return 'Filipino Studies';
      if (deweyNum <= 599)  return 'Science';
      if (deweyNum <= 619)  return 'Nursing & Health';
      if (deweyNum <= 629)  return 'Engineering';
      if (deweyNum <= 639)  return 'Science';
      if (deweyNum <= 649)  return 'Culinary Arts';
      if (deweyNum <= 659)  return 'Business & Management';
      if (deweyNum <= 699)  return 'Engineering';
      if (deweyNum <= 799)  return 'Arts';
      if (deweyNum <= 899)  return 'Fiction';
      return 'History';
    }

    return 'Others';
  }

  factory BookItem.fromJson(Map<String, dynamic> json) {
    return BookItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      author: json['author']?.toString() ?? 'Unknown Author',
      genre: (json['category'] ?? json['genre'])?.toString() ?? 'Other',
      isAvailable: (json['available'] ?? json['isAvailable'] ?? true) == true,
      imageUrl: json['image']?.toString() ?? json['imageUrl']?.toString() ?? json['coverImage']?.toString(),
      description: (json['description'] ?? json['publicationDescription'])?.toString() ?? '',
      publishedIn: (json['placeOfPublication'] ?? json['publishedIn'] ?? json['publisher'] ?? json['publish_place'] ?? json['publishPlace'] ?? json['publicationPlace'] ?? json['location'])?.toString() ?? 'Unknown Origins',
      isbn: (json['isbn'] ?? json['isbn13'] ?? json['isbn10'] ?? json['identifier'])?.toString() ?? 'Not Available',
    );
  }
}

class BookService {
  final String baseUrl = AuthService.baseUrl;

  static const String _cacheKey = 'cached_books_list';
  static List<BookItem>? _cachedBooks;
  static DateTime? _lastFetchTime;

Future<void> _saveToPersistentCache(List<dynamic> rawJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(rawJson));
    } catch (_) {}
  }

Future<List<BookItem>> getPersistentCachedBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_cacheKey);
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        return list.map((json) => BookItem.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<BookItem>> fetchBooks({bool forceRefresh = false}) async {

    if (!forceRefresh &&
        _cachedBooks != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 10)) {
      return _cachedBooks!;
    }
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

_saveToPersistentCache(data);

        final results = data.map((json) => BookItem.fromJson(json)).toList();

_cachedBooks = results;
        _lastFetchTime = DateTime.now();

        return results;
      } else {
        throw Exception('Failed to load books (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching books: $e');
      return _cachedBooks ?? [];
    }
  }

Future<BookItem?> fetchBookById(String id) async {

    if (_cachedBooks != null) {
      try {
        return _cachedBooks!.firstWhere((b) => b.id == id);
      } catch (_) {}
    }

    try {
      final authService = AuthService();
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/books/$id'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final data = body['data'] ?? body;
        if (data is Map<String, dynamic>) {
          return BookItem.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
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
