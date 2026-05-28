import 'package:flutter/material.dart';
import 'borrow_request_screen.dart';
import 'services/favorite_service.dart';

class BookDetailsScreen extends StatefulWidget {
  final String bookId;
  final String title;
  final String author;
  final String category;
  final bool isAvailable;
  final String? description;
   final String? imageUrl;
  final String publishedIn;
  final String isbn;

  const BookDetailsScreen({
    super.key,
    required this.bookId,
    required this.title,
    required this.author,
    required this.category,
    this.isAvailable = true,
    this.description,
    this.imageUrl,
    this.publishedIn = 'Unknown Origins',
    this.isbn = 'Not Available',
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _accentColor => Theme.of(context).colorScheme.secondary;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ??
      (Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1D2939));
  Color get _cardColor => Theme.of(context).cardColor;

  final FavoriteService _favoriteService = FavoriteService();
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    // 1. Fast load from local storage
    final localStatus = await _favoriteService.isFavorited(widget.bookId);
    if (mounted) setState(() => _isFavorite = localStatus);

    // 2. Background sync with cloud
    final syncedIds = await _favoriteService.getFavoriteIds();
    if (mounted)
      setState(() => _isFavorite = syncedIds.contains(widget.bookId));
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavoriteLoading = true);
    final isNowFavorite = await _favoriteService.toggleFavorite(widget.bookId);
    if (mounted) {
      setState(() {
        _isFavorite = isNowFavorite;
        _isFavoriteLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowFavorite
                ? '${widget.title} added to favorites!'
                : 'Removed from favorites.',
          ),
          backgroundColor:
              isNowFavorite ? const Color(0xFF16A34A) : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

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
          'Back to Catalog',
          style: TextStyle(color: _textColor, fontSize: 14),
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Book Cover ──────────────────────────────────────────────────
             Container(
              width: 180,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Consistent dark navy
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardColor, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(10, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                    ? Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
            ),
            const SizedBox(height: 48),

            // ── Details ─────────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + availability badge
                  Row(
                    children: [
                      Text(
                        widget.category.toUpperCase(),
                        style: TextStyle(
                          color: _textColor.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: widget.isAvailable
                                ? const Color(0xFF4ADE80)
                                : Colors.orange,
                            size: 6,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isAvailable
                                ? 'READY FOR PICKUP'
                                : 'BORROWED',
                            style: TextStyle(
                              color: widget.isAvailable
                                  ? const Color(0xFF4ADE80)
                                  : _primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Author
                  Text(
                    'By ${widget.author}',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.8),
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Container(
                    padding: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                            color: _textColor.withOpacity(0.2), width: 2),
                      ),
                    ),
                    child: Text(
                      (widget.description != null &&
                              widget.description!.isNotEmpty)
                          ? widget.description!
                          : 'A profound addition to the Libraguard system. Dive deep into this extensive piece of literature.',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Meta info row ──────────────────────────────────────────
                  Divider(height: 1, color: Colors.black.withOpacity(0.06)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: _buildMetaInfo('ISBN', widget.isbn),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildMetaInfo('PUBLISHED IN', widget.publishedIn),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 100,
                        child: _buildMetaInfo('LIBRARY UNITS',
                            widget.isAvailable ? '1 left' : 'Borrowed'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(height: 1, color: Colors.black.withOpacity(0.06)),
                  const SizedBox(height: 48),

                  // ── Checkout Button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.isAvailable
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BorrowRequestScreen(
                                    bookId: widget.bookId,
                                    bookTitle: widget.title,
                                    author: widget.author,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        disabledBackgroundColor:
                            Theme.of(context).disabledColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.phone_android,
                          color: Colors.white, size: 20),
                      label: Text(
                        widget.isAvailable ? 'BORROW BOOK' : 'BORROWED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Add to Favorites Button ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isFavoriteLoading ? null : _toggleFavorite,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _cardColor,
                        foregroundColor:
                            _isFavorite ? _primaryColor : _textColor,
                        side: BorderSide(
                          color: _isFavorite
                              ? _primaryColor
                              : _textColor.withOpacity(0.15),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isFavoriteLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _accentColor,
                              ),
                            )
                          : Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? _primaryColor
                                  : _textColor.withOpacity(0.6),
                            ),
                      label: Text(
                        _isFavorite ? 'SAVED TO FAVORITES' : 'ADD TO FAVORITES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: _isFavorite
                              ? _primaryColor
                              : _textColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, color: Colors.white.withOpacity(0.2), size: 40),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.title,
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.author,
            style: TextStyle(
              color: _textColor.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textColor.withOpacity(0.4),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: _textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
