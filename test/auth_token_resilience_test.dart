import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libraguard/services/auth_service.dart';
import 'package:libraguard/services/borrow_service.dart';
import 'package:libraguard/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Token Validation', () {
    final authService = AuthService();

    test('isValidJwt checks 3-part structure and trimming', () {
      expect(authService.isValidJwt(null), isFalse);
      expect(authService.isValidJwt(''), isFalse);
      expect(authService.isValidJwt('   '), isFalse);
      expect(authService.isValidJwt('abc'), isFalse);
      expect(authService.isValidJwt('header.payload'), isFalse);
      expect(authService.isValidJwt('header.payload.'), isFalse);
      expect(authService.isValidJwt('.payload.signature'), isFalse);
      expect(authService.isValidJwt('header..signature'), isFalse);
      expect(authService.isValidJwt('header.payload.signature.extra'), isFalse);

      expect(authService.isValidJwt('header.payload.signature'), isTrue);
      expect(authService.isValidJwt('  header.payload.signature  '), isTrue);
    });

    test('getToken falls back to SharedPreferences if SecureStorage token is corrupted', () async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'fallback.payload.token',
      });

      // SecureStorage might fail in tests, so getToken falls back to SharedPreferences
      final token = await authService.getToken();
      expect(token, equals('fallback.payload.token'));
    });
  });

  group('Session-Expired Dialog', () {
    testWidgets('showSessionExpiredDialog displays dialog and Log In Again button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AuthService().showSessionExpiredDialog(context),
                child: const Text('Trigger Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Session Expired'), findsOneWidget);
      expect(find.text('Session expired. Please log in again.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Log In Again'), findsOneWidget);
    });
  });

  group('2FA and Profile Session Expiry', () {
    final authService = AuthService();

    test('verify2FALogin does not save tempToken when no session token is returned', () async {
      SharedPreferences.setMockInitialValues({});
      // Calling verify2FALogin with invalid backend response or tempToken should fail and not save tempToken
      final res = await authService.verify2FALogin('123456', 'temp.2fa.token');
      expect(res['success'], isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jwt_token'), isNull);
    });
  });

  group('Voided Borrow Request Explanation', () {
    test('BorrowTransaction recognizes voided status', () {
      final tx = BorrowTransaction(
        id: '1',
        userId: 'u1',
        bookId: 'b1',
        bookTitle: 'Test Book',
        borrowerName: 'Test Student',
        borrowDate: '2026-11-08',
        dueDate: '2026-11-15',
        pickupDeadline: '2026-11-10',
        status: 'Voided',
        penalty: '₱0.00',
      );

      expect(tx.isVoided, isTrue);
    });
  });
}

