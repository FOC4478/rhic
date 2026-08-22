import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'giving_confirmation_screen.dart';

class GivingPaymentDetailsScreen extends StatefulWidget {
  final String givingType;
  final String currency;

  const GivingPaymentDetailsScreen({
    super.key,
    required this.givingType,
    required this.currency,
  });

  @override
  State<GivingPaymentDetailsScreen> createState() =>
      _GivingPaymentDetailsScreenState();
}

class _GivingPaymentDetailsScreenState
    extends State<GivingPaymentDetailsScreen> {
  bool _loading = true;

  String _bankName = '';
  String _accountName = '';
  String _accountNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  // ============================================================
  // LOAD PAYMENT DETAILS
  // ============================================================

  Future<void> _loadPaymentDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('giving_settings')
          .doc(widget.currency)
          .get();

      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.data() ?? {};

        setState(() {
          _bankName = data['bankName']?.toString() ?? '';
          _accountName = data['accountName']?.toString() ?? '';
          _accountNumber = data['accountNumber']?.toString() ?? '';
        });
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to load payment details.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // COPY TEXT
  // ============================================================

  Future<void> _copyText(
    String text,
    String message,
  ) async {
    if (text.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    if (!mounted) return;

    _showMessage(message);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // CURRENCY NAME
  // ============================================================

  String _currencyName(String currency) {
    switch (currency) {
      case 'NGN':
        return 'Naira';

      case 'USD':
        return 'US Dollar';

      case 'GBP':
        return 'British Pound';

      case 'EUR':
        return 'Euro';

      default:
        return currency;
    }
  }

  // ============================================================
  // CURRENCY SYMBOL
  // ============================================================

  String _currencySymbol(String currency) {
    switch (currency) {
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currencyName = _currencyName(widget.currency);
    final currencySymbol = _currencySymbol(widget.currency);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'Payment Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D004D),
        elevation: 0,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF6B1FA2),
              onRefresh: _loadPaymentDetails,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  // ==================================================
                  // GIVING TYPE
                  // ==================================================

                  Text(
                    widget.givingType,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3D004D),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'Payment details for $currencyName ($currencySymbol${widget.currency})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // INFORMATION CARD
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1D9F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          color: Color(0xFF6B1FA2),
                          size: 27,
                        ),

                        SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            'Use the payment details below to make '
                            'your transfer. Please verify the account '
                            'information before sending your money.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3D004D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // PAYMENT DETAILS CARD
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.04,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // =================================================
                        // BANK
                        // =================================================

                        _PaymentDetailRow(
                          label: 'Bank',
                          value: _bankName,
                          showCopy: false,
                        ),

                        const Divider(
                          height: 32,
                        ),

                        // =================================================
                        // ACCOUNT NAME
                        // =================================================

                        _PaymentDetailRow(
                          label: 'Account Name',
                          value: _accountName,
                          showCopy: true,
                          onCopy: () {
                            _copyText(
                              _accountName,
                              'Account name copied.',
                            );
                          },
                        ),

                        const Divider(
                          height: 32,
                        ),

                        // =================================================
                        // ACCOUNT NUMBER
                        // =================================================

                        _PaymentDetailRow(
                          label: 'Account Number',
                          value: _accountNumber,
                          showCopy: true,
                          onCopy: () {
                            _copyText(
                              _accountNumber,
                              'Account number copied.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // COPY ACCOUNT NUMBER BUTTON
                  // ==================================================

                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _accountNumber.isEmpty
                          ? null
                          : () {
                              _copyText(
                                _accountNumber,
                                'Account number copied.',
                              );
                            },
                      icon: const Icon(
                        Icons.copy_outlined,
                      ),
                      label: const Text(
                        'Copy Account Number',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF6B1FA2),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFFB99AC5),
                        disabledForegroundColor:
                            Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(27),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),


                  const SizedBox(height: 14),

SizedBox(
  height: 54,
  child: OutlinedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GivingConfirmationScreen(
            givingType: widget.givingType,
            currency: widget.currency,
          ),
        ),
      );
    },
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF6B1FA2),
      side: const BorderSide(
        color: Color(0xFF6B1FA2),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(27),
      ),
    ),
    child: const Text(
      "I've Made the Transfer",
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    ),
  ),
),

                  // ==================================================
                  // SECURITY NOTICE
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: const Color(0xFFE9DDEE),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF6B1FA2),
                          size: 21,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'For your security, only transfer money '
                            'to the account details displayed here. '
                            'Always confirm the account name and '
                            'number before completing your transfer.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // AFTER PAYMENT NOTICE
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F4FA),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF6B1FA2),
                          size: 21,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'After making your transfer, you can '
                            'return to the giving section to '
                            'confirm your payment. Your giving '
                            'will remain pending until it is '
                            'confirmed by RHIC.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

// ================================================================
// PAYMENT DETAIL ROW
// ================================================================

class _PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showCopy;
  final VoidCallback? onCopy;

  const _PaymentDetailRow({
    required this.label,
    required this.value,
    this.showCopy = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                value.isEmpty ? 'Unavailable' : value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3D004D),
                ),
              ),
            ],
          ),
        ),

        if (showCopy && value.isNotEmpty)
          IconButton(
            tooltip: 'Copy $label',
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_outlined,
              color: Color(0xFF6B1FA2),
            ),
          ),
      ],
    );
  }
}