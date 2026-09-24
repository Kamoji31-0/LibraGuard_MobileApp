import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatefulWidget {
  final bool showAcceptButton;
  final VoidCallback? onAccepted;

  const TermsConditionsScreen({
    super.key,
    this.showAcceptButton = false,
    this.onAccepted,
  });

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  Color get _accentColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFD72036)
      : const Color(0xFF800000);

  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? const Color(0xFFD72036) : _textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: widget.showAcceptButton
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.onAccepted != null) {
                        widget.onAccepted!();
                      }
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'I Understand & Agree',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Badge / Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF2C151B),
                          const Color(0xFF1C1D24),
                        ]
                      : [
                          const Color(0xFFFBE8EC),
                          const Color(0xFFF7D9E0),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFFD72036).withOpacity(0.12)
                        : const Color(0xFF800000).withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFD72036)
                      : const Color(0xFF800000),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(isDark ? 0.2 : 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: _accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIBRAGUARD USER AGREEMENT',
                              style: TextStyle(
                                color: _accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'University of Eastern Pangasinan',
                              style: TextStyle(
                                color: _textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'These Terms and Conditions ("Agreement") govern the use of LibraGuard, an IoT and RFID-based library management system developed for the University of Eastern Pangasinan (UEP) Library. By creating an account or using the LibraGuard mobile application ("App"), the User agrees to comply with all terms stated herein.',
                    style: TextStyle(
                      color: isDark
                          ? _textColor.withOpacity(0.85)
                          : const Color(0xFF475467),
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 1: Definition (NO ICONS)
            _buildSectionCard(
              sectionNumber: '1',
              title: 'Definition',
              child: Text(
                'LibraGuard refers to the mobile application, RFID-based borrowing system, and all related features developed to support library transactions, notifications, and record-keeping for the UEP Library.',
                style: _bodyTextStyle,
              ),
            ),

            // Section 2: User Eligibility (NO ICONS)
            _buildSectionCard(
              sectionNumber: '2',
              title: 'User Eligibility',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Access to LibraGuard is granted to members of the UEP academic community, consistent with the UEP Library\'s authorized borrowers:',
                    style: _bodyTextStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildBulletItem(
                      'Enrolled students of UEP with a valid, current-semester registration'),
                  _buildBulletItem('Faculty members of UEP'),
                  _buildBulletItem('Administrative staff and personnel of UEP'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'Other users (alumni, visiting researchers, or clients from partner institutions) may be granted limited access subject to the same requirements set by the UEP Library\'s existing policies.',
                      style: TextStyle(
                        color: isDark
                            ? _textColor.withOpacity(0.75)
                            : const Color(0xFF64748B),
                        fontSize: 13,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Section 3: Account and Library Card Use (NO ICONS)
            _buildSectionCard(
              sectionNumber: '3',
              title: 'Account and Library Card Use',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberedClause(
                    '3.1',
                    'A LibraGuard account is linked to the User\'s UEP Library Borrower\'s Card and RFID credentials. The User is responsible for safeguarding their login credentials and RFID card, and must not allow unauthorized third parties to use them.',
                  ),
                  _buildNumberedClause(
                    '3.2',
                    'The Borrower\'s Card/RFID credential is non-transferable. Any use of another person\'s credentials may result in confiscation of the card and appropriate disciplinary action by library staff.',
                    isWarning: true,
                  ),
                  _buildNumberedClause(
                    '3.3',
                    'Loss of a Borrower\'s Card or RFID credential must be reported to library staff immediately. Replacement is subject to the corresponding fee set by the UEP Library.',
                  ),
                  _buildNumberedClause(
                    '3.4',
                    'The User agrees that all information provided during registration is true, complete, and accurate, and agrees to keep this information updated.',
                  ),
                ],
              ),
            ),

            // Section 4: Borrowing Policies (NO ICONS)
            _buildSectionCard(
              sectionNumber: '4',
              title: 'Borrowing Policies',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberedClause(
                    '4.1',
                    'Each student may borrow a maximum of three (3) books at a time, provided the titles are not duplicates.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '4.2  Loan periods depend on the type of borrowing:',
                    style: TextStyle(
                      color: isDark ? Colors.white : _textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSubLoanType(
                    title: 'Class Use',
                    desc: 'Returned after the specified class period',
                  ),
                  _buildSubLoanType(
                    title: 'Library Room Use',
                    desc:
                        'Unlimited time unless the material is requested by another user',
                  ),
                  _buildSubLoanType(
                    title: 'Overnight / Weekend Use',
                    desc:
                        'Issued between 3:00 PM – 5:00 PM (Mon–Fri), must be returned by 8:00 AM the following day',
                  ),
                  const SizedBox(height: 8),
                  _buildNumberedClause(
                    '4.3',
                    'Reference materials such as periodicals, encyclopedias, and journals are for in-library use only and may not be borrowed for take-out.',
                  ),
                  _buildNumberedClause(
                    '4.4',
                    'All borrowing and returning transactions must be completed through the LibraGuard system using the User\'s registered RFID credential.',
                  ),
                ],
              ),
            ),

            // Section 5: Fines and Penalties (NO ICONS)
            _buildSectionCard(
              sectionNumber: '5',
              title: 'Fines and Penalties',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberedClause(
                    '5.1',
                    'Overdue books are subject to fines computed by the library staff in accordance with UEP Library policy.',
                  ),
                  _buildNumberedClause(
                    '5.2',
                    'The App may display fine information and borrowing history, but official settlement of fines must be made through the designated payment process (e.g., cashier\'s office).',
                  ),
                  _buildNumberedClause(
                    '5.3',
                    'Users with unsettled fines or penalties may have borrowing privileges suspended until resolved.',
                    isWarning: true,
                  ),
                ],
              ),
            ),

            // Section 6: User Conduct (NO ICONS)
            _buildSectionCard(
              sectionNumber: '6',
              title: 'User Conduct',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The User agrees not to:',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildProhibitedItem(
                    letter: '(a)',
                    text:
                        'Tamper with, damage, or attempt to bypass the RFID scanning system or any related hardware',
                  ),
                  _buildProhibitedItem(
                    letter: '(b)',
                    text:
                        'Provide false information during registration or borrowing transactions',
                  ),
                  _buildProhibitedItem(
                    letter: '(c)',
                    text:
                        'Use another person\'s account or credentials without authorization',
                  ),
                  _buildProhibitedItem(
                    letter: '(d)',
                    text:
                        'Use the App for any unlawful purpose or in a way that disrupts library operations or other users\' access',
                  ),
                ],
              ),
            ),

            // Section 7: Data Privacy (NO ICONS)
            _buildSectionCard(
              sectionNumber: '7',
              title: 'Data Privacy',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberedClause(
                    '7.1',
                    'LibraGuard collects and processes personal information (e.g., name, student number, borrowing history, RFID scan logs) solely for the purpose of managing library transactions and improving library services.',
                  ),
                  _buildNumberedClause(
                    '7.2',
                    'Collected data will be stored securely and will not be shared with third parties except as required by UEP policy or applicable law.',
                  ),
                  _buildNumberedClause(
                    '7.3',
                    'Users have the right to inquire about the personal data collected about them, consistent with the Data Privacy Act of 2012 (RA 10173).',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFD72036).withOpacity(0.12)
                          : const Color(0xFF800000).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _accentColor.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      'Compliant with RA 10173 (Data Privacy Act of 2012)',
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Section 8: Limitation of Liability (NO ICONS)
            _buildSectionCard(
              sectionNumber: '8',
              title: 'Limitation of Liability',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberedClause(
                    '8.1',
                    'LibraGuard is provided on an "as is" basis. The developers do not guarantee uninterrupted or error-free operation of the App or RFID system.',
                  ),
                  _buildNumberedClause(
                    '8.2',
                    'The developers and UEP Library are not liable for any loss or inconvenience resulting from system downtime, RFID malfunction, or delayed notifications, except where caused by gross negligence.',
                  ),
                  _buildNumberedClause(
                    '8.3',
                    'The User remains responsible for the physical condition and timely return of borrowed materials regardless of app-related issues.',
                  ),
                ],
              ),
            ),

            // Section 9: Amendments (NO ICONS)
            _buildSectionCard(
              sectionNumber: '9',
              title: 'Amendments',
              child: Text(
                'LibraGuard\'s developers and the UEP Library reserve the right to modify this Agreement. Users will be notified of significant changes through an in-app notice prior to the changes taking effect.',
                style: _bodyTextStyle,
              ),
            ),

            // Section 10: Governing Policy (NO ICONS)
            _buildSectionCard(
              sectionNumber: '10',
              title: 'Governing Policy',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Agreement operates in conjunction with, and does not replace, the official UEP Library Rules and Regulations as stated in the UEP Student Manual. In case of conflict, the UEP Student Manual and official library policies shall prevail.',
                    style: _bodyTextStyle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  TextStyle get _bodyTextStyle {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? _textColor.withOpacity(0.85) : const Color(0xFF334155),
      fontSize: 13.5,
      height: 1.5,
    );
  }

  Widget _buildSectionCard({
    required String sectionNumber,
    required String title,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  sectionNumber,
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildNumberedClause(
    String number,
    String text, {
    bool isWarning = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor =
        isDark ? const Color(0xFFD72036) : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number  ',
            style: TextStyle(
              color: isWarning ? warningColor : _accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark
                    ? _textColor.withOpacity(0.85)
                    : const Color(0xFF334155),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark
                    ? _textColor.withOpacity(0.85)
                    : const Color(0xFF334155),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubLoanType({
    required String title,
    required String desc,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 84),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : _textColor,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
              color: isDark
                  ? _textColor.withOpacity(0.7)
                  : const Color(0xFF64748B),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProhibitedItem({
    required String letter,
    required String text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFD72036).withOpacity(0.12)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFFD72036).withOpacity(0.3)
              : const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$letter ',
            style: TextStyle(
              color: isDark ? const Color(0xFFD72036) : const Color(0xFFDC2626),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark
                    ? _textColor.withOpacity(0.9)
                    : const Color(0xFF991B1B),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
