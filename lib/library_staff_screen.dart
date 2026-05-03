import 'package:flutter/material.dart';

class LibraryStaffScreen extends StatefulWidget {
  const LibraryStaffScreen({super.key});

  @override
  State<LibraryStaffScreen> createState() => _LibraryStaffScreenState();
}

class _LibraryStaffScreenState extends State<LibraryStaffScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
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
        title: const SizedBox.shrink(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Library Staff',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'MEET OUR DEDICATED TEAM',
                style: TextStyle(
                  color: _textColor.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              _buildStaffSection(context),
              const SizedBox(height: 32),
              _buildHoursCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
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
              Icon(Icons.badge_outlined, color: _primaryColor, size: 24),
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
          Column(
            children: [
              Row(
                children: [
                  _buildStaffMember(
                      context, 'RP', 'Ria C. Pacia', 'Library Staff',
                      imagePath: 'assets/images/Pacia.jpg'),
                  const SizedBox(width: 16),
                  _buildStaffMember(
                      context, 'JF', 'Jacqueline P. Fiesta', 'Library Staff',
                      imagePath: 'assets/images/Fiesta.jpg'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStaffMember(
                      context, 'JA', 'Joe Pepe J. Acosta', 'Library Staff',
                      imagePath: 'assets/images/Acosta.jpg'),
                  const SizedBox(width: 16),
                  _buildStaffMember(
                      context, 'IE', 'Imelda S. Esquejo', 'Library Staff',
                      imagePath: 'assets/images/Esquejo.jpg'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 96) / 2,
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
        : Expanded(
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
            backgroundColor: _primaryColor,
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
              Icon(Icons.access_time_outlined, color: _primaryColor, size: 24),
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
