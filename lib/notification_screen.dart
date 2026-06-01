import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'profile_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final AuthService _authService = AuthService();
  bool _is2FAEnabled = true;
  bool _isLoading = true;
  List<NotificationData> _notifications = [];

  Color get _primaryColor => const Color(0xFF75111D); // Dark Maroon
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardColor => Theme.of(context).cardColor;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadData();
    _generateNotifications();
  }

  void _generateNotifications() {
    _notifications = [
      NotificationData(
        id: '1',
        title: 'New book added: "The Art of Flutter" is now available.',
        date: 'June 1, 2026',
        type: NotificationType.info,
        avatarIcon: Icons.library_books_outlined,
      ),
      NotificationData(
        id: '2',
        title: 'Return Reminder: "Data Science 101" is due in 2 days.',
        date: 'June 1, 2026',
        type: NotificationType.reminder,
        avatarIcon: Icons.alarm_outlined,
        hasAction: true,
        actionText: 'Renew',
      ),
      NotificationData(
        id: '3',
        title: 'Gate Entry: Successful entry at Lane 1 recorded.',
        date: 'June 1, 2026',
        type: NotificationType.info,
        avatarIcon: Icons.login_outlined,
        section: 'Earlier today',
      ),
      NotificationData(
        id: '4',
        title: 'System Update: LibraGuard updated to v2.4.0.',
        date: 'June 1, 2026',
        type: NotificationType.info,
        avatarIcon: Icons.system_update_alt_outlined,
        section: 'Earlier today',
      ),
      NotificationData(
        id: '5',
        title: 'Monthly Report: Your October reading session is ready.',
        date: 'May 31, 2026',
        type: NotificationType.reminder,
        avatarIcon: Icons.assessment_outlined,
        hasAction: true,
        actionText: 'View',
        section: 'Yesterday',
      ),
    ];
  }

  Future<void> _loadData() async {
    final enabled = await _authService.is2FAEnabled();
    if (mounted) {
      setState(() {
        _is2FAEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
              color: _textColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _textColor),
            onSelected: (value) {
              if (value == 'clear_all') {
                setState(() => _notifications.clear());
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'read_all', child: Text('Mark All as Read')),
              const PopupMenuItem(value: 'clear_all', child: Text('Clear All')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final now = _notifications.where((n) => n.section == 'New').toList();
    final today =
        _notifications.where((n) => n.section == 'Earlier today').toList();
    final yesterday =
        _notifications.where((n) => n.section == 'Yesterday').toList();

    final bool hasAnything = !_is2FAEnabled ||
        now.isNotEmpty ||
        today.isNotEmpty ||
        yesterday.isNotEmpty;

    if (!hasAnything) return _buildEmptyState();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── NEW ─────────────────────────────────────────────────────────
        _buildSectionHeader('New'),
        if (!_is2FAEnabled) _buildSecurityAlertCard(),
        ..._buildDismissibleItems(now),

        // ── EARLIER TODAY ───────────────────────────────────────────────
        if (today.isNotEmpty) ...[
          _buildSectionHeader('Earlier Today'),
          ..._buildDismissibleItems(today),
        ],

        // ── YESTERDAY ───────────────────────────────────────────────────
        if (yesterday.isNotEmpty) ...[
          _buildSectionHeader('Yesterday'),
          ..._buildDismissibleItems(yesterday),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: _textColor.withOpacity(0.4),
        ),
      ),
    );
  }

  List<Widget> _buildDismissibleItems(List<NotificationData> items) {
    return items.map((n) {
      return Dismissible(
        key: Key(n.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) =>
            setState(() => _notifications.removeWhere((i) => i.id == n.id)),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete_outline,
              color: Color(0xFFF43F5E), size: 22),
        ),
        child: _buildListItem(n),
      );
    }).toList();
  }

  Color _iconColorFor(NotificationType type) {
    if (_isDark) {
      switch (type) {
        case NotificationType.security:
          return const Color(0xFFF87171); // Light Red
        case NotificationType.reminder:
          return const Color(0xFFFB923C); // Light Orange
        case NotificationType.info:
          return const Color(0xFF60A5FA); // Light Blue
      }
    } else {
      switch (type) {
        case NotificationType.security:
          return const Color(0xFFB21A2D); // Deep Red/Maroon
        case NotificationType.reminder:
          return const Color(0xFFC2410C); // Dark Orange
        case NotificationType.info:
          return const Color(0xFF1D4ED8); // Dark Blue
      }
    }
  }

  /// Flat list item — matches img2 layout
  Widget _buildListItem(NotificationData n) {
    final iconColor = _iconColorFor(n.type);
    final dividerColor = _textColor.withOpacity(0.07);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(n.avatarIcon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.date,
                      style: TextStyle(
                        color: _textColor.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Optional action button (pill/outlined)
              if (n.hasAction) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: iconColor.withOpacity(0.5),
                    ),
                    foregroundColor: iconColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    n.actionText ?? 'Action',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.8, color: dividerColor),
      ],
    );
  }

  // ── Security Alert Card ──────────────────────────────────────────────────

  Widget _buildSecurityAlertCard() {
    final Color alertAccent = _isDark ? Colors.white : _primaryColor;
    final Color alertText = _isDark ? Colors.white : _primaryColor;
    final Color subText = _isDark
        ? Colors.white.withOpacity(0.9)
        : _primaryColor.withOpacity(0.8);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [
                  _primaryColor.withOpacity(0.55),
                  _primaryColor.withOpacity(0.25),
                ]
              : [
                  _primaryColor.withOpacity(0.12),
                  _primaryColor.withOpacity(0.06),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isDark
              ? Colors.redAccent.withOpacity(0.7)
              : _primaryColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alertAccent.withOpacity(_isDark ? 0.15 : 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.security_outlined, color: alertAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Security Alert',
                          style: TextStyle(
                            color: alertText,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: alertAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTION NEEDED',
                          style: TextStyle(
                            color: alertText,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your account has low security. Enable Two-Factor Authentication to protect your resources and data.',
                    style: TextStyle(
                      color: subText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfileScreen()),
                        ).then((_) => _loadData());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDark ? Colors.white : _primaryColor,
                        foregroundColor: _isDark ? _primaryColor : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Enable 2FA Now',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 72, color: _textColor.withOpacity(0.15)),
          const SizedBox(height: 20),
          Text(
            'No Notifications',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(color: _textColor.withOpacity(0.45), fontSize: 14),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _primaryColor),
              foregroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

enum NotificationType { security, reminder, info }

class NotificationData {
  final String id;
  final String title;
  final String date;
  final String section;
  final NotificationType type;
  final IconData avatarIcon;
  final bool hasAction;
  final String? actionText;

  NotificationData({
    required this.id,
    required this.title,
    required this.date,
    this.section = 'New',
    required this.type,
    required this.avatarIcon,
    this.hasAction = false,
    this.actionText,
  });
}
