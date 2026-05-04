import 'package:flutter/material.dart';
import 'services/borrow_service.dart';

class BorrowRequestScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final String author;

  const BorrowRequestScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.author,
  });

  @override
  State<BorrowRequestScreen> createState() => _BorrowRequestScreenState();
}

class _BorrowRequestScreenState extends State<BorrowRequestScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _accentColor => Theme.of(context).colorScheme.secondary;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor => Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;

  // 0 = rules, 1 = confirm, 2 = submitted/approval
  int _step = 0;

  bool _isSubmitting = false;
  String? _errorMessage;
  BorrowTransaction? _resultTransaction;

  final BorrowService _borrowService = BorrowService();

  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final res = await _borrowService.submitBorrowRequest(
      bookId: widget.bookId,
      dueDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _isSubmitting = false;
        _step = 2;
        _resultTransaction = res['transaction'];
      });
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = res['message'] ?? 'Something went wrong.';
      });
    }
  }

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _step == 2 ? 'Request Status' : 'Borrow Request',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_step != 2)
                Text(
                  'Follow the steps to borrow your book.',
                  style: TextStyle(
                    color: _textColor.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              _buildStepper(),
              const SizedBox(height: 32),
              if (_step == 2)
                _buildAwaitingApprovalContent()
              else if (_step == 0)
                _buildRulesContent()
              else
                _buildConfirmationContent(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF800000).withOpacity(0.05)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF800000).withOpacity(0.2)
                          : Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF800000)
                              : Colors.red.shade700,
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF800000)
                                  : Colors.red.shade700,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Awaiting Approval ─────────────────────────────────────────────────────

  Widget _buildAwaitingApprovalContent() {
    final tx = _resultTransaction;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF16A34A),
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Request Submitted!',
            style: TextStyle(
              color: Color(0xFF1D2939),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Status: Pending Approval',
            style: TextStyle(
              color: _accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (tx != null) ...[
            _buildInfoRow(Icons.menu_book_outlined, 'Book', tx.bookTitle),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_outlined, 'Due Date', tx.dueDate),
            if (tx.pickupDeadline.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                  Icons.access_time, 'Pickup Deadline', tx.pickupDeadline),
            ],
          ] else ...[
            Text(
              'Your request is now in the library system. The librarian will approve it shortly. Have your RFID card ready for pickup.',
              style: TextStyle(
                color: _textColor.withOpacity(0.7),
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.black.withOpacity(0.1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Back to Home',
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _accentColor.withOpacity(0.7)),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
                color: _textColor.withOpacity(0.55),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                color: _textColor, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Library Rules ─────────────────────────────────────────────────────────

  Widget _buildRulesContent() {
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule, color: _accentColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Library Rules',
                style: TextStyle(
                  color: Color(0xFF1D2939),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRuleItem('01.',
              'Present your valid RFID Card at the circulation desk. Card is ',
              bold: 'non-transferable',
              text2: ' and must be used only by the registered owner.'),
          const SizedBox(height: 16),
          _buildRuleItem('02.',
              'Proceed to the circulation desk and inform the librarian of the ',
              bold: 'book title', text2: ' you wish to borrow.'),
          const SizedBox(height: 16),
          _buildRuleItem('03.', 'Tap your RFID card at the reader for ',
              bold: 'official checkout',
              text2: ' after the librarian identifies the book.'),
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.info_outline, color: _accentColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Notes',
                style: TextStyle(
                  color: Color(0xFF1D2939),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRuleItem('01.', 'Borrowers are allowed to borrow up to ',
              bold: '3 books', text2: ' at a time.'),
          const SizedBox(height: 16),
          _buildRuleItem('02.', 'Ensure the book is ',
              bold: 'undamaged',
              text2:
                  ' before borrowing. Report any damage to the librarian immediately.'),
          const SizedBox(height: 16),
          _buildRuleItem('03.', 'Reference books and periodicals are for ',
              bold: 'library use only', text2: ' and cannot be borrowed.'),
          const SizedBox(height: 16),
          _buildRuleItem('04.', 'Books must be returned on or before the ',
              bold: 'due date', text2: ' to avoid fines.'),
          const SizedBox(height: 16),
          _buildRuleItem('05.', 'Visiting researchers must register at the ',
              bold: 'LibraGuard App',
              text2: ' and present a valid institutional ID.'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _step = 1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('I Understand, Proceed',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirmation ──────────────────────────────────────────────────────────

  Widget _buildConfirmationContent() {
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Confirm Request',
            style: TextStyle(
              color: Color(0xFF1D2939),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.book, color: _accentColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bookTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Author: ${widget.author}',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Due date info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accentColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: _accentColor, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Return due in 7 days from approval.',
                    style: TextStyle(
                        color: _textColor.withOpacity(0.75), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Upon submission your request will be sent to the library system. The librarian will approve it shortly. Have your RFID card ready for pickup.',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _step = 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Request',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stepper ───────────────────────────────────────────────────────────────

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 24,
            right: 24,
            child: Container(
              height: 3,
              color: Colors.black.withOpacity(0.05),
            ),
          ),
          Positioned(
            top: 20,
            left: 24,
            right: 24,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double progress = 0.0;
                if (_step == 1) progress = 0.333;
                else if (_step == 2) progress = 0.666;

                return Container(
                  height: 3,
                  width: constraints.maxWidth * progress,
                  color: _accentColor,
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepItem('1. Process', Icons.checklist_rtl,
                  _step >= 0, _step > 0),
              _buildStepItem('2. Request', Icons.menu_book,
                  _step >= 1, _step > 1),
              _buildStepItem('3. Approval', Icons.access_time,
                  _step >= 2, _step > 2),
              _buildStepItem('4. Pick Up', Icons.credit_card,
                  _step >= 3, _step > 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
      String label, IconData icon, bool isActive, bool isFinished) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isFinished ? _primaryColor : _cardColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: (isFinished || isActive)
                  ? _primaryColor
                  : Colors.black.withOpacity(0.1),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isFinished
                ? Colors.white
                : (isActive ? _primaryColor : Colors.black.withOpacity(0.2)),
            size: 20,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: isActive || isFinished
                ? _textColor
                : _textColor.withOpacity(0.4),
            fontSize: 11,
            fontWeight:
                isActive || isFinished ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ── Rule Item ─────────────────────────────────────────────────────────────

  Widget _buildRuleItem(String number, String text1,
      {String? bold, String? text2}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
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
                TextSpan(text: text1),
                if (bold != null)
                  TextSpan(
                    text: bold,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                if (text2 != null) TextSpan(text: text2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
