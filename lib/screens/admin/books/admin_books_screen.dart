import 'package:flutter/material.dart';

import '../../../models/book_model.dart';
import '../../../repositories/shop_repository.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() =>
      _AdminBooksScreenState();
}

class _AdminBooksScreenState
    extends State<AdminBooksScreen> {
  static const Color purple = Color(0xFF350044);
  static const Color lightBackground = Color(0xFFF7F5F8);

  final ShopRepository _repository =
      ShopRepository.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery =
            _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER BOOKS
  // ============================================================

  List<BookModel> _filterBooks(
    List<BookModel> books,
  ) {
    return books.where((book) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          book.title.toLowerCase().contains(_searchQuery) ||
          book.author.toLowerCase().contains(_searchQuery) ||
          book.category.toLowerCase().contains(_searchQuery);

      bool matchesFilter = true;

      switch (_filter) {
        case 'Published':
          matchesFilter = book.isPublished;
          break;

        case 'Unpublished':
          matchesFilter = !book.isPublished;
          break;

        case 'Featured':
          matchesFilter = book.isFeatured;
          break;

        case 'Not Featured':
          matchesFilter = !book.isFeatured;
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ============================================================
  // ADD BOOK
  // ============================================================

  Future<void> _showAddBookDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _BookFormDialog(),
    );

    if (result == true && mounted) {
      _showMessage('Book added successfully.');
    }
  }

  // ============================================================
  // EDIT BOOK
  // ============================================================

  Future<void> _showEditBookDialog(
    BookModel book,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _BookFormDialog(book: book),
    );

    if (result == true && mounted) {
      _showMessage('Book updated successfully.');
    }
  }

  // ============================================================
  // DELETE BOOK
  // ============================================================

  Future<void> _deleteBook(
    BookModel book,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Book',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${book.title}"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    _showLoadingDialog();

    try {
      await _repository.deleteBook(book.id);

      if (!mounted) return;

      Navigator.pop(context);

      _showMessage(
        'Book deleted successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      _showError(
        'Unable to delete book: $e',
      );
    }
  }

  // ============================================================
  // PUBLISH
  // ============================================================

  Future<void> _togglePublished(
    BookModel book,
  ) async {
    try {
      await _repository.setPublished(
        bookId: book.id,
        published: !book.isPublished,
      );

      if (!mounted) return;

      _showMessage(
        book.isPublished
            ? 'Book unpublished.'
            : 'Book published.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to update publication status: $e',
      );
    }
  }

  // ============================================================
  // FEATURED
  // ============================================================

  Future<void> _toggleFeatured(
    BookModel book,
  ) async {
    try {
      await _repository.setFeatured(
        bookId: book.id,
        featured: !book.isFeatured,
      );

      if (!mounted) return;

      _showMessage(
        book.isFeatured
            ? 'Book removed from featured.'
            : 'Book marked as featured.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to update featured status: $e',
      );
    }
  }

  // ============================================================
  // LOADING DIALOG
  // ============================================================

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: StreamBuilder<List<BookModel>>(
              stream:
                  _repository.adminBooksStream(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(
                    snapshot.error.toString(),
                  );
                }

                final books =
                    snapshot.data ?? [];

                final filteredBooks =
                    _filterBooks(books);

                if (books.isEmpty) {
                  return _buildEmptyState();
                }

                if (filteredBooks.isEmpty) {
                  return _buildNoResultsState();
                }

                return _buildBooksContent(
                  filteredBooks,
                  books.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        28,
        24,
        28,
        20,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Books',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w800,
                        color: purple,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Manage your RHIC digital books.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    _showAddBookDialog,
                icon: const Icon(
                  Icons.add,
                  size: 19,
                ),
                label:
                    const Text('Add Book'),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                      _searchController,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Search books, authors or categories...',
                    prefixIcon:
                        const Icon(
                      Icons.search,
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController
                                      .clear();
                                },
                                icon:
                                    const Icon(
                                  Icons.clear,
                                ),
                              )
                            : null,
                    filled: true,
                    fillColor:
                        lightBackground,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                decoration:
                    BoxDecoration(
                  color: lightBackground,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child:
                      DropdownButton<String>(
                    value: _filter,
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text('All'),
                      ),
                      DropdownMenuItem(
                        value: 'Published',
                        child:
                            Text('Published'),
                      ),
                      DropdownMenuItem(
                        value: 'Unpublished',
                        child:
                            Text('Unpublished'),
                      ),
                      DropdownMenuItem(
                        value: 'Featured',
                        child:
                            Text('Featured'),
                      ),
                      DropdownMenuItem(
                        value: 'Not Featured',
                        child: Text(
                          'Not Featured',
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _filter = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKS CONTENT
  // ============================================================

  Widget _buildBooksContent(
    List<BookModel> books,
    int totalBooks,
  ) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        int columns = 1;

        if (constraints.maxWidth >= 1200) {
          columns = 4;
        } else if (constraints.maxWidth >=
            850) {
          columns = 3;
        } else if (constraints.maxWidth >=
            550) {
          columns = 2;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '$totalBooks ${totalBooks == 1 ? 'book' : 'books'} total',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: books.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: .72,
                ),
                itemBuilder: (
                  context,
                  index,
                ) {
                  return _buildBookCard(
                    books[index],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BOOK CARD
  // ============================================================

  Widget _buildBookCard(
    BookModel book,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9E5EA),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: book.coverUrl
                          .trim()
                          .isNotEmpty
                      ? Image.network(
                          book.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return _coverPlaceholder();
                          },
                        )
                      : _coverPlaceholder(),
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  child: _statusBadge(
                    book.isPublished,
                  ),
                ),

                if (book.isFeatured)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.amber
                            .shade700,
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color:
                                Colors.white,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Featured',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            flex: 4,
            child: Padding(
              padding:
                  const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    book.category
                        .toUpperCase(),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: Color(
                        0xFFF7931E,
                      ),
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    book.title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: purple,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'By ${book.author}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    book.formattedPrice,
                    style:
                        const TextStyle(
                      color: purple,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed: () =>
                              _showEditBookDialog(
                            book,
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 9,
                            ),
                            side:
                                const BorderSide(
                              color: purple,
                            ),
                            foregroundColor:
                                purple,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                9,
                              ),
                            ),
                          ),
                          child:
                              const Text(
                            'Edit',
                            style:
                                TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 7),

                      PopupMenuButton<String>(
                        onSelected:
                            (value) {
                          switch (value) {
                            case 'publish':
                              _togglePublished(
                                book,
                              );
                              break;

                            case 'featured':
                              _toggleFeatured(
                                book,
                              );
                              break;

                            case 'delete':
                              _deleteBook(
                                book,
                              );
                              break;
                          }
                        },
                        itemBuilder:
                            (context) {
                          return [
                            PopupMenuItem(
                              value:
                                  'publish',
                              child: Text(
                                book.isPublished
                                    ? 'Unpublish'
                                    : 'Publish',
                              ),
                            ),
                            PopupMenuItem(
                              value:
                                  'featured',
                              child: Text(
                                book.isFeatured
                                    ? 'Remove Featured'
                                    : 'Make Featured',
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value:
                                  'delete',
                              child: Text(
                                'Delete',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.red,
                                ),
                              ),
                            ),
                          ];
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration:
                              BoxDecoration(
                            border: Border.all(
                              color:
                                  const Color(
                                0xFFE0DCE2,
                              ),
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              9,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons.more_vert,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    bool published,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: published
            ? const Color(0xFF087F75)
            : Colors.black54,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        published
            ? 'Published'
            : 'Unpublished',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // COVER PLACEHOLDER
  // ============================================================

  Widget _coverPlaceholder() {
    return Container(
      color: const Color(0xFFF1E8F3),
      child: const Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 55,
          color: purple,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: purple.withValues(
                  alpha: .08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.library_books_outlined,
                size: 38,
                color: purple,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No books yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Add your first digital book to the RHIC shop.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed:
                  _showAddBookDialog,
              icon:
                  const Icon(Icons.add),
              label:
                  const Text('Add Book'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO SEARCH RESULTS
  // ============================================================

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 55,
            color: Colors.black26,
          ),
          const SizedBox(height: 15),
          const Text(
            'No matching books',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try another search or filter.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 55,
              color: Colors.red,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load books',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// BOOK FORM DIALOG
// ==================================================================

class _BookFormDialog extends StatefulWidget {
  final BookModel? book;

  const _BookFormDialog({
    this.book,
  });

  @override
  State<_BookFormDialog> createState() =>
      _BookFormDialogState();
}

class _BookFormDialogState
    extends State<_BookFormDialog> {
  static const Color purple =
      Color(0xFF350044);

  final ShopRepository _repository =
      ShopRepository.instance;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _titleController;

  late final TextEditingController
      _authorController;

  late final TextEditingController
      _descriptionController;

  late final TextEditingController
      _categoryController;

  late final TextEditingController
      _coverUrlController;

  late final TextEditingController
      _ebookUrlController;

  late final TextEditingController
      _priceController;

  String _currency = 'NGN';

  bool _isPublished = false;
  bool _isFeatured = false;
  bool _saving = false;

  bool get _editing =>
      widget.book != null;

  @override
  void initState() {
    super.initState();

    final book = widget.book;

    _titleController =
        TextEditingController(
      text: book?.title ?? '',
    );

    _authorController =
        TextEditingController(
      text: book?.author ?? '',
    );

    _descriptionController =
        TextEditingController(
      text: book?.description ?? '',
    );

    _categoryController =
        TextEditingController(
      text: book?.category ?? '',
    );

    _coverUrlController =
        TextEditingController(
      text: book?.coverUrl ?? '',
    );

    _ebookUrlController =
        TextEditingController(
      text: book?.ebookUrl ?? '',
    );

    _priceController =
        TextEditingController(
      text: book == null
          ? ''
          : book.price.toString(),
    );

    _currency =
        book?.currency ?? 'NGN';

    _isPublished =
        book?.isPublished ?? false;

    _isFeatured =
        book?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _coverUrlController.dispose();
    _ebookUrlController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final price = double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null || price < 0) {
      _showError(
        'Please enter a valid price.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_editing) {
        await _repository.updateBook(
          bookId: widget.book!.id,
          title:
              _titleController.text,
          author:
              _authorController.text,
          description:
              _descriptionController.text,
          category:
              _categoryController.text,
          coverUrl:
              _coverUrlController.text,
          ebookUrl:
              _ebookUrlController.text,
          price: price,
          currency: _currency,
          isPublished:
              _isPublished,
          isFeatured:
              _isFeatured,
        );
      } else {
        await _repository.createBook(
          title:
              _titleController.text,
          author:
              _authorController.text,
          description:
              _descriptionController.text,
          category:
              _categoryController.text,
          coverUrl:
              _coverUrlController.text,
          ebookUrl:
              _ebookUrlController.text,
          price: price,
          currency: _currency,
          isPublished:
              _isPublished,
          isFeatured:
              _isFeatured,
        );
      }

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showError(
        'Unable to save book: $e',
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _field({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint:
              maxLines > 1,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide:
                const BorderSide(
              color: purple,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COVER PREVIEW
  // ============================================================

  Widget _buildCoverPreview() {
    final url =
        _coverUrlController.text.trim();

    if (url.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1E8F3),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            size: 50,
            color: purple,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(14),
      child: Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF1E8F3),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .broken_image_outlined,
                    size: 40,
                    color: Colors.black38,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Unable to preview image',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _editing
            ? 'Edit Book'
            : 'Add Book',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: purple,
        ),
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                // ------------------------------------------------
                // COVER PREVIEW
                // ------------------------------------------------

                _buildCoverPreview(),

                const SizedBox(height: 14),

                _field(
                  controller:
                      _coverUrlController,
                  label: 'Cover Image URL',
                  hint:
                      'https://example.com/cover.jpg',
                  keyboardType:
                      TextInputType.url,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter a cover image URL';
                    }

                    return null;
                  },
                ),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------

                _field(
                  controller:
                      _titleController,
                  label: 'Book Title',
                  hint:
                      'Enter book title',
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter the book title';
                    }

                    return null;
                  },
                ),

                // ------------------------------------------------
                // AUTHOR
                // ------------------------------------------------

                _field(
                  controller:
                      _authorController,
                  label: 'Author',
                  hint:
                      'Enter author name',
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter the author';
                    }

                    return null;
                  },
                ),

                // ------------------------------------------------
                // CATEGORY
                // ------------------------------------------------

                _field(
                  controller:
                      _categoryController,
                  label: 'Category',
                  hint:
                      'e.g. Faith, Leadership, Prayer',
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter a category';
                    }

                    return null;
                  },
                ),

                // ------------------------------------------------
                // DESCRIPTION
                // ------------------------------------------------

                _field(
                  controller:
                      _descriptionController,
                  label: 'Description',
                  hint:
                      'Describe the book',
                  maxLines: 5,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter a description';
                    }

                    return null;
                  },
                ),

                // ------------------------------------------------
                // EBOOK URL
                // ------------------------------------------------

                _field(
                  controller:
                      _ebookUrlController,
                  label: 'eBook URL',
                  hint:
                      'https://example.com/book.pdf',
                  keyboardType:
                      TextInputType.url,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter the eBook URL';
                    }

                    return null;
                  },
                ),

                // ------------------------------------------------
                // PRICE + CURRENCY
                // ------------------------------------------------

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        controller:
                            _priceController,
                        label: 'Price',
                        hint: '0',
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter price';
                          }

                          final price =
                              double.tryParse(
                            value.trim(),
                          );

                          if (price == null ||
                              price < 0) {
                            return 'Invalid price';
                          }

                          return null;
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: DropdownButtonFormField<
                          String>(
                        initialValue:
                            _currency,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Currency',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'NGN',
                            child:
                                Text('NGN'),
                          ),
                          DropdownMenuItem(
                            value: 'USD',
                            child:
                                Text('USD'),
                          ),
                          DropdownMenuItem(
                            value: 'GBP',
                            child:
                                Text('GBP'),
                          ),
                          DropdownMenuItem(
                            value: 'EUR',
                            child:
                                Text('EUR'),
                          ),
                        ],
                        onChanged:
                            _saving
                                ? null
                                : (value) {
                                    if (value ==
                                        null) {
                                      return;
                                    }

                                    setState(() {
                                      _currency =
                                          value;
                                    });
                                  },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // ------------------------------------------------
                // PUBLISHED
                // ------------------------------------------------

                SwitchListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  title: const Text(
                    'Published',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'Make this book visible in the shop.',
                  ),
                  value:
                      _isPublished,
                  activeThumbColor:
                      purple,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _isPublished =
                                value;
                          });
                        },
                ),

                // ------------------------------------------------
                // FEATURED
                // ------------------------------------------------

                SwitchListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  title: const Text(
                    'Featured',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'Show this book in featured books.',
                  ),
                  value:
                      _isFeatured,
                  activeThumbColor:
                      purple,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _isFeatured =
                                value;
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
          child:
              const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _saving ? null : _save,
          style:
              ElevatedButton.styleFrom(
            backgroundColor: purple,
            foregroundColor:
                Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _editing
                      ? 'Save Changes'
                      : 'Add Book',
                ),
        ),
      ],
    );
  }
}

