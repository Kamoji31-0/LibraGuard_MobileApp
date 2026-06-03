import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'services/auth_service.dart';
import 'services/secure_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

late Animation<Offset> _blob1Offset;
  late Animation<Offset> _blob2Offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

_fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

_blob1Offset = Tween<Offset>(
      begin: const Offset(-0.1, -0.1),
      end: const Offset(0.2, 0.2),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));

    _blob2Offset = Tween<Offset>(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.1, 1.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));

    _controller.forward();

_controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });
  }

  Future<void> _navigateToHome() async {
    final authService = AuthService();
    final secureStorage = SecureStorageService();

    final bool hasToken = await secureStorage.hasToken();
    String? firstName;

    if (hasToken) {

      firstName = await authService.getFirstName();

}

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasToken
                ? HomeScreen(firstName: firstName)
                : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [

          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),

AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final size = MediaQuery.of(context).size;
              return Stack(
                children: [
                  _buildBlob(
                    offset: _blob1Offset.value,
                    size: size.width * 1.5,
                    color: const Color(0xFF800000).withOpacity(0.35),
                  ),
                  _buildBlob(
                    offset: _blob2Offset.value,
                    size: size.width * 1.5,
                    color: const Color(0xFF800000).withOpacity(0.5),
                  ),
                ],
              );
            },
          ),

Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.15),
                            blurRadius: 25,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'LIBRAGUARD',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 50,
                        height: 2,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'YOUR DIGITAL LIBRARY COMPANION',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor.withOpacity(0.8),
                            fontSize: 14,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildBlob({
    required Offset offset,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: (offset.dx * MediaQuery.of(context).size.width) - (size / 2),
      top: (offset.dy * MediaQuery.of(context).size.height) - (size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0.0)],
            stops: const [0.2, 1.0],
          ),
        ),
      ),
    );
  }
}
