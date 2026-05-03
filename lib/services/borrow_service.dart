import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Model representing one borrow transaction from the API.
class BorrowTransaction {
  final String id;
  final String userId;
  final String bookId;
  final String bookTitle;
  final String borrowerName;
  final String borrowDate;
  final String dueDate;
  final String pickupDeadline;
  final String? returnDate;
  final String status;
  final String penalty;

  BorrowTransaction({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.borrowerName,
    required this.borrowDate,
    required this.dueDate,
    required this.pickupDeadline,
    this.returnDate,
    required this.status,
    required this.penalty,
  });

  factory BorrowTransaction.fromJson(Map<String, dynamic> json) {
    return BorrowTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['studentId']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      bookTitle: json['book']?.toString() ?? json['bookTitle']?.toString() ?? 'Unknown Book',
      borrowerName: json['name']?.toString() ?? '',
      borrowDate: json['borrowDate']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      pickupDeadline: json['pickupDeadline']?.toString() ?? '',
      returnDate: json['returnDate']?.toString(),
      status: json['status']?.toString() ?? 'Unknown',
      penalty: json['penalty']?.toString() ?? '₱0.00',
    );
  }

  bool get isPending => status.toLowerCase().contains('pending');
  bool get isApproved =>
      status.toLowerCase().contains('approved') ||
      status.toLowerCase().contains('checked out');
  bool get isReturned => status.toLowerCase().contains('returned');
  bool get isRejected => status.toLowerCase().contains('rejected');
}

class BorrowService {
  static const String _baseUrl = 'https://libraguard-api.onrender.com/api';

  /// Submit a new borrow request for [bookId].
  /// The [dueDate] defaults to 7 days from now if not provided.
  Future<Map<String, dynamic>> submitBorrowRequest({
    required String bookId,
    DateTime? dueDate,
  }) async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'You are not logged in.'};
    }

    // Get userId from the cached profile
    final profileRes = await authService.getProfile();
    final userId = profileRes['data']?['id']?.toString() ??
        profileRes['data']?['_id']?.toString() ??
        '';
    if (userId.isEmpty) {
      return {'success': false, 'message': 'Could not retrieve user ID.'};
    }

    final due = dueDate ?? DateTime.now().add(const Duration(days: 7));

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'bookId': bookId,
          'dueDate': due.toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Normalize: API may return the transaction directly or wrapped
        final tx = data is Map && data['data'] != null ? data['data'] : data;
        return {
          'success': true,
          'transaction': tx is Map<String, dynamic>
              ? BorrowTransaction.fromJson(tx)
              : null,
          'message': 'Borrow request submitted successfully!',
        };
      } else {
        return {
          'success': false,
          'message': data['message']?.toString() ??
              'Failed to submit request (${response.statusCode})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Fetch all borrow transactions for the currently logged-in user.
  Future<List<BorrowTransaction>> fetchMyTransactions() async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Handle { data: [...] } or plain list
        final List<dynamic> list =
            body is List ? body : (body['data'] ?? body['transactions'] ?? []);
        return list
            .map((e) => BorrowTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
