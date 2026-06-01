import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'services/auth_service.dart';
import 'main.dart' show themeNotifier; // Import for theme synchronization
import 'widgets/glow_text_field.dart';
import 'two_factor_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _cardColor => Theme.of(context).cardColor;
  Color get _accentColor => Theme.of(context).colorScheme.secondary; // Maroon in light, Primary 600 in dark
  Color get _textColor => Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final isRemembered = prefs.getBool('remember_me') ?? false;

    if (isRemembered && savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Handle Remember Me persistence
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('saved_email', _emailController.text.trim());
          await prefs.setString('saved_password', _passwordController.text);
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
          await prefs.remove('remember_me');
        }

        // Extract first name from API response
        final data = result['data'] ?? {};
        final user = data['user'] ?? data['data'] ?? data;
        final fullName =
            (user['name'] ?? user['fullName'] ?? '').toString().trim();
        final firstName =
            fullName.isNotEmpty ? fullName.split(' ').first : null;

        // Sync theme preference for this account
        if (mounted) {
          final userEmail = _emailController.text.trim().toLowerCase();
          final userThemeMode = await _authService.getThemePreference(userEmail);
          
          if (userThemeMode == 'dark') {
            themeNotifier.value = ThemeMode.dark;
          } else if (userThemeMode == 'light') {
            themeNotifier.value = ThemeMode.light;
          } else {
            themeNotifier.value = ThemeMode.system;
          }
        }

        if (!mounted) return;

        // Check if 2FA is enabled for this user (Server-driven or Local fallback)
        final bool is2FARequiredByServer = result['require2fa'] == true;
        final bool is2FAEnabledLocally = await _authService.is2FAEnabled();
        
        if (is2FARequiredByServer || is2FAEnabledLocally) {
          // Slide animation to 2FA screen
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  TwoFactorVerificationScreen(
                firstName: firstName,
                tempToken: result['tempToken'],
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutQuart;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
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
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Access Granted',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome back! You have successfully authenticated.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HomeScreen(firstName: firstName),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white, // Fix: Ensure white text
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'PROCEED TO HOME',
                          style: TextStyle(
                            color: Colors.white, // Fix: Force white text visibility
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFB21A2D) // Primary 700
                : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top colored area (Maroon)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access the library system.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // White Card Area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Email Field
                        _buildLabel('Email Address'),
                        const SizedBox(height: 12),
                        GlowTextField(
                          hint: 'scholar@libraguard.edu',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(
                              r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                            ).hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Password Field
                        _buildLabel('Password'),
                        const SizedBox(height: 12),
                        GlowTextField(
                          hint: 'Enter your password...',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Remember Me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) {
                                      setState(() {
                                        _rememberMe = val ?? false;
                                      });
                                    },
                                    activeColor: _accentColor,
                                    checkColor: Colors.white,
                                    side: BorderSide(
                                      color: _textColor.withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: _textColor.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _showForgotPasswordSheet,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: _accentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.login, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'SIGN IN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Register
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: _textColor.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Register',
                                style: TextStyle(
                                  color: _accentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _textColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }



  void _showForgotPasswordSheet() {
    final TextEditingController forgotEmailController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final GlobalKey<FormState> _resetFormKey = GlobalKey<FormState>();

    bool isSendingReset = false;
    bool obscureNew = true;
    bool obscureConfirm = true;
    int step = 1; // 1 = Email, 2 = Target Password

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
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _resetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _textColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    step == 1 ? 'Forgot Password' : 'Reset Password',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    step == 1
                        ? 'Enter your email address to reset your password.'
                        : 'Enter your new secure password.',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.6),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (step == 1) ...[
                    _buildLabel('Email Address'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: forgotEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: _textColor),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email address.';
                        }
                        if (!RegExp(
                          r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                        ).hasMatch(value.trim())) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF8FAFC),
                        filled: true,
                        hintText: 'scholar@libraguard.edu',
                        hintStyle: TextStyle(color: _textColor.withOpacity(0.4)),
                        prefixIcon: Icon(Icons.email_outlined, color: _textColor.withOpacity(0.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : const Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _accentColor, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFB21A2D) : Colors.redAccent, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFB21A2D) : Colors.redAccent, width: 2)),
                      ),
                    ),
                  ] else ...[
                    _buildLabel('New Password'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      style: TextStyle(color: _textColor),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a password.';
                        if (value.length < 8) return 'Minimum 8 characters required.';
                        if (!value.contains(RegExp(r'[A-Z]'))) return 'Requires an uppercase letter.';
                        if (!value.contains(RegExp(r'[a-z]'))) return 'Requires a lowercase letter.';
                        if (!value.contains(RegExp(r'[0-9]'))) return 'Requires a number.';
                        if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) return 'Requires a special character.';
                        return null;
                      },
                      decoration: InputDecoration(
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF8FAFC),
                        filled: true,
                        hintText: 'Enter strong password',
                        hintStyle: TextStyle(color: _textColor.withOpacity(0.4)),
                        prefixIcon: Icon(Icons.lock_outline, color: _textColor.withOpacity(0.5)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _textColor.withOpacity(0.5)),
                          onPressed: () => setModalState(() => obscureNew = !obscureNew),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : const Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _accentColor, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFB21A2D) : Colors.redAccent, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFB21A2D) : Colors.redAccent, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Confirm Password'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      style: TextStyle(color: _textColor),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm your password.';
                        if (value != newPasswordController.text) return 'Passwords do not match.';
                        return null;
                      },
                      decoration: InputDecoration(
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF8FAFC),
                        filled: true,
                        hintText: 'Re-enter strong password',
                        hintStyle: TextStyle(color: _textColor.withOpacity(0.4)),
                        prefixIcon: Icon(Icons.lock_outline, color: _textColor.withOpacity(0.5)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _textColor.withOpacity(0.5)),
                          onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : const Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _accentColor, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFB21A2D) : Colors.redAccent, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFB21A2D) : Colors.redAccent, width: 2)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSendingReset
                          ? null
                          : () async {
                              // Perform unified inline validation
                              if (!_resetFormKey.currentState!.validate()) return;
                              
                              if (step == 1) {
                                setModalState(() => isSendingReset = true);
                                final res = await AuthService().forgotPassword(forgotEmailController.text.trim());
                                if (mounted) {
                                  setModalState(() {
                                    isSendingReset = false;
                                    if (res['success'] == true) {
                                      step = 2; // Transition without requiring token
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to send'), backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFB21A2D) : Colors.redAccent));
                                    }
                                  });
                                }
                              } else {
                                setModalState(() => isSendingReset = true);
                                // The email itself handles identity via proxy since explicit token is dropped.
                                final res = await AuthService().resetPassword(
                                    resetToken: forgotEmailController.text.trim(),
                                    newPassword: newPasswordController.text);

                                if (mounted) {
                                  setModalState(() => isSendingReset = false);
                                  if (res['success'] == true) {
                                    Navigator.pop(context);
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
                                                decoration: BoxDecoration(color: const Color(0xFF16A34A).withOpacity(0.1), shape: BoxShape.circle),
                                                child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 48),
                                              ),
                                              const SizedBox(height: 24),
                                              const Text('Success!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1D2939))),
                                              const SizedBox(height: 8),
                                              Text(res['message'] ?? 'Password reset successfully!', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _textColor, height: 1.5)),
                                              const SizedBox(height: 24),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 50,
                                                child: ElevatedButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                                                  child: const Text('Okay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to reset password'), backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFB21A2D) : Colors.redAccent));
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isSendingReset
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(step == 1 ? 'Verify Email' : 'Update Password', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
