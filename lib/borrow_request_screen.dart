import 'package:flutter/material.dart';
import 'library_rules_screen.dart';
import 'library_service_guide_screen.dart';
import 'services/borrow_service.dart';
import 'services/auth_service.dart';
import 'services/book_service.dart';

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
  Color get _textColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF1D2939));
  }

  Color get _cardColor => Theme.of(context).cardColor;

int _step = 0;

  bool _isSubmitting = false;
  String? _errorMessage;
  BorrowTransaction? _resultTransaction;

  final BorrowService _borrowService = BorrowService();
  final AuthService _authService = AuthService();
  final BookService _bookService = BookService();

String _borrowerName = "";
  String _borrowerRole = "";
  String _borrowerDept = "";
  String _borrowerYear = "";

String _bookGenre = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadBookDetails();
  }

  Future<void> _loadBookDetails() async {

    final cachedBooks = await _bookService.getPersistentCachedBooks();
    final cachedMatch = cachedBooks.where((b) => b.id == widget.bookId);
    if (cachedMatch.isNotEmpty && mounted) {
      setState(() {
        _bookGenre = cachedMatch.first.displayGenre.toUpperCase();
      });
    }

try {
      final books = await _bookService.fetchBooksByIds([widget.bookId]);
      if (books.isNotEmpty && mounted) {
        setState(() {
          _bookGenre = books.first.displayGenre.toUpperCase();
        });
      } else if (mounted && _bookGenre == "Loading...") {
        setState(() {
          _bookGenre = "General Collection";
        });
      }
    } catch (_) {
      if (mounted && _bookGenre == "Loading...") {
        setState(() {
          _bookGenre = "General Collection";
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {

    final cached = await _authService.getCachedProfile();
    if (cached != null && mounted) {
      _applyProfileData(cached);
    }

final result = await _authService.getProfile();
    if (result['success'] == true && result['data'] != null && mounted) {
      _applyProfileData(result['data']);
    }
  }

  void _applyProfileData(Map<String, dynamic> data) {
    setState(() {
      _borrowerName = (data['name'] ?? data['fullName'] ?? '').toString();
      _borrowerRole = (data['role'] ?? 'Student').toString();
      _borrowerDept = (data['dept'] ?? data['department'] ?? '').toString();
      _borrowerYear = (data['year'] ?? data['yearLevel'] ?? '').toString();
    });
  }

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
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
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

Widget _buildAwaitingApprovalContent() {
    final tx = _resultTransaction;
    if (tx == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Borrowing Summary',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 24),

_buildBorrowerDetails(),

              const SizedBox(height: 24),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 24),

_buildBookSummaryCard(),

              const SizedBox(height: 24),

_buildPickupAndReturnDetails(tx),

              const SizedBox(height: 24),

_buildRemindersWithLink(isBorrowing: true),

              const SizedBox(height: 12),

_buildFinalConfirmButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickupAndReturnDetails(BorrowTransaction tx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note, color: _primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Schedule Details',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.access_time_filled, 'Pickup Deadline',
              tx.pickupDeadline, _primaryColor),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.calendar_today_rounded, 'Returning Date',
              tx.dueDate, const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.8)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: _textColor.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersWithLink({bool isBorrowing = false}) {
    final String guideText =
        isBorrowing ? 'Borrowing Process Guide' : 'Returning Process Guide';
    final int targetIndex = isBorrowing ? 1 : 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFF59E0B).withOpacity(0.15)
            : const Color(0xFFF59E0B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFF59E0B).withOpacity(0.3)
                : const Color(0xFFF59E0B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              Text(
                'Reminders',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTermItem('Pick up within 3 working days.'),
          _buildTermItem('Bring your RFID card for pickup.'),
          _buildTermItem('Return the book on or before the due date.'),
          _buildTermItem('Library Hours: 8:00 AM – 5:00 PM (Mon – Sat).'),
          const SizedBox(height: 8),
          const Divider(color: Color(0x11D97706)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LibraryServiceGuideScreen(
                    initialExpandedIndex: targetIndex,
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 14, color: _primaryColor.withOpacity(0.8)),
                const SizedBox(width: 6),
                Text(
                  guideText,
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalConfirmButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _showSuccessDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Confirm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF16A34A),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Request Submitted!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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
              const SizedBox(height: 24),
              Text(
                'Your borrow request has been successfully recorded in our system. Please wait for librarian approval.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textColor.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Back to Home',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: _primaryColor.withOpacity(0.2)),
                      ),
                      child: Text('Borrow More Books',
                          style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              Icon(Icons.checklist_rtl, color: _textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'How to Borrow in App',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRuleItem('01.', 'Select your desired book from the catalog.'),
          const SizedBox(height: 12),
          _buildRuleItem('02.', 'Tap the ',
              bold: 'Borrow Book', text2: ' button to initiate the request.'),
          const SizedBox(height: 12),
          _buildRuleItem(
              '03.', 'Review the book pickup process and reminders.'),
          const SizedBox(height: 12),
          _buildRuleItem('04.', 'Submit your request for librarian approval.'),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(Icons.back_hand_outlined, color: _textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Book Pickup Process',
                style: TextStyle(
                  color: _textColor,
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
              bold: 'official pickup',
              text2: ' after the librarian identifies the book.'),
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Reminder',
                style: TextStyle(
                  color: _textColor,
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
          _buildRuleItem('03.', 'Borrowed books must be picked up within ',
              bold: '3 working days', text2: ' from approval.'),
          const SizedBox(height: 16),
          _buildRuleItem('04.', 'Due Date: ',
              bold: '7 days',
              text2: ' return period for general collection books.'),
          const SizedBox(height: 16),
          _buildRuleItem('05.', 'Library Hours: ',
              bold: '8:00 AM – 5:00 PM', text2: ' (Monday – Saturday).'),
          const SizedBox(height: 16),
          _buildRuleItem('06.', 'Reference books and periodicals are for ',
              bold: 'library use only', text2: ' and cannot be borrowed.'),
          const SizedBox(height: 16),
          _buildRuleItem('07.', 'Books must be returned on or before the ',
              bold: 'due date', text2: ' to avoid fines.'),
          const SizedBox(height: 16),
          _buildRuleItem('08.', 'Visiting researchers must register at the ',
              bold: 'LibraGuard App',
              text2: ' and present a valid institutional ID.'),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LibraryRulesScreen(
                      initialExpandedIndex: 3,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.info_outline, size: 16, color: _accentColor),
              label: Text(
                'Read more about Loaning Policies',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
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

Widget _buildConfirmationContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Borrowing Request Summary',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 24),

_buildBorrowerDetails(),

              const SizedBox(height: 24),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 24),

_buildBookSummaryCard(),

              const SizedBox(height: 24),

_buildTermsAndConditions(),

              const SizedBox(height: 32),

_buildActionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBorrowerDetails() {
    bool isLoading = _borrowerName.isEmpty && _errorMessage == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, color: _accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              "Borrower's Details",
              style: TextStyle(
                color: _textColor.withOpacity(0.4),
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else ...[
          _buildSummaryRow('Name',
              _borrowerName.isNotEmpty ? _borrowerName : 'Not available'),
          _buildSummaryRow(
              'Role', _borrowerRole.isNotEmpty ? _borrowerRole : 'N/A'),
          _buildSummaryRow(
              'Department', _borrowerDept.isNotEmpty ? _borrowerDept : 'N/A'),
          if (_borrowerRole.toLowerCase() == 'student')
            _buildSummaryRow(
                'Year', _borrowerYear.isNotEmpty ? _borrowerYear : 'N/A'),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 84,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: _accentColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _bookGenre,
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.bookTitle,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${widget.author}',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0x11000000)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBookMetaItem(
                  Icons.calendar_month_outlined, 'Return Period', '7 Days'),
              const SizedBox(width: 24),
              _buildBookMetaItem(
                  Icons.location_on_outlined, 'Unit', 'Main Library'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookMetaItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _textColor.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: _textColor.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: _textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFF59E0B).withOpacity(0.15)
            : const Color(0xFFF59E0B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFF59E0B).withOpacity(0.3)
                : const Color(0xFFF59E0B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Reminders',
                style: TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTermItem('Please return the book within 7 days.'),
          _buildTermItem('Pick up your book within 3 working days.'),
          _buildTermItem('Library Hours: 8:00 AM – 5:00 PM (Mon – Sat).'),
          _buildTermItem('Bring your RFID card for book pickup.'),
          _buildTermItem('You can borrow a maximum of 3 books.'),
          const SizedBox(height: 12),
          Divider(color: const Color(0xFFF59E0B).withOpacity(0.1)),
          const SizedBox(height: 12),
          Text(
            'Upon submission, your request will be sent to the library system. The librarian will approve it shortly. Have your RFID card ready for pickup.',
            style: TextStyle(
              color: _textColor.withOpacity(0.8),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.9)
                    : _textColor.withOpacity(0.7),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isSubmitting ? null : () => setState(() => _step = 0),
            style: TextButton.styleFrom(
              foregroundColor: _textColor.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _textColor.withOpacity(0.1)),
              ),
            ),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

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
                if (_step == 1)
                  progress = 0.333;
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
              _buildStepItem(
                  '1. Process', Icons.checklist_rtl, _step >= 0, _step > 0),
              _buildStepItem(
                  '2. Request', Icons.menu_book, _step >= 1, _step > 1),
              _buildStepItem(
                  '3. Approval', Icons.access_time, _step >= 2, _step > 2),
              _buildStepItem(
                  '4. Pick Up', Icons.credit_card, _step >= 3, _step > 3),
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
                  : _textColor.withOpacity(0.1),
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
                : (isActive ? _primaryColor : _textColor.withOpacity(0.2)),
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
