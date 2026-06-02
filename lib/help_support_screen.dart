import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _accentColor => Theme.of(context).colorScheme.secondary;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor => Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;

  // Track expanded FAQ index
  int _expandedIndex = -1;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'What if I lose my RFID card?',
      'answer':
          'Report immediately to the library staff to deactivate your card and prevent unauthorized usage under your account. The replacement fee for a lost card is ₱300.00.',
    },
    {
      'question': 'Can I renew my borrowed books?',
      'answer':
          'Yes. A 7-day renewal is permitted provided no other student has reserved the book. You can request a renewal from your \'My Books\' dashboard.',
    },
    {
      'question': 'How many books can I borrow at once?',
      'answer':
          'Undergraduate students can borrow up to 3 books at a time for a specific duration depending on the book category (Class Use or Overnight).',
    },
    {
      'question': 'How do I enable Two-Factor Authentication (2FA)?',
      'answer':
          '1. Go to your Profile screen.\n2. Tap the "Two-Factor Authentication" section to expand it.\n3. Scan the QR code with an authenticator app (like Google Authenticator) OR long-press the Manual Entry Key to copy it.\n4. Open your authenticator app, add a new account, and paste the key if scanning isn\'t used.\n5. Enter the 6-digit code from your app into LibraGuard and tap "Enable".',
    },
    {
      'question': 'What are the fines for late returns?',
      'answer':
          'Overnight books incur a fine of ₱5.00 per day or ₱1.00 per hour depending on the overdue status. Please return books on time to avoid academic holds.',
    },
    {
      'question': 'Do I need to reserve a PC in advance?',
      'answer':
          'Yes. All computer units must be reserved through the LibraGuard system/app. Reservations are held for 15 minutes before being released to others.',
    },
    {
      'question': 'Is eating allowed inside the library?',
      'answer':
          'No. To protect library materials and equipment, eating and drinking (except water in capped bottles) are strictly prohibited in all areas.',
    },
    {
      'question': 'Can I use the library during semester breaks?',
      'answer':
          'The library is generally closed to patrons during breaks. However, if summer classes are ongoing, the library will be open to accommodate those students.',
    },
  ];

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
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildFAQSection(),
            const SizedBox(height: 32),
            _buildContactSection(),
            const SizedBox(height: 32),
            _buildHoursCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
              Icon(Icons.quiz_outlined, color: _accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faqs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildFAQItem(
                  index, _faqs[index]['question']!, _faqs[index]['answer']!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(int index, String question, String answer) {
    bool isExpanded = _expandedIndex == index;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            color: isExpanded ? _primaryColor : _textColor,
            fontSize: 14,
            fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        trailing: Icon(
          isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
          color: isExpanded ? _primaryColor : _textColor.withOpacity(0.3),
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedIndex = expanded ? index : -1;
          });
        },
        initiallyExpanded: isExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: _textColor.withOpacity(0.7),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
              Icon(Icons.contact_support_outlined,
                  color: _accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Contact Information',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildContactRow('Email:', 'support@libraguard.edu.ph'),
          const SizedBox(height: 16),
          _buildContactRow('Phone:', '(123) 456-7890 local 112'),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHoursCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
              Icon(Icons.access_time_outlined, color: _accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Library Hours',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHourRow('Mondays - Fridays', '8:00 AM – 5:00 PM'),
          const SizedBox(height: 12),
          _buildHourRow('Saturdays', '8:00 AM – 5:00 PM'),
          const SizedBox(height: 12),
          _buildHourRow('Sundays & Holidays', 'Closed', isClosed: true),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'During Semester Break/ Christmas/ Summer Break - no patrons/clients services. However, if there is summer class the library is open for patrons needs.',
            style: TextStyle(
              color: _textColor.withOpacity(0.6),
              fontSize: 12,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(String days, String hours, {bool isClosed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          days,
          style: TextStyle(
            color: _textColor.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          hours,
          style: TextStyle(
          color: isClosed
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF800000)
                  : Colors.red.shade700)
              : _primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
