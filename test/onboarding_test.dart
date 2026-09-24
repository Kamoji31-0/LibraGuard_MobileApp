import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:libraguard/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': false,
      });
    });

    testWidgets('Renders first card correctly with branding and category',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(find.text('LIBRAGUARD'), findsOneWidget);
      expect(find.text('LIBRARY ACCESS'), findsOneWidget);
      expect(find.text('Seamless Digital Entry'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Tapping Skip marks has_seen_onboarding = true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      final skipButton = find.text('Skip');
      expect(skipButton, findsOneWidget);
      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_seen_onboarding'), isTrue);
    });

    testWidgets('Swiping to last card changes button to GET STARTED',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(find.text('CONTINUE'), findsOneWidget);

      // Tap CONTINUE 3 times to reach page 4
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('CONTINUE'));
        await tester.pumpAndSettle();
      }

      expect(find.text('STUDY ENVIRONMENT'), findsOneWidget);
      expect(find.text('Find Your Quiet Zone'), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);

      // Tap GET STARTED to complete
      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_seen_onboarding'), isTrue);
    });
  });
}
