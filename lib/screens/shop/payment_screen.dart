import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/cart_item_model.dart';
import '../../models/payment_settings_model.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/payment_repository.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<CartItemModel> items;
  final double total;
  final String currency;

  const PaymentScreen({
    super.key,
    required this.items,
    required this.total,
    required this.currency,
  });

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState
    extends State<PaymentScreen> {
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

  Future<void> _submitPayment(
    PaymentSettingsModel settings,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final reference =
        _referenceController.text.trim();

    if (reference.isEmpty) {
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
        paymentReference: reference,
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
          'Payment',
          style: TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.w800,
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
            return const _PaymentError(
              message:
                  'Unable to load payment details.',
            );
          }

          final settings = snapshot.data;

          if (settings == null ||
              !settings.isActive) {
            return const _PaymentError(
              message:
                  'Payment is currently unavailable. Please try again later.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete your payment',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: darkPurple,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Transfer the exact amount below to the account provided.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                _PaymentAmountCard(
                  total: widget.total,
                  currency:
                      widget.currency,
                ),

                const SizedBox(height: 18),

                _BankDetailsCard(
                  settings: settings,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Payment reference',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkPurple,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller:
                      _referenceController,
                  textCapitalization:
                      TextCapitalization.characters,
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
                        15,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Use the transaction reference or transfer narration shown by your bank.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () =>
                            _submitPayment(
                              settings,
                            ),
                    style: ElevatedButton
                        .styleFrom(
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
                              strokeWidth: 2,
                              color:
                                  Colors.white,
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

                const SizedBox(height: 20),

                const _VerificationNotice(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaymentAmountCard
    extends StatelessWidget {
  final double total;
  final String currency;

  const _PaymentAmountCard({
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EAF5),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount to pay',
            style: TextStyle(
              color: Color(0xFF777777),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currency == 'NGN'
                ? '₦${total.toStringAsFixed(0)}'
                : '$currency ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF3D004D),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankDetailsCard
    extends StatelessWidget {
  final PaymentSettingsModel settings;

  const _BankDetailsCard({
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8DFEA),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Bank transfer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),

          const SizedBox(height: 20),

          _DetailRow(
            label: 'Bank',
            value: settings.bankName,
          ),

          _DetailRow(
            label: 'Account name',
            value: settings.accountName,
          ),

          _DetailRow(
            label: 'Account number',
            value: settings.accountNumber,
            copyable: true,
          ),

          if (settings.instructions
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 12),
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

class _DetailRow
    extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const _DetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF3D004D),
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: value,
                  ),
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Account number copied.',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.copy_outlined,
                size: 20,
                color: Color(0xFF6B1FA2),
              ),
            ),
        ],
      ),
    );
  }
}

class _VerificationNotice
    extends StatelessWidget {
  const _VerificationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E7),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFFF7931E),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your order will remain pending until an administrator verifies your payment.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentError
    extends StatelessWidget {
  final String message;

  const _PaymentError({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}