import 'package:flutter/material.dart';
import 'book_details_screen.dart';
import 'pc_reservation_rules_screen.dart';
import 'profile_screen.dart';
import 'services/book_service.dart';
import 'services/favorite_service.dart';

// Screen

class BookListScreen extends StatefulWidget {
  final String? initialQuery;
  const BookListScreen({super.key, this.initialQuery});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  // Theme
  Color get _primary => Theme.of(context).primaryColor;
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _textDark =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;

  // All genres for filter
  static const List<String> _allGenres = [
    'Technology',
    'Science',
    'Fiction',
    'History',
    'Education',
    'Children',
    'Sci-Fi',
    'Self-Help',
  ];

  // Sort options
  static const List<String> _sortOptions = [
    'A – Z',
    'Z – A',
    'New Arrivals',
    'Popular',
  ];

  // State
  late List<BookItem> _allBooks;
  List<BookItem> _filteredBooks = [];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // Filter state
  Set<String> _selectedGenres = {};
  String _availabilityFilter = 'All'; // 'All' | 'Available' | 'Unavailable'

  // Sort state
  String _selectedSort = 'A – Z';

  // Pagination
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  int _selectedIndex = 1;
  bool _isInitialLoading = true;

  final BookService _bookService = BookService();
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchQuery = widget.initialQuery!;
      _searchController.text = _searchQuery;
    }
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isInitialLoading = true);
    final books = await _bookService.fetchBooks();
    final favoriteIds = await _favoriteService.getFavoriteIds();

    if (mounted) {
      setState(() {
        _allBooks = books;
        for (var b in _allBooks) {
          if (favoriteIds.contains(b.id)) {
            b.isFavorite = true;
          }
        }
        _isInitialLoading = false;
        _applyAll();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  //Filter + Sort logic

  void _applyAll() {
    List<BookItem> result = _allBooks.where((b) {
      // Search
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.genre.toLowerCase().contains(q);

      // Genre
      final matchGenre =
          _selectedGenres.isEmpty || _selectedGenres.contains(b.genre);

      // Availability
      final matchAvail = _availabilityFilter == 'All' ||
          (_availabilityFilter == 'Available' && b.isAvailable) ||
          (_availabilityFilter == 'Borrowed' && !b.isAvailable);

      return matchSearch && matchGenre && matchAvail;
    }).toList();

    // Sort
    switch (_selectedSort) {
      case 'A – Z':
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Z – A':
        result.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'New Arrivals':
        result.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Popular':
        result
            .sort((a, b) => (a.id.hashCode % 10).compareTo(b.id.hashCode % 10));
        break;
    }

    setState(() {
      _filteredBooks = result;
      _currentPage = 1;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedGenres = {};
      _availabilityFilter = 'All';
      _selectedSort = 'A – Z';
      _searchQuery = '';
      _searchController.clear();
    });
    _applyAll();
  }

  // ── Bottom Sheets ─────────────────────────────────────────────────────────

  void _showFilterSheet() {
    // Local copies for the sheet
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
                // Handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Books',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: _textDark,
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
                        // Genre section
                        Row(
                          children: [
                            Icon(Icons.menu_book_outlined,
                                color: _primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Genre',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._allGenres.map((genre) {
                          final selected = tempGenres.contains(genre);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(genre,
                                style:
                                    TextStyle(color: _textDark, fontSize: 14)),
                            value: selected,
                            activeColor: _primary,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
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
                        // Availability section
                        Row(
                          children: [
                            Icon(Icons.library_books_outlined,
                                color: _primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Availability',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children:
                              ['All', 'Available', 'Borrowed'].map((opt) {
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
                                    color: sel ? _primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          sel ? _primary : Colors.grey.shade300,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      color: sel ? Colors.white : _textDark,
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
                // Buttons
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
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child:
                              Text('Reset', style: TextStyle(color: _textDark)),
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
                            _applyAll();
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
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
                    color: Colors.grey.shade300,
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
                              color: _textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: _textDark,
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
                            style: TextStyle(color: _textDark, fontSize: 14)),
                        activeColor: _primary,
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
                        _applyAll();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
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

  // ── Build ─────────────────────────────────────────────────────────────────

  bool get _hasActiveFilters =>
      _selectedGenres.isNotEmpty || _availabilityFilter != 'All';

  int get _totalPages => (_filteredBooks.length / _itemsPerPage).ceil();

  List<BookItem> get _pageBooks {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredBooks.length);
    if (start >= _filteredBooks.length) return [];
    return _filteredBooks.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final count = _filteredBooks.length;
    final start = (_currentPage - 1) * _itemsPerPage + 1;
    final end = ((_currentPage) * _itemsPerPage).clamp(0, count);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _isInitialLoading
            ? Center(child: CircularProgressIndicator(color: _primary))
            : Column(
                children: [
                  // ── Light header ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Catalog',
                          style: TextStyle(
                            color: _primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EXPLORE OUR COLLECTION',
                          style: TextStyle(
                            color: _textDark.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Search bar
                        AnimatedBuilder(
                          animation: _searchFocusNode,
                          builder: (context, child) {
                            final hasFocus = _searchFocusNode.hasFocus;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCirc,
                              transform: Matrix4.identity()
                                ..scale(hasFocus ? 1.03 : 1.0),
                              transformAlignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasFocus
                                      ? _primary.withOpacity(0.5)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: hasFocus
                                        ? _primary.withOpacity(0.15)
                                        : Colors.black.withOpacity(0.08),
                                    blurRadius: hasFocus ? 16 : 10,
                                    offset: Offset(0, hasFocus ? 6 : 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style:
                                    TextStyle(color: _textDark, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Search books, authors, genres…',
                                  hintStyle: TextStyle(
                                      color: _textDark.withOpacity(0.4),
                                      fontSize: 13),
                                  prefixIcon: Icon(Icons.search,
                                      color: _textDark.withOpacity(0.4)),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.close,
                                              color: _textDark.withOpacity(0.4),
                                              size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                            _applyAll();
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                ),
                                onChanged: (v) {
                                  setState(() => _searchQuery = v.trim());
                                  _applyAll();
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Filter + Sort row
                        Row(
                          children: [
                            _headerChipButton(
                              icon: Icons.tune_rounded,
                              label: 'Filters',
                              active: _hasActiveFilters,
                              onTap: _showFilterSheet,
                            ),
                            const SizedBox(width: 10),
                            _headerChipButton(
                              icon: Icons.swap_vert_rounded,
                              label: _selectedSort,
                              active: _selectedSort != 'A – Z',
                              onTap: _showSortSheet,
                            ),
                            if (_hasActiveFilters ||
                                _selectedSort != 'A – Z') ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: _clearAllFilters,
                                child: Text(
                                  'Clear all',
                                  style: TextStyle(
                                    color: _textDark.withOpacity(0.75),
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                        _textDark.withOpacity(0.75),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Active filter chips
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (_availabilityFilter != 'All')
                                  _activeChip(_availabilityFilter, () {
                                    setState(() => _availabilityFilter = 'All');
                                    _applyAll();
                                  }),
                                ..._selectedGenres.map((g) =>
                                    _activeChip(g, () {
                                      setState(() => _selectedGenres.remove(g));
                                      _applyAll();
                                    })),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── White body ────────────────────────────────────────────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _cardColor,
                      ),
                      child: Column(
                        children: [
                          // Info bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  count == 0
                                      ? 'No books found'
                                      : 'Showing $start–$end of $count',
                                  style: TextStyle(
                                    color: _textDark.withOpacity(0.55),
                                    fontSize: 12,
                                  ),
                                ),
                                if (_totalPages > 1)
                                  Text(
                                    'Page $_currentPage / $_totalPages',
                                    style: TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Book list
                          Expanded(
                            child: count == 0
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off_rounded,
                                            size: 52,
                                            color: _textDark.withOpacity(0.2)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No books match your search.',
                                          style: TextStyle(
                                              color:
                                                  _textDark.withOpacity(0.45),
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 4, 20, 16),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.55,
                                    ),
                                    itemCount: _pageBooks.length,
                                    itemBuilder: (ctx, i) =>
                                        _buildBookCard(_pageBooks[i]),
                                  ),
                          ),

                          // Pagination
                          if (_totalPages > 1)
                            Container(
                              color: _cardColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: SafeArea(
                                top: false,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      color: _currentPage > 1
                                          ? _primary
                                          : Colors.grey.shade300,
                                      onPressed: _currentPage > 1
                                          ? () => setState(() => _currentPage--)
                                          : null,
                                    ),
                                    ..._buildPageNumbers(),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      color: _currentPage < _totalPages
                                          ? _primary
                                          : Colors.grey.shade300,
                                      onPressed: _currentPage < _totalPages
                                          ? () => setState(() => _currentPage++)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  // ── Helper widgets ────────────────────────────────────────────────────────

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
          color: active ? _primary : _cardColor,
          borderRadius: BorderRadius.circular(20),
          border:
              active ? null : Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : _textDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : _textDark,
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
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: _textDark, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child:
                Icon(Icons.close, color: _textDark.withOpacity(0.5), size: 13),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final total = _totalPages;
    int start = (_currentPage - 2).clamp(1, total);
    int end = (start + 4).clamp(1, total);
    if (end - start < 4) start = (end - 4).clamp(1, total);

    return List.generate(end - start + 1, (i) {
      final page = start + i;
      final sel = page == _currentPage;
      return GestureDetector(
        onTap: () => setState(() => _currentPage = page),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? _primary : Colors.grey.shade300),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              color: sel ? Colors.white : _textDark,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBookCard(BookItem book) {
    return Container(
      height: 240,
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
          // Book cover (navy blue)
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Dark navy
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.book,
                      color: Colors.white.withOpacity(0.2), size: 36),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () async {
                      final isNowFavorite =
                          await _favoriteService.toggleFavorite(book.id);
                      setState(() => book.isFavorite = isNowFavorite);
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
                        color: _primary,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Category
          Text(
            book.genre.toUpperCase(),
            style: TextStyle(
              color: _textDark.withOpacity(0.5),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          // Title
          Text(
            book.title,
            style: TextStyle(
              color: _primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          // Author
          Text(
            book.author,
            style: TextStyle(
              color: _textDark.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Availability Dot + Text
          Row(
            children: [
              Container(
                width: 6,
                height: 8,
                decoration: BoxDecoration(
                  color: book.isAvailable ? const Color(0xFF4ADE80) : _primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 11),
              Text(
                book.isAvailable ? 'AVAILABLE' : 'BORROWED',
                style: TextStyle(
                  color: _textDark.withOpacity(0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Outlined Maroon Button
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
                side: BorderSide(color: _primary, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                foregroundColor: _primary,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'BORROW',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
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
        if (index == _selectedIndex) return;

        setState(() {
          _selectedIndex = index;
        });

        if (index == 0) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PcReservationRulesScreen()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? _primary : _textDark.withOpacity(0.3),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? _primary : _textDark.withOpacity(0.4),
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
                color: _primary,
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
