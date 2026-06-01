import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/borrow_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/pc_service.dart';
import 'services/book_service.dart';
import 'login_screen.dart';
import 'book_list_screen.dart';
import 'pc_reservation_rules_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'main.dart' show themeNotifier;
import 'widgets/app_bottom_nav.dart';
import 'library_service_guide_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _accentColor => Theme.of(context)
      .colorScheme
      .secondary; // Maroon in light, Primary 600 in dark
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF1D2939));
  }

  Color get _cardColor => Theme.of(context).cardColor;

  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  List<BorrowTransaction> _cachedTransactions = [];
  List<Map<String, dynamic>> _cachedGateLogs = [];
  List<PcSession> _cachedSessions = [];
  List<LibraryComputer> _cachedComputers = [];
  String? _profileImageUrl;
  String? _base64Image;
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
  final TextEditingController _2faCodeController = TextEditingController();
  final TextEditingController _2faDisablePasswordController =
      TextEditingController();
  final _securityFormKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isUpdatingSecurity = false;

  // 2FA State
  bool _is2FAEnabled = false;
  bool _is2FAExpanded = false;
  String? _2faQrCodeUrl;
  String? _2faManualKey;
  String? _2faSecret;
  bool _isEnabling2FA = false;
  bool _isDisabling2FA = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. Load ALL cached data in one shot for instant UI
    final results = await Future.wait([
      BorrowService().getPersistentCachedTransactions(),
      AuthService().getCachedGateLogs(),
      PcService().getPersistentCachedSessions(),
      AuthService().getCachedProfile(),
    ]);

    if (mounted) {
      setState(() {
        _cachedTransactions = (results[0] as List).cast<BorrowTransaction>();
        _cachedGateLogs = (results[1] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _cachedSessions = (results[2] as List).cast<PcSession>();

        final cachedProfile = results[3] as Map<String, dynamic>?;
        if (cachedProfile != null) {
          _userProfile = cachedProfile;
          _updateControllers(cachedProfile);
        }
        _isLoading = false;
      });
    }

    // Load 2FA status
    final _is2faEnabledLocal = await AuthService().is2FAEnabled();
    if (mounted) {
      setState(() {
        _is2FAEnabled = _is2faEnabledLocal;
      });
    }

    // 2. Silently fetch fresh data in background
    _refreshProfileData();
  }

  void _updateControllers(Map<String, dynamic> profile) {
    _nameController.text = profile['name'] ?? profile['fullName'] ?? '';
    _emailController.text = profile['email'] ?? profile['emailAddress'] ?? '';
    _idController.text = profile['idNumber'] ?? '';
    _contactController.text = profile['contact'] ?? profile['phone'] ?? '';
    _deptController.text = profile['dept'] ?? profile['department'] ?? 'N/A';
    _yearController.text = profile['year'] ?? profile['yearLevel'] ?? 'N/A';
    _selectedGender = profile['gender'] ?? 'Unspecified';
    if (!_genderOptions.contains(_selectedGender)) {
      _selectedGender = 'Unspecified';
    }

    final imgData =
        profile['image'] ?? profile['profilePictureUrl'] ?? profile['avatar'];
    if (imgData != null && imgData.toString().startsWith('data:image')) {
      _base64Image = imgData.toString().split(',').last;
    } else if (imgData != null) {
      String url = imgData.toString();
      if (url.startsWith('/')) {
        url = AuthService.baseUrl.replaceAll('/api', '') + url;
      }
      _profileImageUrl = url;
      _base64Image = null;
    }
  }

  Future<void> _refreshProfileData() async {
    final res = await AuthService().getProfile();
    if (res['success'] == true && mounted) {
      setState(() {
        _userProfile = res['data'];
        _updateControllers(_userProfile!);
      });
    }
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _refreshProfileData(),
      // Pre-fetch other history items as well to update local cache
      BorrowService().fetchMyTransactions(),
      PcService().fetchMySessions(),
      AuthService().getGateLogs().then((res) {
        if (mounted) {
          setState(() {
            _cachedGateLogs = res;
          });
        }
      }),
    ]);
    if (mounted) setState(() {});
  }

  Future<String?> _showResizeDialog(Uint8List imageBytes) async {
    final GlobalKey boundaryKey = GlobalKey();
    final TransformationController transformController =
        TransformationController();
    double currentZoom = 1.0;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: _cardColor,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cropping Area
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // RepaintBoundary to capture the final view
                        RepaintBoundary(
                          key: boundaryKey,
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRect(
                              child: InteractiveViewer(
                                transformationController: transformController,
                                clipBehavior: Clip.none,
                                minScale: 0.1,
                                maxScale: 5.0,
                                boundaryMargin: const EdgeInsets.all(200),
                                onInteractionUpdate: (details) {
                                  setDialogState(() {
                                    currentZoom = transformController.value
                                        .getMaxScaleOnAxis();
                                  });
                                },
                                child: Image.memory(
                                  imageBytes,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Circular Overlay (using a hole in a stack)
                        IgnorePointer(
                          child: SizedBox(
                            width: 300,
                            height: 300,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.5),
                                BlendMode.srcOut,
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      backgroundBlendMode: BlendMode.dstOut,
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      width: 250,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Helper Text
                        Positioned(
                          top: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.open_with,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  "Drag or use arrow keys to reposition image",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Zoom Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                    child: Row(
                      children: [
                        Icon(Icons.remove,
                            color: _textColor.withOpacity(0.54), size: 20),
                        Expanded(
                          child: Slider(
                            value: currentZoom.clamp(0.5, 3.0),
                            min: 0.5,
                            max: 3.0,
                            activeColor: _accentColor,
                            inactiveColor: _textColor.withOpacity(0.12),
                            onChanged: (val) {
                              setDialogState(() {
                                currentZoom = val;
                                // Update scale while keeping center
                                final translation =
                                    transformController.value.getTranslation();
                                transformController.value = Matrix4.identity()
                                  ..translate(translation.x, translation.y)
                                  ..scale(val);
                              });
                            },
                          ),
                        ),
                        Icon(Icons.add,
                            color: _textColor.withOpacity(0.54), size: 20),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Reminder: Please use a proper image for your profile.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _textColor.withOpacity(0.4), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white12),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel",
                              style: TextStyle(
                                  color: _textColor.withOpacity(0.7))),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              // Capture the RepaintBoundary as an image
                              final RenderRepaintBoundary boundary =
                                  boundaryKey.currentContext!.findRenderObject()
                                      as RenderRepaintBoundary;
                              final ui.Image image =
                                  await boundary.toImage(pixelRatio: 2.0);
                              final ByteData? byteData = await image.toByteData(
                                  format: ui.ImageByteFormat.png);
                              final Uint8List pngBytes =
                                  byteData!.buffer.asUint8List();
                              final String base64String =
                                  'data:image/png;base64,${base64Encode(pngBytes)}';
                              Navigator.pop(context, base64String);
                            } catch (e) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Save",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
      imageBase64:
          _base64Image != null ? 'data:image/png;base64,$_base64Image' : null,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final updatedUser = res['data'] as Map<String, dynamic>?;
      setState(() {
        if (updatedUser != null) {
          _userProfile = updatedUser;
        } else {
          _userProfile = {
            ...?_userProfile,
            'name': _nameController.text,
            'idNumber': _idController.text,
            'contact': _contactController.text,
            'gender': _selectedGender,
            'dept': _deptController.text,
            'year': _yearController.text,
          };
        }
        _isSaving = false;
      });

      // Close modal first
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show success dialog with a very small delay to ensure modal is out of the way
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _showSuccessDialog('Profile updated successfully!');
      });
    } else {
      setState(() => _isSaving = false);
      if (!mounted) return;
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
      useRootNavigator: true,
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
                    backgroundColor: _accentColor,
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

  Future<void> _handleEnable2FA() async {
    final code = _2faCodeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code')),
      );
      return;
    }

    if (_2faSecret == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('2FA session expired. Please refresh.')),
      );
      return;
    }

    setState(() => _isEnabling2FA = true);
    final res = await AuthService().enable2FA(code, _2faSecret!);
    setState(() => _isEnabling2FA = false);

    if (res['success'] == true) {
      setState(() {
        _is2FAEnabled = true;
        _2faCodeController.clear();
        _2faSecret = null;
      });
      _showSuccessDialog('Two-Factor Authentication enabled!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to enable 2FA')),
      );
    }
  }

  Future<void> _handleDisable2FA() async {
    final password = _2faDisablePasswordController.text.trim();
    final code = _2faCodeController.text.trim();

    if (password.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter password and a 6-digit code')),
      );
      return;
    }

    setState(() => _isDisabling2FA = true);
    final res = await AuthService().disable2FA(password, code);
    setState(() => _isDisabling2FA = false);

    if (res['success'] == true) {
      setState(() {
        _is2FAEnabled = false;
        _2faCodeController.clear();
        _2faDisablePasswordController.clear();
      });
      _showSuccessDialog('Two-Factor Authentication disabled!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to disable 2FA')),
      );
    }
  }

  Future<void> _openAuthenticatorApp() async {
    final Uri otpauthUri = Uri.parse('otpauth://');
    final Uri googleAuthUri = Uri.parse('googleauthenticator://');

    try {
      if (await canLaunchUrl(otpauthUri)) {
        await launchUrl(otpauthUri);
      } else if (await canLaunchUrl(googleAuthUri)) {
        await launchUrl(googleAuthUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No authenticator app found. Please open it manually.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open authenticator app')),
        );
      }
    }
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
          : RefreshIndicator(
              onRefresh: _refreshAllData,
              color: _primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Stack(
                  children: [
                    // Maroon Background behind the profile card, scrolling with the view
                    Container(
                      height: 350, // Made longer/larger as requested
                      decoration: BoxDecoration(
                        color: _accentColor,
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
                                _build2FASection(),
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
                                  title: 'Entry & Exit Gate Logs',
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
            ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: 3,
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pop(context);
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
      ),
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

  Future<void> _pickImage(
      {bool instantSave = true, Function? onImageSelected}) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Optimize for base64
    );

    if (image != null && mounted) {
      // Show Resize Dialog before uploading
      final Uint8List bytes = await image.readAsBytes();
      final String? resizedBase64 = await _showResizeDialog(bytes);

      if (resizedBase64 != null && mounted) {
        if (instantSave) {
          setState(() => _isSaving = true);

          final res = await AuthService().updateProfile(
            name: _nameController.text,
            idNumber: _idController.text,
            contact: _contactController.text,
            gender: _selectedGender,
            dept: _deptController.text,
            year: _yearController.text,
            imageBase64: resizedBase64,
          );

          if (mounted) {
            setState(() {
              _isSaving = false;
              if (res['success'] == true) {
                _userProfile = res['data'];
                // Sync base64 immediately for UI feedback
                _base64Image = resizedBase64.split(',').last;
                _profileImageUrl = null;
                _showSuccessDialog('Profile picture updated!');
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
        } else {
          // Deferred save (e.g. from Manage Profile modal)
          setState(() {
            _base64Image = resizedBase64.split(',').last;
            _profileImageUrl = null;
          });
          if (onImageSelected != null) onImageSelected();
        }
      }
    }
  }

  Widget _buildProfileBanner() {
    final fullName =
        _userProfile?['name'] ?? _userProfile?['fullName'] ?? 'LibraGuard User';
    final role = _userProfile?['role'] ?? 'Member';
    final email = _userProfile?['email'] ?? 'user@libraguard.edu';
    final department =
        _userProfile?['dept'] ?? _userProfile?['department'] ?? 'N/A';
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
                    borderRadius: BorderRadius.circular(16), // Squircle shape
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 85,
                      height: 85,
                      color: _accentColor.withOpacity(0.1),
                      child: _base64Image != null
                          ? Image.memory(
                              base64Decode(_base64Image!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.person,
                                      color: _accentColor, size: 40),
                            )
                          : (_profileImageUrl != null
                              ? Image.network(
                                  _profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.person,
                                          color: _accentColor, size: 40),
                                )
                              : Icon(Icons.person,
                                  color: _accentColor, size: 40)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: () => _pickImage(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary, // Maroon in light, Primary 600 in dark
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
    final theme = Theme.of(context);
    final accentColor =
        theme.colorScheme.secondary; // Maroon in light, Primary 600 in dark
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accentColor, size: 24),
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

  void _showSecuritySheet() async {
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
                            backgroundColor: _accentColor,
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
                          color: _accentColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: _accentColor,
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
                                backgroundColor: _accentColor,
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
          foregroundColor: _accentColor,
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
          color: _accentColor.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _accentColor, size: 20),
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
              Icon(Icons.check_circle, color: _accentColor, size: 22),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions({
    required BuildContext context,
    required String title,
    required Map<String, List<String>> options,
    required Map<String, String> currentValues,
    required Function(Map<String, String>) onApply,
  }) {
    final Map<String, String> localValues = Map.from(currentValues);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setFilterState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: _textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      onApply(localValues);
                      Navigator.pop(context);
                    },
                    child: Text('Apply',
                        style: TextStyle(
                            color: _primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...options.entries.map((entry) {
                final category = entry.key;
                final values = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        category,
                        style: TextStyle(
                            color: _textColor.withOpacity(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: values.map((val) {
                        final bool isSelected = localValues[category] == val;
                        return ChoiceChip(
                          label: Text(val),
                          selected: isSelected,
                          checkmarkColor: _primaryColor,
                          onSelected: (selected) {
                            if (selected) {
                              setFilterState(() => localValues[category] = val);
                            }
                          },
                          backgroundColor: _textColor.withOpacity(0.05),
                          selectedColor: _primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? _primaryColor
                                : _textColor.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? _primaryColor.withOpacity(0.2)
                                  : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showBorrowingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        String selectedStatus = 'All';
        String selectedTimeframe = 'All Time';
        String selectedSort = 'Newest First';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
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
                  const SizedBox(height: 12),
                  // Search and Filter Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _textColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              onChanged: (val) =>
                                  setSheetState(() => searchQuery = val),
                              style: TextStyle(color: _textColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search books or authors...',
                                hintStyle: TextStyle(
                                    color: _textColor.withOpacity(0.3),
                                    fontSize: 14),
                                prefixIcon: Icon(Icons.search,
                                    color: _textColor.withOpacity(0.3),
                                    size: 20),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: selectedStatus != 'All' ||
                                    selectedTimeframe != 'All Time' ||
                                    selectedSort != 'Newest First'
                                ? _primaryColor.withOpacity(0.1)
                                : _textColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.filter_list,
                                color: selectedStatus != 'All' ||
                                        selectedTimeframe != 'All Time' ||
                                        selectedSort != 'Newest First'
                                    ? _primaryColor
                                    : _textColor.withOpacity(0.6),
                                size: 20),
                            onPressed: () {
                              _showFilterOptions(
                                context: context,
                                title: 'Filter Borrowing',
                                options: {
                                  'Status': [
                                    'All',
                                    'Borrowed',
                                    'Returned',
                                    'Cancelled'
                                  ],
                                  'Timeframe': [
                                    'All Time',
                                    'This Week',
                                    'This Month'
                                  ],
                                  'Sort By': [
                                    'Newest First',
                                    'Oldest First',
                                    'Book Title (A-Z)'
                                  ],
                                },
                                currentValues: {
                                  'Status': selectedStatus,
                                  'Timeframe': selectedTimeframe,
                                  'Sort By': selectedSort,
                                },
                                onApply: (newValues) {
                                  setSheetState(() {
                                    selectedStatus = newValues['Status']!;
                                    selectedTimeframe = newValues['Timeframe']!;
                                    selectedSort = newValues['Sort By']!;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<BorrowTransaction>>(
                      future: BorrowService().fetchMyTransactions(),
                      initialData: _cachedTransactions,
                      builder: (context, snapshot) {
                        final transactions =
                            snapshot.data ?? _cachedTransactions;

                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            transactions.isEmpty) {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: _primaryColor));
                        }

                        // Apply Search & Advanced Filtering
                        List<BorrowTransaction> filtered =
                            transactions.where((tx) {
                          final query = searchQuery.toLowerCase();
                          final bookTitle = tx.bookTitle.toLowerCase();
                          final borrower = tx.borrowerName.toLowerCase();

                          // Search Match
                          bool matchesSearch = bookTitle.contains(query) ||
                              borrower.contains(query);

                          // Status Match
                          bool matchesStatus = true;
                          if (selectedStatus == 'Borrowed') {
                            matchesStatus =
                                tx.returnDate == null && !tx.isCancelled;
                          } else if (selectedStatus == 'Returned') {
                            matchesStatus = tx.returnDate != null;
                          } else if (selectedStatus == 'Cancelled') {
                            matchesStatus = tx.isCancelled;
                          }

                          // Timeframe Match
                          bool matchesTime = true;
                          if (selectedTimeframe != 'All Time') {
                            try {
                              final borrowDate = DateTime.parse(tx.borrowDate);
                              final now = DateTime.now();
                              if (selectedTimeframe == 'This Week') {
                                matchesTime =
                                    now.difference(borrowDate).inDays <= 7;
                              } else if (selectedTimeframe == 'This Month') {
                                matchesTime = now.month == borrowDate.month &&
                                    now.year == borrowDate.year;
                              }
                            } catch (_) {}
                          }

                          return matchesSearch && matchesStatus && matchesTime;
                        }).toList();

                        // Apply Sorting
                        if (selectedSort == 'Newest First') {
                          filtered.sort(
                              (a, b) => b.borrowDate.compareTo(a.borrowDate));
                        } else if (selectedSort == 'Oldest First') {
                          filtered.sort(
                              (a, b) => a.borrowDate.compareTo(b.borrowDate));
                        } else if (selectedSort == 'Book Title (A-Z)') {
                          filtered.sort((a, b) => a.bookTitle
                              .toLowerCase()
                              .compareTo(b.bookTitle.toLowerCase()));
                        }

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 48,
                                    color: _textColor.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Text(
                                  'No matching records found',
                                  style: TextStyle(
                                      color: _textColor.withOpacity(0.4),
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }

                        return _buildBorrowingCardList(context, filtered);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {});
  }

  Widget _buildBorrowingCardList(
      BuildContext context, List<BorrowTransaction> transactions) {
    final active = transactions
        .where((tx) => !tx.status.toLowerCase().contains('archived'))
        .toList();

    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined,
                size: 48, color: _textColor.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(
              'No borrowing records yet.',
              style:
                  TextStyle(color: _textColor.withOpacity(0.4), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: active.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildBorrowCard(context, active[index]),
    );
  }

  Widget _buildBorrowCard(BuildContext context, BorrowTransaction tx) {
    Color statusColor;
    if (tx.isPending) {
      statusColor = const Color(0xFFF59E0B);
    } else if (tx.isApproved) {
      statusColor = const Color(0xFF16A34A);
    } else if (tx.isReturned) {
      statusColor = Colors.blue;
    } else if (tx.isRejected) {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.grey;
    }

    String formattedDate = tx.borrowDate;
    try {
      final dt = DateTime.parse(tx.borrowDate).toLocal();
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
      formattedDate = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textColor.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 72,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.menu_book_rounded,
                color: _accentColor.withOpacity(0.6), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        tx.bookTitle,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requested on',
                          style: TextStyle(
                            color: _textColor.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: _textColor.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _showBorrowDetailDialog(context, tx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "View Details",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPcSessionCardList(
      BuildContext context, List<PcSession> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.computer_outlined,
                size: 48, color: _textColor.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(
              'No computer sessions yet.',
              style:
                  TextStyle(color: _textColor.withOpacity(0.4), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildPcSessionCard(context, sessions[index]),
    );
  }

  Widget _buildPcSessionCard(BuildContext context, PcSession sess) {
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

    String dateStr = '---';
    if (sess.createdAt != null && sess.createdAt!.isNotEmpty) {
      try {
        final dt = DateTime.parse(sess.createdAt!).toLocal();
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
        dateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textColor.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.computer_rounded,
                color: _accentColor.withOpacity(0.6), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        sess.computerName,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
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
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Duration: ${sess.duration}',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (sess.reference != null)
                      Text(
                        'Ref: ${sess.reference}',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBorrowDetailDialog(BuildContext context, BorrowTransaction tx) {
    Color statusColor;
    if (tx.isPending) {
      statusColor = const Color(0xFFF59E0B);
    } else if (tx.isApproved) {
      statusColor = const Color(0xFF16A34A);
    } else if (tx.isReturned) {
      statusColor = Colors.blue;
    } else if (tx.isRejected) {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.grey;
    }

    String fmtDate(String raw) {
      try {
        final dt = DateTime.parse(raw).toLocal();
        return "${dt.month}/${dt.day}/${dt.year}";
      } catch (_) {
        return raw.isNotEmpty ? raw : '---';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Scaffold(
            backgroundColor: _cardColor,
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Borrowing Summary',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: _textColor.withOpacity(0.5)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(color: _textColor.withOpacity(0.07), height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                color: _textColor.withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tx.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Section 1: Borrower's Details
                        _buildDialogSection(
                          title: "Borrower's Details",
                          showIcon: false,
                          hasOutline: true,
                          children: [
                            _buildDialogRow(
                                'Name',
                                _nameController.text.isNotEmpty
                                    ? _nameController.text
                                    : tx.borrowerName),
                            _buildDialogRow(
                                'Role',
                                (_userProfile?['role'] ?? 'STUDENT')
                                    .toString()
                                    .toUpperCase()),
                            _buildDialogRow('Department', _deptController.text),
                            _buildDialogRow('Year', _yearController.text),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Book Details
                        FutureBuilder<BookItem?>(
                          future: BookService().fetchBookById(tx.bookId),
                          builder: (context, snapshot) {
                            final book = snapshot.data;
                            final isLoading = snapshot.connectionState ==
                                ConnectionState.waiting;

                            return _buildDialogSection(
                              title: 'BOOK DETAILS',
                              showIcon: false,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _textColor.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: _textColor.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: _accentColor.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: isLoading
                                            ? Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: _accentColor,
                                                  ),
                                                ),
                                              )
                                            : Icon(Icons.menu_book_rounded,
                                                size: 40, color: _accentColor),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (book != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _accentColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  book.displayGenre
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color: _accentColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Text(
                                              tx.bookTitle,
                                              style: TextStyle(
                                                color: _textColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                height: 1.3,
                                              ),
                                            ),
                                            if (book != null) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                'by ${book.author}',
                                                style: TextStyle(
                                                  color: _textColor
                                                      .withOpacity(0.5),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                            if (isLoading)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text(
                                                  'Loading details...',
                                                  style: TextStyle(
                                                    color: _textColor
                                                        .withOpacity(0.3),
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Section 3: Schedule
                        _buildDialogSection(
                          title: 'SCHEDULE',
                          showIcon: false,
                          children: [
                            _buildDialogRow(
                                'Requested On', fmtDate(tx.borrowDate)),
                            _buildDialogRow(
                                'Pickup Deadline',
                                tx.pickupDeadline.isNotEmpty
                                    ? fmtDate(tx.pickupDeadline)
                                    : '---',
                                valueColor: const Color(0xFFF59E0B)),
                            _buildDialogRow(
                                'Return By',
                                tx.dueDate.isNotEmpty
                                    ? fmtDate(tx.dueDate)
                                    : '---',
                                valueColor: const Color(0xFF16A34A)),
                            if (tx.returnDate != null &&
                                tx.returnDate!.isNotEmpty)
                              _buildDialogRow(
                                  'Returned On', fmtDate(tx.returnDate!)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Section 4: Penalty if any
                        if (tx.penalty.isNotEmpty && tx.penalty != '₱0.00') ...[
                          _buildDialogSection(
                            title: 'PENALTY',
                            showIcon: false,
                            children: [
                              _buildDialogRow('Amount', tx.penalty,
                                  valueColor: Colors.redAccent),
                            ],
                          ),
                        ],

                        const SizedBox(height: 3), // Section 5: Reminders
                        _buildDialogSection(
                          title: 'Reminders',
                          showIcon: false,
                          titleColor: _accentColor,
                          children: [
                            _buildReminderItem(
                                'Pick up within 3 working days.'),
                            _buildReminderItem(
                                'Bring your RFID card for pickup.'),
                            _buildReminderItem(
                                'Return the book on or before the due date.'),
                            _buildReminderItem(
                                'Library Hours: 8:00 AM – 5:00 PM (Mon – Sat).'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LibraryServiceGuideScreen(
                                      initialExpandedIndex: 2, // Return Books
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.menu_book_rounded,
                                      size: 18, color: _accentColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Returning Process Guide',
                                    style: TextStyle(
                                      color: _accentColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
      ),
    );
  }

  Widget _buildReminderItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Colors.orange.shade800),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _textColor.withOpacity(0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogSection({
    IconData? icon,
    required String title,
    required List<Widget> children,
    bool showIcon = true,
    bool hasOutline = false,
    Color? titleColor,
  }) {
    final sectionContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showIcon && icon != null) ...[
              Icon(icon, size: 18, color: _accentColor),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                color: titleColor ?? _textColor.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
        if (!hasOutline) ...[
          const SizedBox(height: 12),
          Divider(color: _textColor.withOpacity(0.12), height: 1, thickness: 1),
          const SizedBox(height: 16),
        ],
      ],
    );

    if (hasOutline) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _textColor.withOpacity(0.1)),
        ),
        child: sectionContent,
      );
    }

    return sectionContent;
  }

  Widget _buildDialogRow(String label, String value, {Color? valueColor}) {
    final bool isLong = value.length > 25;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: isLong
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: valueColor ?? _textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showGateLogs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        String selectedPresence = 'All';
        String selectedLane = 'All';
        String selectedTimeframe = 'All Time';
        bool _refreshStarted = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (!_refreshStarted) {
              _refreshStarted = true;
              AuthService().getGateLogs().then((fresh) {
                if (mounted && fresh.isNotEmpty) {
                  setState(() => _cachedGateLogs = fresh);
                  setSheetState(() {});
                }
              });
            }

            final localLogs = _cachedGateLogs;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
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
                        color: _textColor.withOpacity(0.12),
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
                  const SizedBox(height: 12),
                  // Search and Filter Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _textColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              onChanged: (val) =>
                                  setSheetState(() => searchQuery = val),
                              style: TextStyle(color: _textColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search by date or lane...',
                                hintStyle: TextStyle(
                                    color: _textColor.withOpacity(0.3),
                                    fontSize: 14),
                                prefixIcon: Icon(Icons.search,
                                    color: _textColor.withOpacity(0.3),
                                    size: 20),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: selectedPresence != 'All' ||
                                    selectedLane != 'All' ||
                                    selectedTimeframe != 'All Time'
                                ? _primaryColor.withOpacity(0.1)
                                : _textColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.filter_list,
                                color: selectedPresence != 'All' ||
                                        selectedLane != 'All' ||
                                        selectedTimeframe != 'All Time'
                                    ? _primaryColor
                                    : _textColor.withOpacity(0.6),
                                size: 20),
                            onPressed: () {
                              _showFilterOptions(
                                context: context,
                                title: 'Filter Gate Logs',
                                options: {
                                  'Presence': [
                                    'All',
                                    'Still Inside',
                                    'Checked Out'
                                  ],
                                  'Lane': ['All', 'Lane 1', 'Lane 2'],
                                  'Timeframe': [
                                    'All Time',
                                    'This Week',
                                    'This Month'
                                  ],
                                },
                                currentValues: {
                                  'Presence': selectedPresence,
                                  'Lane': selectedLane,
                                  'Timeframe': selectedTimeframe,
                                },
                                onApply: (newValues) {
                                  setSheetState(() {
                                    selectedPresence = newValues['Presence']!;
                                    selectedLane = newValues['Lane']!;
                                    selectedTimeframe = newValues['Timeframe']!;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        // Apply filtering to localLogs
                        final filtered = localLogs.where((log) {
                          final query = searchQuery.toLowerCase();
                          final timeIn =
                              log['timeIn']?.toString().toLowerCase() ?? '';
                          final laneVal =
                              log['lane']?.toString().toLowerCase() ?? '';

                          // Search Match
                          bool matchesSearch =
                              timeIn.contains(query) || laneVal.contains(query);

                          // Presence Match
                          bool matchesPresence = true;
                          final bool isAtLibrary = log['timeOut'] == null ||
                              log['timeOut'].toString().isEmpty ||
                              log['timeOut'].toString() == 'null';
                          if (selectedPresence == 'Still Inside') {
                            matchesPresence = isAtLibrary;
                          } else if (selectedPresence == 'Checked Out') {
                            matchesPresence = !isAtLibrary;
                          }

                          // Lane Match
                          bool matchesLane = true;
                          if (selectedLane != 'All') {
                            matchesLane = selectedLane
                                .toLowerCase()
                                .contains(laneVal.toLowerCase());
                          }

                          // Timeframe Match
                          bool matchesTime = true;
                          if (selectedTimeframe != 'All Time') {
                            try {
                              final timeInStr = log['timeIn']?.toString() ?? '';
                              final logDate = DateTime.parse(timeInStr);
                              final now = DateTime.now();
                              if (selectedTimeframe == 'This Week') {
                                matchesTime =
                                    now.difference(logDate).inDays <= 7;
                              } else if (selectedTimeframe == 'This Month') {
                                matchesTime = now.month == logDate.month &&
                                    now.year == logDate.year;
                              }
                            } catch (_) {}
                          }

                          return matchesSearch &&
                              matchesPresence &&
                              matchesLane &&
                              matchesTime;
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.door_sliding_outlined,
                                    size: 48,
                                    color: _textColor.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Text(
                                  'No matching logs found.',
                                  style: TextStyle(
                                      color: _textColor.withOpacity(0.4),
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1.2),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(1),
                              3: FlexColumnWidth(0.5),
                            },
                            children: [
                              TableRow(
                                children: [
                                  _buildTableHeader('Date'),
                                  _buildTableHeader('Time In'),
                                  _buildTableHeader('Time Out'),
                                  _buildTableHeader('Lane'),
                                ],
                              ),
                              ...filtered.map((log) {
                                String dateStr = 'N/A';
                                String timeInStr = 'N/A';
                                String timeOutStr = '--';
                                final rawTimeIn =
                                    log['timeIn']?.toString() ?? '';
                                final rawTimeOut =
                                    log['timeOut']?.toString() ?? '';
                                final laneVal =
                                    log['lane']?.toString() ?? 'N/A';
                                final bool isActive = rawTimeOut.isEmpty ||
                                    rawTimeOut == 'null' ||
                                    log['timeOut'] == null;

                                try {
                                  if (rawTimeIn.isNotEmpty &&
                                      rawTimeIn != 'null') {
                                    final dt =
                                        DateTime.parse(rawTimeIn).toLocal();
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
                                    final hour = dtOut.hour % 12 == 0
                                        ? 12
                                        : dtOut.hour % 12;
                                    final minute =
                                        dtOut.minute.toString().padLeft(2, '0');
                                    final period =
                                        dtOut.hour >= 12 ? 'PM' : 'AM';
                                    timeOutStr = '$hour:$minute $period';
                                  }
                                } catch (_) {}

                                return TableRow(
                                  children: [
                                    _buildTableCell(dateStr),
                                    _buildTableCell(timeInStr),
                                    isActive
                                        ? _buildStatusCell(
                                            'Active', Colors.green)
                                        : _buildTableCell(timeOutStr),
                                    _buildTableCell(laneVal),
                                  ],
                                );
                              }).toList(),
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
        );
      },
    ).then((_) {});
  }

  void _showSessions() {
    // Pre-hook to pre-fetch computers for the filter
    PcService().fetchComputers().then((pcs) {
      if (mounted && pcs.isNotEmpty) {
        setState(() => _cachedComputers = pcs);
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        String selectedStatus = 'All';
        String selectedDuration = 'All';
        String selectedPc = 'All';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
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
                  const SizedBox(height: 12),
                  // Search and Filter Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _textColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              onChanged: (val) =>
                                  setSheetState(() => searchQuery = val),
                              style: TextStyle(color: _textColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search PC or reference...',
                                hintStyle: TextStyle(
                                    color: _textColor.withOpacity(0.3),
                                    fontSize: 14),
                                prefixIcon: Icon(Icons.search,
                                    color: _textColor.withOpacity(0.3),
                                    size: 20),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: selectedStatus != 'All' ||
                                    selectedDuration != 'All' ||
                                    selectedPc != 'All'
                                ? _primaryColor.withOpacity(0.1)
                                : _textColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.filter_list,
                                color: selectedStatus != 'All' ||
                                        selectedDuration != 'All' ||
                                        selectedPc != 'All'
                                    ? _primaryColor
                                    : _textColor.withOpacity(0.6),
                                size: 20),
                            onPressed: () {
                              // Get unique PC names from history AND the full computer list
                              final historyPcs = _cachedSessions
                                  .map((s) => s.computerName)
                                  .toSet();
                              final fullPcs =
                                  _cachedComputers.map((pc) => pc.name).toSet();
                              final allPcs =
                                  {...historyPcs, ...fullPcs}.toList()..sort();

                              _showFilterOptions(
                                context: context,
                                title: 'Filter Sessions',
                                options: {
                                  'Status': [
                                    'All',
                                    'Pending',
                                    'Active',
                                    'Completed',
                                    'Rejected'
                                  ],
                                  'Duration': [
                                    'All',
                                    '15 Min',
                                    '30 Min',
                                    '1 Hour',
                                    '2 Hours'
                                  ],
                                  'PC Number': ['All', ...allPcs],
                                },
                                currentValues: {
                                  'Status': selectedStatus,
                                  'Duration': selectedDuration,
                                  'PC Number': selectedPc,
                                },
                                onApply: (newValues) {
                                  setSheetState(() {
                                    selectedStatus = newValues['Status']!;
                                    selectedDuration = newValues['Duration']!;
                                    selectedPc = newValues['PC Number']!;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<PcSession>>(
                      future: PcService().fetchMySessions(),
                      initialData: _cachedSessions,
                      builder: (context, snapshot) {
                        final sessions = snapshot.data ?? _cachedSessions;

                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            sessions.isEmpty) {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: _primaryColor));
                        }

                        // Apply Search & Advanced Filtering
                        final filtered = sessions.where((s) {
                          final query = searchQuery.toLowerCase();
                          final pcName = s.computerName.toLowerCase();
                          final ref = s.reference?.toLowerCase() ?? '';

                          // Search Match
                          bool matchesSearch =
                              pcName.contains(query) || ref.contains(query);

                          // Status Match
                          bool matchesStatus = true;
                          if (selectedStatus != 'All') {
                            final sStatus = s.status.toLowerCase();
                            final selSt = selectedStatus.toLowerCase();
                            if (selSt == 'active') {
                              matchesStatus =
                                  sStatus == 'active' || sStatus == 'approved';
                            } else {
                              matchesStatus = sStatus == selSt;
                            }
                          }

                          // Duration Match
                          bool matchesDuration = true;
                          if (selectedDuration != 'All') {
                            final dur = s.duration.toLowerCase();
                            final sel = selectedDuration.toLowerCase();
                            // Match "1 Hour" with "1 Hour", "1 hr", "60 min" etc.
                            if (sel == '1 hour') {
                              matchesDuration = dur.contains('1 hour') ||
                                  dur.contains('1 hr') ||
                                  dur.contains('60 min');
                            } else if (sel == '2 hours') {
                              matchesDuration = dur.contains('2 hour') ||
                                  dur.contains('2 hr') ||
                                  dur.contains('120 min');
                            } else {
                              matchesDuration = dur.contains(sel);
                            }
                          }

                          // PC Match
                          bool matchesPc = true;
                          if (selectedPc != 'All') {
                            matchesPc = s.computerName
                                .toLowerCase()
                                .contains(selectedPc.toLowerCase());
                          }

                          return matchesSearch &&
                              matchesStatus &&
                              matchesDuration &&
                              matchesPc;
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 48,
                                    color: _textColor.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Text(
                                  sessions.isEmpty
                                      ? 'No computer sessions found.'
                                      : 'No matching sessions found.',
                                  style: TextStyle(
                                      color: _textColor.withOpacity(0.4),
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }

                        return _buildPcSessionCardList(context, filtered);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {});
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
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
                        _pickImage(
                          instantSave: false,
                          onImageSelected: () => setModalState(() {}),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              image: _profileImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_profileImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _base64Image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      base64Decode(_base64Image!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (_profileImageUrl == null
                                    ? Icon(Icons.person,
                                        color: _accentColor, size: 40)
                                    : null),
                          ),
                          const SizedBox(height: 12),
                          Text('Change Profile Photo',
                              style: TextStyle(
                                  color: _accentColor,
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
                        backgroundColor: _accentColor,
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
                              'Update Profile',
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
                Icon(icon, color: _accentColor.withOpacity(0.7), size: 20),
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

  Widget _buildTableHeader(String label, {bool forceWhite = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        label,
        style: TextStyle(
          color: forceWhite ? Colors.white : _textColor.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableCell(String value,
      {String? subtitle, bool forceWhite = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: forceWhite ? Colors.white : _textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: forceWhite
                    ? Colors.white.withOpacity(0.7)
                    : _textColor.withOpacity(0.4),
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCell(String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _build2FASection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // Collapsed Tile
          ListTile(
            onTap: () async {
              if (!_is2FAExpanded && !_is2FAEnabled) {
                // Fetch setup data when expanding
                final setup = await AuthService().get2FASetup();
                setState(() {
                  _2faQrCodeUrl = setup['qrCodeUrl'];
                  _2faManualKey = setup['manualKey'];
                  _2faSecret = setup['secret'];
                });
              }
              setState(() => _is2FAExpanded = !_is2FAExpanded);
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phonelink_lock_outlined,
                  color: _primaryColor, size: 20),
            ),
            title: const Text(
              'Two-Factor Authentication',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _is2FAEnabled
                        ? const Color(0xFF22C55E).withOpacity(0.12)
                        : _primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _is2FAEnabled ? 'ENABLED' : 'NOT SET UP',
                    style: TextStyle(
                      color: _is2FAEnabled
                          ? const Color(0xFF16A34A)
                          : _primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _is2FAExpanded ? Icons.expand_more : Icons.chevron_right,
                  color: _textColor.withOpacity(0.2),
                  size: 20,
                ),
              ],
            ),
          ),

          // Expanded Content
          if (_is2FAExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: _primaryColor, width: 3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _is2FAEnabled
                    ? _build2FAEnabledView()
                    : _build2FASetupView(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _build2FASetupView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Protect your account with an authenticator app (Google Authenticator, Authy, Bitwarden, etc.). Scan the QR code below, then enter the 6-digit code to confirm.',
          style: TextStyle(
              color: _textColor.withOpacity(0.6), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Step By Step Guide Summary
        _build2FAStep(1, "Open Account Settings",
            "Navigate to Profile → Account Settings → tap \"Two-Factor Authentication\""),
        _build2FAStep(2, "View the Setup Panel",
            "The section expands to show a QR code and a Manual Entry Key"),

        const SizedBox(height: 24),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, spreadRadius: 2)
              ],
            ),
            child: _2faQrCodeUrl != null
                ? Image.network(_2faQrCodeUrl!, width: 180, height: 180)
                : const SizedBox(
                    width: 180,
                    height: 180,
                    child: Center(child: CircularProgressIndicator())),
          ),
        ),
        const SizedBox(height: 24),

        _build2FAStep(3, "Scan or Enter Manually",
            "Open your authenticator app and choose one of the options below"),

        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _textColor.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _textColor.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Text(
                'MANUAL ENTRY KEY',
                style: TextStyle(
                  color: _textColor.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _2faManualKey ?? 'Loading...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openAuthenticatorApp,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open Authenticator App'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accentColor,
              side: BorderSide(color: _accentColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),

        _build2FAStep(4, "Confirm Security Code",
            "Enter the 6-digit code generated by your app below to finalize"),
        const SizedBox(height: 12),
        Text(
          'Verification Code',
          style: TextStyle(
              color: _textColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _2faCodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '– – – – – –',
            counterText: '',
            fillColor: _textColor.withOpacity(0.03),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isEnabling2FA ? null : _handleEnable2FA,
            icon: const Icon(Icons.verified_user_outlined),
            label: _isEnabling2FA
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Enable Two-Factor Authentication',
                    style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _build2FAStep(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              "$step",
              style: TextStyle(
                  color: _primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: _textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(description,
                    style: TextStyle(
                        color: _textColor.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build2FAEnabledView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Color(0xFF16A34A), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Two-Factor Authentication is Active',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Your account is protected. A code is required at every login.',
                      style: TextStyle(
                        color: const Color(0xFF16A34A).withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'To disable 2FA, enter your current password and a live code from your authenticator app.',
          style: TextStyle(color: _textColor.withOpacity(0.6), fontSize: 13),
        ),
        const SizedBox(height: 20),
        Text(
          'Current Password',
          style: TextStyle(
              color: _textColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _2faDisablePasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Required for confirmation',
            fillColor: _textColor.withOpacity(0.03),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Authenticator Code',
          style: TextStyle(
              color: _textColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _2faCodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '6-digit code',
            counterText: '',
            fillColor: _textColor.withOpacity(0.03),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isDisabling2FA ? null : _handleDisable2FA,
            icon: const Icon(Icons.no_encryption_gmailerrorred_outlined,
                size: 20),
            label: _isDisabling2FA
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Disable Two-Factor Authentication',
                    style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
