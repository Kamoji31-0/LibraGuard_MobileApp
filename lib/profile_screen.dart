import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/borrow_service.dart';
import 'services/pc_service.dart';
import 'login_screen.dart';
import 'book_list_screen.dart';
import 'pc_reservation_rules_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'main.dart' show themeNotifier;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;

  Map<String, dynamic>? _userProfile;
  List<dynamic> _gateLogs = []; // Added missing variable
  bool _isLoading = true;
  String? _profileImageUrl;
  String? _base64Image;
  int _selectedIndex = 3;
  int _occupancyCount = 0;
  int _maxCapacity = 100;
  Timer? _occupancyTimer;

  int _activeUtilityIndex = -1;
  bool _obscurePassword = true;

  String _selectedGender = 'Unspecified';
  final List<String> _genderOptions = [
    'Unspecified',
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _securityFormKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isUpdatingSecurity = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = AuthService();
    final res = await auth.getProfile();
    final logs = await auth.getGateLogs();

    if (mounted) {
      setState(() {
        if (res['success'] == true) {
          _userProfile = res['data'];
          _nameController.text =
              _userProfile?['name'] ?? _userProfile?['fullName'] ?? '';
          _emailController.text =
              _userProfile?['email'] ?? _userProfile?['emailAddress'] ?? '';
          _idController.text = _userProfile?['idNumber'] ?? '';
          _contactController.text =
              _userProfile?['contact'] ?? _userProfile?['phone'] ?? '';
          _deptController.text =
              _userProfile?['dept'] ?? _userProfile?['department'] ?? 'N/A';
          _yearController.text =
              _userProfile?['year'] ?? _userProfile?['yearLevel'] ?? 'N/A';
          _selectedGender = _userProfile?['gender'] ?? 'Unspecified';
          if (!_genderOptions.contains(_selectedGender)) {
            _selectedGender = 'Unspecified';
          }

          // Handle base64 image or URL
          final imgData = _userProfile?['image'] ??
              _userProfile?['profilePictureUrl'] ??
              _userProfile?['avatar'];
          if (imgData != null && imgData.toString().startsWith('data:image')) {
            _base64Image = imgData.toString().split(',').last;
          } else if (imgData != null) {
            String url = imgData.toString();
            // Prepend relative paths uploaded from the web dashboard
            if (url.startsWith('/')) {
              url = AuthService.baseUrl.replaceAll('/api', '') + url;
            }
            _profileImageUrl = url;
            _base64Image = null; // Clear stale local cache
          }
        }

        _gateLogs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Optimize for base64
    );

    if (image != null && mounted) {
      final bytes = await image.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      setState(() => _isSaving = true);

      final res = await AuthService().updateProfile(
        name: _nameController.text,
        idNumber: _idController.text,
        contact: _contactController.text,
        gender: _selectedGender,
        dept: _deptController.text,
        year: _yearController.text,
        imageBase64: base64String,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          if (res['success'] == true) {
            _userProfile = res['data'];
            // Sync base64 immediately for UI feedback
            _base64Image = base64String.split(',').last;
            _profileImageUrl = null;
            _showSuccessDialog('Profile picture updated successfully!');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(res['message'] ?? 'Failed to update image'),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF800000)
                          : Colors.red),
            );
          }
        });
      }
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isSaving = true);

    final res = await AuthService().updateProfile(
      name: _nameController.text,
      idNumber: _idController.text,
      contact: _contactController.text,
      gender: _selectedGender,
      dept: _deptController.text,
      year: _yearController.text,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (res['success'] == true) {
      final updatedUser = res['data'] as Map<String, dynamic>?;
      setState(() {
        if (updatedUser != null) {
          _userProfile = updatedUser;
        } else {
          // Manually patch local cache so UI reflects instantly
          _userProfile = {
            ...?_userProfile,
            'name': _nameController.text,
            'idNumber': _idController.text,
            'contact': _contactController.text,
            'gender': _selectedGender,
            'dept': _deptController.text, // Updated to keep local cache sync
            'year': _yearController.text,
          };
        }
      });
      Navigator.of(context).pop(); // Close modal AFTER setState
      _showSuccessDialog('Profile updated successfully!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(res['message'] ?? 'Failed to update'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF800000)
                : Colors.red),
      );
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF16A34A),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Success!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _textColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Great',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine trailing theme label
    final mode = themeNotifier.value;
    final themeLabel = mode == ThemeMode.system
        ? 'System'
        : (mode == ThemeMode.dark ? 'Dark' : 'Light');

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              child: Stack(
                children: [
                  // Maroon Background behind the profile card, scrolling with the view
                  Container(
                    height: 350, // Made longer/larger as requested
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20)),
                    ),
                  ),

                  // Content
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom embedded App Bar so it scrolls with the page
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                              const Text(
                                'Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                  width: 48), // Balances the back button
                            ],
                          ),
                          const SizedBox(height: 24),

                          _buildProfileBanner(),
                          const SizedBox(height: 32),
                          _buildSection(
                            title: 'Account',
                            items: [
                              _buildSettingsTile(
                                icon: Icons.person_outline,
                                title: 'Manage Profile',
                                onTap: () => _showEditProfileModal(),
                              ),
                              _buildSettingsTile(
                                icon: Icons.lock_outline,
                                title: 'Password & Security',
                                onTap: () => _showSecuritySheet(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: 'Preferences',
                            items: [
                              _buildSettingsTile(
                                icon: Icons.info_outline,
                                title: 'About LibraGuard',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AboutScreen()),
                                  );
                                },
                              ),
                              _buildSettingsTile(
                                icon: Icons.palette_outlined,
                                title: 'Theme',
                                trailingLabel: themeLabel,
                                onTap: _showThemeSettings,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: 'Library Records',
                            items: [
                              _buildSettingsTile(
                                icon: Icons.book_outlined,
                                title: 'Borrowing Records',
                                onTap: () => _showBorrowingSheet(),
                              ),
                              _buildSettingsTile(
                                icon: Icons.door_front_door_outlined,
                                title: 'Library Gate Logs',
                                onTap: () => _showGateLogs(),
                              ),
                              _buildSettingsTile(
                                icon: Icons.computer_outlined,
                                title: 'Computer Sessions',
                                onTap: () => _showSessions(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: 'Support',
                            items: [
                              _buildSettingsTile(
                                icon: Icons.help_outline,
                                title: 'Help Center',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HelpSupportScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                          _buildLogoutButton(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              color: _textColor.withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length * 2 - 1, (index) {
              if (index.isOdd) {
                return Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: _textColor.withOpacity(0.05),
                );
              }
              return items[index ~/ 2];
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileBanner() {
    final fullName =
        _userProfile?['name'] ?? _userProfile?['fullName'] ?? 'LibraGuard User';
    final role = _userProfile?['role'] ?? 'Member';
    final email = _userProfile?['email'] ?? 'user@libraguard.edu';
    final department = _userProfile?['dept'] ?? _userProfile?['department'] ?? 'N/A';
    final year = _userProfile?['year'] ?? _userProfile?['yearLevel'] ?? 'N/A';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 24),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _cardColor, // White border effect
                    borderRadius:
                        BorderRadius.circular(28), // Squircle shape like image
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 85,
                      height: 85,
                      color: _primaryColor.withOpacity(0.1),
                      child: _base64Image != null
                          ? Image.memory(
                              base64Decode(_base64Image!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.person,
                                      color: _primaryColor, size: 40),
                            )
                          : (_profileImageUrl != null
                              ? Image.network(
                                  _profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.person,
                                          color: _primaryColor, size: 40),
                                )
                              : Icon(Icons.person,
                                  color: _primaryColor, size: 40)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF800000), // Maroon camera badge
                        shape: BoxShape.circle,
                        border: Border.all(color: _cardColor, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Name and badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 24), // Offset for badge spacing
                Text(
                  fullName,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified,
                  color: Color(0xFFFFD700), // Yellow verified badge
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Email underneath name
            Text(
              email,
              style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Badges Row (Department, Year, Role)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: _textColor
                    .withOpacity(0.03), // Light grey background like image
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProfileBadge(Icons.business, department, 'Dept'),
                  _buildProfileBadge(Icons.school, year, 'Year'),
                  _buildProfileBadge(Icons.shield, role.toUpperCase(), 'Role'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBadge(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF800000).withOpacity(0.1), // Marron tinted bg
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: const Color(0xFF800000), size: 24), // Maroon icon
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: _textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _textColor.withOpacity(0.4),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildClickableTile({
    required int index,
    required String title,
    required VoidCallback onTap,
  }) {
    final bool isActive = _activeUtilityIndex == index;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          color: isActive ? _primaryColor : _textColor.withOpacity(0.8),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        child: Text(title),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isActive ? _primaryColor : _textColor.withOpacity(0.4),
        size: 20,
      ),
      onTap: () {
        setState(() => _activeUtilityIndex = index);
        onTap();
      },
    );
  }

  void _showSecuritySheet() async {
    setState(() => _activeUtilityIndex = 0);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _textColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: Form(
                  key: _securityFormKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Update Security',
                            style: TextStyle(
                                color: _textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                            color: _textColor.withOpacity(0.4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure your account with a strong password.',
                        style: TextStyle(
                            color: _textColor.withOpacity(0.55), fontSize: 13),
                      ),
                      const SizedBox(height: 32),
                      _buildTextField(
                        'Current Password',
                        'Enter current password',
                        controller: _currentPasswordController,
                        onToggleVisibility: () {
                          setModalState(
                              () => _obscurePassword = !_obscurePassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        'New Password',
                        'Enter new password',
                        controller: _newPasswordController,
                        onToggleVisibility: () {
                          setModalState(
                              () => _obscurePassword = !_obscurePassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return 'Must contain an uppercase letter';
                          }
                          if (!value.contains(RegExp(r'[a-z]'))) {
                            return 'Must contain a lowercase letter';
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'Must contain a number';
                          }
                          if (!value
                              .contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
                            return 'Must contain a special character';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        'Confirm New Password',
                        'Re-enter new password',
                        controller: _confirmPasswordController,
                        onToggleVisibility: () {
                          setModalState(
                              () => _obscurePassword = !_obscurePassword);
                        },
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isUpdatingSecurity
                              ? null
                              : () async {
                                  if (_securityFormKey.currentState!
                                      .validate()) {
                                    setModalState(
                                        () => _isUpdatingSecurity = true);

                                    final res =
                                        await AuthService().updateSecurity(
                                      _currentPasswordController.text,
                                      _newPasswordController.text,
                                    );

                                    if (mounted) {
                                      setModalState(
                                          () => _isUpdatingSecurity = false);
                                      if (res['success'] == true) {
                                        _currentPasswordController.clear();
                                        _newPasswordController.clear();
                                        _confirmPasswordController.clear();
                                        Navigator.pop(
                                            context); // Close bottom sheet
                                        _showSuccessDialog(res['message'] ??
                                            'Password updated successfully!');
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(res['message'] ??
                                                'Failed to update'),
                                            backgroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF800000)
                                                    : Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isUpdatingSecurity
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Update Password',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) setState(() => _activeUtilityIndex = -1);
  }

  Widget _buildTextField(String label, String hint,
      {TextEditingController? controller,
      VoidCallback? onToggleVisibility,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: _textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: _obscurePassword,
          style: TextStyle(color: _textColor, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: _textColor.withOpacity(0.3), fontSize: 12),
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF8FAFC),
            filled: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _textColor.withOpacity(0.3),
                size: 16,
              ),
              onPressed: onToggleVisibility,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                backgroundColor: _cardColor,
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: _primaryColor,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you sure you want to log out from your account? You will need to sign in again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textColor.withOpacity(0.65),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _textColor.withOpacity(0.8),
                                side: BorderSide(
                                    color: _textColor.withOpacity(0.12),
                                    width: 1.5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Log Out',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );

          if (confirm == true) {
            await AuthService().logout();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: BorderSide(color: _primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingLabel,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 12,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                trailingLabel,
                style: TextStyle(
                  color: _textColor.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ),
          Icon(Icons.chevron_right,
              color: _textColor.withOpacity(0.2), size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showThemeSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'App Theme',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your preferred display mode.',
                style: TextStyle(
                    color: _textColor.withOpacity(0.55), fontSize: 13),
              ),
              const SizedBox(height: 24),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, currentMode, __) => Column(
                  children: [
                    _buildThemeOption(
                      icon: Icons.light_mode_outlined,
                      label: 'Light Mode',
                      description: 'Bright, clean interface',
                      isSelected: currentMode == ThemeMode.light,
                      onTap: () async {
                        themeNotifier.value = ThemeMode.light;
                        final email = (_userProfile?['email'] ??
                                _userProfile?['emailAddress'] ??
                                _userProfile?['username'])
                            ?.toString();
                        if (email != null) {
                          await AuthService()
                              .saveThemePreference(email, 'light');
                        }
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildThemeOption(
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark Mode',
                      description: 'Easy on the eyes at night',
                      isSelected: currentMode == ThemeMode.dark,
                      onTap: () async {
                        themeNotifier.value = ThemeMode.dark;
                        final email = (_userProfile?['email'] ??
                                _userProfile?['emailAddress'] ??
                                _userProfile?['username'])
                            ?.toString();
                        if (email != null) {
                          await AuthService()
                              .saveThemePreference(email, 'dark');
                        }
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildThemeOption(
                      icon: Icons.settings_brightness_outlined,
                      label: 'System Default',
                      description: 'Follow device settings',
                      isSelected: currentMode == ThemeMode.system,
                      onTap: () async {
                        themeNotifier.value = ThemeMode.system;
                        final email = (_userProfile?['email'] ??
                                _userProfile?['emailAddress'] ??
                                _userProfile?['username'])
                            ?.toString();
                        if (email != null) {
                          await AuthService()
                              .saveThemePreference(email, 'system');
                        }
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor.withOpacity(0.08)
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _primaryColor
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isSelected ? _primaryColor.withOpacity(0.12) : _cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color:
                      isSelected ? _primaryColor : _textColor.withOpacity(0.5),
                  size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: TextStyle(
                          color: _textColor.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: _primaryColor, size: 22),
          ],
        ),
      ),
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
              _buildNavItem(Icons.person_rounded, 'Profile', 3),
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
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PcReservationRulesScreen()),
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

  void _showBorrowingSheet() async {
    setState(() => _activeUtilityIndex = 1);

    // Fetch typed transactions on demand
    final List<BorrowTransaction> transactions =
        await BorrowService().fetchMyTransactions();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Borrowing Records',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: _textColor.withOpacity(0.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined,
                              size: 48, color: _textColor.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text(
                            'No borrowing records yet.',
                            style: TextStyle(
                                color: _textColor.withOpacity(0.4),
                                fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, color: Colors.black.withOpacity(0.06)),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];

                        // Status badge colour
                        Color statusColor;
                        if (tx.isPending) {
                          statusColor = const Color(0xFFF59E0B);
                        } else if (tx.isApproved) {
                          statusColor = const Color(0xFF16A34A);
                        } else if (tx.isRejected) {
                          statusColor = Colors.redAccent;
                        } else {
                          statusColor = Colors.grey;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.menu_book,
                                    color: _primaryColor, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.bookTitle,
                                      style: TextStyle(
                                          color: _textColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      tx.dueDate.isNotEmpty
                                          ? 'Due: ${tx.dueDate}'
                                          : 'Borrow: ${tx.borrowDate}',
                                      style: TextStyle(
                                          color: _textColor.withOpacity(0.5),
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tx.status,
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (mounted) setState(() => _activeUtilityIndex = -1);
  }

  Future<void> _fetchOccupancy(
      void Function(void Function()) setSheetState) async {
    final data = await AuthService().getLibraryOccupancy();
    if (mounted) {
      setSheetState(() {
        _occupancyCount = data['count'] as int? ?? 0;
        _maxCapacity = (data['maxCapacity'] as int? ?? 100);
        if (_maxCapacity <= 0) _maxCapacity = 100;
      });
    }
  }

  void _showGateLogs() async {
    setState(() => _activeUtilityIndex = 2);

    // Initial occupancy fetch
    final initialOccupancy = await AuthService().getLibraryOccupancy();
    if (mounted) {
      setState(() {
        _occupancyCount = initialOccupancy['count'] as int? ?? 0;
        _maxCapacity = (initialOccupancy['maxCapacity'] as int? ?? 100);
        if (_maxCapacity <= 0) _maxCapacity = 100;
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Start polling timer when sheet opens
          _occupancyTimer?.cancel();
          _occupancyTimer = Timer.periodic(const Duration(seconds: 30), (_) {
            _fetchOccupancy(setSheetState);
          });

          final double ratio = _occupancyCount / _maxCapacity;
          final Color barColor = ratio < 0.6
              ? const Color(0xFF22C55E)
              : ratio < 0.85
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444);

          return Container(
            height: MediaQuery.of(context).size.height * 0.80,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _textColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Library Gate Logs',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: _textColor.withOpacity(0.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // ── Real-Time Capacity Card ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryColor.withOpacity(0.08),
                          _primaryColor.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Pulsing live dot
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: barColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: barColor.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LIVE · Library Occupancy',
                              style: TextStyle(
                                color: _textColor.withOpacity(0.55),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _fetchOccupancy(setSheetState),
                              child: Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: _primaryColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$_occupancyCount',
                              style: TextStyle(
                                color: barColor,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6, left: 4),
                              child: Text(
                                '/ $_maxCapacity',
                                style: TextStyle(
                                  color: _textColor.withOpacity(0.45),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: barColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ratio < 0.6
                                    ? 'Available'
                                    : ratio < 0.85
                                        ? 'Filling Up'
                                        : 'Near Full',
                                style: TextStyle(
                                  color: barColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'students currently inside',
                          style: TextStyle(
                            color: _textColor.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: _textColor.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Updates every 30 seconds',
                          style: TextStyle(
                            color: _textColor.withOpacity(0.3),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ────────────────────────────────────────────────────────

                const SizedBox(height: 12),
                // Column headers
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text('Date',
                            style: TextStyle(
                                color: _primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Time In',
                            style: TextStyle(
                                color: _primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Time Out',
                            style: TextStyle(
                                color: _primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                      SizedBox(
                        width: 46,
                        child: Text('Lane',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: _primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Log entries
                Expanded(
                  child: _gateLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.door_front_door_outlined,
                                  size: 48, color: _textColor.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text(
                                'No entry logs recorded.',
                                style: TextStyle(
                                    color: _textColor.withOpacity(0.4),
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          itemCount: _gateLogs.length,
                          separatorBuilder: (_, __) => Divider(
                              height: 1, color: _textColor.withOpacity(0.05)),
                          itemBuilder: (context, index) {
                            final log = _gateLogs[index];
                            String dateStr = 'N/A';
                            String timeInStr = 'N/A';
                            String timeOutStr = '--';
                            final rawTimeIn = log['timeIn']?.toString() ?? '';
                            final rawTimeOut = log['timeOut']?.toString() ?? '';
                            final lane = log['lane']?.toString() ?? 'N/A';
                            final bool isActive = rawTimeOut.isEmpty ||
                                rawTimeOut == 'null' ||
                                log['timeOut'] == null;

                            try {
                              if (rawTimeIn.isNotEmpty && rawTimeIn != 'null') {
                                final dt = DateTime.parse(rawTimeIn).toLocal();
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
                                dateStr =
                                    '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
                                final hour =
                                    dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                                final minute =
                                    dt.minute.toString().padLeft(2, '0');
                                final period = dt.hour >= 12 ? 'PM' : 'AM';
                                timeInStr = '$hour:$minute $period';
                              }
                            } catch (_) {}

                            try {
                              if (!isActive) {
                                final dtOut =
                                    DateTime.parse(rawTimeOut).toLocal();
                                final hour =
                                    dtOut.hour % 12 == 0 ? 12 : dtOut.hour % 12;
                                final minute =
                                    dtOut.minute.toString().padLeft(2, '0');
                                final period = dtOut.hour >= 12 ? 'PM' : 'AM';
                                timeOutStr = '$hour:$minute $period';
                              }
                            } catch (_) {}

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      dateStr,
                                      style: TextStyle(
                                          color: _textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      timeInStr,
                                      style: TextStyle(
                                          color: _textColor.withOpacity(0.75),
                                          fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: isActive
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'Active',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        : Text(
                                            timeOutStr,
                                            style: TextStyle(
                                                color: _textColor
                                                    .withOpacity(0.75),
                                                fontSize: 12),
                                          ),
                                  ),
                                  SizedBox(
                                    width: 46,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          lane,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: _primaryColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );

    // Stop polling when sheet closes
    _occupancyTimer?.cancel();
    _occupancyTimer = null;

    if (mounted) setState(() => _activeUtilityIndex = -1);
  }

  void _showSessions() async {
    setState(() => _activeUtilityIndex = 3);

    // Fetch typed sessions on demand
    final List<PcSession> sessions = await PcService().fetchMySessions();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Computer Sessions',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: _textColor.withOpacity(0.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.computer_outlined,
                              size: 48, color: _textColor.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text(
                            'No computer sessions yet.',
                            style: TextStyle(
                                color: _textColor.withOpacity(0.4),
                                fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, color: Colors.black.withOpacity(0.06)),
                      itemBuilder: (context, index) {
                        final sess = sessions[index];

                        // Status badge colour
                        Color statusColor;
                        if (sess.isPending) {
                          statusColor = const Color(0xFFF59E0B);
                        } else if (sess.isActive) {
                          statusColor = Colors.blue;
                        } else if (sess.isCompleted) {
                          statusColor = const Color(0xFF16A34A);
                        } else {
                          statusColor = Colors.grey;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.computer,
                                    color: _primaryColor, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sess.computerName,
                                      style: TextStyle(
                                          color: _textColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Duration: ${sess.duration}',
                                      style: TextStyle(
                                          color: _textColor.withOpacity(0.5),
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  sess.status.toUpperCase(),
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (mounted) setState(() => _activeUtilityIndex = -1);
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Credentials',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update your personal information to keep your profile accurate.',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Close modal
                        _pickImage(); // Open picker
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _primaryColor.withOpacity(0.1),
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                            child: _base64Image != null
                                ? ClipOval(
                                    child: Image.memory(
                                        base64Decode(_base64Image!),
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80))
                                : (_profileImageUrl == null
                                    ? Icon(Icons.person,
                                        color: _primaryColor, size: 40)
                                    : null),
                          ),
                          const SizedBox(height: 12),
                          Text('Change Profile Photo',
                              style: TextStyle(
                                  color: _primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildEditField(
                      'Full Name', _nameController, Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildEditField(
                      'Email Address', _emailController, Icons.email_outlined,
                      enabled: false),
                  const SizedBox(height: 20),
                  _buildEditField('Contact Number', _contactController,
                      Icons.phone_outlined),
                  const SizedBox(height: 20),
                  _buildEditField(
                      'ID Number', _idController, Icons.badge_outlined,
                      enabled: false),
                  const SizedBox(height: 20),
                  _buildEditField('Department', _deptController,
                      Icons.account_balance_outlined,
                      enabled: false),
                  const SizedBox(height: 20),
                  _buildEditField(
                      'Year Level', _yearController, Icons.history_edu_outlined,
                      enabled: false),
                  const SizedBox(height: 20),
                  const Text('Gender',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _textColor.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        items: _genderOptions
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => _selectedGender = val);
                            setState(() => _selectedGender = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfileChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(
      String label, TextEditingController controller, IconData icon,
      {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(
            color: enabled ? _textColor : _textColor.withOpacity(0.5),
          ),
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, color: _primaryColor.withOpacity(0.7), size: 20),
            hintText: 'Enter your $label',
            filled: !enabled,
            fillColor: enabled ? null : _textColor.withOpacity(0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _textColor.withOpacity(0.1)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _textColor.withOpacity(0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _textColor.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
