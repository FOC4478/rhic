import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/book_model.dart';
import '../../../repositories/cart_repository.dart';
import '../../../repositories/shop_repository.dart';
import 'book_details_screen.dart';
import 'cart_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
  });

  @override
  State<ShopScreen> createState() =>
      _ShopScreenState();
}

class _ShopScreenState
    extends State<ShopScreen> {
  static const Color primaryColor =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  static const Color orangeColor =
      Color(0xFFF7931E);

  String _search = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please sign in to visit the shop.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Shop',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: darkPurple,
          ),
        ),
        actions: [
          StreamBuilder(
            stream: CartRepository.instance
                .cartStream(user.uid),
            builder: (context, snapshot) {
              final count =
                  snapshot.data?.fold<int>(
                        0,
                        (total, item) =>
                            total + item.quantity,
                      ) ??
                      0;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  right: 12,
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons
                            .shopping_cart_outlined,
                        color: darkPurple,
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
                    if (count > 0)
                      Positioned(
                        right: 3,
                        top: 3,
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .all(4),
                          decoration:
                              const BoxDecoration(
                            color: orangeColor,
                            shape:
                                BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<BookModel>>(
        stream: ShopRepository.instance
            .booksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: () => setState(() {}),
            );
          }

          final books =
              snapshot.data ?? [];

          final categories = <String>{
            'All',
            ...books
                .map((book) => book.category)
                .where(
                  (category) =>
                      category.trim().isNotEmpty,
                ),
          }.toList();

          final filteredBooks =
              books.where((book) {
            final matchesSearch =
                book.title
                        .toLowerCase()
                        .contains(
                          _search.toLowerCase(),
                        ) ||
                    book.author
                        .toLowerCase()
                        .contains(
                          _search.toLowerCase(),
                        );

            final matchesCategory =
                _selectedCategory == 'All' ||
                    book.category ==
                        _selectedCategory;

            return matchesSearch &&
                matchesCategory;
          }).toList();

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                35,
              ),
              children: [
                _buildHero(),

                const SizedBox(height: 20),

                TextField(
                  onChanged: (value) {
                    setState(() {
                      _search = value;
                    });
                  },
                  decoration:
                      InputDecoration(
                    hintText:
                        'Search digital books...',
                    prefixIcon:
                        const Icon(
                      Icons.search_rounded,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection:
                        Axis.horizontal,
                    itemCount:
                        categories.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      width: 8,
                    ),
                    itemBuilder:
                        (context, index) {
                      final category =
                          categories[index];

                      final selected =
                          category ==
                              _selectedCategory;

                      return ChoiceChip(
                        label:
                            Text(category),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory =
                                category;
                          });
                        },
                        selectedColor:
                            primaryColor,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : darkPurple,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      'Digital Books',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.w800,
                        color: darkPurple,
                      ),
                    ),
                    Text(
                      '${filteredBooks.length} books',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                if (filteredBooks.isEmpty)
                  const _EmptyShop(),

                if (filteredBooks.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount:
                        filteredBooks.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 18,
                      childAspectRatio: .62,
                    ),
                    itemBuilder:
                        (context, index) {
                      return _BookCard(
                        book:
                            filteredBooks[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookDetailsScreen(
                                book:
                                    filteredBooks[
                                        index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3D004D),
            Color(0xFF6B1FA2),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow through  the Word.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.1,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Explore digital books from RHIC.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 72,
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFF0E8F3),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              clipBehavior:
                  Clip.antiAlias,
              child: book.coverUrl.isNotEmpty
                  ? Image.network(
                      book.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            book.title,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF3D004D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            book.formattedPrice,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B1FA2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.menu_book_outlined,
        size: 50,
        color: Color(0xFF6B1FA2),
      ),
    );
  }
}

class _EmptyShop extends StatelessWidget {
  const _EmptyShop();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(50),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 60,
            color: Color(0xFFD0C5D4),
          ),
          SizedBox(height: 15),
          Text(
            'No books found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 55,
            color: Colors.grey,
          ),
          const SizedBox(height: 15),
          const Text(
            'Unable to load the shop.',
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}