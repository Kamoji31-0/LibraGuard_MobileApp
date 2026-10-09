import 'package:flutter/material.dart';
import 'library_rules_screen.dart';
import 'library_service_guide_screen.dart';
import 'services/borrow_service.dart';
import 'services/auth_service.dart';
import 'services/book_service.dart';
import 'services/notification_cache_service.dart';
import 'profile_screen.dart';

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
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

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

  String? _selectedUseType = 'Library Room Use';
  TimeOfDay? _classStartTime;
  TimeOfDay? _classEndTime;

  static const List<Map<String, dynamic>> _useTypeOptions = [
    {
      'id': 'Library Room Use',
      'label': 'Library Room Use',
      'desc': 'Use books inside the library only.',
      'returnInfo': 'Return by 4:00 PM today.',
      'pickupInfo': 'Pickup: Immediately after approval.',
      'fineInfo':
          '₱5/hour after 4:00 PM. Exceeding 5:00 PM will have penalty fees.',
      'icon': Icons.meeting_room_outlined,
    },
    {
      'id': 'Class Use',
      'label': 'Class Use',
      'desc': 'Bring the book to your class.',
      'returnInfo': 'Return after your class ends.',
      'pickupInfo': 'Pickup: Immediately after approval.',
      'fineInfo':
          '₱5/hour if overdue. Exceeding 5:00 PM (or grace period) will have penalty fees.',
      'icon': Icons.school_outlined,
    },
    {
      'id': 'Overnight',
      'label': 'Overnight Use',
      'desc': 'Take the book home, return next morning.',
      'returnInfo': 'Return next day by 8:00 AM.',
      'pickupInfo': 'Pickup: From 3:00 PM today.',
      'fineInfo':
          '₱5/hour if overdue. Exceeding scheduled deadline will have penalty fees.',
      'icon': Icons.nightlight_round,
    },
    {
      'id': 'Weekend',
      'label': 'Weekend Use',
      'desc': 'Borrow over the weekend.',
      'returnInfo': 'Return Monday by 8:00 AM.',
      'pickupInfo': 'Pickup: Friday from 3:00 PM only.',
      'fineInfo':
          '₱5/hour if overdue. Exceeding scheduled deadline will have penalty fees.',
      'icon': Icons.calendar_month_outlined,
    },
  ];

  Map<String, dynamic>? _getOption(String? id) {
    if (id == null) return null;
    try {
      return _useTypeOptions.firstWhere((opt) => opt['id'] == id);
    } catch (_) {
      return null;
    }
  }

  String _getOptionLabel(String? id) {
    if (id == null) return 'None';
    final opt = _getOption(id);
    return opt?['label'] ?? id;
  }

  String? _getRestrictionReason(String type) {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday; // 1 = Mon, 5 = Fri, 6 = Sat, 7 = Sun

    if (type == 'Library Room Use' && hour >= 16) {
      return 'Library Room Use requests cannot be submitted after 4:00 PM. The book must be returnable within library hours today.';
    }
    if (type == 'Overnight' && hour < 15) {
      return 'Overnight Use pickup is only available from 3:00 PM onwards. Please come back after 3:00 PM to submit this request.';
    }
    if (type == 'Weekend' && weekday != DateTime.friday) {
      return 'Weekend Use is only available on Fridays. Please come back on Friday to submit this request.';
    }
    if (type == 'Weekend' && hour < 15) {
      return 'Weekend Use pickup starts at 3:00 PM on Fridays. Please come back after 3:00 PM.';
    }
    return null;
  }

  DateTime? _calculateDueDateTime() {
    if (_selectedUseType == null) return null;
    final now = DateTime.now();

    switch (_selectedUseType) {
      case 'Library Room Use':
        return DateTime(now.year, now.month, now.day, 16, 0);

      case 'Class Use':
        if (_classEndTime != null) {
          final end = DateTime(
            now.year,
            now.month,
            now.day,
            _classEndTime!.hour,
            _classEndTime!.minute,
          );
          final fivePm = DateTime(now.year, now.month, now.day, 17, 0);
          if (end.isAfter(fivePm)) {
            return DateTime(now.year, now.month, now.day, 17, 30);
          }
          return end;
        }
        return null;

      case 'Overnight':
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);

      case 'Weekend':
        int daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
        if (daysUntilMonday == 0) daysUntilMonday = 7;
        final nextMonday = now.add(Duration(days: daysUntilMonday));
        return DateTime(
            nextMonday.year, nextMonday.month, nextMonday.day, 8, 0);

      case 'Instructor':
        return now.add(const Duration(days: 30));

      default:
        return now.add(const Duration(days: 7));
    }
  }

  String _formatSummaryDeadline(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final monthStr = months[dt.month - 1];
    final dayStr = dt.day.toString();
    final int hour12 =
        dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final hourStr = hour12.toString().padLeft(2, '0');
    return '$monthStr $dayStr, $hourStr:$minuteStr $amPm';
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final int hour12 =
        tod.hour == 0 ? 12 : (tod.hour > 12 ? tod.hour - 12 : tod.hour);
    final minuteStr = tod.minute.toString().padLeft(2, '0');
    final amPm = tod.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minuteStr $amPm';
  }

  bool _canContinueFromTypeStep() {
    if (_selectedUseType == null) return false;
    if (_getRestrictionReason(_selectedUseType!) != null) return false;
    if (_selectedUseType == 'Class Use') {
      return _classStartTime != null && _classEndTime != null;
    }
    return true;
  }

  String _getReturnPeriodDisplay() {
    final type = _resultTransaction?.borrowType ?? _selectedUseType;
    switch (type) {
      case 'Library Room Use':
        return 'Today (4:00 PM)';
      case 'Class Use':
        return 'After Class';
      case 'Overnight':
        return 'Next Day (8 AM)';
      case 'Weekend':
        return 'Monday (8 AM)';
      case 'Instructor':
        return '30 Days';
      default:
        return '7 Days';
    }
  }

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

    final calculatedDue = _calculateDueDateTime();

    String? classStartIso;
    String? classEndIso;
    final now = DateTime.now();
    if (_selectedUseType == 'Class Use') {
      if (_classStartTime != null) {
        classStartIso = DateTime(
          now.year,
          now.month,
          now.day,
          _classStartTime!.hour,
          _classStartTime!.minute,
        ).toUtc().toIso8601String();
      }
      if (_classEndTime != null) {
        classEndIso = DateTime(
          now.year,
          now.month,
          now.day,
          _classEndTime!.hour,
          _classEndTime!.minute,
        ).toUtc().toIso8601String();
      }
    }

    final bool isFacultyOrInstructor =
        _borrowerRole.toLowerCase().contains('faculty') ||
            _borrowerRole.toLowerCase().contains('instructor');

    final String finalBorrowType = isFacultyOrInstructor
        ? 'Instructor'
        : (_selectedUseType ?? 'Library Room Use');

    final res = await _borrowService.submitBorrowRequest(
      bookId: widget.bookId,
      dueDate: calculatedDue ?? DateTime.now().add(const Duration(days: 7)),
      borrowType: finalBorrowType,
      classStart: classStartIso,
      classEnd: classEndIso,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final BorrowTransaction? tx = res['transaction'];
      if (tx != null) {
        await NotificationCacheService().seedBorrowStatus(tx.id, tx.status);
      }
      setState(() {
        _isSubmitting = false;
        _step = 3;
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
          onPressed: () {
            if (_step > 0 && _step < 3) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _step == 3 ? 'Request Status' : 'Borrow Request',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_step != 3)
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
              if (_step == 3)
                _buildAwaitingApprovalContent()
              else if (_step == 0)
                _buildRulesContent()
              else if (_step == 1)
                _buildSelectTypeOfUseContent()
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
    final type = tx.borrowType ?? _selectedUseType;
    final isClassUse = type == 'Class Use';
    final hasClassSchedule =
        (_classStartTime != null && _classEndTime != null) ||
            (tx.classStart != null && tx.classEnd != null);

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
          Text(
            'Schedule Details',
            style: TextStyle(
              color: _textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _buildPlainDetailRow(
            'Pickup',
            _getPickupScheduleDisplay(tx),
            _primaryColor,
          ),
          const SizedBox(height: 10),
          _buildPlainDetailRow(
            'Return By',
            _getReturnScheduleDisplay(tx),
            const Color(0xFF16A34A),
          ),
          if (type != null) ...[
            const SizedBox(height: 10),
            _buildPlainDetailRow(
              'Type of Use',
              _getOptionLabel(type),
              _accentColor,
            ),
          ],
          if (isClassUse && hasClassSchedule) ...[
            const SizedBox(height: 10),
            _buildPlainDetailRow(
              'Class Schedule',
              _getClassScheduleDisplay(tx),
              const Color(0xFF10B981),
            ),
          ],
        ],
      ),
    );
  }

  String _getPickupScheduleDisplay(BorrowTransaction tx) {
    final type = tx.borrowType ?? _selectedUseType;
    if (type == 'Library Room Use' || type == 'Class Use') {
      return 'Immediately after approval';
    } else if (type == 'Overnight') {
      return 'From 3:00 PM today';
    } else if (type == 'Weekend') {
      return 'Friday from 3:00 PM only';
    } else if (type == 'Instructor') {
      return 'Immediately after approval';
    }

    if (tx.pickupDeadline.isNotEmpty) {
      return _formatDisplayDateTime(tx.pickupDeadline,
          fallback: tx.pickupDeadline);
    }
    return 'Within 3 working days';
  }

  String _getReturnScheduleDisplay(BorrowTransaction tx) {
    final type = tx.borrowType ?? _selectedUseType;
    final dueDt = _calculateDueDateTime();

    if (dueDt != null && (_selectedUseType == type || type == null)) {
      return _formatSummaryDeadline(dueDt);
    }

    if (tx.dueDateISO != null && tx.dueDateISO!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(tx.dueDateISO!).toLocal();
        return _formatSummaryDeadline(parsed);
      } catch (_) {}
    }

    if (tx.dueDate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(tx.dueDate).toLocal();
        return _formatSummaryDeadline(parsed);
      } catch (_) {
        final formattedDate = _formatDateOnly(tx.dueDate);
        if (type == 'Library Room Use') {
          return '$formattedDate (4:00 PM)';
        } else if (type == 'Overnight' || type == 'Weekend') {
          return '$formattedDate (8:00 AM)';
        }
        return formattedDate.isNotEmpty ? formattedDate : tx.dueDate;
      }
    }

    return '—';
  }

  String _getClassScheduleDisplay(BorrowTransaction tx) {
    if (_classStartTime != null && _classEndTime != null) {
      return '${_formatTimeOfDay(_classStartTime!)} – ${_formatTimeOfDay(_classEndTime!)}';
    }
    if (tx.classStart != null && tx.classEnd != null) {
      return '${_formatTimeOrIso(tx.classStart!)} – ${_formatTimeOrIso(tx.classEnd!)}';
    }
    return 'As scheduled';
  }

  String _formatTimeOrIso(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return _formatTimeOfDay(TimeOfDay.fromDateTime(dt));
    } catch (_) {
      return raw;
    }
  }

  String _formatDateOnly(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      final parts = raw.split(',');
      final datePart = parts[0].trim();
      final tokens = datePart.split('/');
      if (tokens.length == 3) {
        final m = int.tryParse(tokens[0]);
        final d = int.tryParse(tokens[1]);
        final y = int.tryParse(tokens[2]);
        if (m != null && d != null && y != null && m >= 1 && m <= 12) {
          const months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];
          return '${months[m - 1]} $d, $y';
        }
      }
      return raw;
    }
  }

  String _formatDisplayDateTime(String raw, {required String fallback}) {
    if (raw.isEmpty) return fallback;
    try {
      final dt = DateTime.parse(raw).toLocal();
      return _formatSummaryDeadline(dt);
    } catch (_) {
      final parts = raw.split(',');
      if (parts.length > 1) {
        final formattedDate = _formatDateOnly(parts[0].trim());
        final timePart = parts[1].trim();
        return '$formattedDate · $timePart';
      }
      final dateOnly = _formatDateOnly(raw);
      return dateOnly.isNotEmpty ? dateOnly : fallback;
    }
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

  // No-icon variant used in Schedule Details cards
  Widget _buildPlainDetailRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: TextStyle(
              color: _textColor.withOpacity(0.55),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
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
          const SizedBox(height: 10),
          _buildTermItem('Your request is now awaiting librarian approval.'),
          _buildTermItem(
              'Pick up your book within 3 working days after approval.'),
          _buildTermItem(
              'Present your RFID Borrower\'s Card upon claiming the book.'),
          _buildTermItem('Return on or before the due date to avoid fines.'),
          _buildTermItem(
              'Late returns incur ₱5/hour. Exceeding 5:00 PM has penalty fees.'),
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
                        Navigator.popUntil(context, (route) => route.isFirst);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(
                              showBorrowingRecordsOnInit: true,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: _primaryColor, width: 1.5),
                      ),
                      child: Text('Check Borrowing Records',
                          style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold)),
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
          _buildRuleItem('01.', 'Review borrowing guidelines and reminders.'),
          const SizedBox(height: 12),
          _buildRuleItem(
              '02.', 'Select your desired Type of Use and schedule.'),
          const SizedBox(height: 12),
          _buildRuleItem('03.', 'Review borrowing request summary and terms.'),
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
              Icon(Icons.warning_amber_rounded,
                  color: _isDark ? Colors.white : _textColor, size: 24),
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
              bold: 'due date',
              text2:
                  ' to avoid fines. Exceeding 5:00 PM will have penalty fees.'),
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
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: _textColor.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _textColor.withOpacity(0.12)),
                    ),
                  ),
                  child: const Text('Back',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
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
        ],
      ),
    );
  }

  Widget _buildSelectTypeOfUseContent() {
    final selectedOption = _getOption(_selectedUseType);
    final restriction = _selectedUseType != null
        ? _getRestrictionReason(_selectedUseType!)
        : null;
    final dueDateTime = _calculateDueDateTime();

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
          Text(
            'Select Type of Use',
            style: TextStyle(
              color: _textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How will you be using this book? Choose the option that best fits your need.',
            style: TextStyle(
              color: _textColor.withOpacity(0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          _buildDropdownSelector(),
          const SizedBox(height: 18),
          if (selectedOption != null) ...[
            _buildOptionDetailCard(selectedOption, restriction),
            const SizedBox(height: 16),
          ],
          if (_selectedUseType == 'Class Use') ...[
            _buildClassScheduleCard(),
            const SizedBox(height: 16),
          ],
          if (_selectedUseType != null && restriction == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor.withOpacity(0.25)),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: 'Summary: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                    const TextSpan(text: 'You selected '),
                    TextSpan(
                      text: '${selectedOption?['label'] ?? _selectedUseType}. ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (dueDateTime != null) ...[
                      const TextSpan(text: 'Must return by '),
                      TextSpan(
                        text: '${_formatSummaryDeadline(dueDateTime)}.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _step = 0),
                  style: TextButton.styleFrom(
                    foregroundColor: _textColor.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _textColor.withOpacity(0.12)),
                    ),
                  ),
                  child: const Text('Back',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _canContinueFromTypeStep()
                        ? [
                            BoxShadow(
                              color: _accentColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _canContinueFromTypeStep()
                        ? () => setState(() => _step = 2)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      disabledBackgroundColor: _isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: _isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Continue',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            )),
                        SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector() {
    return Container(
      decoration: BoxDecoration(
        color: _isDark ? _backgroundColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accentColor.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUseType,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: _accentColor, size: 24),
          dropdownColor: _cardColor,
          borderRadius: BorderRadius.circular(16),
          hint: Text(
            'Select Type of Use...',
            style: TextStyle(color: _textColor.withOpacity(0.4), fontSize: 14),
          ),
          onChanged: (String? newVal) {
            if (newVal != null) {
              setState(() {
                _selectedUseType = newVal;
              });
            }
          },
          items: _useTypeOptions.map((opt) {
            final String id = opt['id'];
            final String label = opt['label'];
            final IconData icon = opt['icon'];
            final isSelected = _selectedUseType == id;

            return DropdownMenuItem<String>(
              value: id,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _accentColor.withOpacity(0.15)
                          : _accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: _accentColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOptionDetailCard(Map<String, dynamic> opt, String? restriction) {
    final IconData icon = opt['icon'];
    final String label = opt['label'];
    final String desc = opt['desc'];
    final String returnInfo = opt['returnInfo'];
    final String pickupInfo = opt['pickupInfo'];
    final String fineInfo = opt['fineInfo'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: restriction != null
              ? Colors.red.withOpacity(0.3)
              : _accentColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.check_circle_rounded, color: _accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: TextStyle(
              color: _textColor.withOpacity(0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.event_available_outlined,
            returnInfo,
            isBold: true,
            iconColor: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            Icons.schedule_outlined,
            pickupInfo,
            iconColor: _accentColor,
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            Icons.payments_outlined,
            fineInfo,
            label: 'Fine:',
            iconColor: _isDark ? Colors.white70 : Colors.black87,
            textColor: _isDark ? Colors.white : Colors.black,
          ),
          if (restriction != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDark
                    ? const Color(0xFF800000).withOpacity(0.15)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isDark
                      ? const Color(0xFF800000).withOpacity(0.4)
                      : const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.block_rounded,
                    size: 16,
                    color:
                        _isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      restriction,
                      style: TextStyle(
                        color: _isDark
                            ? const Color(0xFFFCA5A5)
                            : Colors.red.shade700,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassScheduleCard() {
    String? deadlineNotice;
    if (_classEndTime != null) {
      if (_classEndTime!.hour > 17 ||
          (_classEndTime!.hour == 17 && _classEndTime!.minute > 0)) {
        deadlineNotice = '5:30 PM (grace applied)';
      } else {
        deadlineNotice = _formatTimeOfDay(_classEndTime!);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Class Schedule',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTimePickerInput(
                  label: 'CLASS START TIME',
                  time: _classStartTime,
                  onPick: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _classStartTime ??
                          const TimeOfDay(hour: 8, minute: 0),
                      builder: (context, child) =>
                          _applyMaroonTimePickerTheme(child),
                    );
                    if (picked != null) {
                      setState(() => _classStartTime = picked);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePickerInput(
                  label: 'CLASS END TIME',
                  time: _classEndTime,
                  onPick: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime:
                          _classEndTime ?? const TimeOfDay(hour: 10, minute: 0),
                      builder: (context, child) =>
                          _applyMaroonTimePickerTheme(child),
                    );
                    if (picked != null) {
                      setState(() => _classEndTime = picked);
                    }
                  },
                ),
              ),
            ],
          ),
          if (deadlineNotice != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 4),
                Text(
                  'Return deadline: ',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  deadlineNotice,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _applyMaroonTimePickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _accentColor,
              onPrimary: Colors.white,
              surface: _cardColor,
              onSurface: _textColor,
            ),
      ),
      child: child ?? const SizedBox(),
    );
  }

  Widget _buildTimePickerInput({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textColor.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _isDark ? _backgroundColor : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _textColor.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time != null ? _formatTimeOfDay(time) : '--:-- --',
                  style: TextStyle(
                    color:
                        time != null ? _textColor : _textColor.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight:
                        time != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Icon(
                  Icons.access_time,
                  color: _textColor.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text, {
    String? label,
    bool isBold = false,
    Color? textColor,
    Color? iconColor,
  }) {
    final defaultColor = _isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5, right: 8.0),
            child: Icon(
              icon,
              size: 15,
              color: iconColor ?? defaultColor.withOpacity(0.7),
            ),
          ),
          if (label != null) ...[
            Text(
              '$label ',
              style: TextStyle(
                color: defaultColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor ?? defaultColor,
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBorrowTypeCard() {
    final opt = _getOption(_selectedUseType);
    final dueDateTime = _calculateDueDateTime();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Borrow Type Selected',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: _textColor,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: opt?['label'] ?? _selectedUseType ?? 'Not specified',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_selectedUseType == 'Class Use' &&
                    _classStartTime != null &&
                    _classEndTime != null) ...[
                  TextSpan(
                    text:
                        ' — Class: ${_formatTimeOfDay(_classStartTime!)} to ${_formatTimeOfDay(_classEndTime!)}',
                    style: TextStyle(color: _textColor.withOpacity(0.8)),
                  ),
                ],
                if (dueDateTime != null) ...[
                  TextSpan(
                    text: ' · Return by: ',
                    style: TextStyle(color: _textColor.withOpacity(0.7)),
                  ),
                  TextSpan(
                    text: _formatSummaryDeadline(dueDateTime),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetailsCard() {
    final dueDateTime = _calculateDueDateTime();
    final String pickup = _selectedUseType == 'Overnight'
        ? 'From 3:00 PM today'
        : _selectedUseType == 'Weekend'
            ? 'Friday from 3:00 PM only'
            : 'Immediately after approval';

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
          Text(
            'Schedule Details',
            style: TextStyle(
              color: _textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _buildPlainDetailRow(
            'Pickup',
            pickup,
            _primaryColor,
          ),
          const SizedBox(height: 10),
          _buildPlainDetailRow(
            'Return By',
            dueDateTime != null ? _formatSummaryDeadline(dueDateTime) : '—',
            const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          _buildPlainDetailRow(
            'Type',
            _getOptionLabel(_selectedUseType),
            _accentColor,
          ),
          if (_selectedUseType == 'Class Use' &&
              _classStartTime != null &&
              _classEndTime != null) ...[
            const SizedBox(height: 10),
            _buildPlainDetailRow(
              'Class Schedule',
              '${_formatTimeOfDay(_classStartTime!)} – ${_formatTimeOfDay(_classEndTime!)}',
              const Color(0xFF10B981),
            ),
          ],
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
              const SizedBox(height: 20),
              _buildSelectedBorrowTypeCard(),
              const SizedBox(height: 16),
              _buildScheduleDetailsCard(),
              const SizedBox(height: 20),
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
              _buildBookMetaItem(Icons.calendar_month_outlined, 'Return Period',
                  _getReturnPeriodDisplay()),
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
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(_isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No Extensions Allowed',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Loan extensions are not permitted. If you need to continue using the book, you must return it first and submit a new borrow request.',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.8),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isDark
                ? const Color(0xFF800000).withOpacity(0.12)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isDark
                  ? const Color(0xFF800000).withOpacity(0.3)
                  : const Color(0xFFFCA5A5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color:
                        _isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fine Policy',
                    style: TextStyle(
                      color: _isDark
                          ? const Color(0xFFFCA5A5)
                          : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Returning late incurs a ₱5/hour fine. Exceeding 5:00 PM library closing will incur penalty fees. Ticket is automatically voided if not picked up within the allowed window.',
                style: TextStyle(
                  color: _textColor.withOpacity(0.8),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                _isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _textColor.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: _accentColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Reminders',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildTermItem(
                  'Pick up your book/s after the approval of your request.'),
              _buildTermItem(
                  'Please return the book on or before the due date.'),
              _buildTermItem(
                  'Present your RFID Borrower\'s Card upon claiming the book.'),
              _buildTermItem(
                  'Late returns incur ₱5/hour. Exceeding 5:00 PM will have penalty fees.'),
              _buildTermItem('Library Hours: 8:00 AM – 5:00 PM (Mon – Sat).'),
              _buildTermItem('You can borrow a maximum of 3 books at a time.'),
            ],
          ),
        ),
      ],
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
            decoration: BoxDecoration(
              color: _accentColor,
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
            onPressed: _isSubmitting ? null : () => setState(() => _step = 1),
            style: TextButton.styleFrom(
              foregroundColor: _textColor.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _textColor.withOpacity(0.1)),
              ),
            ),
            child: const Text('Back',
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
            top: 18,
            left: 20,
            right: 20,
            child: Container(
              height: 3,
              color: Colors.black.withOpacity(0.05),
            ),
          ),
          Positioned(
            top: 18,
            left: 20,
            right: 20,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double progress = 0.0;
                if (_step == 1) {
                  progress = 0.25;
                } else if (_step == 2) {
                  progress = 0.50;
                } else if (_step == 3) {
                  progress = 0.75;
                } else if (_step >= 4) {
                  progress = 1.0;
                }

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
                  '2. Type', Icons.category_outlined, _step >= 1, _step > 1),
              _buildStepItem(
                  '3. Request', Icons.menu_book, _step >= 2, _step > 2),
              _buildStepItem(
                  '4. Approval', Icons.access_time, _step >= 3, _step > 3),
              _buildStepItem(
                  '5. Pick Up', Icons.credit_card, _step >= 4, _step > 4),
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
          width: 38,
          height: 38,
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
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive || isFinished
                ? _textColor
                : _textColor.withOpacity(0.4),
            fontSize: 10,
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
