import 'package:flutter/material.dart';
import 'book_list_screen.dart';
import 'pc_reservation_rules_screen.dart';
import 'profile_screen.dart';
import 'widgets/app_bottom_nav.dart';

class RfidLibraryCardScreen extends StatefulWidget {
  const RfidLibraryCardScreen({super.key});

  @override
  State<RfidLibraryCardScreen> createState() => _RfidLibraryCardScreenState();
}

class _RfidLibraryCardScreenState extends State<RfidLibraryCardScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _accentColor => Theme.of(context).colorScheme.secondary;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RFID Library Card',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'CREATE YOUR RFID LIBRARY CARD',
                style: TextStyle(
                  color: _textColor.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.badge_outlined,
                      color: _textColor.withOpacity(0.8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'RFID Library Card',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _cardColor,
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
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: _textColor, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Guide',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildRuleItem('01.',
                        'New students must present their Official Enrollment Form and register at the circulation desk.'),
                    const SizedBox(height: 16),
                    _buildRuleItem('02.',
                        'Old students must present their School ID and register at the circulation desk.'),
                    const SizedBox(height: 16),
                    _buildRuleItem('03.', 'Fill out the registration form.'),
                    const SizedBox(height: 16),
                    _buildRuleItem('04.',
                        'Faculty members must present their teaching load schedule approved by their respective dean.'),
                    const SizedBox(height: 16),
                    _buildRuleItem('05.',
                        'Once registered, your RFID Borrower’s Card will be issued and activated for use.'),
                    const SizedBox(height: 16),
                    _buildRuleItem('06.',
                        'Use your RFID card to tap in kiosks and transactions for borrowing, returning, and computer access.'),
                    const SizedBox(height: 16),
                    _buildRuleItem('07.',
                        'Visiting researchers must register at the LibraGuard App and leave a valid ID at the service desk.'),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: _textColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Note',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRuleItem('01.',
                        'Only currently enrolled students, faculty, and staff are allowed to use the card.'),
                    const SizedBox(height: 12),
                    _buildRuleItem('02.',
                        'The card is strictly non-transferable and must not be used by another person.'),
                    const SizedBox(height: 12),
                    _buildRuleItem('03.',
                        'Unauthorized use of another person’s card will result in confiscation and disciplinary action.'),
                    const SizedBox(height: 12),
                    _buildRuleItem('04.',
                        'Lost cards must be reported immediately to the librarian.'),
                    const SizedBox(height: 12),
                    _buildRuleItem('05.',
                        'Replacement of lost cards requires a fee of Php 300.00.'),
                    const SizedBox(height: 12),
                    _buildRuleItem('06.',
                        'Visitor IDs are kept temporarily and returned upon exit from the library.'),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
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
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: -1, // Not on main nav items
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BookListScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const PcReservationRulesScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildRuleItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: TextStyle(
            color: _accentColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _textColor.withOpacity(0.8),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
