import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/giving_model.dart';
import '../../repositories/giving_repository.dart';

class GivingConfirmationScreen extends StatefulWidget {
  final String givingType;
  final String currency;

  const GivingConfirmationScreen({
    super.key,
    required this.givingType,
    required this.currency,
  });

  @override
  State<GivingConfirmationScreen> createState() =>
      _GivingConfirmationScreenState();
}

class _GivingConfirmationScreenState
    extends State<GivingConfirmationScreen> {
  final TextEditingController _amountController =
      TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ============================================================
  // SUBMIT GIVING
  // ============================================================

  Future<void> _submitGiving() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in before submitting your giving.',
      );
      return;
    }

    if (_submitting) {
      return;
    }

    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      _showMessage(
        'Please enter the amount you transferred.',
      );
      return;
    }

    final amount = double.tryParse(
      amountText.replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      _showMessage(
        'Please enter a valid amount.',
      );
      return;
    }

    final confirmed = await _showConfirmation(
      amount,
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final giving = GivingModel(
        id: '',
        userId: user.uid,
        userName:
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'RHIC Member',
        type: widget.givingType,
        currency: widget.currency,
        amount: amount,
        status: 'pending',
        paymentMethod: 'bank_transfer',
        createdAt: null,
        verifiedAt: null,
        verifiedBy: null,
        adminNote: null,
      );

      await GivingRepository.instance.createGiving(
        giving: giving,

      );

      if (!mounted) {
        return;
      }

      await _showSuccessDialog();

      if (!mounted) {
        return;
      }

      // Return all the way back to the Giving screen.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to submit your giving. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // ============================================================
  // CONFIRMATION DIALOG
  // ============================================================

  Future<bool?> _showConfirmation(
    double amount,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm Giving',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'You are confirming that you transferred '
            '${widget.currency == 'NGN' ? '₦' : widget.currency} '
            '${_formatAmount(amount)} '
            'towards ${widget.givingType}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF6B1FA2),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Confirm',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1D9F7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 38,
                  color: Color(0xFF6B1FA2),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Giving Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3D004D),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Your ${widget.givingType.toLowerCase()} '
                'has been submitted and is waiting '
                'for confirmation by RHIC.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6B1FA2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // FORMAT AMOUNT
  // ============================================================

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        widget.currency == 'NGN'
            ? '₦'
            : widget.currency;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FA),
      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        title: const Text(
          'Confirm Giving',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D004D),
        elevation: 0,
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ========================================================
          // HEADER
          // ========================================================

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1D9F7),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFF6B1FA2),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        widget.givingType,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3D004D),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Text(
                  'Enter the amount you transferred so '
                  'your giving can be recorded for '
                  'confirmation.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ========================================================
          // AMOUNT LABEL
          // ========================================================

          const Text(
            'Amount transferred',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),

          const SizedBox(height: 9),

          // ========================================================
          // AMOUNT FIELD
          // ========================================================

          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9.,]'),
              ),
            ],
            decoration: InputDecoration(
              prefixText: '$currencySymbol ',
              prefixStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3D004D),
              ),
              hintText: '0.00',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFF6B1FA2),
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ========================================================
          // PAYMENT TYPE
          // ========================================================

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFFE9DDEE),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: Color(0xFF6B1FA2),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment method',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Bank Transfer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3D004D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // ========================================================
          // STATUS INFORMATION
          // ========================================================

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFFE9DDEE),
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF6B1FA2),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Your giving will initially be marked '
                    'as pending. An authorized RHIC admin '
                    'will confirm the payment before it '
                    'is marked as verified.',
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

          // ========================================================
          // SUBMIT BUTTON
          // ========================================================

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed:
                  _submitting
                      ? null
                      : _submitGiving,
                      style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF6B1FA2),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFFB99AC5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(27),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirm Giving',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}