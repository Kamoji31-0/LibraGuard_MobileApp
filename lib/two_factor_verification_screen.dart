import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'services/auth_service.dart';

class TwoFactorVerificationScreen extends StatefulWidget {
  final String? firstName;
  final String? tempToken;
  const TwoFactorVerificationScreen({super.key, this.firstName, this.tempToken});

  @override
  State<TwoFactorVerificationScreen> createState() =>
      _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState
    extends State<TwoFactorVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyCode() async {
    String code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() => _isLoading = true);

    final result = await AuthService().verify2FALogin(code, widget.tempToken);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAuthenticatorApp() async {
    // Try direct launch — more reliable than canLaunchUrl on many devices
    final Uri otpauthUri = Uri.parse('otpauth://');
    final Uri googleAuthUri = Uri.parse('googleauthenticator://');

    try {
      // Attempt direct launch of otpauth:// first
      await launchUrl(otpauthUri, mode: LaunchMode.externalApplication);
      return;
    } catch (_) {}

    try {
      // Fallback: try googleauthenticator://
      await launchUrl(googleAuthUri, mode: LaunchMode.externalApplication);
      return;
    } catch (_) {}

    // If all else fails, show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No authenticator app found. Please open it manually.'),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    // Use theme-defined colors for consistency
    final Color dialogBg = theme.dialogTheme.backgroundColor ?? (isDark ? const Color(0xFF272B30) : Colors.white);
    final Color dialogTextColor = isDark ? Colors.white : const Color(0xFF1D2939);
    final Color primaryColor = theme.primaryColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: dialogBg,
          elevation: 20,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: isDark ? Colors.greenAccent.shade400 : Colors.green.shade600,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Access Granted',
                  style: TextStyle(
                    color: dialogTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome back! You have successfully authenticated.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dialogTextColor.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HomeScreen(firstName: widget.firstName),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'PROCEED TO HOME',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
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
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBackground = Theme.of(context).cardColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF1D2939));
    final Color subTextColor = Colors.white.withOpacity(0.8);
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Header Area (Maroon) - Following Register Screen format
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Two-Factor\nVerification',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Security check for ${widget.firstName ?? 'Scholar'}',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // White/Dark Card Area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: cardBackground,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Label from Register Screen style
                      Text(
                        'Verification Code',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter the 6-digit code from your authenticator app to authorize this login.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Code boxes
                      Center(
                        child: FittedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < 6; i++) 
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: _buildCodeBox(i, isDark, accentColor),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
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
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.shield_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'VERIFY ACCOUNT',
                                      style: TextStyle(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _openAuthenticatorApp,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text(
                            'Open Authenticator App',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accentColor),
                            foregroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeBox(int index, bool isDark, Color accentColor) {
    final Color textColor = isDark ? Colors.white : const Color(0xFF1D2939);
    final Color borderColor = isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFE2E8F0);
    final Color fillColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF8FAFC);

    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor, width: 2.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        cursorColor: accentColor,
        style: TextStyle(
          fontSize: 24, 
          fontWeight: FontWeight.bold,
          color: textColor, // Explicitly set text color
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              _verifyCode();
            }
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
