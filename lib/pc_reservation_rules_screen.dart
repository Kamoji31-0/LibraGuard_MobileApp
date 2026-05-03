import 'package:flutter/material.dart';
import 'pc_selection_screen.dart';
import 'book_list_screen.dart';
import 'profile_screen.dart';

class PcReservationRulesScreen extends StatefulWidget {
  const PcReservationRulesScreen({super.key});

  @override
  State<PcReservationRulesScreen> createState() =>
      _PcReservationRulesScreenState();
}

class _PcReservationRulesScreenState extends State<PcReservationRulesScreen> {
  int _selectedIndex = 2;

  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor => Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
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
                'Computer Reservation',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'RESERVE A LIBRARY COMPUTER',
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
                  Icon(Icons.desktop_windows_outlined,
                      color: _textColor.withOpacity(0.8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Computer Lab',
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
                        Icon(Icons.warning_amber_rounded,
                            color: _textColor, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Usage Rules',
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
                        'Reserve a computer through the library system and arrive before your scheduled time.'),
                    const SizedBox(height: 16),
                    _buildRuleItem('03.',
                        'Tap your RFID card to log in and start your session.'),
                    const SizedBox(height: 16),
                    _buildRuleItem('04.',
                        'After use, log out and sign out properly to end your session.'),
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
                        'Access is limited to bonafide students, faculty, and staff.'),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                        '02.', 'Only one user per computer is allowed.'),
                    const SizedBox(height: 12),
                    _buildRuleItem('03.',
                        'Usage: 1 hour per day (extendable if no queue).'),
                    const SizedBox(height: 12),
                    _buildRuleItem('04.',
                        'Must end session immediately if another user needs the unit.'),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                        '05.', 'Operating Hours: 8:00 AM – 5:00 PM (Mon–Sat).'),
                    const SizedBox(height: 12),
                    _buildRuleItem('06.',
                        'Eating/drinking in the area is strictly prohibited.'),
                    const SizedBox(height: 12),
                    _buildRuleItem('07.',
                        'Inappropriate/obscene content is strictly prohibited.'),
                    const SizedBox(height: 12),
                    _buildRuleItem('08.',
                        'All sessions are monitored and logged via RFID.'),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textColor,
                            side: BorderSide(
                                color: Colors.black.withOpacity(0.1)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PcSelectionScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Proceed',
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
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
              _buildNavItem(Icons.home_filled, 'Home', 0),
              _buildNavItem(Icons.menu_book, 'Books', 1),
              _buildNavItem(Icons.computer, 'PC', 2),
              _buildNavItem(Icons.person_outline, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == _selectedIndex) return;

        setState(() {
          _selectedIndex = index;
        });

        if (index == 0) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BookListScreen()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? _primaryColor : _textColor.withOpacity(0.3),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? _primaryColor : _textColor.withOpacity(0.4),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: 4),
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ] else ...[
            const SizedBox(height: 7),
          ]
        ],
      ),
    );
  }

  Widget _buildRuleItem(String number, String text,
      {String? highlight, String? suffix}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: TextStyle(
            color: _primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: _textColor.withOpacity(0.7),
                fontSize: 15,
                height: 1.4,
              ),
              children: [
                TextSpan(text: text),
                if (highlight != null)
                  TextSpan(
                    text: highlight,
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (suffix != null) TextSpan(text: suffix),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
