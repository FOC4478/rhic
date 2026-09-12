import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../repositories/payment_repository.dart';
import '../../../models/payment_settings_model.dart';
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
  bool _hasError = false;

  PaymentSettingsModel? _paymentSettings;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  // ============================================================
  // DETERMINE PAYMENT TYPE
  // ============================================================

  String get _paymentType {
    if (widget.givingType.trim().toLowerCase() ==
        'church projects') {
      return 'church_projects';
    }

    return 'giving';
  }

  // ============================================================
  // LOAD PAYMENT DETAILS
  // ============================================================

  Future<void> _loadPaymentDetails() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
      });
    }

    try {
      final settings =
          await PaymentRepository.instance.getPaymentSettings(
        paymentType: _paymentType,
        currency: widget.currency,
      );

      if (!mounted) return;

      setState(() {
        _paymentSettings = settings;
        _loading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _paymentSettings = null;
        _loading = false;
        _hasError = true;
      });
    }
  }

  // ============================================================
  // COPY TEXT
  // ============================================================

  Future<void> _copyText(
    String text,
    String message,
  ) async {
    if (text.trim().isEmpty) return;

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
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
    switch (currency.toUpperCase()) {
      case 'NGN':
        return 'Naira';

      case 'USD':
        return 'US Dollar';

      case 'GBP':
        return 'British Pound';

      default:
        return currency;
    }
  }

  // ============================================================
  // CURRENCY SYMBOL
  // ============================================================

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'NGN':
        return '₦';

      case 'USD':
        return '\$';

      case 'GBP':
        return '£';

      default:
        return '';
    }
  }

  // ============================================================
  // PAYMENT DETAILS AVAILABLE
  // ============================================================

  bool get _hasPaymentDetails {
    final settings = _paymentSettings;

    if (settings == null) {
      return false;
    }

    if (!settings.isActive) {
      return false;
    }

    return settings.bankName.trim().isNotEmpty &&
        settings.accountName.trim().isNotEmpty &&
        settings.accountNumber.trim().isNotEmpty;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currencyName =
        _currencyName(widget.currency);

    final currencySymbol =
        _currencySymbol(widget.currency);

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
                physics:
                    const AlwaysScrollableScrollPhysics(),
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
                    'Payment details for '
                    '$currencyName '
                    '($currencySymbol${widget.currency})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // ERROR STATE
                  // ==================================================

                  if (_hasError) ...[
                    _buildErrorCard(),
                    const SizedBox(height: 20),
                  ]

                  // ==================================================
                  // NO PAYMENT DETAILS
                  // ==================================================

                  else if (!_hasPaymentDetails) ...[
                    _buildUnavailableCard(),
                    const SizedBox(height: 20),
                  ]

                  // ==================================================
                  // INFORMATION CARD
                  // ==================================================

                  else ...[
                    _buildInformationCard(),

                    const SizedBox(height: 22),

                    // ==================================================
                    // PAYMENT DETAILS CARD
                    // ==================================================

                    _buildPaymentDetailsCard(),

                    // ==================================================
                    // INSTRUCTIONS
                    // ==================================================

                    if (_paymentSettings!
                        .instructions
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildInstructionsCard(),
                    ],

                    const SizedBox(height: 22),

                    // ==================================================
                    // COPY ACCOUNT NUMBER
                    // ==================================================

                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _copyText(
                            _paymentSettings!
                                .accountNumber,
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
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF6B1FA2),
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(27),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // TRANSFER CONFIRMATION
                    // ==================================================

                    SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GivingConfirmationScreen(
                                givingType:
                                    widget.givingType,
                                currency:
                                    widget.currency,
                              ),
                            ),
                          );
                        },
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF6B1FA2),
                          side: const BorderSide(
                            color:
                                Color(0xFF6B1FA2),
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(27),
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

                    const SizedBox(height: 22),

                    // ==================================================
                    // SECURITY NOTICE
                    // ==================================================

                    _buildSecurityNotice(),

                    const SizedBox(height: 20),

                    // ==================================================
                    // AFTER PAYMENT NOTICE
                    // ==================================================

                    _buildAfterPaymentNotice(),

                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard() {
    return Container(
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
    );
  }

  // ============================================================
  // PAYMENT DETAILS CARD
  // ============================================================

  Widget _buildPaymentDetailsCard() {
    final settings = _paymentSettings!;

    return Container(
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
          _PaymentDetailRow(
            label: 'Bank',
            value: settings.bankName,
          ),

          const Divider(height: 32),

          _PaymentDetailRow(
            label: 'Account Name',
            value: settings.accountName,
            showCopy: true,
            onCopy: () {
              _copyText(
                settings.accountName,
                'Account name copied.',
              );
            },
          ),

          const Divider(height: 32),

          _PaymentDetailRow(
            label: 'Account Number',
            value: settings.accountNumber,
            showCopy: true,
            onCopy: () {
              _copyText(
                settings.accountNumber,
                'Account number copied.',
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INSTRUCTIONS CARD
  // ============================================================

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9DDEE),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: Color(0xFF6B1FA2),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Instructions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3D004D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _paymentSettings!.instructions,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 45,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load payment details',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'We could not retrieve the payment account '
            'at the moment. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadPaymentDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(0xFF6B1FA2),
              side: const BorderSide(
                color: Color(0xFF6B1FA2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UNAVAILABLE CARD
  // ============================================================

  Widget _buildUnavailableCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE9DDEE),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_outlined,
            size: 45,
            color: Color(0xFF6B1FA2),
          ),
          const SizedBox(height: 12),
          const Text(
            'Payment account unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'A payment account has not been configured '
            'for ${widget.givingType} in ${widget.currency} '
            'or the account is currently inactive.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadPaymentDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(0xFF6B1FA2),
              side: const BorderSide(
                color: Color(0xFF6B1FA2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECURITY NOTICE
  // ============================================================

  Widget _buildSecurityNotice() {
    return Container(
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
    );
  }

  // ============================================================
  // AFTER PAYMENT NOTICE
  // ============================================================

  Widget _buildAfterPaymentNotice() {
    return Container(
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
              'After making your transfer, tap '
              '"I\'ve Made the Transfer" to continue. '
              'Your giving will remain pending until '
              'it is confirmed by RHIC.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
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
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value.isEmpty
                    ? 'Unavailable'
                    : value,
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