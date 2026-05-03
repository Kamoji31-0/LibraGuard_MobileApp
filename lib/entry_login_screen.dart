import 'package:flutter/material.dart';
import 'book_list_screen.dart';
import 'pc_reservation_rules_screen.dart';
import 'profile_screen.dart';

class EntryLoginScreen extends StatelessWidget {
  const EntryLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
    final cardColor = Theme.of(context).cardColor;

    Widget ruleItem(String number, String text) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              color: primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      );
    }

    Widget sectionTitle(IconData icon, String title) {
      return Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Library Entry Login',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'HOW TO ENTER THE LIBRARY',
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.sensor_door_outlined,
                      color: textColor.withOpacity(0.8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Gate Entry Process',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(Icons.login_rounded, 'Entry Procedure'),
                    const SizedBox(height: 28),
                    ruleItem('01.',
                        'Approach the library gate and locate the RFID scanner kiosk at the entrance.'),
                    const SizedBox(height: 16),
                    ruleItem('02.',
                        'Tap your RFID Borrower\'s Card on the scanner. The system will automatically log your time-in.'),
                    const SizedBox(height: 16),
                    ruleItem('03.',
                        'Wait for the green indicator light and the confirmation beep before entering.'),
                    const SizedBox(height: 16),
                    ruleItem('04.',
                        'If the scanner does not respond, proceed to the circulation desk for manual logging.'),
                    const SizedBox(height: 16),
                    ruleItem('05.',
                        'Your entry will be recorded in the system and visible in your Library Gate Logs inside the LibraGuard app.'),
                    const SizedBox(height: 16),
                    ruleItem('06.',
                        'When leaving, tap your card again at the gate to log your time-out and complete your session.'),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    sectionTitle(Icons.warning_amber_rounded, 'Reminders'),
                    const SizedBox(height: 20),
                    ruleItem('01.',
                        'You must be a registered library member with an active RFID card to enter.'),
                    const SizedBox(height: 14),
                    ruleItem('02.',
                        'Tailgating (entering without tapping your card) is strictly prohibited.'),
                    const SizedBox(height: 14),
                    ruleItem('03.',
                        'Do not lend your RFID card to others. Each entry must be personally authenticated.'),
                    const SizedBox(height: 14),
                    ruleItem('04.',
                        'Loud behavior, eating, and use of mobile phones are not allowed inside the library.'),
                    const SizedBox(height: 14),
                    ruleItem('05.',
                        'Bags and belongings are subject to inspection upon exit by library personnel.'),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Got it',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

// Standalone bottom nav for this screen (no state needed)
class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);

    Widget navItem(IconData icon, String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor.withOpacity(0.3), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(Icons.home_filled, 'Home',
                  () => Navigator.popUntil(context, (r) => r.isFirst)),
              navItem(
                  Icons.menu_book,
                  'Books',
                  () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const BookListScreen()))),
              navItem(
                  Icons.computer,
                  'PC',
                  () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PcReservationRulesScreen()))),
              navItem(
                  Icons.person_outline,
                  'Profile',
                  () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()))),
            ],
          ),
        ),
      ),
    );
  }
}
