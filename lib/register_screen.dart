import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'services/auth_service.dart';
import 'widgets/glow_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _deptController = TextEditingController();
  final _yearController = TextEditingController();
  final _facultyCodeController = TextEditingController();
  String? _selectedYearLevel;

  bool _isLoading = false;
  String _selectedRole = 'STUDENT';
  final AuthService _authService = AuthService();

  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _cardColor => Theme.of(context).cardColor;
  Color get _accentColor => Theme.of(context).colorScheme.secondary; // Maroon in light, Primary 600 in dark
  Color get _textColor => Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _deptController.dispose();
    _yearController.dispose();
    _facultyCodeController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        idNumber: _idController.text.trim(),
        department: (_selectedRole == 'STUDENT' || _selectedRole == 'FACULTY') ? _deptController.text.trim() : null,
        yearLevel: _selectedRole == 'STUDENT' ? _yearController.text.trim() : null,
        accessCode: _selectedRole == 'FACULTY' ? _facultyCodeController.text.trim() : null,
        role: _selectedRole,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (!mounted) return;
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
                      child: Icon(Icons.check_circle,
                          color: Colors.green.shade600, size: 48),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Account Created',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your $_selectedRole account has been created. Please verify your account by checking your email for the verification link. You can then go back to login.',
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
                                builder: (context) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'BACK TO LOGIN',
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Register to access the library system.',
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
                        // Segmented Control for Roles
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFF1F5F9), // Slate 100
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildRoleTab('STUDENT'),
                              _buildRoleTab('FACULTY'),
                              _buildRoleTab('GUEST'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Full Name Field
                        _buildLabel('Full Name'),
                        const SizedBox(height: 8),
                        GlowTextField(
                          hint: 'Jane Doe',
                          icon: Icons.person_outline,
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value.trim())) {
                              return 'Name must contain letters only (no numbers or special characters)';
                            }
                            return null;
                          },
                        ),

                        // Optional ID Field mapping
                        if (_selectedRole != 'GUEST') ...[
                          const SizedBox(height: 24),
                          _buildLabel(_selectedRole == 'STUDENT'
                              ? 'Student ID Number'
                              : 'Faculty ID Number'),
                          const SizedBox(height: 8),
                          GlowTextField(
                            hint: _selectedRole == 'STUDENT'
                                ? '2023-00216'
                                : 'FAC-001A',
                            icon: Icons.badge_outlined,
                            controller: _idController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your ID number';
                              }
                              if (!RegExp(r'^\d{4}-\d{5}$').hasMatch(value.trim())) {
                                return 'Student ID must follow the format: 2023-00216';
                              }
                              return null;
                            },
                          ),
                        ],

                        if (_selectedRole == 'STUDENT') ...[
                          const SizedBox(height: 24),
                          _buildLabel('Department'),
                          const SizedBox(height: 8),
                          GlowTextField(
                            hint: 'BSIT',
                            icon: Icons.account_balance_outlined,
                            controller: _deptController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your department';
                              }
                              if (value.trim().length < 2) {
                                return 'Department must be at least 2 characters';
                              }
                              if (!RegExp(r"^[a-zA-Z\s/&]+$").hasMatch(value.trim())) {
                                return 'Department must contain letters only';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('Year Level'),
                          const SizedBox(height: 8),
                          _buildYearLevelDropdown(),
                        ],

                        if (_selectedRole == 'FACULTY') ...[
                          const SizedBox(height: 24),
                          _buildLabel('Faculty Access Code'),
                          const SizedBox(height: 8),
                          GlowTextField(
                            hint: 'Enter staff verification code...',
                            icon: Icons.vpn_key_outlined,
                            isPassword: true,
                            controller: _facultyCodeController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the authorization key';
                              }
                              if (value.trim().length < 6) {
                                return 'Authorization key must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'SECURITY CLEARANCE REQUIRED: Please enter the staff authorization key.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('Department'),
                          const SizedBox(height: 8),
                          GlowTextField(
                            hint: 'Computer Science',
                            icon: Icons.account_balance_outlined,
                            controller: _deptController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your department';
                              }
                              if (value.trim().length < 2) {
                                return 'Department must be at least 2 characters';
                              }
                              if (!RegExp(r"^[a-zA-Z\s/&]+$").hasMatch(value.trim())) {
                                return 'Department must contain letters only';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Email Field
                        _buildLabel('Email Address'),
                        const SizedBox(height: 8),
                        GlowTextField(
                          hint: 'scholar@libraguard.edu',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(
                                    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
                                .hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Password Field
                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        GlowTextField(
                          hint: 'Create a strong password...',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!value.contains(RegExp(r'[A-Z]'))) {
                              return 'Password must contain at least one uppercase letter';
                            }
                            if (!value.contains(RegExp(r'[a-z]'))) {
                              return 'Password must contain at least one lowercase letter';
                            }
                            if (!value.contains(RegExp(r'[0-9]'))) {
                              return 'Password must contain at least one number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Confirm Password Field
                        _buildLabel('Confirm Password'),
                        const SizedBox(height: 8),
                        GlowTextField(
                          hint: 'Confirm your password...',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _confirmController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _register,
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
                                      Icon(Icons.person_add_outlined, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'REGISTER',
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

                        // Sign In Redirect
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
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
                                          const LoginScreen()),
                                );
                              },
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: _accentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 80),
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

  Widget _buildYearLevelDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      value: _selectedYearLevel,
      decoration: InputDecoration(
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF8FAFC),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        prefixIcon: Icon(
          Icons.history_edu_outlined,
          color: _textColor.withOpacity(0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFFB21A2D) : Colors.redAccent,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFFB21A2D) : Colors.redAccent,
            width: 2,
          ),
        ),
      ),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      hint: Text(
        'Select year level',
        style: TextStyle(color: _textColor.withOpacity(0.4)),
      ),
      style: TextStyle(color: _textColor, fontSize: 16),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: _textColor.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(16),
      items: const [
        DropdownMenuItem(value: '1st Year', child: Text('1st Year')),
        DropdownMenuItem(value: '2nd Year', child: Text('2nd Year')),
        DropdownMenuItem(value: '3rd Year', child: Text('3rd Year')),
        DropdownMenuItem(value: '4th Year', child: Text('4th Year')),
      ],
      onChanged: (val) {
        setState(() {
          _selectedYearLevel = val;
          if (val != null) _yearController.text = val;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your year level';
        }
        return null;
      },
    );
  }

  Widget _buildRoleTab(String role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
            // Clear ID field when swapping roles to avoid confusion
            _idController.clear();
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? _accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            role,
            style: TextStyle(
              color: isSelected ? Colors.white : _textColor.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
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
}
