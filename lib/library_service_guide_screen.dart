// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'book_list_screen.dart';
import 'pc_reservation_rules_screen.dart';
import 'profile_screen.dart';

class LibraryServiceGuideScreen extends StatefulWidget {
  const LibraryServiceGuideScreen({super.key});

  @override
  State<LibraryServiceGuideScreen> createState() =>
      _LibraryServiceGuideScreenState();
}

class _LibraryServiceGuideScreenState extends State<LibraryServiceGuideScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;

  // Track open state for dropdown
  int? _expandedIndex;

  final List<Map<String, dynamic>> _guideItems = [
    {
      'id': '01',
      'category': 'RFID CARD',
      'title': "Get your Borrower's Card",
      'icon': Icons.badge_outlined,
      'detailTitle': 'Process',
      'detailIcon': Icons.info_outline,
      'rules': [
        {
          'number': '01.',
          'text': 'New students must present their ',
          'bold': 'Official Enrollment Form',
          'text2': 'and register at the circulation desk.',
        },
        {
          'number': '02.',
          'text': 'Old students must present their ',
          'bold': 'School ID',
          'text2': 'and register at the circulation desk.',
        },
        {
          'number': '03.',
          'text': 'Fill out the ',
          'bold': 'registration form.',
        },
        {
          'number': '04.',
          'text': 'Faculty members must present their ',
          'bold': 'teaching load schedule',
          'text2': ' approved by their respective dean.',
        },
        {
          'number': '05.',
          'text': 'Once registered, your ',
          'bold': 'RFID Borrower’s Card',
          'text2': ' will be issued and activated for use.',
        },
        {
          'number': '06.',
          'text': 'Use your RFID card to ',
          'bold': 'tap in kiosks and transactions',
          'text2': ' for borrowing, returning, and computer access.',
        },
        {
          'number': '07.',
          'text': 'Visiting researchers must register at the ',
          'bold': 'LibraGuard App',
          'text2': ' and leave a valid ID at the service desk.',
        },
      ],
      'note': [
        {
          'number': '01.',
          'text': 'Only ',
          'bold': 'currently enrolled students, faculty, and staff',
          'text2': ' are allowed to use the card.',
        },
        {
          'number': '02.',
          'text': 'The card is ',
          'bold': 'strictly non-transferable',
          'text2': ' and must not be used by another person.',
        },
        {
          'number': '03.',
          'text': 'Unauthorized use of another person’s card will result in ',
          'bold': 'confiscation and disciplinary action',
          'text2': '.',
        },
        {
          'number': '04.',
          'text': 'Lost cards must be reported ',
          'bold': 'immediately',
          'text2': ' to the librarian.',
        },
        {
          'number': '05.',
          'text': 'Replacement of lost cards requires a fee of ',
          'bold': 'Php 300.00',
          'text2': '.',
        },
        {
          'number': '06.',
          'text': 'Visitor IDs are kept temporarily and returned upon ',
          'bold': 'exit from the library',
          'text2': '.',
        },
      ],
    },
    {
      'id': '02',
      'category': 'BORROWING',
      'title': "Borrow Books",
      'detailTitle': 'Process',
      'detailIcon': Icons.info_outline,
      'rules': [
        {
          'number': '01.',
          'text':
              'Present your valid RFID Card at the circulation desk. Card is ',
          'bold': 'non-transferable',
          'text2': ' and must be used only by the registered owner.',
        },
        {
          'number': '02.',
          'text':
              'Proceed to the circulation desk and inform the librarian of the ',
          'bold': 'book title',
          'text2': ' you wish to borrow.',
        },
        {
          'number': '03.',
          'text': 'Tap your RFID card at the reader for ',
          'bold': 'official checkout',
          'text2': ' after the librarian identifies the book.',
        },
      ],
      'note': [
        {
          'number': '01.',
          'text': 'Borrowers are allowed to borrow up to ',
          'bold': '3 books',
          'text2': ' at a time.',
        },
        {
          'number': '02.',
          'text': 'Ensure the book is ',
          'bold': 'undamaged',
          'text2':
              ' before borrowing. Report any damage to the librarian immediately.',
        },
        {
          'number': '03.',
          'text': 'Reference books and periodicals are for ',
          'bold': 'library use only',
          'text2': ' and cannot be borrowed.',
        },
        {
          'number': '04.',
          'text': 'Books must be returned on or before the ',
          'bold': 'due date',
          'text2': ' to avoid fines.',
        },
        {
          'number': '05.',
          'text': 'Visiting researchers must register at the ',
          'bold': 'LibraGuard App',
          'text2': ' and present a valid institutional ID.',
        },
      ],
      'buttonText': 'Explore Books',
      'icon': Icons.menu_book_outlined,
    },
    {
      'id': '03',
      'category': 'RETURNING',
      'title': "Return Books",
      'icon': Icons.keyboard_return_outlined,
      'detailTitle': 'Process',
      'detailIcon': Icons.info_outline,
      'rules': [
        {
          'number': '01.',
          'text': 'Proceed to the circulation desk with the ',
          'bold': 'books to be returned',
          'text2': '.',
        },
        {
          'number': '02.',
          'text': 'Tap your RFID card to the reader to ',
          'bold': 'verify your record',
          'text2': ' and log the return.',
        },
        {
          'number': '03.',
          'text': 'Wait for the librarian to ',
          'bold': 'check the book’s condition',
          'text2': ' and update the system.',
        },
      ],
      'note': [
        {
          'number': '01.',
          'text': 'If books are returned late, a ',
          'bold': 'daily fine',
          'text2': ' will be computed and charged.',
        },
        {
          'number': '02.',
          'text': 'In case of lost or damaged books, the borrower must ',
          'bold': 'replace the book',
          'text2': ' with the same title or pay the current market value.',
        },
        {
          'number': '03.',
          'text': 'Securing a ',
          'bold': 'clearance slip',
          'text2':
              ' is mandatory for students with outstanding library obligations.',
        },
      ],
      'buttonText': 'View My Books'
    },
    {
      'id': '04',
      'category': 'COMPUTER',
      'title': "Computer Access",
      'icon': Icons.computer_outlined,
      'detailTitle': 'Process',
      'detailIcon': Icons.info_outline,
      'rules': [
        {
          'number': '01.',
          'text': 'Reserve a computer through the ',
          'bold': 'library system',
          'text2': ' and arrive before your scheduled time.',
        },
        {
          'number': '02.',
          'text': 'Tap your RFID card to ',
          'bold': 'log in',
          'text2': ' and start your session.',
        },
        {
          'number': '03.',
          'text': 'After use, ',
          'bold': 'log out and sign out',
          'text2': ' properly to end your session.',
        },
      ],
      'note': [
        {
          'number': '01.',
          'text': 'Access is limited to ',
          'bold': 'bonafide students, faculty, and staff',
          'text2': ' of the institution.',
        },
        {
          'number': '02.',
          'text': 'Only ',
          'bold': 'one user per computer',
          'text2': ' is allowed at any given time.',
        },
        {
          'number': '03.',
          'text': 'Usage is limited to ',
          'bold': '1 hour per day',
          'text2': ', but may be extended if no other users are waiting.',
        },
        {
          'number': '04.',
          'text': 'If another user needs the unit, you must ',
          'bold': 'end your session and sign out',
          'text2': ' immediately.',
        },
        {
          'number': '05.',
          'text': 'Internet access is available from ',
          'bold': '8:00 AM – 5:00 PM (Monday–Saturday)',
          'text2': '.',
        },
        {
          'number': '06.',
          'text': 'Eating or drinking in the computer area is ',
          'bold': 'strictly prohibited',
          'text2': ' to protect equipment.',
        },
        {
          'number': '07.',
          'text': 'Accessing ',
          'bold': 'obscene or inappropriate content',
          'text2': ' is strictly prohibited.',
        },
        {
          'number': '08.',
          'text': 'All sessions are ',
          'bold': 'monitored and logged via RFID system',
          'text2': ' for security and accountability.',
        },
      ],
      'buttonText': 'Reserve Computer'
    },
    {
      'id': '05',
      'category': 'RFID LOGIN ENTRY',
      'title': 'Library Entry & Exit',
      'icon': Icons.sensor_door_outlined,
      'detailTitle': 'Process',
      'detailIcon': Icons.info_outline,
      'rules': [
        {
          'number': '01.',
          'text': 'All students, faculty, and staff must ',
          'bold': 'tap or scan their RFID card',
          'text2': ' at the entrance kiosk before entering the library.',
        },
        {
          'number': '02.',
          'text':
              'Upon exiting, tap your RFID card again at the exit kiosk to ',
          'bold': 'log your departure',
          'text2': ' and ensure a complete gate record.',
        },
        {
          'number': '03.',
          'text': 'Visitors without an RFID card must register at the ',
          'bold': 'circulation desk',
          'text2': ' and surrender a valid ID before entry.',
        },
        {
          'number': '04.',
          'text': 'Do not allow others to ',
          'bold': 'tailgate or piggyback',
          'text2': ' through the gate — each person must tap individually.',
        },
        {
          'number': '05.',
          'text': 'If the kiosk fails to read your card, approach the ',
          'bold': 'librarian on duty',
          'text2': ' for manual entry logging.',
        },
        {
          'number': '06.',
          'text': 'Students carrying borrowed books must present them for ',
          'bold': 'inspection at the exit',
          'text2': ' to confirm they were properly checked out.',
        },
      ],
      'note': [
        {
          'number': '01.',
          'text': 'Your RFID card is ',
          'bold': 'strictly non-transferable',
          'text2':
              ' — unauthorized sharing will result in confiscation and disciplinary action.',
        },
        {
          'number': '02.',
          'text': 'All entry and exit logs are ',
          'bold': 'recorded in the system',
          'text2': ' and may be reviewed for security and attendance purposes.',
        },
        {
          'number': '03.',
          'text':
              'Repeatedly bypassing the RFID gate without tapping may result in ',
          'bold': 'suspension of library privileges',
          'text2': '.',
        },
        {
          'number': '04.',
          'text': 'Lost or damaged RFID cards must be ',
          'bold': 'reported immediately',
          'text2':
              ' to prevent unauthorized access. Replacement fee is Php 300.00.',
        },
        {
          'number': '05.',
          'text': 'The library gate system operates ',
          'bold': '8:00 AM – 5:00 PM (Monday–Saturday)',
          'text2':
              '. Outside these hours, access requires special authorization.',
        },
        {
          'number': '06.',
          'text': 'Only ',
          'bold': 'currently enrolled students, faculty, and staff',
          'text2': ' are permitted to enter the library using their RFID card.',
        },
      ],
      'buttonText': 'View My Entry',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                itemCount: _guideItems.length,
                itemBuilder: (context, index) {
                  return _buildExpandableGuideItem(
                    index: index,
                    item: _guideItems[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back, color: _textColor, size: 20),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Library Services',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore the process and guideline of Library services',
            style: TextStyle(
              color: _textColor.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableGuideItem(
      {required int index, required Map<String, dynamic> item}) {
    final bool isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'], color: _primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['id']} — ${item['category']}',
                        style: TextStyle(
                          color: _primaryColor.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['title'],
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.chevron_right,
                      color: _textColor.withOpacity(0.3)),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildDetailsContent(item),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsContent(Map<String, dynamic> item) {
    List<Widget> children = [];

    // Process/Rules section
    if (item.containsKey('rules')) {
      children.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item['detailIcon'] ?? Icons.info_outline,
                    color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  item['detailTitle'] ?? 'Rules',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...((item['rules'] as List).map((rule) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule['number'],
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: _textColor.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: rule['text'] ?? ''),
                            if (rule['bold'] != null)
                              TextSpan(
                                text: rule['bold'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            if (rule['text2'] != null)
                              TextSpan(text: rule['text2']),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      );
    } else if (item.containsKey('details')) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 64.0),
          child: Text(
            item['details'] ?? '',
            style: TextStyle(
              color: _textColor.withOpacity(0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    // Divider and Note section
    if (item.containsKey('note')) {
      if (children.isNotEmpty) {
        children.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ));
      }

      children.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.black, size: 20),
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
            if (item['note'] is String)
              Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: Text(
                  item['note'],
                  style: TextStyle(
                    color: _textColor.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              )
            else if (item['note'] is List)
              ...((item['note'] as List).map((rule) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule['number'],
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: _textColor.withOpacity(0.8),
                              fontSize: 13,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(text: rule['text'] ?? ''),
                              if (rule['bold'] != null)
                                TextSpan(
                                  text: rule['bold'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              if (rule['text2'] != null)
                                TextSpan(text: rule['text2']),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()),
          ],
        ),
      );
    }

    // Button section
    if (item['buttonText'] != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (item['buttonText'] == 'Explore Books') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookListScreen(),
                    ),
                  );
                } else if (item['buttonText'] == 'Reserve Computer') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PcReservationRulesScreen(),
                    ),
                  );
                } else if (item['buttonText'] == 'View My Books') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                } else if (item['buttonText'] == 'View My Entry') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                item['buttonText'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // To match the UI look for bottom nav, since it was shown in the screenshot
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
    bool isSelected =
        false; // Guide is usually opened from Home, so none are "selected" on this sub-page unless we want to highlight one.
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.popUntil(context, (route) => route.isFirst);
          return;
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BookListScreen()),
          );
          return;
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PcReservationRulesScreen()),
          );
          return;
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
          return;
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
}
