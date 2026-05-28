import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'splash_screen.dart';

// Global theme notifier bridging the StyleGuide across the app without external packages.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore persisted theme preference
  final prefs = await SharedPreferences.getInstance();
  final modeStr = prefs.getString('app_theme_mode') ?? 'system';

  if (modeStr == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else if (modeStr == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else {
    themeNotifier.value = ThemeMode.system;
  }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'LibraGuard',
          debugShowCheckedModeBanner: false,
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          themeMode: currentMode,

          // Light Theme — Standard White/Slate Palette
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF800000), // Maroon 900 equivalent
            scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
            cardColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF800000),
              secondary: Color(0xFF800000), // Updated to Maroon
              surface: Colors.white,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF1D2939)),
              bodyMedium: TextStyle(color: Color(0xFF667085)),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Dark Theme — Premium Dark/Red Palette matching external image StyleGuide
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFB21A2D), // Primary 700
            scaffoldBackgroundColor:
                const Color(0xFF131518), // Secondary 900 Background
            cardColor: const Color(0xFF272B30), // Secondary 500 Surface
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB21A2D), // Primary 700
              secondary: Color(0xFFD72036), // Primary 600 Accent
              surface: Color(0xFF272B30),
              surfaceContainerHighest: Color(0xFF23272B), // Secondary 600
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium:
                  TextStyle(color: Color(0xFF8B8E98)), // Secondary 400 Text
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF272B30),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFD72036), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFB21A2D), width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFB21A2D), width: 2),
              ),
            ),
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}
