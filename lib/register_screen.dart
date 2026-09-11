import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _nameController     = TextEditingController();
  final _idController       = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  final _ageController      = TextEditingController();

  String? _selectedYearLevel;
  String? _selectedDepartment;
  bool _showPasswordChecklist = false;
  bool _isLoading = false;
  String _selectedRole = 'STUDENT';

  final AuthService _authService = AuthService();

  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _cardColor    => Theme.of(context).cardColor;
  Color get _accentColor  => Theme.of(context).colorScheme.secondary;
  Color get _textColor    =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (_showPasswordChecklist) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _authService.register(
      name:       _nameController.text.trim(),
      email:      _emailController.text.trim(),
      password:   _passwordController.text,
      idNumber:   _selectedRole == 'STUDENT' ? _idController.text.trim() : '',
      age:        _ageController.text.trim(),
      department: _selectedRole == 'STUDENT' ? (_selectedDepartment ?? '') : null,
      yearLevel:  _selectedRole == 'STUDENT' ? (_selectedYearLevel ?? '') : null,
      role:       _selectedRole,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success']) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
                ),
                const SizedBox(height: 20),
                Text('Account Created',
                    style: TextStyle(
                        color: _textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Your $_selectedRole account has been created. Please verify your '
                  'account by checking your email for the verification link. '
                  'You can then go back to login.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _textColor.withOpacity(0.7), fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('BACK TO LOGIN',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Registration failed'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFB21A2D)
            : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
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
                    onPressed: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                  ),
                  const SizedBox(height: 16),
                  const Text('Create Account',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Register to access the library system.',
                      style:
                          TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(40)),
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
                        // Role selector
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            _buildRoleTab('STUDENT'),
                            _buildRoleTab('VISITOR'),
                          ]),
                        ),
                        const SizedBox(height: 32),

                        // Full Name
                        _buildLabel('Full Name'),
                        const SizedBox(height: 8),
                        GlowTextField(
                          hint: 'Jane Doe',
                          icon: Icons.person_outline,
                          controller: _nameController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Please enter your full name';
                            if (v.trim().length < 2)
                              return 'Name must be at least 2 characters';
                            if (!RegExp(r"^[a-zA-Z\s.''-]+$").hasMatch(v.trim()))
                              return 'Name must contain letters only';
                            return null;
                          },
                        ),

                        // STUDENT-only
                        if (_selectedRole == 'STUDENT') ...[
                          const SizedBox(height: 24),
                          _buildLabel('Student ID Number'),
                          const SizedBox(height: 8),
                          GlowTextField(
                            hint: '2023-00216',
                            icon: Icons.tag_outlined,
                            controller: _idController,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Please enter your Student ID';
                              if (!RegExp(r'^\d{4}-\d{5}$').hasMatch(v.trim()))
                                return 'Format must be: 2023-00216';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('Year Level'),
                          const SizedBox(height: 8),
                          _buildYearLevelDropdown(),
                          const SizedBox(height: 24),
                          _buildLabel('Course / Department'),
                          const SizedBox(height: 8),
                          _buildDepartmentDropdown(),
                        ],

                        // Age (all roles)
                        const SizedBox(height: 24),
                        _buildLabel('Age'),
                        const SizedBox(height: 8),
                        GlowTextField(
                          hint: 'e.g. 19',
                          icon: Icons.cake_outlined,
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Please enter your age';
                            final age = int.tryParse(v.trim());
                            if (age == null || age < 10 || age > 120)
                              return 'Please enter a valid age';
                            return null;
                          },
                        ),

                        // Email
                        const SizedBox(height: 24),
                        _buildLabel('Email Address'),
                        const SizedBox(height: 8),
                        GlowTextField(
                          hint: 'scholar@libraguard.edu',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Please enter your email';
                            if (!RegExp(
                                    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
                                .hasMatch(v.trim()))
                              return 'Please enter a valid email address';
                            return null;
                          },
                        ),

                        // Password
                        const SizedBox(height: 24),
                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        Focus(
                          onFocusChange: (hasFocus) =>
                              setState(() => _showPasswordChecklist = hasFocus),
                          child: GlowTextField(
                            hint: 'Create a strong password...',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            controller: _passwordController,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Please enter a password';
                              if (v.length < 8)
                                return 'Password must be at least 8 characters';
                              if (!v.contains(RegExp(r'[A-Z]')))
                                return 'Must contain at least one uppercase letter';
                              if (!v.contains(RegExp(r'[a-z]')))
                                return 'Must contain at least one lowercase letter';
                              if (!v.contains(RegExp(r'[0-9]')))
                                return 'Must contain at least one number';
                              return null;
                            },
                          ),
                        ),
                        if (_showPasswordChecklist) _buildPasswordChecklist(),

                        // Confirm Password
                        const SizedBox(height: 24),
                        _buildLabel('Confirm Password'),
                        const SizedBox(height: 8),
                        GlowTextField(
                          hint: 'Confirm your password...',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _confirmController,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Please confirm your password';
                            if (v != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                       // Visitor banner
                        if (_selectedRole == 'VISITOR') ...[
                          _buildInfoBanner(
                            icon: Icons.info_outline_rounded,
                            text:
                                'Visitor accounts have limited access. A librarian '
                                'may ask to verify your identity on first visit.',
                            color: const Color(0xFFFFF3CD),
                            textColor: const Color(0xFF856404),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Staff banner (all roles)
                        _buildInfoBanner(
                          icon: Icons.info_outline_rounded,
                          boldPrefix: 'Library Staff? ',
                          text:
                              'Staff accounts are created by the administrator. '
                              'Check your email for an invite link.',
                          color: const Color(0xFFFDE8EA),
                          textColor: const Color(0xFF842029),
                        ),

                        const SizedBox(height: 32),

                        // Register button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add_outlined, size: 20),
                                      SizedBox(width: 8),
                                      Text('REGISTER',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5)),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ',
                                style: TextStyle(
                                    color: _textColor.withOpacity(0.6),
                                    fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen())),
                              child: Text('Sign In',
                                  style: TextStyle(
                                      color: _accentColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
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

  Widget _buildRoleTab(String role) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = role;
          _idController.clear();
          _selectedYearLevel = null;
          _selectedDepartment = null;
        }),
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
                        offset: const Offset(0, 2))
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
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style:
          TextStyle(color: _textColor, fontSize: 14, fontWeight: FontWeight.bold));

 Widget _buildInfoBanner({
    required IconData icon,
    String? boldPrefix,
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                children: [
                  if (boldPrefix != null)
                    TextSpan(
                        text: boldPrefix,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(
      {required IconData icon, required bool isDark}) {
    return InputDecoration(
      fillColor:
          isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
      filled: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      prefixIcon: Icon(icon, color: _textColor.withOpacity(0.5)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: isDark ? const Color(0xFFB21A2D) : Colors.redAccent,
            width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: isDark ? const Color(0xFFB21A2D) : Colors.redAccent,
            width: 2),
      ),
    );
  }

  Widget _buildYearLevelDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      value: _selectedYearLevel,
      decoration:
          _dropdownDecoration(icon: Icons.history_edu_outlined, isDark: isDark),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      hint: Text('Select year level...',
          style: TextStyle(color: _textColor.withOpacity(0.4))),
      style: TextStyle(color: _textColor, fontSize: 15),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: _textColor.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(16),
      items: const [
        DropdownMenuItem(value: '1st Year', child: Text('1st Year')),
        DropdownMenuItem(value: '2nd Year', child: Text('2nd Year')),
        DropdownMenuItem(value: '3rd Year', child: Text('3rd Year')),
        DropdownMenuItem(value: '4th Year', child: Text('4th Year')),
      ],
      onChanged: (val) => setState(() => _selectedYearLevel = val),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Please select your year level' : null,
    );
  }

  static const List<Map<String, String>> _departments = [
    {'code': 'BSA',    'name': 'Bachelor of Science in Accountancy'},
    {'code': 'BSAIS',  'name': 'Bachelor of Science in Accounting Information System'},
    {'code': 'BSAB',   'name': 'Bachelor of Science in Agribusiness'},
    {'code': 'BSBA',   'name': 'Bachelor of Science in Business Administration'},
    {'code': 'BSCE',   'name': 'Bachelor of Science in Civil Engineering'},
    {'code': 'BSCRIM', 'name': 'Bachelor of Science in Criminology'},
    {'code': 'BECED',  'name': 'Bachelor of Early Childhood Education'},
    {'code': 'BEED',   'name': 'Bachelor of Elementary Education'},
    {'code': 'BSHM',   'name': 'Bachelor of Science in Hospitality Management'},
    {'code': 'BSISM',  'name': 'Bachelor of Science in Industrial Security Management'},
    {'code': 'BSIT',   'name': 'Bachelor of Science in Information Technology'},
    {'code': 'BSMID',  'name': 'Bachelor of Science in Midwifery'},
    {'code': 'BSED',   'name': 'Bachelor of Secondary Education'},
  ];

  Widget _buildDepartmentDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      isExpanded: true,
      decoration: _dropdownDecoration(
          icon: Icons.account_balance_outlined, isDark: isDark),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      hint: Text('Select your course...',
          style: TextStyle(color: _textColor.withOpacity(0.4))),
      style: TextStyle(color: _textColor, fontSize: 15),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: _textColor.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(16),
      items: _departments.map((dept) {
        final value = '${dept['code']} - ${dept['name']}';
        return DropdownMenuItem<String>(
          value: value,
          child: Text('${dept['code']} - ${dept['name']}',
              overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedDepartment = val),
      validator: (v) => (v == null || v.isEmpty)
          ? 'Please select your course / department'
          : null,
    );
  }

  Widget _buildPasswordChecklist() {
    final p = _passwordController.text;
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 4.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _checkItem('At least 8 characters', p.length >= 8),
          const SizedBox(height: 6),
          _checkItem('At least one uppercase letter',
              p.contains(RegExp(r'[A-Z]'))),
          const SizedBox(height: 6),
          _checkItem('At least one lowercase letter',
              p.contains(RegExp(r'[a-z]'))),
          const SizedBox(height: 6),
          _checkItem('At least one number', p.contains(RegExp(r'[0-9]'))),
        ],
      ),
    );
  }

  Widget _checkItem(String text, bool met) => Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color:
                met ? Colors.green.shade600 : _textColor.withOpacity(0.3),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: met ? _textColor : _textColor.withOpacity(0.55),
                fontSize: 13.5,
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      );
}
