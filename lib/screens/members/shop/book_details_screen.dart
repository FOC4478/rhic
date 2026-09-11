
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/book_model.dart';
import '../../../repositories/cart_repository.dart';
import '../../../services/b2_upload_service.dart';
import 'cart_screen.dart';

class BookDetailsScreen
    extends StatefulWidget {
  final BookModel book;

  const BookDetailsScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailsScreen> createState() =>
      _BookDetailsScreenState();
}

class _BookDetailsScreenState
    extends State<BookDetailsScreen> {
  static const Color purple =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  final B2UploadService
      _b2UploadService =
      B2UploadService.instance;

  String? _coverUrl;
  bool _loadingCover = true;

  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    if (widget.book.coverObjectKey
        .trim()
        .isEmpty) {
      if (mounted) {
        setState(() {
          _loadingCover = false;
        });
      }
      return;
    }

    try {
      final url =
          await _b2UploadService
              .getBookCoverUrl(
        bookId:
            widget.book.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _coverUrl = url;
        _loadingCover = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingCover = false;
      });
    }
  }

  Future<void> _addToCart() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _adding = true;
    });

    try {
      await CartRepository.instance
          .addToCart(
        userId: user.uid,
        book: widget.book,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Book added to cart.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to add book: $e',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final book =
        widget.book;

    return Scaffold(
      backgroundColor:
          Colors.white,
      appBar: AppBar(
        backgroundColor:
            Colors.white,
        surfaceTintColor:
            Colors.white,
        elevation: 0,
        title:
            const Text(
          'Book Details',
          style:
              TextStyle(
            color:
                darkPurple,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(
              Icons
                  .shopping_cart_outlined,
              color:
                  darkPurple,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const CartScreen(),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar:
          SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),
          child: SizedBox(
            height: 54,
            child:
                ElevatedButton
                    .icon(
              onPressed:
                  _adding
                      ? null
                      : _addToCart,
              icon:
                  _adding
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                      : const Icon(
                        Icons
                            .shopping_cart_outlined,
                      ),
              label: Text(
                _adding
                    ? 'Adding...'
                    : 'Add to Cart • ${book.formattedPrice}',
              ),
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    purple,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
              child:
                  AspectRatio(
                aspectRatio:
                    .75,
                child:
                    _buildCover(),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            Text(
              book.category
                  .toUpperCase(),
              style:
                  const TextStyle(
                color:
                    Color(0xFFF7931E),
                fontWeight:
                    FontWeight.w800,
                fontSize:
                    12,
                letterSpacing:
                    1,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              book.title,
              style:
                  const TextStyle(
                fontSize:
                    27,
                fontWeight:
                    FontWeight.w800,
                color:
                    darkPurple,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'By ${book.author}',
              style: TextStyle(
                color: Colors
                    .grey
                    .shade600,
                fontSize:
                    14,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              book.formattedPrice,
              style:
                  const TextStyle(
                fontSize:
                    23,
                fontWeight:
                    FontWeight.w800,
                color:
                    purple,
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            const Text(
              'About this book',
              style:
                  TextStyle(
                fontSize:
                    19,
                fontWeight:
                    FontWeight.w800,
                color:
                    darkPurple,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              book.description
                      .isEmpty
                  ? 'No description available.'
                  : book.description,
              style: TextStyle(
                height:
                    1.7,
                color: Colors
                    .grey
                    .shade700,
                fontSize:
                    14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (_loadingCover) {
      return Container(
        color:
            const Color(
          0xFFF3EAF5,
        ),
        alignment:
            Alignment.center,
        child:
            const SizedBox(
          width: 32,
          height: 32,
          child:
              CircularProgressIndicator(
            color:
                purple,
            strokeWidth:
                2.5,
          ),
        ),
      );
    }

    if (_coverUrl == null ||
        _coverUrl!
            .trim()
            .isEmpty) {
      return _placeholder();
    }

    return Image.network(
      _coverUrl!,
      fit:
          BoxFit.cover,
      width:
          double.infinity,
      height:
          double.infinity,
      errorBuilder:
          (
        _,
        __,
        ___,
      ) =>
              _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color:
          const Color(
        0xFFF3EAF5,
      ),
      child:
          const Center(
        child:
            Icon(
          Icons
              .menu_book_outlined,
          size: 70,
          color:
              purple,
        ),
      ),
    );
  }
}

