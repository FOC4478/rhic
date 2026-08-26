import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/cart_item_model.dart';
import '../../models/payment_settings_model.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/payment_repository.dart';
import 'order_success_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
  });

  static const Color purple =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  static const Color orange =
      Color(0xFFF7931E);

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please sign in.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),

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
        stream: CartRepository.instance
            .cartStream(user.uid),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: purple,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load your cart.',
              ),
            );
          }

          final items =
              snapshot.data ?? [];

          if (items.isEmpty) {
            return const _EmptyCart();
          }

          final total = items.fold<double>(
            0,
            (sum, item) =>
                sum + item.total,
          );

          final currency =
              items.first.currency;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.all(20),

                  itemCount: items.length,

                  separatorBuilder:
                      (_, __) =>
                          const SizedBox(
                    height: 12,
                  ),

                  itemBuilder:
                      (context, index) {
                    return _CartItem(
                      item: items[index],
                      userId: user.uid,
                    );
                  },
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.fromLTRB(
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
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          Text(
                            _formatAmount(
                              total,
                              currency,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.w800,
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
                                builder: (_) =>
                                    CheckoutScreen(
                                  items: items,
                                  total: total,
                                  currency:
                                      currency,
                                ),
                              ),
                            );
                          },

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                purple,

                            foregroundColor:
                                Colors.white,

                            elevation: 0,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                27,
                              ),
                            ),
                          ),

                          child: const Text(
                            'Continue to Checkout',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w800,
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

class _CartItem extends StatelessWidget {
  final CartItemModel item;
  final String userId;

  const _CartItem({
    required this.item,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: const Color(
            0xFFF0EBF2,
          ),
        ),
      ),

      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(12),

            child: SizedBox(
              width: 75,
              height: 90,

              child:
                  item.coverUrl.isNotEmpty
                      ? Image.network(
                          item.coverUrl,
                          fit: BoxFit.cover,

                          errorBuilder:
                              (_, __, ___) {
                            return const ColoredBox(
                              color:
                                  Color(
                                0xFFF3EAF5,
                              ),
                              child: Icon(
                                Icons
                                    .menu_book_outlined,
                                color:
                                    Color(
                                  0xFF6B1FA2,
                                ),
                              ),
                            );
                          },
                        )
                      : const ColoredBox(
                          color:
                              Color(
                            0xFFF3EAF5,
                          ),
                          child: Icon(
                            Icons
                                .menu_book_outlined,
                            color:
                                Color(
                              0xFF6B1FA2,
                            ),
                          ),
                        ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  item.title,

                  maxLines: 2,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,

                    color:
                        Color(0xFF3D004D),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  item.author,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  item.formattedPrice,

                  style: const TextStyle(
                    color:
                        Color(0xFF6B1FA2),

                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    IconButton(
                      visualDensity:
                          VisualDensity.compact,

                      onPressed: () {
                        CartRepository.instance
                            .updateQuantity(
                          userId: userId,
                          bookId: item.bookId,
                          quantity:
                              item.quantity - 1,
                        );
                      },

                      icon: const Icon(
                        Icons
                            .remove_circle_outline,
                        size: 20,
                      ),
                    ),

                    Text(
                      '${item.quantity}',

                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    IconButton(
                      visualDensity:
                          VisualDensity.compact,

                      onPressed: () {
                        CartRepository.instance
                            .updateQuantity(
                          userId: userId,
                          bookId: item.bookId,
                          quantity:
                              item.quantity + 1,
                        );
                      },

                      icon: const Icon(
                        Icons
                            .add_circle_outline,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              CartRepository.instance
                  .removeFromCart(
                userId: userId,
                bookId: item.bookId,
              );
            },

            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
          ),
        ],
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
            Icons
                .shopping_cart_outlined,

            size: 65,

            color:
                Color(0xFFD4CAD8),
          ),

          SizedBox(height: 18),

          Text(
            'Your cart is empty',

            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF777777),
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Add a digital book to get started.',

            style: TextStyle(
              color:
                  Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// CHECKOUT SCREEN
// ============================================================

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> items;
  final double total;
  final String currency;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.total,
    required this.currency,
  });

  @override
  State<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}

class _CheckoutScreenState
    extends State<CheckoutScreen> {
  static const Color purple =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  final TextEditingController
      _referenceController =
          TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    if (_referenceController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your payment reference.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final orderId =
          await PaymentRepository.instance
              .createOrder(
        userId: user.uid,
        items: widget.items,
        total: widget.total,
        currency: widget.currency,
        paymentReference:
            _referenceController.text,
      );

      await CartRepository.instance
          .clearCart(user.uid);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OrderSuccessScreen(
            orderId: orderId,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to submit payment: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String _formatAmount() {
    if (widget.currency == 'NGN') {
      return '₦${widget.total.toStringAsFixed(0)}';
    }

    return '${widget.currency} ${widget.total.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Checkout',

          style: TextStyle(
            color: darkPurple,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: StreamBuilder<
          PaymentSettingsModel?>(
        stream: PaymentRepository.instance
            .paymentSettingsStream(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: purple,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(24),
                child: Text(
                  'Unable to load payment details.',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final settings =
              snapshot.data;

          if (settings == null) {
            return const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(24),
                child: Text(
                  'Payment is currently unavailable. Please try again later.',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Complete your payment',

                  style: TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        darkPurple,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Transfer the exact amount below to the account details provided.',

                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: purple,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Amount to pay',

                        style: TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _formatAmount(),

                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 30,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Bank Transfer Details',

                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        darkPurple,
                  ),
                ),

                const SizedBox(height: 12),

                _PaymentDetailsCard(
                  settings: settings,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Payment Reference',

                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    color:
                        darkPurple,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      _referenceController,

                  decoration:
                      InputDecoration(
                    hintText:
                        'Enter transfer reference',

                    filled: true,
                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),

                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFFE5DCE8),
                      ),
                    ),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),

                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFFE5DCE8),
                      ),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),

                      borderSide:
                          const BorderSide(
                        color: purple,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'After transferring, enter the payment reference and submit your order. An administrator will verify your payment.',

                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton(
                    onPressed:
                        _submitting
                            ? null
                            : _submitOrder,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          purple,

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),
                      ),
                    ),

                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,

                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Payment',

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          );
        },
      ),
    );
  }
}


// ============================================================
// PAYMENT DETAILS CARD
// ============================================================

class _PaymentDetailsCard
    extends StatelessWidget {
  final PaymentSettingsModel settings;

  const _PaymentDetailsCard({
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              const Color(0xFFECE4EF),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _DetailRow(
            label: 'Bank',
            value: settings.bankName,
          ),

          const Divider(height: 28),

          _DetailRow(
            label: 'Account Name',
            value: settings.accountName,
          ),

          const Divider(height: 28),

          _DetailRow(
            label: 'Account Number',
            value: settings.accountNumber,
            canCopy: true,
          ),

          if (settings
              .instructions
              .trim()
              .isNotEmpty) ...[
            const Divider(height: 28),

            const Text(
              'Instructions',

              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF3D004D),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              settings.instructions,

              style: TextStyle(
                color:
                    Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ============================================================
// PAYMENT DETAIL ROW
// ============================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    this.canCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                label,

                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,

                style: const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 15,
                  color:
                      Color(0xFF3D004D),
                ),
              ),
            ],
          ),
        ),

        if (canCopy)
          IconButton(
            onPressed: () {
              // Clipboard can be added here if needed.
            },

            icon: const Icon(
              Icons.copy_outlined,
              color:
                  Color(0xFF6B1FA2),
            ),
          ),
      ],
    );
  }
}