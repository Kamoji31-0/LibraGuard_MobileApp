import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'book_details_screen.dart';
import 'book_list_screen.dart';
import 'profile_screen.dart';
import 'pc_reservation_rules_screen.dart';
import 'favorites_screen.dart';
import 'services/auth_service.dart';
import 'rfid_library_card_screen.dart';
import 'entry_login_screen.dart';
import 'library_service_guide_screen.dart';
import 'library_rules_screen.dart';
import 'library_staff_screen.dart';
import 'services/book_service.dart';
import 'services/favorite_service.dart';

class HomeScreen extends StatefulWidget {
  final String? firstName;
  const HomeScreen({super.key, this.firstName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedQuickAction = -1;
  String _firstName = 'Scholar'; // generic default

  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;
  final Color _accentYellow = const Color(0xFFFFC107); // Yellow matching image

  List<BookItem> _homeBooks = [];
  final BookService _bookService = BookService();
  final FavoriteService _favoriteService = FavoriteService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearching = false;

  // Search filter/sort state
  Set<String> _selectedGenres = {};
  String _availabilityFilter = 'All';
  String _selectedSort = 'A – Z';

  static const List<String> _allGenres = [
    'Technology',
    'Science',
    'Fiction',
    'History',
    'Education',
    'Children',
    'Sci-Fi',
    'Self-Help'
  ];

  static const List<String> _sortOptions = [
    'A – Z',
    'Z – A',
    'New Arrivals',
    'Popular'
  ];

  String? _profileImageUrl;
  String? _base64Image;
  Map<String, dynamic>? _userProfile;

  int _occupancyCount = 0;
  int _maxCapacity = 100;
  Timer? _occupancyTimer;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadHomeBooks();
    _fetchOccupancy();
    _startOccupancyPolling();

    if (widget.firstName != null && widget.firstName!.isNotEmpty) {
      _firstName = widget.firstName!;
    } else {
      AuthService().getFirstName().then((name) {
        if (name != null && name.isNotEmpty && mounted) {
          setState(() => _firstName = name);
        }
      });
    }
  }

  Future<void> _loadHomeBooks() async {
    final books = await _bookService.fetchBooks();
    final favoriteIds = await _favoriteService.getFavoriteIds();

    if (mounted) {
      setState(() {
        _homeBooks = books.take(8).toList(); // Show first 8 books on home
        for (var b in _homeBooks) {
          if (favoriteIds.contains(b.id)) {
            b.isFavorite = true;
          }
        }
      });
    }
  }

  Future<void> _fetchOccupancy() async {
    final data = await AuthService().getLibraryOccupancy();
    if (mounted) {
      setState(() {
        _occupancyCount = data['count'] as int? ?? 0;
        _maxCapacity = data['maxCapacity'] as int? ?? 100;
        if (_maxCapacity <= 0) _maxCapacity = 100;
      });
    }
  }

  void _startOccupancyPolling() {
    _occupancyTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchOccupancy();
    });
  }

  @override
  void dispose() {
    _occupancyTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final res = await AuthService().getProfile();
    if (res['success'] == true && mounted) {
      setState(() {
        _userProfile = res['data'];

        // Handle base64 image or URL
        final imgData = _userProfile?['image'] ??
            _userProfile?['profilePictureUrl'] ??
            _userProfile?['avatar'];
        if (imgData != null && imgData.toString().startsWith('data:image')) {
          _base64Image = imgData.toString().split(',').last;
        } else {
          _profileImageUrl = imgData;
        }

        if (_userProfile?['name'] != null) {
          _firstName = _userProfile!['name'].toString().split(' ').first;
        } else if (_userProfile?['fullName'] != null) {
          _firstName = _userProfile!['fullName'].toString().split(' ').first;
        }
      });
    } else {
      // Fallback to mock image if API fails
      if (mounted) {
        setState(() {
          _profileImageUrl =
              'https://api.dicebear.com/7.x/avataaars/png?seed=Felix';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 24),
                if (_isSearching)
                  _buildSearchResults()
                else ...[
                  _buildCapacityCard(),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BookListScreen()),
                      );
                    },
                    child: _buildSectionHeader('BOOKS', 'View all >'),
                  ),
                  const SizedBox(height: 16),
                  _buildBookList(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('LIBRARY GUIDES', ''),
                  const SizedBox(height: 16),
                  _buildGuidesList(),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.shield, color: _primaryColor, size: 28),
                ),
                const SizedBox(width: 10),
                Text(
                  'LibraGuard',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome, $_firstName!',
              style: TextStyle(
                color: _textColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Favorites heart icon
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavoritesScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(Icons.favorite_border, color: _primaryColor),
              ),
            ),
            const SizedBox(width: 10),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: _primaryColor.withOpacity(0.1),
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                child: _base64Image != null
                    ? ClipOval(
                        child: Image.memory(
                          base64Decode(_base64Image!),
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.person, color: _primaryColor),
                        ),
                      )
                    : (_profileImageUrl == null
                        ? Icon(Icons.person, color: _primaryColor)
                        : null),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchFocusNode,
      builder: (context, child) {
        final hasFocus = _searchFocusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCirc,
          transform: Matrix4.identity()..scale(hasFocus ? 1.03 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasFocus
                  ? _primaryColor.withOpacity(0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: hasFocus
                    ? _primaryColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.03),
                blurRadius: hasFocus ? 16 : 10,
                offset: Offset(0, hasFocus ? 6 : 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              final query = value.trim();
              if (query.isNotEmpty) {
                setState(() {
                  _searchQuery = query;
                  _isSearching = true;
                });
              }
            },
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
                if (_searchQuery.isEmpty) {
                  _isSearching = false;
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Search for books, guides...',
              hintStyle:
                  TextStyle(color: _textColor.withOpacity(0.4), fontSize: 13),
              prefixIcon:
                  Icon(Icons.search, color: _textColor.withOpacity(0.4)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close,
                          color: _textColor.withOpacity(0.4), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _isSearching = false;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCapacityCard() {
    final int occupied = _occupancyCount;
    final int total = _maxCapacity;
    final double occupancyPercent =
        total > 0 ? (occupied / total).clamp(0.0, 1.0) : 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor,
            const Color(0xFF5E0000), // Deeper maroon shade
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Subtle Icon Watermark Background
          Positioned(
            right: -24,
            bottom: -32,
            child: Icon(
              Icons.door_front_door,
              size: 160,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF69F0AE).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF69F0AE),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Color(0xFF69F0AE),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Library Capacity',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _fetchOccupancy,
                      child: Icon(Icons.refresh, color: Colors.white.withOpacity(0.6), size: 20),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Main Dashboard Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Capacity Statistics (Left aligned now)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Row(
                           crossAxisAlignment: CrossAxisAlignment.baseline,
                           textBaseline: TextBaseline.alphabetic,
                           children: [
                             Text(
                               '$occupied',
                               style: const TextStyle(
                                 color: Color(0xFF69F0AE),
                                 fontSize: 44,
                                 fontWeight: FontWeight.bold,
                                 height: 1.0,
                               ),
                             ),
                             Text(
                               ' / $total',
                               style: TextStyle(
                                 color: Colors.white.withOpacity(0.6),
                                 fontSize: 18,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 4),
                         Text(
                           'Students Inside',
                           style: TextStyle(
                             color: Colors.white.withOpacity(0.7),
                             fontSize: 13,
                           ),
                         ),
                      ],
                    ),
                    
                    // Status Badge (Right aligned)
                    Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                       decoration: BoxDecoration(
                         color: (occupied >= total ? Colors.redAccent : const Color(0xFF69F0AE)).withOpacity(0.15),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         occupied >= total ? 'Capacity Reached' : 'Seats Available',
                         style: TextStyle(
                           color: occupied >= total ? const Color(0xFFFF8A80) : const Color(0xFF69F0AE),
                           fontSize: 11,
                           fontWeight: FontWeight.w700,
                         ),
                       ),
                     ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Straight Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: occupancyPercent,
                    minHeight: 8,
                    backgroundColor: Colors.black.withOpacity(0.2), // Dark track
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF69F0AE)), // Green fill
                  ),
                ),
                
                const SizedBox(height: 24),
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                const SizedBox(height: 16),
                
                // Footer Schedule Row
                Builder(builder: (context) {
                  final now = DateTime.now();
                  final bool isMondayToSaturday = now.weekday >= DateTime.monday && now.weekday <= DateTime.saturday;
                  final bool isOpen = isMondayToSaturday && now.hour >= 8 && now.hour < 17;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOpen ? Icons.check_circle_outline : Icons.schedule,
                            color: isOpen ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? 'Library OPEN till 5:00 PM' : 'CLOSED, opens at 8:00 AM',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Updates ~30s',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionIcon(
            Icons.library_books, 'Borrow Books', _selectedQuickAction == 0, () {
          setState(() => _selectedQuickAction = 0);
          Future.delayed(const Duration(milliseconds: 150), () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BookListScreen()),
            ).then((_) {
              if (mounted) setState(() => _selectedQuickAction = -1);
            });
          });
        }),
        _buildActionIcon(
            Icons.desktop_mac, 'Reserve PC', _selectedQuickAction == 1, () {
          setState(() => _selectedQuickAction = 1);
          Future.delayed(const Duration(milliseconds: 150), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PcReservationRulesScreen()),
            ).then((_) {
              if (mounted) setState(() => _selectedQuickAction = -1);
            });
          });
        }),
        _buildActionIcon(Icons.badge, 'Create RFID', _selectedQuickAction == 2,
            () {
          setState(() => _selectedQuickAction = 2);
          Future.delayed(const Duration(milliseconds: 150), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const RfidLibraryCardScreen()),
            ).then((_) {
              if (mounted) setState(() => _selectedQuickAction = -1);
            });
          });
        }),
        _buildActionIcon(Icons.sensor_door_outlined, 'Entry Login',
            _selectedQuickAction == 3, () {
          setState(() => _selectedQuickAction = 3);
          Future.delayed(const Duration(milliseconds: 150), () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EntryLoginScreen()),
            ).then((_) {
              if (mounted) setState(() => _selectedQuickAction = -1);
            });
          });
        }),
      ],
    );
  }

  Widget _buildActionIcon(
      IconData icon, String label, bool isPrimary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isPrimary
                    ? _primaryColor.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isPrimary ? _primaryColor : _textColor.withOpacity(0.7),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: _textColor,
              fontSize: 11,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: _accentYellow,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: _textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        if (action.isNotEmpty)
          Text(
            action,
            style: TextStyle(
              color: _textColor.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults() {
    // Apply all filters & sorting
    List<BookItem> filtered = _homeBooks.where((book) {
      // Search query
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          book.title.toLowerCase().contains(q) ||
          book.author.toLowerCase().contains(q) ||
          book.genre.toLowerCase().contains(q);

      // Genre filter
      final matchGenre =
          _selectedGenres.isEmpty || _selectedGenres.contains(book.genre);

      // Availability filter
      final matchAvail = _availabilityFilter == 'All' ||
          (_availabilityFilter == 'Available' && book.isAvailable) ||
          (_availabilityFilter == 'Borrowed' && !book.isAvailable);

      return matchSearch && matchGenre && matchAvail;
    }).toList();

    // Sorting
    switch (_selectedSort) {
      case 'A – Z':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Z – A':
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'New Arrivals':
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Popular':
        filtered
            .sort((a, b) => (a.id.hashCode % 10).compareTo(b.id.hashCode % 10));
        break;
    }

    final hasActiveFilters =
        _selectedGenres.isNotEmpty || _availabilityFilter != 'All';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter + Sort header
          Row(
            children: [
              _headerChipButton(
                icon: Icons.tune_rounded,
                label: 'Filters',
                active: hasActiveFilters,
                onTap: _showFilterSheet,
              ),
              const SizedBox(width: 10),
              _headerChipButton(
                icon: Icons.swap_vert_rounded,
                label: _selectedSort,
                active: _selectedSort != 'A – Z',
                onTap: _showSortSheet,
              ),
              if (hasActiveFilters || _selectedSort != 'A – Z') ...[
                const Spacer(),
                GestureDetector(
                  onTap: _clearAllFilters,
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.75),
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: _textColor.withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (hasActiveFilters) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_availabilityFilter != 'All')
                    _activeChip(_availabilityFilter, () {
                      setState(() => _availabilityFilter = 'All');
                    }),
                  ..._selectedGenres.map((g) => _activeChip(g, () {
                        setState(() => _selectedGenres.remove(g));
                      })),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          Text(
            filtered.isEmpty
                ? 'No matches found'
                : 'Showing ${filtered.length} results for "$_searchQuery"',
            style: TextStyle(
              color: _textColor.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        color: _textColor.withOpacity(0.2), size: 52),
                    const SizedBox(height: 12),
                    Text(
                      'Try another keyword.',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.45),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.58, // Taller cards to prevent overflow
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                // Find the index in _homeBooks to reuse _buildBookCard
                final book = filtered[index];
                final originalIndex = _homeBooks.indexOf(book);
                return _buildBookCard(originalIndex);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBookList() {
    return SizedBox(
      height: 270, // balanced with card height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _homeBooks.length,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: _buildBookCard(index),
          );
        },
      ),
    );
  }

  Widget _buildBookCard(int index) {
    final book = _homeBooks[index];

    return Container(
      width: 190,
      height: 260, // ✅ FIXED (was 400 ❌)
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
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 115,
            width: double.infinity, // ✅ FIXED
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.book,
                      color: Colors.white.withOpacity(0.2), size: 32),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () async {
                      final isNowFavorite =
                          await _favoriteService.toggleFavorite(book.id);
                      setState(() {
                        book.isFavorite = isNowFavorite;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        book.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _primaryColor,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.genre.toUpperCase(),
            style: TextStyle(
              color: _textColor.withOpacity(0.5),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            book.title,
            style: TextStyle(
              color: _primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            book.author,
            style: TextStyle(
              color: _textColor.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: book.isAvailable
                      ? const Color(0xFF4ADE80)
                      : _primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                book.isAvailable ? 'AVAILABLE' : 'BORROWED',
                style: TextStyle(
                  color: _textColor.withOpacity(0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailsScreen(
                      bookId: book.id,
                      title: book.title,
                      author: book.author,
                      category: book.genre,
                      isAvailable: book.isAvailable,
                      description: book.description,
                      imageUrl: book.imageUrl,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _primaryColor, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                foregroundColor: _primaryColor,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'BORROW',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidesList() {
    return Column(
      children: [
        _buildGuideItem(
          title: 'Library Rules and Regulations',
          subtitle: 'Read the guidelines before your visit.',
          icon: Icons.school_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const LibraryRulesScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGuideItem(
          title: 'Library Service Guide',
          subtitle: 'Learn more about our services.',
          icon: Icons.contact_support_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const LibraryServiceGuideScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGuideItem(
          title: 'Library Staff',
          subtitle: 'Meet the staff here to help you.',
          icon: Icons.people_alt_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const LibraryStaffScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGuideItem(
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textColor.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: _textColor.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    Set<String> tempGenres = Set.from(_selectedGenres);
    String tempAvail = _availabilityFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _textColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Results',
                        style: TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: _textColor,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildFilterTitle(Icons.category_outlined, 'Genre'),
                        const SizedBox(height: 10),
                        ..._allGenres.map((genre) {
                          final selected = tempGenres.contains(genre);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(genre,
                                style:
                                    TextStyle(color: _textColor, fontSize: 14)),
                            value: selected,
                            activeColor: _primaryColor,
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) {
                                  tempGenres.add(genre);
                                } else {
                                  tempGenres.remove(genre);
                                }
                              });
                            },
                          );
                        }),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildFilterTitle(
                            Icons.library_books_outlined, 'Availability'),
                        const SizedBox(height: 10),
                        Row(
                          children: ['All', 'Available', 'Borrowed'].map((opt) {
                            final sel = tempAvail == opt;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setSheetState(() => tempAvail = opt),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? _primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: sel
                                          ? _primaryColor
                                          : _textColor.withOpacity(0.12),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      color: sel ? Colors.white : _textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              tempGenres = {};
                              tempAvail = 'All';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side:
                                BorderSide(color: _textColor.withOpacity(0.12)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Reset',
                              style: TextStyle(color: _textColor)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedGenres = tempGenres;
                              _availabilityFilter = tempAvail;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Apply Filters',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showSortSheet() {
    String tempSort = _selectedSort;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _textColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sort By',
                          style: TextStyle(
                              color: _textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: _textColor,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: _sortOptions.map((opt) {
                      return RadioListTile<String>(
                        value: opt,
                        groupValue: tempSort,
                        title: Text(opt,
                            style: TextStyle(color: _textColor, fontSize: 14)),
                        activeColor: _primaryColor,
                        onChanged: (val) {
                          setSheetState(() => tempSort = val!);
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _selectedSort = tempSort);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Apply',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildFilterTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  Widget _headerChipButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _primaryColor : _cardColor,
          borderRadius: BorderRadius.circular(20),
          border:
              active ? null : Border.all(color: _textColor.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : _textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : _textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: _textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child:
                Icon(Icons.close, color: _textColor.withOpacity(0.5), size: 13),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedGenres = {};
      _availabilityFilter = 'All';
      _selectedSort = 'A – Z';
    });
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
              _buildNavItem(Icons.person_outline, 'Profile', 3),
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
        setState(() {
          _selectedIndex = index;
        });
        if (index == 1) {
          // Books
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookListScreen()),
          ).then((_) {
            // reset nav when coming back
            setState(() {
              _selectedIndex = 0;
            });
          });
        } else if (index == 2) {
          // PC
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PcReservationRulesScreen()),
          ).then((_) {
            setState(() {
              _selectedIndex = 0;
            });
          });
        } else if (index == 3) {
          // Profile
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ).then((_) {
            setState(() {
              _selectedIndex = 0;
            });
          });
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
}
