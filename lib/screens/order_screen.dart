import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/order_model.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({
    super.key,
  });

  static const Color purple = Color(0xFF6B1FA2);
  static const Color darkPurple = Color(0xFF3D004D);

  Stream<List<OrderModel>> _ordersStream(String userId) {
    return FirebaseFirestore.instance
        .collection('book_orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => OrderModel.fromFirestore(doc),
              )
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please sign in to view your orders.',
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
          'My Orders',
          style: TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _ordersStream(user.uid),
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
            return const _OrderError();
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const _EmptyOrders();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return _OrderCard(
                order: orders[index],
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({
    required this.order,
  });

  static const Color purple = Color(0xFF6B1FA2);
  static const Color darkPurple = Color(0xFF3D004D);

  Color _statusColor() {
    switch (order.status.toLowerCase()) {
      case 'approved':
      case 'verified':
      case 'completed':
        return Colors.green;

      case 'rejected':
      case 'cancelled':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon() {
    switch (order.status.toLowerCase()) {
      case 'approved':
      case 'verified':
      case 'completed':
        return Icons.check_circle_outline;

      case 'rejected':
      case 'cancelled':
        return Icons.cancel_outlined;

      default:
        return Icons.access_time_rounded;
    }
  }

  String _statusText() {
    switch (order.status.toLowerCase()) {
      case 'approved':
        return 'Approved';

      case 'verified':
        return 'Verified';

      case 'completed':
        return 'Completed';

      case 'rejected':
        return 'Rejected';

      case 'cancelled':
        return 'Cancelled';

      default:
        return 'Pending Verification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isNotEmpty
        ? order.items.first
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF3EAF5,
                    ),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: purple,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id}',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w800,
                          color: darkPurple,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor()
                        .withValues(alpha: .10),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(),
                        size: 15,
                        color: _statusColor(),
                      ),

                      const SizedBox(width: 5),

                      Text(
                        _statusText(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w700,
                          color: _statusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (firstItem != null) ...[
            const Divider(
              height: 1,
              color: Color(0xFFF0EDF1),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: SizedBox(
                      width: 55,
                      height: 70,
                      child: firstItem
                              .coverUrl.isNotEmpty
                          ? Image.network(
                              firstItem.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) {
                                return const ColoredBox(
                                  color: Color(
                                    0xFFF3EAF5,
                                  ),
                                  child: Icon(
                                    Icons
                                        .menu_book_outlined,
                                    color: purple,
                                  ),
                                );
                              },
                            )
                          : const ColoredBox(
                              color:
                                  Color(0xFFF3EAF5),
                              child: Icon(
                                Icons
                                    .menu_book_outlined,
                                color: purple,
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
                          firstItem.title,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w800,
                            color: darkPurple,
                          ),
                        ),

                        const SizedBox(height: 4),

                        if (firstItem.author
                            .isNotEmpty)
                          Text(
                            firstItem.author,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.grey.shade600,
                            ),
                          ),

                        if (order.items.length >
                            1) ...[
                          const SizedBox(height: 5),

                          Text(
                            '+ ${order.items.length - 1} more item${order.items.length - 1 == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w700,
                              color: purple,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(
            height: 1,
            color: Color(0xFFF0EDF1),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              13,
              16,
              16,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${_currencySymbol(order.currency)}${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                        color: darkPurple,
                      ),
                    ),
                  ],
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailsScreen(
                          order: order,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: purple,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'NGN':
        return '₦';

      case 'USD':
        return '\$';

      case 'GBP':
        return '£';

      case 'EUR':
        return '€';

      default:
        return '';
    }
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  static const Color purple = Color(0xFF6B1FA2);
  static const Color darkPurple = Color(0xFF3D004D);

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'NGN':
        return '₦';

      case 'USD':
        return '\$';

      case 'GBP':
        return '£';

      case 'EUR':
        return '€';

      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Information',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                    color: darkPurple,
                  ),
                ),

                const SizedBox(height: 16),

                _DetailRow(
                  label: 'Order ID',
                  value: order.id,
                ),

                const SizedBox(height: 12),

                _DetailRow(
                  label: 'Status',
                  value: order.status,
                ),

                const SizedBox(height: 12),

                _DetailRow(
                  label: 'Payment Method',
                  value: 'Bank Transfer',
                ),

                const SizedBox(height: 12),

                _DetailRow(
                  label: 'Payment Reference',
                  value: order.paymentReference
                          .isEmpty
                      ? 'Not provided'
                      : order.paymentReference,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Books',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: darkPurple,
            ),
          ),

          const SizedBox(height: 12),

          ...order.items.map(
            (item) => Container(
              margin:
                  const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: SizedBox(
                      width: 50,
                      height: 65,
                      child: item.coverUrl.isNotEmpty
                          ? Image.network(
                              item.coverUrl,
                              fit: BoxFit.cover,
                            )
                          : const ColoredBox(
                              color:
                                  Color(0xFFF3EAF5),
                              child: Icon(
                                Icons
                                    .menu_book_outlined,
                                color: purple,
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
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w800,
                            color: darkPurple,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Quantity: ${item.quantity}',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '${_currencySymbol(item.currency)}${item.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            color: purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: darkPurple,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                Text(
                  '${_currencySymbol(order.currency)}${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          if (order.adminNote.isNotEmpty) ...[
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E8),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Administrator Note',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w800,
                      color: darkPurple,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    order.adminNote,
                    style: TextStyle(
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D004D),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 70,
              color: Color(0xFFD4CAD8),
            ),

            SizedBox(height: 18),

            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF777777),
              ),
            ),

            SizedBox(height: 7),

            Text(
              'Your book orders will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderError extends StatelessWidget {
  const _OrderError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.redAccent,
            ),

            SizedBox(height: 16),

            Text(
              'Unable to load your orders.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}