import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _accentColor => Theme.of(context).colorScheme.secondary;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor => Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;

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
        title: Text(
          'About LibraGuard',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About Libraguard Card
            _buildInfoCard(
              title: 'About Libraguard',
              icon: Icons.info_outline,
              content:
                  'The Libraguard system automates library processes like book borrowing, computer reservation, and access monitoring via RFID technology. Our goal is to provide an efficient and secure environment for all students and staff.',
            ),
            const SizedBox(height: 32),

            // System Mission Card
            _buildInfoCard(
              title: 'System Mission',
              icon: Icons.rocket_launch_outlined,
              content:
                  'LibraGuard was established to modernize and secure the university\'s library collections. Through our advanced cataloging and physical tracking, we ensure that knowledge is always accessible to students and faculty while maintaining secure records.\n\nOur network operates on the principles of speed, security, and accessibility. The librarians and administration are dedicated to maintaining the vast catalog of physical books and digital resources within our walls.',
            ),
            const SizedBox(height: 32),

            // Library Staff Card
            _buildStaffSection(context),
            const SizedBox(height: 32),

            // Library Hours Card
            _buildHoursCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title,
      required IconData icon,
      required String content}) {
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
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: _textColor.withOpacity(0.8),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSection(BuildContext context) {
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
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, color: _accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Library Staff',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Leadership
          _buildStaffMember(context, 'RT', 'Rebecca S. Tique, MLIS',
              'Librarian I / Chief Librarian',
              imagePath: 'assets/images/Rebecca.jpg', isLarge: true),
          const SizedBox(height: 16),
          _buildStaffMember(
              context, 'KH', 'Kimberly Y. Hambon, RL', 'Assistant Librarian',
              imagePath: 'assets/images/Hambon.jpg', isLarge: true),
          const SizedBox(height: 24),

          const Divider(),
          const SizedBox(height: 24),

          // Staff Section with Centered Last Item
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStaffMember(
                        context, 'RP', 'Ria C. Pacia', 'Library Staff',
                        imagePath: 'assets/images/Pacia.jpg'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStaffMember(
                        context, 'JF', 'Jacqueline P. Fiesta', 'Library Staff',
                        imagePath: 'assets/images/Fiesta.jpg'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStaffMember(
                        context, 'JA', 'Joe Pepe J. Acosta', 'Library Staff',
                        imagePath: 'assets/images/Acosta.jpg'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStaffMember(
                        context, 'IE', 'Imelda S. Esquejo', 'Library Staff',
                        imagePath: 'assets/images/Esquejo.jpg'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Centered last item
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 96) /
                        2, // Adjusted for card padding
                    child: _buildStaffMember(
                        context, 'RP', 'Reianne Joy Pascua', 'Library Staff',
                        imagePath: 'assets/images/Pascua.jpg'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffMember(
      BuildContext context, String initials, String name, String role,
      {String? imagePath, bool isLarge = false}) {
    return isLarge
        ? _buildLargeStaffCard(initials, name, role, imagePath)
        : Container(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.03)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF344054),
                    backgroundImage:
                        imagePath != null ? AssetImage(imagePath) : null,
                    child: imagePath == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(
                      color: _textColor.withOpacity(0.5),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildLargeStaffCard(
      String initials, String name, String role, String? imagePath) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _accentColor,
            backgroundImage: imagePath != null ? AssetImage(imagePath) : null,
            child: imagePath == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              color: _textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: TextStyle(
              color: _textColor.withOpacity(0.5),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHoursCard() {
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
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_outlined, color: _accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Library Hours',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHourRow('Mondays - Fridays', '8:00 AM – 5:00 PM'),
          const SizedBox(height: 12),
          _buildHourRow('Saturdays', '8:00 AM – 5:00 PM'),
          const SizedBox(height: 12),
          _buildHourRow('Sundays & Holidays', 'Closed', isClosed: true),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'During Semester Break/ Christmas/ Summer Break - no patrons/clients services. However, if there is summer class the library is open for patrons needs.',
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: _textColor.withOpacity(0.6),
              fontSize: 12,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(String days, String hours, {bool isClosed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          days,
          style: TextStyle(
            color: _textColor.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          hours,
          style: TextStyle(
          color: isClosed
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF800000)
                  : Colors.red.shade700)
              : _primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
