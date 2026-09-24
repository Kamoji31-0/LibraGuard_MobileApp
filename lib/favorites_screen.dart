import 'package:flutter/material.dart';
import 'book_details_screen.dart';
import 'services/book_service.dart';
import 'services/favorite_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _accentColor => Theme.of(context).colorScheme.secondary;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;

  final BookService _bookService = BookService();
  final FavoriteService _favoriteService = FavoriteService();

  List<BookItem> _favoriteBooks = [];
  bool _isLoading = true;

Set<String> _selectedGenres = {};
  String _availabilityFilter = 'All';
  String _selectedSort = 'A – Z';

  static const List<String> _allGenres = [
    'Arts',
    'Business & Management',
    'Criminology',
    'Culinary Arts',
    'Education',
    'Engineering',
    'Fiction',
    'Filipino Studies',
    'History',
    'Hospitality Management',
    'IT & Programming',
    'Law, Govt & Social',
    'Mathematics',
    'Nursing & Health',
    'Psychology',
    'Science',
    'Others',
  ];

  static const List<String> _sortOptions = [
    'A – Z',
    'Z – A',
    'New Arrivals',
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {

    final ids = await _favoriteService.getFavoriteIds();
    final cached = await _bookService.getPersistentCachedBooks();

final cachedFavorites = cached.where((b) => ids.contains(b.id)).toList();

    if (cachedFavorites.isNotEmpty && mounted) {
      setState(() {
        _favoriteBooks = cachedFavorites;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = true);
    }

final books = await _bookService.fetchBooksByIds(ids);

    if (mounted) {
      setState(() {
        _favoriteBooks = books;
        _isLoading = false;
      });
    }
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
                        'Filter Favorites',
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
                            activeColor: _accentColor,
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
                            backgroundColor: _accentColor,
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
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
                            activeColor: _accentColor,
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
                            backgroundColor: _accentColor,
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
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildFilterTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _accentColor, size: 18),
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

  @override
  Widget build(BuildContext context) {

    List<BookItem> filteredBooks = _favoriteBooks.where((book) {

      final matchGenre =
          _selectedGenres.isEmpty || _selectedGenres.contains(book.displayGenre);

final matchAvail = _availabilityFilter == 'All' ||
          (_availabilityFilter == 'Available' && book.isAvailable) ||
          (_availabilityFilter == 'Borrowed' && !book.isAvailable);

      return matchGenre && matchAvail;
    }).toList();

switch (_selectedSort) {
      case 'A – Z':
        filteredBooks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Z – A':
        filteredBooks.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'New Arrivals':
        filteredBooks.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    final hasActiveFilters =
        _selectedGenres.isNotEmpty || _availabilityFilter != 'All';

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF800000)))
            : RefreshIndicator(
                onRefresh: _loadFavorites,
                color: _accentColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Favorites',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MY SAVED BOOKS',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

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

                      const SizedBox(height: 32),

                      if (filteredBooks.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                Icon(
                                    hasActiveFilters
                                        ? Icons.search_off
                                        : Icons.favorite_border,
                                    size: 64,
                                    color: _textColor.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text(
                                  hasActiveFilters
                                      ? 'No matching favorites.'
                                      : 'No favorites yet.',
                                  style: TextStyle(
                                      color: _textColor.withOpacity(0.5),
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Builder(
                          builder: (context) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final int crossAxisCount = screenWidth >= 900 ? 4 : (screenWidth >= 600 ? 3 : 2);
                            final double cardWidth = (screenWidth - 48 - (crossAxisCount - 1) * 16) / crossAxisCount;
                            final double imageHeight = (cardWidth - 20) / 1.3;
                            final double mainAxisExtent = imageHeight + 142;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                mainAxisExtent: mainAxisExtent,
                              ),
                              itemCount: filteredBooks.length,
                              itemBuilder: (context, index) {
                                final book = filteredBooks[index];
                                return _buildFavoriteBookCard(
                                  context: context,
                                  book: book,
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFavoriteBookCard({
    required BuildContext context,
    required BookItem book,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coverColor = _genreCoverColor(book.displayGenre, isDark);
    final iconColor = isDark
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.15);

    return GestureDetector(
      onTap: () {
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
              publishedIn: book.publishedIn,
              isbn: book.isbn,
              totalCopies: book.totalCopies,
              availableCopies: book.availableCopies,
            ),
          ),
        );
      },
      child: Container(
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
          mainAxisSize: MainAxisSize.max,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: coverColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                book.imageUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.menu_book,
                                  color: iconColor,
                                  size: 32,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.menu_book,
                              color: iconColor,
                              size: 32,
                            ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () async {
                          await _favoriteService.toggleFavorite(book.id);
                          _loadFavorites();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: _accentColor,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              book.displayGenre.toUpperCase(),
              style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book.title,
              style: TextStyle(
                color: _accentColor,
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
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? (book.availableCopies > 0
                        ? const Color(0x1F4ADE80)
                        : const Color(0x1FEF4444))
                    : (book.availableCopies > 0
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? (book.availableCopies > 0
                          ? const Color(0x3D4ADE80)
                          : const Color(0x3DEF4444))
                      : (book.availableCopies > 0
                          ? const Color(0xFFC8E6C9)
                          : const Color(0xFFFFCDD2)),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? (book.availableCopies > 0
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFF87171))
                          : (book.availableCopies > 0
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '${book.availableCopies} / ${book.totalCopies} copies available',
                      style: TextStyle(
                        color: isDark
                            ? (book.availableCopies > 0
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFF87171))
                            : (book.availableCopies > 0
                                ? const Color(0xFF1B5E20)
                                : const Color(0xFFB71C1C)),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
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
                        publishedIn: book.publishedIn,
                        isbn: book.isbn,
                        totalCopies: book.totalCopies,
                        availableCopies: book.availableCopies,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _accentColor, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'BORROW',
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _genreCoverColor(String genre, bool isDark) {
    const colors = {
      'Arts':                   Color(0xFFF7C5D0),
      'Business & Management':  Color(0xFFFDE7C8),
      'Criminology':            Color(0xFFD4C5F9),
      'Culinary Arts':          Color(0xFFFFF3CC),
      'Education':              Color(0xFFC8E6C9),
      'Engineering':            Color(0xFFB3E5FC),
      'Fiction':                Color(0xFFE8D5F5),
      'Filipino Studies':       Color(0xFFFFCCBC),
      'History':                Color(0xFFD7ECD0),
      'Hospitality Management': Color(0xFFFFC1B0),
      'IT & Programming':       Color(0xFFBBDEFB),
      'Law, Govt & Social':     Color(0xFFCCE5FF),
      'Mathematics':            Color(0xFFE1F5C4),
      'Nursing & Health':       Color(0xFFB2EBF2),
      'Psychology':             Color(0xFFFFD7E8),
      'Science':                Color(0xFFDCEDC8),
      'Others':                 Color(0xFFECEFF1),
    };
    final base = colors[genre] ?? const Color(0xFFECEFF1);
    return isDark ? base.withOpacity(0.22) : base;
  }
}
