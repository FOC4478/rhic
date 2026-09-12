import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/cart_item_model.dart';
import '../../../models/payment_settings_model.dart';
import '../../../repositories/cart_repository.dart';
import '../../../repositories/payment_repository.dart';
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

class _PaymentScreenState extends State<PaymentScreen> {
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

  // ==========================================================
  // SUBMIT PAYMENT
  // ==========================================================

  Future<void> _submitPayment(
    PaymentSettingsModel settings,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in before making a payment.',
      );
      return;
    }

    if (widget.items.isEmpty) {
      _showMessage(
        'Your cart is empty.',
      );
      return;
    }

    if (widget.total <= 0) {
      _showMessage(
        'Invalid order amount.',
      );
      return;
    }

    if (!settings.isActive) {
      _showMessage(
        'This payment method is currently unavailable.',
      );
      return;
    }

    final reference =
        _referenceController.text.trim();

    if (reference.isEmpty) {
      _showMessage(
        'Please enter your payment reference.',
      );
      return;
    }

    if (_submitting) {
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

      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

      final message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      _showMessage(
        message.isEmpty
            ? 'Unable to submit your order.'
            : message,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // FORMAT AMOUNT
  // ==========================================================

  String _formatAmount() {
    final currency =
        widget.currency.trim().toUpperCase();

    if (currency == 'NGN') {
      return '₦${widget.total.toStringAsFixed(0)}';
    }

    return '$currency ${widget.total.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        widget.currency.trim().toUpperCase();

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
        stream:
            PaymentRepository.instance
                .paymentSettingsStream(
          paymentType: 'shop',
          currency: currency,
        ),

        builder: (context, snapshot) {
          // ==================================================
          // LOADING
          // ==================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: purple,
              ),
            );
          }

          // ==================================================
          // FIRESTORE ERROR
          // ==================================================

          if (snapshot.hasError) {
            return const _PaymentError(
              title:
                  'Unable to load payment details',
              message:
                  'We could not load the payment account at the moment. Please try again.',
            );
          }

          // ==================================================
          // NO PAYMENT SETTINGS
          // ==================================================

          final settings = snapshot.data;

          if (settings == null) {
            return const _PaymentError(
              title:
                  'Payment is currently unavailable',
              message:
                  'The bookstore payment account has not been configured yet. Please try again later.',
            );
          }

          // ==================================================
          // INACTIVE PAYMENT SETTINGS
          // ==================================================

          if (!settings.isActive) {
            return const _PaymentError(
              title:
                  'Payment is currently unavailable',
              message:
                  'This payment account is currently inactive. Please try again later.',
            );
          }

          // ==================================================
          // PAYMENT PAGE
          // ==================================================

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
                    fontWeight: FontWeight.w900,
                    color: darkPurple,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Transfer the exact amount below to the account provided.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // AMOUNT
                // ==================================================

                _PaymentAmountCard(
                  amount: _formatAmount(),
                  currency: currency,
                ),

                const SizedBox(height: 24),

                // ==================================================
                // BANK DETAILS
                // ==================================================

                const Text(
                  'Bank Transfer Details',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: darkPurple,
                  ),
                ),

                const SizedBox(height: 12),

                _BankDetailsCard(
                  settings: settings,
                ),

                const SizedBox(height: 24),

                // ==================================================
                // PAYMENT REFERENCE
                // ==================================================

                const Text(
                  'Payment Reference',
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
                  enabled: !_submitting,
                  textCapitalization:
                      TextCapitalization.characters,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Enter transfer reference',
                    filled: true,
                    fillColor:
                        Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
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
                        15,
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
                        15,
                      ),
                      borderSide:
                          const BorderSide(
                        color: purple,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Use the transaction reference or transfer narration shown by your bank.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // VERIFICATION NOTICE
                // ==================================================

                const _VerificationNotice(),

                const SizedBox(height: 28),

                // ==================================================
                // SUBMIT
                // ==================================================

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
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          purple,
                      disabledBackgroundColor:
                          Colors.grey.shade300,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
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

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// PAYMENT AMOUNT CARD
// ============================================================

class _PaymentAmountCard
    extends StatelessWidget {
  final String amount;
  final String currency;

  const _PaymentAmountCard({
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EAF5),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8D9EC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount to pay',
            style: TextStyle(
              color: Color(0xFF777777),
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            amount,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF3D004D),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            currency,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BANK DETAILS CARD
// ============================================================

class _BankDetailsCard
    extends StatelessWidget {
  final PaymentSettingsModel settings;

  const _BankDetailsCard({
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
          color: const Color(0xFFE8DFEA),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                color: Color(0xFF6B1FA2),
              ),
              SizedBox(width: 10),
              Text(
                'Bank Transfer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF3D004D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _DetailRow(
            label: 'Bank',
            value: settings.bankName,
          ),

          const Divider(
            height: 26,
          ),

          _DetailRow(
            label: 'Account Name',
            value: settings.accountName,
          ),

          const Divider(
            height: 26,
          ),

          _DetailRow(
            label: 'Account Number',
            value: settings.accountNumber,
            copyable: true,
          ),

          if (settings.instructions
              .trim()
              .isNotEmpty) ...[
            const Divider(
              height: 28,
            ),

            const Text(
              'Instructions',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF3D004D),
              ),
            ),

            const SizedBox(height: 7),

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
// DETAIL ROW
// ============================================================

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
    return Row(
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

        if (copyable)
          IconButton(
            tooltip:
                'Copy account number',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: value,
                ),
              );

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account number copied.',
                  ),
                  behavior:
                      SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(
              Icons.copy_outlined,
              size: 20,
              color:
                  Color(0xFF6B1FA2),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// VERIFICATION NOTICE
// ============================================================

class _VerificationNotice
    extends StatelessWidget {
  const _VerificationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E7),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFE1B5),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color:
                Color(0xFFF7931E),
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

// ============================================================
// PAYMENT ERROR
// ============================================================

class _PaymentError
    extends StatelessWidget {
  final String title;
  final String message;

  const _PaymentError({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .account_balance_outlined,
              size: 50,
              color:
                  Color(0xFFD0C5D3),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF3D004D),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color:
                    Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}