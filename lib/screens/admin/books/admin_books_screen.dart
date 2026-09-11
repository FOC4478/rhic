import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/book_model.dart';
import '../../../repositories/shop_repository.dart';
import '../../../services/b2_upload_service.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({
    super.key,
  });

  @override
  State<AdminBooksScreen> createState() =>
      _AdminBooksScreenState();
}

class _AdminBooksScreenState
    extends State<AdminBooksScreen> {
  static const Color _primary =
      Color(0xFF350044);

  final ShopRepository _repository =
      ShopRepository.instance;

  final B2UploadService _b2UploadService =
      B2UploadService.instance;

  final TextEditingController
      _searchController =
      TextEditingController();

  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'Published',
    'Unpublished',
    'Featured',
    'Not Featured',
  ];

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
    final search =
        _searchController.text
            .trim()
            .toLowerCase();

    return books.where((book) {
      final matchesSearch =
          search.isEmpty ||
          book.title
              .toLowerCase()
              .contains(search) ||
          book.author
              .toLowerCase()
              .contains(search) ||
          book.category
              .toLowerCase()
              .contains(search);

      bool matchesFilter = true;

      switch (_selectedFilter) {
        case 'Published':
          matchesFilter =
              book.isPublished;
          break;

        case 'Unpublished':
          matchesFilter =
              !book.isPublished;
          break;

        case 'Featured':
          matchesFilter =
              book.isFeatured;
          break;

        case 'Not Featured':
          matchesFilter =
              !book.isFeatured;
          break;

        default:
          matchesFilter = true;
      }

      return matchesSearch &&
          matchesFilter;
    }).toList();
  }

  // ============================================================
  // OPEN BOOK FORM
  // ============================================================

  Future<void> _openBookForm({
    BookModel? book,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _BookFormDialog(
          book: book,
        );
      },
    );
  }

  // ============================================================
  // DELETE BOOK
  // ============================================================

  Future<void> _deleteBook(
    BookModel book,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete book?',
          ),
          content: Text(
            'Are you sure you want to delete "${book.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deleteBook(
        book.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Book deleted.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // BOOK COVER WIDGET
  // ============================================================

  Widget _buildBookCover(
    BookModel book,
  ) {
    if (book.coverObjectKey
        .trim()
        .isEmpty) {
      return _coverPlaceholder();
    }

    return FutureBuilder<String>(
      future:
          _b2UploadService
              .getBookCoverUrl(
        bookId: book.id,
      ),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            color: const Color(
              0xFFEDE6F0,
            ),
            alignment:
                Alignment.center,
            child:
                const SizedBox(
              width: 28,
              height: 28,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!
                .trim()
                .isEmpty) {
          return _coverPlaceholder();
        }

        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          width:
              double.infinity,
          height:
              double.infinity,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _coverPlaceholder();
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF9F7FA),
      appBar: AppBar(
        backgroundColor:
            _primary,
        foregroundColor:
            Colors.white,
        title:
            const Text(
          'Manage Books',
        ),
        actions: [
          IconButton(
            onPressed: () {
              _openBookForm();
            },
            icon:
                const Icon(
              Icons.add,
            ),
            tooltip:
                'Add book',
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            _primary,
        foregroundColor:
            Colors.white,
        onPressed: () {
          _openBookForm();
        },
        icon:
            const Icon(
          Icons.add,
        ),
        label:
            const Text(
          'Add Book',
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child:
                StreamBuilder<
                    List<BookModel>>(
              stream: _repository
                  .adminBooksStream(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(
                        24,
                      ),
                      child:
                          Text(
                        'Unable to load books.\n\n${snapshot.error}',
                        textAlign:
                            TextAlign
                                .center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final books =
                    _filterBooks(
                  snapshot.data!,
                );

                if (books.isEmpty) {
                  return const Center(
                    child: Text(
                      'No books found.',
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (
                    context,
                    constraints,
                  ) {
                    int columns = 1;

                    if (constraints
                            .maxWidth >=
                        1200) {
                      columns = 4;
                    } else if (constraints
                            .maxWidth >=
                        850) {
                      columns = 3;
                    } else if (constraints
                            .maxWidth >=
                        550) {
                      columns = 2;
                    }

                    return GridView
                        .builder(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        20,
                        10,
                        20,
                        100,
                      ),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            columns,
                        crossAxisSpacing:
                            16,
                        mainAxisSpacing:
                            16,
                        childAspectRatio:
                            0.70,
                      ),
                      itemCount:
                          books.length,
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        return _buildBookCard(
                          books[index],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH + FILTERS
  // ============================================================

  Widget _buildSearchAndFilters() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        10,
      ),
      child: Column(
        children: [
          TextField(
            controller:
                _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration:
                InputDecoration(
              hintText:
                  'Search title, author or category',
              prefixIcon:
                  const Icon(
                Icons.search,
              ),
              suffixIcon:
                  _searchController
                          .text
                          .isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController
                                .clear();
                            setState(
                                () {});
                          },
                          icon:
                              const Icon(
                            Icons.close,
                          ),
                        )
                      : null,
              filled: true,
              fillColor:
                  Colors.white,
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  16,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          SizedBox(
            height: 42,
            child:
                ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  _filters.length,
              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                width: 8,
              ),
              itemBuilder: (
                context,
                index,
              ) {
                final filter =
                    _filters[index];

                final selected =
                    filter ==
                        _selectedFilter;

                return ChoiceChip(
                  label:
                      Text(filter),
                  selected:
                      selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter =
                          filter;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOK CARD
  // ============================================================

  Widget _buildBookCard(
    BookModel book,
  ) {
    return Card(
      clipBehavior:
          Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBookCover(
                  book,
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  child:
                      Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          book.isPublished
                              ? Colors
                                  .green
                              : Colors
                                  .orange,
                      borderRadius:
                          BorderRadius
                              .circular(
                        30,
                      ),
                    ),
                    child:
                        Text(
                      book.isPublished
                          ? 'Published'
                          : 'Draft',
                      style:
                          const TextStyle(
                        color: Colors
                            .white,
                        fontSize:
                            11,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ),
                ),

                if (book.isFeatured)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child:
                        CircleAvatar(
                      radius: 17,
                      backgroundColor:
                          Colors.white,
                      child:
                          Icon(
                        Icons.star,
                        color: Colors
                            .orange,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets
                    .all(
              14,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  book.category,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style: TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  book.formattedPrice,
                  style:
                      const TextStyle(
                    color: _primary,
                    fontWeight:
                        FontWeight
                            .bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton
                              .icon(
                        onPressed:
                            () {
                          _openBookForm(
                            book:
                                book,
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .edit_outlined,
                        ),
                        label:
                            const Text(
                          'Edit',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    PopupMenuButton<
                        String>(
                      onSelected:
                          (value) async {
                        try {
                          switch (
                              value) {
                            case 'publish':
                              await _repository
                                  .setPublished(
                                bookId:
                                    book.id,
                                published:
                                    !book
                                        .isPublished,
                              );
                              break;

                            case 'feature':
                              await _repository
                                  .setFeatured(
                                bookId:
                                    book.id,
                                featured:
                                    !book
                                        .isFeatured,
                              );
                              break;

                            case 'delete':
                              await _deleteBook(
                                book,
                              );
                              break;
                          }
                        } catch (
                            error) {
                          if (!mounted) {
                            return;
                          }

                          ScaffoldMessenger
                                  .of(
                            context,
                          ).showSnackBar(
                            SnackBar(
                              content:
                                  Text(
                                error
                                    .toString()
                                    .replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                              ),
                            ),
                          );
                        }
                      },
                      itemBuilder:
                          (context) =>
                              [
                        PopupMenuItem(
                          value:
                              'publish',
                          child:
                              Text(
                            book.isPublished
                                ? 'Unpublish'
                                : 'Publish',
                          ),
                        ),
                        PopupMenuItem(
                          value:
                              'feature',
                          child:
                              Text(
                            book.isFeatured
                                ? 'Remove Featured'
                                : 'Make Featured',
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value:
                              'delete',
                          child:
                              Text(
                            'Delete',
                            style:
                                TextStyle(
                              color:
                                  Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color:
          const Color(0xFFEDE6F0),
      alignment:
          Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        size: 60,
        color: _primary,
      ),
    );
  }
}

// ============================================================
// BOOK FORM
// ============================================================

class _BookFormDialog
    extends StatefulWidget {
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
  static const Color _primary =
      Color(0xFF350044);

  final ShopRepository _repository =
      ShopRepository.instance;

  final B2UploadService
      _b2UploadService =
      B2UploadService.instance;

  final GlobalKey<FormState>
      _formKey =
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
      _priceController;

  String _currency = 'NGN';

  bool _isPublished = false;

  bool _isFeatured = false;

  bool _isSaving = false;

  bool _isUploadingEbook = false;

  bool _isUploadingCover = false;

  String _ebookObjectKey = '';

  String _coverObjectKey = '';

  String? _selectedEbookName;

  String? _selectedCoverName;

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
      text:
          book?.description ?? '',
    );

    _categoryController =
        TextEditingController(
      text:
          book?.category ?? '',
    );

    _priceController =
        TextEditingController(
      text:
          book == null
              ? ''
              : book.price
                  .toString(),
    );

    _currency =
        book?.currency ?? 'NGN';

    _isPublished =
        book?.isPublished ??
            false;

    _isFeatured =
        book?.isFeatured ??
            false;

    _ebookObjectKey =
        book?.ebookObjectKey ?? '';

    _coverObjectKey =
        book?.coverObjectKey ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  // ============================================================
  // SELECT + UPLOAD COVER
  // ============================================================

  Future<void>
      _selectAndUploadCover() async {
    if (_isUploadingCover) {
      return;
    }

    try {
      final files =
          await FilePicker.pickFiles(
        type:
            FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
        ],
      );

      if (files.isEmpty) {
        return;
      }

      final file =
          files.first;

      final bytes =
          await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception(
          'Unable to read the selected cover image.',
        );
      }

      final extension =
          file.extension
              ?.toLowerCase();

      String contentType;

      switch (extension) {
        case 'png':
          contentType =
              'image/png';
          break;

        case 'webp':
          contentType =
              'image/webp';
          break;

        case 'jpg':
        case 'jpeg':
          contentType =
              'image/jpeg';
          break;

        default:
          throw Exception(
            'Please select a JPG, PNG, or WEBP image.',
          );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingCover =
            true;
        _selectedCoverName =
            file.name;
      });

      final uploadResult =
          await _b2UploadService
              .uploadFile(
        bytes: bytes,
        fileName:
            file.name,
        contentType:
            contentType,
        mediaType:
            'image',
        resourceType:
            'book',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _coverObjectKey =
            uploadResult
                .objectKey;
        _isUploadingCover =
            false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Cover image uploaded successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingCover =
            false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // SELECT + UPLOAD EBOOK
  // ============================================================

  Future<void>
      _selectAndUploadEbook() async {
    if (_isUploadingEbook) {
      return;
    }

    try {
      final files =
          await FilePicker.pickFiles(
        type:
            FileType.custom,
        allowedExtensions:
            ['pdf'],
      );

      if (files.isEmpty) {
        return;
      }

      final file =
          files.first;

      final bytes =
          await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception(
          'Unable to read the selected PDF.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingEbook =
            true;
        _selectedEbookName =
            file.name;
      });

      final uploadResult =
          await _b2UploadService
              .uploadFile(
        bytes: bytes,
        fileName:
            file.name,
        contentType:
            'application/pdf',
        mediaType:
            'ebook',
        resourceType:
            'book',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _ebookObjectKey =
            uploadResult
                .objectKey;
        _isUploadingEbook =
            false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Ebook uploaded successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploadingEbook =
            false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // SAVE BOOK
  // ============================================================

  Future<void> _save() async {
    if (_isSaving ||
        _isUploadingEbook ||
        _isUploadingCover) {
      return;
    }

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final price =
        double.tryParse(
      _priceController.text
          .trim(),
    );

    if (price == null ||
        price < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid price.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // COVER IS REQUIRED
    // ----------------------------------------------------------

    if (_coverObjectKey
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload a valid cover image before saving the book.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // PUBLISHED BOOK MUST HAVE PDF
    // ----------------------------------------------------------

    if (_isPublished &&
        _ebookObjectKey
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload the ebook PDF before publishing this book.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.book == null) {
        await _repository
            .createBook(
          title:
              _titleController
                  .text
                  .trim(),
          author:
              _authorController
                  .text
                  .trim(),
          description:
              _descriptionController
                  .text
                  .trim(),
          category:
              _categoryController
                  .text
                  .trim(),
          coverObjectKey:
              _coverObjectKey
                  .trim(),
          ebookObjectKey:
              _ebookObjectKey
                  .trim(),
          price: price,
          currency: _currency,
          isPublished:
              _isPublished,
          isFeatured:
              _isFeatured,
        );
      } else {
        await _repository
            .updateBook(
          bookId:
              widget.book!.id,
          title:
              _titleController
                  .text
                  .trim(),
          author:
              _authorController
                  .text
                  .trim(),
          description:
              _descriptionController
                  .text
                  .trim(),
          category:
              _categoryController
                  .text
                  .trim(),
          coverObjectKey:
              _coverObjectKey
                  .trim(),
          ebookObjectKey:
              _ebookObjectKey
                  .trim(),
          price: price,
          currency: _currency,
          isPublished:
              _isPublished,
          isFeatured:
              _isFeatured,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            widget.book == null
                ? 'Book created successfully.'
                : 'Book updated successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD FORM
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final editing =
        widget.book != null;

    return Dialog(
      insetPadding:
          const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 650,
          maxHeight: 820,
        ),
        child: Column(
          children: [
            // ----------------------------------------------------
            // HEADER
            // ----------------------------------------------------

            Container(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              color: _primary,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      editing
                          ? 'Edit Book'
                          : 'Add Book',
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 21,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isSaving ||
                                _isUploadingEbook ||
                                _isUploadingCover
                            ? null
                            : () {
                              Navigator.pop(
                                context,
                              );
                            },
                    icon:
                        const Icon(
                      Icons.close,
                      color:
                          Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // FORM
            // ----------------------------------------------------

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      _field(
                        controller:
                            _titleController,
                        label:
                            'Book Title',
                        validator:
                            _required,
                      ),

                      _field(
                        controller:
                            _authorController,
                        label:
                            'Author',
                        validator:
                            _required,
                      ),

                      _field(
                        controller:
                            _categoryController,
                        label:
                            'Category',
                        validator:
                            _required,
                      ),

                      _field(
                        controller:
                            _descriptionController,
                        label:
                            'Description',
                        maxLines:
                            5,
                        validator:
                            _required,
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      // ==================================================
                      // COVER
                      // ==================================================

                      const Text(
                        'Book Cover',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .w700,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        decoration:
                            BoxDecoration(
                          border:
                              Border.all(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width:
                                      58,
                                  height:
                                      74,
                                  child:
                                      ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(
                                      8,
                                    ),
                                    child:
                                        _coverObjectKey.isNotEmpty
                                            ? _CoverPreview(
                                              bookId: widget.book?.id,
                                              uploadService:
                                                  _b2UploadService,
                                              fallback:
                                                  _coverSmallPlaceholder(),
                                            )
                                            : _coverSmallPlaceholder(),
                                  ),
                                ),
                                const SizedBox(
                                  width:
                                      12,
                                ),
                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        _selectedCoverName ??
                                            (_coverObjectKey.isNotEmpty
                                                ? 'Cover already uploaded'
                                                : 'No cover selected'),
                                        maxLines:
                                            2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                      if (_coverObjectKey
                                          .isNotEmpty)
                                        const Padding(
                                          padding:
                                              EdgeInsets.only(
                                            top:
                                                4,
                                          ),
                                          child:
                                              Text(
                                            'Private B2 cover ready',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.green,
                                              fontSize:
                                                  12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height:
                                  14,
                            ),

                            SizedBox(
                              width:
                                  double.infinity,
                              child:
                                  OutlinedButton.icon(
                                onPressed:
                                    _isUploadingCover
                                        ? null
                                        : _selectAndUploadCover,
                                icon:
                                    _isUploadingCover
                                        ? const SizedBox(
                                          width:
                                              18,
                                          height:
                                              18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                          ),
                                        )
                                        : const Icon(
                                          Icons
                                              .upload_file_rounded,
                                        ),
                                label:
                                    Text(
                                  _isUploadingCover
                                      ? 'Uploading Cover...'
                                      : _coverObjectKey.isEmpty
                                          ? 'Select & Upload Cover'
                                          : 'Replace Cover',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // EBOOK PDF
                      // ==================================================

                      const Text(
                        'Book PDF',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .w700,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        decoration:
                            BoxDecoration(
                          border:
                              Border.all(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons
                                      .picture_as_pdf_rounded,
                                  color:
                                      Colors.red,
                                  size:
                                      34,
                                ),
                                const SizedBox(
                                  width:
                                      12,
                                ),
                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        _selectedEbookName ??
                                            (_ebookObjectKey
                                                    .isNotEmpty
                                                ? 'Ebook already uploaded'
                                                : 'No PDF selected'),
                                        maxLines:
                                            2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                      if (_ebookObjectKey
                                          .isNotEmpty)
                                        const Padding(
                                          padding:
                                              EdgeInsets.only(
                                            top:
                                                4,
                                          ),
                                          child:
                                              Text(
                                            'Private B2 ebook ready',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.green,
                                              fontSize:
                                                  12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height:
                                  14,
                            ),

                            SizedBox(
                              width:
                                  double.infinity,
                              child:
                                  OutlinedButton.icon(
                                onPressed:
                                    _isUploadingEbook
                                        ? null
                                        : _selectAndUploadEbook,
                                icon:
                                    _isUploadingEbook
                                        ? const SizedBox(
                                          width:
                                              18,
                                          height:
                                              18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                          ),
                                        )
                                        : const Icon(
                                          Icons
                                              .upload_file_rounded,
                                        ),
                                label:
                                    Text(
                                  _isUploadingEbook
                                      ? 'Uploading PDF...'
                                      : _ebookObjectKey
                                              .isEmpty
                                          ? 'Select & Upload PDF'
                                          : 'Replace PDF',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // PRICE + CURRENCY
                      // ==================================================

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child:
                                _field(
                              controller:
                                  _priceController,
                              label:
                                  'Price',
                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                decimal:
                                    true,
                              ),
                              validator:
                                  _required,
                            ),
                          ),
                          const SizedBox(
                            width:
                                12,
                          ),
                          Expanded(
                            child:
                                DropdownButtonFormField<
                                    String>(
                              initialValue:
                                  _currency,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Currency',
                                border:
                                    OutlineInputBorder(),
                              ),
                              items:
                                  const [
                                'NGN',
                                'USD',
                                'GBP',
                                'EUR',
                              ]
                                      .map(
                                (
                                  currency,
                                ) =>
                                    DropdownMenuItem<
                                        String>(
                                  value:
                                      currency,
                                  child:
                                      Text(
                                    currency,
                                  ),
                                ),
                              )
                                      .toList(),
                              onChanged:
                                  _isSaving
                                      ? null
                                      : (
                                          value,
                                        ) {
                                          if (value !=
                                              null) {
                                            setState(
                                              () {
                                                _currency =
                                                    value;
                                              },
                                            );
                                          }
                                        },
                            ),
                          ),
                        ],
                      ),

                      // ==================================================
                      // PUBLISHED
                      // ==================================================

                      SwitchListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title:
                            const Text(
                          'Published',
                        ),
                        subtitle:
                            const Text(
                          'Published books appear in the user shop.',
                        ),
                        value:
                            _isPublished,
                        onChanged:
                            _isSaving
                                ? null
                                : (
                                    value,
                                  ) {
                                    setState(
                                      () {
                                        _isPublished =
                                            value;
                                      },
                                    );
                                  },
                      ),

                      // ==================================================
                      // FEATURED
                      // ==================================================

                      SwitchListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title:
                            const Text(
                          'Featured',
                        ),
                        subtitle:
                            const Text(
                          'Featured books can appear in highlighted areas.',
                        ),
                        value:
                            _isFeatured,
                        onChanged:
                            _isSaving
                                ? null
                                : (
                                    value,
                                  ) {
                                    setState(
                                      () {
                                        _isFeatured =
                                            value;
                                      },
                                    );
                                  },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================================================
            // BOTTOM ACTIONS
            // ==========================================================

            Container(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              decoration:
                  BoxDecoration(
                border:
                    Border(
                  top:
                      BorderSide(
                    color: Colors
                        .grey
                        .shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton(
                      onPressed:
                          _isSaving ||
                                  _isUploadingEbook ||
                                  _isUploadingCover
                              ? null
                              : () {
                                Navigator.pop(
                                  context,
                                );
                              },
                      child:
                          const Text(
                        'Cancel',
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        FilledButton(
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            _primary,
                      ),
                      onPressed:
                          _isSaving ||
                                  _isUploadingEbook ||
                                  _isUploadingCover
                              ? null
                              : _save,
                      child:
                          _isSaving
                              ? const SizedBox(
                                height:
                                    20,
                                width:
                                    20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                              : Text(
                                editing
                                    ? 'Update Book'
                                    : 'Create Book',
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SMALL COVER PLACEHOLDER
  // ============================================================

  Widget _coverSmallPlaceholder() {
    return Container(
      color:
          const Color(0xFFEDE6F0),
      alignment:
          Alignment.center,
      child: const Icon(
        Icons
            .add_photo_alternate_outlined,
        color: _primary,
        size: 28,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _field({
    required TextEditingController
        controller,
    required String label,
    String? Function(String?)?
        validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child:
          TextFormField(
        controller:
            controller,
        maxLines:
            maxLines,
        keyboardType:
            keyboardType,
        validator:
            validator,
        decoration:
            InputDecoration(
          labelText:
              label,
          alignLabelWithHint:
              maxLines > 1,
          border:
              const OutlineInputBorder(),
        ),
      ),
    );
  }

  String? _required(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }
}

// ============================================================
// COVER PREVIEW
// ============================================================

class _CoverPreview
    extends StatelessWidget {
  final String? bookId;
  final B2UploadService uploadService;
  final Widget fallback;

  const _CoverPreview({
    required this.bookId,
    required this.uploadService,
    required this.fallback,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    if (bookId == null ||
        bookId!.trim().isEmpty) {
      return fallback;
    }

    return FutureBuilder<String>(
      future:
          uploadService
              .getBookCoverUrl(
        bookId:
            bookId!,
      ),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            color:
                const Color(
              0xFFEDE6F0,
            ),
            alignment:
                Alignment.center,
            child:
                const SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!
                .trim()
                .isEmpty) {
          return fallback;
        }

        return Image.network(
          snapshot.data!,
          fit:
              BoxFit.cover,
          width:
              double.infinity,
          height:
              double.infinity,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return fallback;
          },
        );
      },
    );
  }
}
