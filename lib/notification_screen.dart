import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
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
  List<NotificationItem> _notifications = [];
  List<String> _missingFields = [];

  Color get _primaryColor => const Color(0xFF75111D);
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final enabled = await _authService.is2FAEnabled();
    final list = await NotificationService.instance.getStoredNotifications();
    list.sort((a, b) => b.firedAt.compareTo(a.firedAt));

    // Detect missing profile credentials
    final missing = <String>[];
    final cachedProfile = await _authService.getCachedProfile();
    if (cachedProfile != null) {
      final name = (cachedProfile['name'] ?? cachedProfile['fullName'] ?? '').toString().trim();
      final idNumber = (cachedProfile['idNumber'] ?? '').toString().trim();
      final contact = (cachedProfile['contact'] ?? cachedProfile['phone'] ?? '').toString().trim();
      final age = (cachedProfile['age'] ?? '').toString().trim();
      final dept = (cachedProfile['dept'] ?? cachedProfile['department'] ?? '').toString().trim();
      final year = (cachedProfile['year'] ?? cachedProfile['yearLevel'] ?? '').toString().trim();

      if (name.isEmpty) missing.add('Full Name');
      if (idNumber.isEmpty) missing.add('ID Number');
      if (contact.isEmpty) missing.add('Contact Number');
      if (age.isEmpty || age == '0') missing.add('Age');
      if (dept.isEmpty || dept == 'N/A') missing.add('Department');
      if (year.isEmpty || year == 'N/A') missing.add('Year Level');
    }

    if (mounted) {
      setState(() {
        _is2FAEnabled = enabled;
        _notifications = list;
        _missingFields = missing;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    await NotificationService.instance.clearAllStored();
    setState(() {
      _notifications = [];
    });
  }

  Future<void> _deleteItem(String id) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    await NotificationService.instance.deleteNotification(id);
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    await NotificationService.instance.markAllAsRead();
  }

  String _getSection(DateTime firedAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final itemDate = DateTime(firedAt.year, firedAt.month, firedAt.day);

    if (itemDate == today) {
      return 'New';
    } else if (itemDate == yesterday) {
      return 'Yesterday';
    } else {
      return 'Earlier';
    }
  }

  IconData _iconFor(String type, String title) {
    if (type == 'gate') {
      if (title.toLowerCase().contains('out')) {
        return Icons.logout_outlined;
      }
      return Icons.login_outlined;
    } else if (type == 'status') {
      if (title.toLowerCase().contains('borrow')) {
        return Icons.book_outlined;
      }
      return Icons.computer_outlined;
    } else if (type == 'deadline') {
      return Icons.alarm_outlined;
    }
    return Icons.notifications_none_outlined;
  }

  Color _iconColorFor(String type) {
    if (_isDark) {
      switch (type) {
        case 'deadline':
          return const Color(0xFFFB923C);
        case 'status':
          return const Color(0xFF60A5FA);
        case 'gate':
          return const Color(0xFF34D399);
      }
      return Colors.white70;
    } else {
      switch (type) {
        case 'deadline':
          return const Color(0xFFC2410C);
        case 'status':
          return const Color(0xFF1D4ED8);
        case 'gate':
          return const Color(0xFF047857);
      }
      return Colors.black54;
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
                _clearAll();
              } else if (value == 'read_all') {
                _markAllAsRead();
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
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    final now = _notifications.where((n) => _getSection(n.firedAt) == 'New').toList();
    final yesterday = _notifications.where((n) => _getSection(n.firedAt) == 'Yesterday').toList();
    final earlier = _notifications.where((n) => _getSection(n.firedAt) == 'Earlier').toList();

    final bool hasSecurityAlert = !_is2FAEnabled || _missingFields.isNotEmpty;
    final bool hasAnything = hasSecurityAlert ||
        now.isNotEmpty ||
        yesterday.isNotEmpty ||
        earlier.isNotEmpty;

    if (!hasAnything) return _buildEmptyState();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (!_is2FAEnabled || _missingFields.isNotEmpty) ...[
          _buildSectionHeader('Security Status'),
          if (_missingFields.isNotEmpty) _buildMissingCredentialsCard(),
          if (!_is2FAEnabled) _build2FAAlertCard(),
        ],
        if (now.isNotEmpty) ...[
          _buildSectionHeader('New'),
          ..._buildDismissibleItems(now),
        ],
        if (yesterday.isNotEmpty) ...[
          _buildSectionHeader('Yesterday'),
          ..._buildDismissibleItems(yesterday),
        ],
        if (earlier.isNotEmpty) ...[
          _buildSectionHeader('Earlier'),
          ..._buildDismissibleItems(earlier),
        ],
      ],
    );
  }

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

  List<Widget> _buildDismissibleItems(List<NotificationItem> items) {
    return items.map((n) {
      return Dismissible(
        key: Key(n.id + '_' + n.firedAt.millisecondsSinceEpoch.toString()),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteItem(n.id),
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

  Future<void> _onItemTap(NotificationItem n) async {
    if (!n.isRead) {
      setState(() {
        n.isRead = true;
      });
      await NotificationService.instance.markAsRead(n.id);
    }

    String? route;
    if (n.type == 'gate') {
      route = '/profile/gate';
    } else if (n.type == 'deadline') {
      route = '/profile/borrowing';
    } else if (n.type == 'status') {
      final titleLower = n.title.toLowerCase();
      final subtitleLower = (n.subtitle ?? '').toLowerCase();
      if (titleLower.contains('borrow') || subtitleLower.contains('borrow') || subtitleLower.contains('book')) {
        route = '/profile/borrowing';
      } else if (titleLower.contains('pc') || subtitleLower.contains('pc') || titleLower.contains('computer') || subtitleLower.contains('computer') || subtitleLower.contains('session')) {
        route = '/profile/computer';
      }
    }

    if (route != null && mounted) {
      Navigator.pushNamed(context, route);
    }
  }

  Widget _buildListItem(NotificationItem n) {
    final iconColor = _iconColorFor(n.type);
    final avatarIcon = _iconFor(n.type, n.title);
    final dividerColor = _textColor.withOpacity(0.07);

    final String dateString = _formatDateLabel(n.firedAt);

    return Column(
      children: [
        InkWell(
          onTap: () => _onItemTap(n),
          child: Container(
            color: n.isRead ? Colors.transparent : _primaryColor.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(avatarIcon, color: iconColor, size: 20),
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
                                n.title,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          n.subtitle ?? '',
                          style: TextStyle(
                            color: _textColor.withOpacity(0.7),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateString,
                          style: TextStyle(
                            color: _textColor.withOpacity(0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 0.8, color: dividerColor),
      ],
    );
  }

  String _formatDateLabel(DateTime firedAt) {
    final now = DateTime.now();
    final difference = now.difference(firedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${firedAt.month}/${firedAt.day}/${firedAt.year}';
    }
  }

  /// Card shown when the user has missing profile fields.
  Widget _buildMissingCredentialsCard() {
    final Color accentColor = _isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
    final Color subText = _isDark
        ? Colors.white.withOpacity(0.85)
        : const Color(0xFF7C2D12);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [accentColor.withOpacity(0.30), accentColor.withOpacity(0.12)]
              : [accentColor.withOpacity(0.10), accentColor.withOpacity(0.04)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withOpacity(_isDark ? 0.60 : 0.35),
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
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.manage_accounts_outlined, color: accentColor, size: 20),
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
                          'Incomplete Profile',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_missingFields.length} MISSING',
                          style: TextStyle(
                            color: _isDark ? Colors.white : accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Missing: ${_missingFields.join(', ')}.',
                    style: TextStyle(
                      color: subText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfileScreen()),
                        ).then((_) => _loadData());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 13, color: Colors.white),
                      label: const Text(
                        'Update Account',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
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

  /// Card shown when 2FA is disabled.
  Widget _build2FAAlertCard() {
    final Color alertAccent = _isDark ? Colors.white : _primaryColor;
    final Color alertText = _isDark ? Colors.white : _primaryColor;
    final Color subText = _isDark
        ? Colors.white.withOpacity(0.9)
        : _primaryColor.withOpacity(0.8);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [_primaryColor.withOpacity(0.55), _primaryColor.withOpacity(0.25)]
              : [_primaryColor.withOpacity(0.12), _primaryColor.withOpacity(0.06)],
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
              child: Icon(Icons.security_outlined, color: alertAccent, size: 20),
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
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: alertAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTION NEEDED',
                          style: TextStyle(
                            color: _isDark ? _primaryColor : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
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
                    child: ElevatedButton.icon(
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: _isDark ? _primaryColor : Colors.white,
                      ),
                      label: const Text(
                        'Enable 2FA Now',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
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
