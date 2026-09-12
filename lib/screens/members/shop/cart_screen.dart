import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/cart_item_model.dart';
import '../../../repositories/cart_repository.dart';
import '../../../services/b2_upload_service.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const Color purple = Color(0xFF6B1FA2);
  static const Color darkPurple = Color(0xFF3D004D);
  static const Color orange = Color(0xFFF7931E);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in.'),
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
          'Your Cart',
          style: TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<List<CartItemModel>>(
        stream: CartRepository.instance.cartStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: purple,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load your cart.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const _EmptyCart();
          }

          final total = items.fold<double>(
            0,
            (sum, item) => sum + item.total,
          );

          final currency = items.first.currency.trim().toUpperCase();

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _CartItem(
                      item: items[index],
                      userId: user.uid,
                    );
                  },
                ),
              ),

              // ==================================================
              // CART SUMMARY
              // ==================================================

              Container(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFEFE9F1),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _formatAmount(
                              total,
                              currency,
                            ),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: darkPurple,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentScreen(
                                  items: List<CartItemModel>.unmodifiable(
                                    items,
                                  ),
                                  total: total,
                                  currency: currency,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(27),
                            ),
                          ),
                          child: const Text(
                            'Continue to Payment',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatAmount(
    double amount,
    String currency,
  ) {
    if (currency == 'NGN') {
      return '₦${amount.toStringAsFixed(0)}';
    }

    return '$currency ${amount.toStringAsFixed(2)}';
  }
}

// ============================================================
// CART ITEM
// ============================================================

class _CartItem extends StatefulWidget {
  final CartItemModel item;
  final String userId;

  const _CartItem({
    required this.item,
    required this.userId,
  });

  @override
  State<_CartItem> createState() => _CartItemState();
}

class _CartItemState extends State<_CartItem> {
  final B2UploadService _b2UploadService =
      B2UploadService.instance;

  String? _coverUrl;
  bool _loadingCover = true;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  @override
  void didUpdateWidget(
    covariant _CartItem oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item.bookId != widget.item.bookId) {
      _coverUrl = null;
      _loadingCover = true;
      _loadCover();
    }
  }

  Future<void> _loadCover() async {
    final bookId = widget.item.bookId.trim();

    if (bookId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _loadingCover = false;
      });

      return;
    }

    try {
      final url =
          await _b2UploadService.getBookCoverUrl(
        bookId: bookId,
      );

      if (!mounted) return;

      setState(() {
        _coverUrl = url;
        _loadingCover = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _coverUrl = null;
        _loadingCover = false;
      });
    }
  }

  Future<void> _decreaseQuantity() async {
    final newQuantity = widget.item.quantity - 1;

    await CartRepository.instance.updateQuantity(
      userId: widget.userId,
      bookId: widget.item.bookId,
      quantity: newQuantity,
    );
  }

  Future<void> _increaseQuantity() async {
    await CartRepository.instance.updateQuantity(
      userId: widget.userId,
      bookId: widget.item.bookId,
      quantity: widget.item.quantity + 1,
    );
  }

  Future<void> _removeItem() async {
    await CartRepository.instance.removeFromCart(
      userId: widget.userId,
      bookId: widget.item.bookId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF0EBF2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 75,
              height: 90,
              child: _buildCover(),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3D004D),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.item.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.item.formattedPrice,
                  style: const TextStyle(
                    color: Color(0xFF6B1FA2),
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    IconButton(
                      visualDensity:
                          VisualDensity.compact,
                      tooltip: 'Decrease quantity',
                      onPressed: _decreaseQuantity,
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        size: 20,
                      ),
                    ),

                    Text(
                      '${widget.item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    IconButton(
                      visualDensity:
                          VisualDensity.compact,
                      tooltip: 'Increase quantity',
                      onPressed: _increaseQuantity,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Remove from cart',
            onPressed: _removeItem,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    if (_loadingCover) {
      return Container(
        color: const Color(0xFFF3EAF5),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Color(0xFF6B1FA2),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_coverUrl == null ||
        _coverUrl!.trim().isEmpty) {
      return _placeholder();
    }

    return Image.network(
      _coverUrl!,
      fit: BoxFit.cover,
      width: 75,
      height: 90,
      errorBuilder: (_, __, ___) {
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return const ColoredBox(
      color: Color(0xFFF3EAF5),
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          color: Color(0xFF6B1FA2),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY CART
// ============================================================

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 65,
            color: Color(0xFFD4CAD8),
          ),
          SizedBox(height: 18),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF777777),
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Add a digital book to get started.',
            style: TextStyle(
              color: Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}