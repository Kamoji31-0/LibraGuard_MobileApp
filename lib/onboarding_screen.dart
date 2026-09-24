import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _pages = const [
    OnboardingItem(
      title: 'Seamless Digital Entry',
      description:
          'Tap in with your RFID ID at the library gate. Your entry is logged automatically — no lines, no hassle.',
      illustration: 'assets/images/illus_library_access.png',
      gradientColors: [Color(0xFF800000), Color(0xFFD72036)],
    ),
    OnboardingItem(
      title: 'Explore & Reserve Books',
      description:
          'Search the full library catalog, check if a book is on the shelf right now, and borrow it in one tap.',
      illustration: 'assets/images/illus_book_catalog.png',
      gradientColors: [Color(0xFF800000), Color(0xFFB71C1C)],
    ),
    OnboardingItem(
      title: 'Reserve Study Terminals',
      description:
          'See which computer stations are free, reserve one in advance, and keep track of your session time.',
      illustration: 'assets/images/illus_workstation.png',
      gradientColors: [Color(0xFF800000), Color(0xFFC2185B)],
    ),
    OnboardingItem(
      title: 'Find Your Quiet Zone',
      description:
          'Check live noise levels and room occupancy to find the quietest, least crowded spot to study.',
      illustration: 'assets/images/illus_quiet.png',
      gradientColors: [Color(0xFF800000), Color(0xFF990000)],
    ),
  ];

  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _cardColor => Theme.of(context).cardColor;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _subTextColor =>
      Theme.of(context).textTheme.bodyMedium?.color ?? const Color(0xFF667085);
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Future<void> _completeOnboarding({required Widget destination}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (e) {
      debugPrint('Error saving onboarding preference: $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding(destination: const RegisterScreen());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip Button only
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      _completeOnboarding(destination: const LoginScreen()),
                  style: TextButton.styleFrom(
                    foregroundColor: _subTextColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _subTextColor,
                    ),
                  ),
                ),
              ),
            ),

            // Page View with Cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return _buildPageCard(item);
                },
              ),
            ),

            // Bottom Navigation & Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 28 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _primaryColor
                              : (_isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Main Action Button (Next or Get Started)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _primaryColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? 'GET STARTED' : 'CONTINUE',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Secondary Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: _subTextColor,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _completeOnboarding(
                            destination: const LoginScreen()),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCard(OnboardingItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration Hero Container
                Container(
                  height: (constraints.maxHeight * 0.45).clamp(220.0, 300.0),
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF800000).withValues(
                                alpha: _isDark ? 0.22 : 0.08,
                              ),
                              const Color(0xFF800000).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      Image.asset(
                        item.illustration,
                        fit: BoxFit.contain,
                        height:
                            (constraints.maxHeight * 0.45).clamp(220.0, 300.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card Title
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _subTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String illustration;
  final List<Color> gradientColors;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.illustration,
    required this.gradientColors,
  });
}
