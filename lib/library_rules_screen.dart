import 'package:flutter/material.dart';
import 'book_list_screen.dart';
import 'pc_reservation_rules_screen.dart';
import 'profile_screen.dart';
import 'widgets/app_bottom_nav.dart';

class LibraryRulesScreen extends StatefulWidget {
  final int? initialExpandedIndex;
  const LibraryRulesScreen({super.key, this.initialExpandedIndex});

  @override
  State<LibraryRulesScreen> createState() => _LibraryRulesScreenState();
}

class _LibraryRulesScreenState extends State<LibraryRulesScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _accentColor => Theme.of(context).colorScheme.secondary;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;

  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _expandedIndex = widget.initialExpandedIndex;
  }

  final List<Map<String, dynamic>> _rulesItems = [
    {
      'id': '01',
      'category': 'BORROWERS',
      'title': "Authorized Borrowers",
      'icon': Icons.groups,
      'detailTitle': 'Who can borrow?',
      'detailIcon': Icons.check_circle_outline,
      'rules': [
        {
          'number': '01.',
          'text': 'The library is open to all members of the ',
          'bold': 'University of Eastern Pangasinan (UEP)',
          'text2': ' academic community.',
        },
      ],
      'subSections': [
        {
          'title': 'Regular Users',
          'items': [
            'Enrolled students of UEP',
            'Faculty members of UEP',
            'Administrative staff and personnel of UEP',
          ],
        },
        {
          'title': 'Other Authorized Users',
          'items': [
            'Alumni (with valid UEP Alumni ID)',
            'Municipal staff of Binalonan, Pangasinan',
            'Clients from partner schools (Inter-Library Loan Program)',
            'Visiting / outside researchers with referral letter',
          ],
        },
      ],
      'note': [
        {
          'number': '02.',
          'text': 'Visiting researchers must present a ',
          'bold': 'referral letter',
          'text2': ' from their institution before accessing library services.',
        },
        {
          'number': '03.',
          'text': 'Library access is ',
          'bold': 'free of charge',
          'text2':
              ' unless reciprocity applies with institutions that charge fees.',
        },
        {
          'number': '04.',
          'text': 'A fee of ',
          'bold': 'Php 35.00',
          'text2':
              ' may be charged to external users depending on institutional agreements.',
        },
      ],
    },
    {
      'id': '02',
      'category': 'GENERAL RULES',
      'title': "Library Rules",
      'icon': Icons.local_library,
      'detailTitle': 'Conduct & Usage',
      'detailIcon': Icons.rule_outlined,
      'rules': [
        {
          'number': '01.',
          'text': 'All users must ',
          'bold': 'log in using their RFID or digital system',
          'text2': ' upon entering the library.',
        },
        {
          'number': '02.',
          'text': 'The library is intended for ',
          'bold': 'research, learning, and quiet reading',
          'text2': ' only.',
        },
        {
          'number': '03.',
          'text': 'Bags must be placed in the ',
          'bold': 'designated baggage area',
          'text2': '. Do not leave valuables unattended.',
        },
        {
          'number': '04.',
          'text': 'Mobile phones must be set to ',
          'bold': 'silent mode',
          'text2': ' while inside the library.',
        },
        {
          'number': '05.',
          'text': 'The following are strictly prohibited: ',
          'bold': 'eating, littering, and damaging library materials',
          'text2': '.',
        },
        {
          'number': '06.',
          'text': 'Users must maintain ',
          'bold': 'silence and proper behavior',
          'text2': ' at all times.',
        },
        {
          'number': '07.',
          'text': 'No valid ',
          'bold': 'RFID Borrower’s Card',
          'text2': ' means no borrowing privileges.',
        },
        {
          'number': '08.',
          'text': 'Each student may borrow up to ',
          'bold': '3 books at a time',
          'text2': ' provided they are not of the same title.',
        },
        {
          'number': '09.',
          'text': 'All activities are ',
          'bold': 'monitored through the library system',
          'text2': ' for security and accountability.',
        },
        {
          'number': '10.',
          'text': 'The librarian and library staff have the authority to ',
          'bold': 'enforce rules and apply sanctions',
          'text2': ' for any violations.',
        },
      ],
    },
    {
      'id': '03',
      'category': 'CONDUCT',
      'title': "Conduct Inside Premises",
      'icon': Icons.menu_book,
      'detailTitle': 'Behavioral Guide',
      'detailIcon': Icons.person_search_outlined,
      'rules': [
        {
          'number': '01.',
          'text': 'Maintain ',
          'bold': 'silence at all times',
          'text2': ' and respect others who are studying or reading.',
        },
        {
          'number': '02.',
          'text': 'Mobile phones and electronic devices must be in ',
          'bold': 'silent mode',
          'text2': ' while inside the library.',
        },
        {
          'number': '03.',
          'text': 'Bags and large items must be placed in the ',
          'bold': 'designated baggage area',
          'text2': '. Do not leave valuables unattended.',
        },
        {
          'number': '04.',
          'text': 'The library is a ',
          'bold': 'no eating and no drinking zone',
          'text2': ' to maintain cleanliness and protect materials.',
        },
        {
          'number': '05.',
          'text': 'Laptops may only be used for ',
          'bold': 'research and academic work',
          'text2': '. Games and movie viewing are not allowed.',
        },
        {
          'number': '06.',
          'text': 'Damaging library materials such as ',
          'bold': 'writing, folding, or inserting objects in books',
          'text2': ' is strictly prohibited.',
        },
        {
          'number': '07.',
          'text': 'Keep your area ',
          'bold': 'clean and organized',
          'text2':
              '. Arrange chairs and dispose of trash properly before leaving.',
        },
        {
          'number': '08.',
          'text': 'Library staff and librarians have the authority to ',
          'bold': 'enforce discipline and maintain order',
          'text2': '.',
        },
      ],
      'note': [
        {
          'number': '01.',
          'text': 'Any person found violating these rules may be asked to ',
          'bold': 'leave the library',
          'text2': '.',
        },
      ],
    },
    {
      'id': '04',
      'category': 'LOANING',
      'title': "Loaning Policies",
      'icon': Icons.menu_book,
      'detailTitle': 'Circulation Rules',
      'detailIcon': Icons.history_edu_outlined,
      'rules': [
        {
          'number': '01.',
          'text': 'At least ',
          'bold': 'one (1) copy per title',
          'text2': ' must always remain in the library.',
        },
        {
          'number': '02.',
          'text': 'Reserved books may be borrowed for ',
          'bold': 'class use only',
          'text2': ' and must be returned immediately after class.',
        },
        {
          'number': '03.',
          'text': 'Renewal is allowed only if there is ',
          'bold': 'no demand from other users',
          'text2': '.',
        },
        {
          'number': '04.',
          'text': 'Allowed for overnight use: ',
          'bold': 'Filipiniana, General Collection, and Professional Books',
          'text2': '.',
        },
        {
          'number': '05.',
          'text': 'The following materials are for ',
          'bold': 'library use only',
          'text2':
              ': Periodicals, Journals, Encyclopedias, Dictionaries, Atlases, and Almanacs.',
        },
        {
          'number': '06.',
          'text': 'Faculty members may borrow up to ',
          'bold': '10 books',
          'text2':
              ' depending on subject load, valid for 1 month if not in demand.',
        },
        {
          'number': '07.',
          'text': 'Visiting researchers and alumni are allowed ',
          'bold': 'library room use only',
          'text2': '.',
        },
        {
          'number': '08.',
          'text': 'CDs, DVDs, and tapes may be borrowed for ',
          'bold': 'overnight use only',
          'text2': '.',
        },
      ],
      'subSections': [
        {
          'title': 'Class Use Books',
          'items': [
            'Books borrowed for class use must be returned immediately after the specified class.',
          ],
        },
        {
          'title': 'Library Room Use',
          'items': [
            'Books may be used inside the library for unlimited time.',
            'Borrowers must return the book if another user needs it.',
          ],
        },
        {
          'title': 'Overnight / Weekend Use',
          'items': [
            'Borrowing time: 3:00 PM – 5:00 PM (Monday–Friday only).',
            'Maximum of 3 books per borrower at a time.',
            'Books must not be of the same title.',
            'Return deadline: on or before 8:00 AM the following day.',
          ],
        },
      ],
    },
    {
      'id': '05',
      'category': 'INTERNET',
      'title': "Internet/Computer Policy",
      'icon': Icons.computer_outlined,
      'detailTitle': 'Usage Rules',
      'detailIcon': Icons.monitor_outlined,
      'rules': [
        {
          'number': '01.',
          'text': 'Reserve a computer through the ',
          'bold': 'library system',
          'text2': ' and arrive before your scheduled time.',
        },
        {
          'number': '02.',
          'text': 'Sign in to the ',
          'bold': 'logbook or digital system',
          'text2': ' before accessing the unit.',
        },
        {
          'number': '03.',
          'text': 'Tap your RFID card to ',
          'bold': 'log in',
          'text2': ' and start your session.',
        },
        {
          'number': '04.',
          'text': 'After use, ',
          'bold': 'log out and sign out',
          'text2': ' properly to end your session.',
        },
        {
          'number': '05.',
          'text': 'Access is limited to ',
          'bold': 'bonafide students, faculty, and staff',
          'text2': ' of the institution.',
        },
        {
          'number': '06.',
          'text': 'Only ',
          'bold': 'one user per computer',
          'text2': ' is allowed at any given time.',
        },
        {
          'number': '07.',
          'text': 'Usage is limited to ',
          'bold': '1 hour per day',
          'text2': ', but may be extended if no other users are waiting.',
        },
        {
          'number': '08.',
          'text': 'If another user needs the unit, you must ',
          'bold': 'end your session and sign out',
          'text2': ' immediately.',
        },
        {
          'number': '09.',
          'text': 'Internet access is available from ',
          'bold': '8:00 AM – 5:00 PM (Monday–Saturday)',
          'text2': '.',
        },
        {
          'number': '10.',
          'text': 'Eating or drinking in the computer area is ',
          'bold': 'strictly prohibited',
          'text2': ' to protect equipment.',
        },
        {
          'number': '11.',
          'text': 'Accessing ',
          'bold': 'obscene or inappropriate content',
          'text2': ' is strictly prohibited.',
        },
        {
          'number': '12.',
          'text': 'All sessions are ',
          'bold': 'monitored and logged via RFID system',
          'text2': ' for security and accountability.',
        },
      ],
    },
    {
      'id': '06',
      'category': 'FINES',
      'title': "Fees and Penalties",
      'icon': Icons.gavel,
      'detailTitle': 'Fine Structure & Sanctions',
      'detailIcon': Icons.account_balance_wallet_outlined,
      'rules': [
        {
          'number': '01.',
          'text': 'Lost books must be replaced with the ',
          'bold': 'same title',
          'text2': '.',
        },
        {
          'number': '02.',
          'text':
              'Defacing, cutting, or damaging library materials is subject to ',
          'bold': 'disciplinary action',
          'text2': '.',
        },
        {
          'number': '03.',
          'text': 'Unauthorized taking of library materials results in ',
          'bold': 'progressive sanctions',
          'text2': '.',
        },
        {
          'number': '04.',
          'text': 'Eating, drinking, noise disruption, and misconduct follow ',
          'bold':
              '3-step penalties (Warning → Suspension → Extended Suspension)',
          'text2': '.',
        },
        {
          'number': '05.',
          'text': 'Disrespect toward library personnel may result in ',
          'bold': 'reporting to Student Affairs / Guidance Office',
          'text2': '.',
        },
        {
          'number': '06.',
          'text': 'Using another person’s Borrower’s Card results in ',
          'bold': 'confiscation and suspension of privileges',
          'text2': '.',
        },
      ],
      'subSections': [
        {
          'title': 'Photocopying',
          'items': [
            'Allowed duration: 2 hours only.',
            'Exceeding time incurs ₱5.00 per hour.',
            'Photocopy slip must be signed at the service desk.',
            'Borrower’s card must be left as security.',
          ],
        },
        {
          'title': 'Overnight / Weekend Books',
          'items': [
            '₱1.00 per book per hour after due date OR',
            '₱5.00 per book per day after due date.',
          ],
        },
        {
          'title': 'Class Use Books',
          'items': [
            '₱5.00 per hour after the specified class period.',
          ],
        },
      ],
      'violationMatrix': [
        {
          'violation': 'Eating / Drinking / Noise / Misconduct',
          'tier1': 'Warning',
          'tier2': '1 week suspension',
          'tier3': '1 month suspension',
        },
        {
          'violation': 'Borrower’s Card misuse',
          'tier1': 'Warning',
          'tier2': '1 week suspension',
          'tier3': '2 weeks suspension',
        },
        {
          'violation': 'Lost Borrower’s Card',
          'process': [
            'Pay ₱300 at cashier',
            'Present receipt to librarian',
            'Receive replacement card',
          ],
        },
      ],
      'paymentPolicy': [
        'All payments must be made at the Cashier’s Office.',
        'Receipts must be presented to library staff before clearance.',
      ],
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
                itemCount: _rulesItems.length,
                itemBuilder: (context, index) {
                  return _buildExpandableRuleItem(
                    index: index,
                    item: _rulesItems[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          if (index == 0) {
            // Already "home" logic for rules
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: _textColor),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 12),
          Text(
            'Rules & Regulations',
            style: TextStyle(
              color: _accentColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Understand the guidelines for a better library experience.',
            style: TextStyle(
              color: _textColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableRuleItem({
    required int index,
    required Map<String, dynamic> item,
  }) {
    bool isExpanded = _expandedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isExpanded ? 0.08 : 0.04),
                blurRadius: isExpanded ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: isExpanded
                ? Border.all(color: _accentColor.withOpacity(0.1), width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        item['icon'],
                        color: _accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['category'],
                            style: TextStyle(
                              color: _accentColor.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['title'],
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: _textColor.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _buildDetailsContent(item),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsContent(Map<String, dynamic> item) {
    List<Widget> children = [];

    // Divider
    children.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Divider(
          color: Colors.black.withOpacity(0.05),
          thickness: 1,
        ),
      ),
    );

    // Detail Title
    children.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Icon(item['detailIcon'],
                color: _textColor.withOpacity(0.8), size: 18),
            const SizedBox(width: 8),
            Text(
              item['detailTitle'],
              style: TextStyle(
                color: _textColor.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    // List of rules
    if (item['rules'] != null) {
      children.addAll((item['rules'] as List).map((rule) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rule['number'],
                style: TextStyle(
                  color: _accentColor,
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
                      TextSpan(text: rule['text']),
                      if (rule['bold'] != null)
                        TextSpan(
                          text: rule['bold'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      if (rule['text2'] != null) TextSpan(text: rule['text2']),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList());
    }

    // List of sub-sections (bullet points with headers)
    if (item['subSections'] != null) {
      children.addAll((item['subSections'] as List).map((section) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              section['title'],
              style: TextStyle(
                color: _textColor.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...((section['items'] as List).map((text) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ",
                        style: TextStyle(
                            color: _accentColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          color: _textColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        );
      }).toList());
    }

    // Take Note section
    if (item['note'] != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 32, thickness: 1),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: _textColor.withOpacity(0.8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Reminder',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...((item['note'] as List).map((rule) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule['number'],
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: _textColor.withOpacity(0.8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(text: rule['text']),
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
        ),
      );
    }

    // Violation Matrix
    if (item['violationMatrix'] != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VIOLATION MATRIX',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              ...((item['violationMatrix'] as List).map((v) {
                if (v['process'] != null) {
                  final bool isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue.withOpacity(0.12)
                          : Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v['violation'],
                          style: TextStyle(
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ...((v['process'] as List).map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 12,
                                      color: isDark
                                          ? Colors.blue.shade300
                                          : Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(p,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.blue.shade100
                                              : Colors.blue.shade900)),
                                ],
                              ),
                            ))),
                      ],
                    ),
                  );
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['violation'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTierInfo('1st', v['tier1']),
                          _buildTierInfo('2nd', v['tier2']),
                          _buildTierInfo('3rd', v['tier3']),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList()),
            ],
          ),
        ),
      );
    }

    // Payment Policy
    if (item['paymentPolicy'] != null) {
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.green.withOpacity(0.12)
                  : Colors.green.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: isDark
                      ? Colors.green.withOpacity(0.3)
                      : Colors.green.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance,
                        color: isDark
                            ? Colors.green.shade400
                            : Colors.green.shade700,
                        size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Policy',
                      style: TextStyle(
                        color: isDark
                            ? Colors.green.shade300
                            : Colors.green.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...((item['paymentPolicy'] as List).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14,
                              color: isDark
                                  ? Colors.green.shade400
                                  : Colors.green.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(p,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.green.shade100
                                          : Colors.green.shade900))),
                        ],
                      ),
                    ))),
              ],
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

  Widget _buildTierInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: _accentColor,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 11,
                color: _textColor.withOpacity(0.8),
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
