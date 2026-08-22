import 'package:flutter/material.dart';

import 'giving_payment_details_screen.dart';

class GivingCurrencyScreen extends StatelessWidget {
  final String givingType;

  const GivingCurrencyScreen({
    super.key,
    required this.givingType,
  });

  void _openPaymentDetails(
    BuildContext context,
    String currency,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GivingPaymentDetailsScreen(
          givingType: givingType,
          currency: currency,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FA),

      appBar: AppBar(
        title: Text(
          givingType,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D004D),
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),

          const Text(
            'Choose Currency',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Select the currency you would like to use for your $givingType.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 28),

          // ======================================================
          // NAIRA
          // ======================================================

          _CurrencyCard(
            symbol: '₦',
            currency: 'Naira',
            code: 'NGN',
            description: 'Nigerian Naira',
            onTap: () {
              _openPaymentDetails(
                context,
                'NGN',
              );
            },
          ),

          // ======================================================
          // US DOLLAR
          // ======================================================

          _CurrencyCard(
            symbol: '\$',
            currency: 'US Dollar',
            code: 'USD',
            description: 'United States Dollar',
            onTap: () {
              _openPaymentDetails(
                context,
                'USD',
              );
            },
          ),

          // ======================================================
          // BRITISH POUND
          // ======================================================

          _CurrencyCard(
            symbol: '£',
            currency: 'British Pound',
            code: 'GBP',
            description: 'British Pound Sterling',
            onTap: () {
              _openPaymentDetails(
                context,
                'GBP',
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================================================================
// CURRENCY CARD
// ================================================================

class _CurrencyCard extends StatelessWidget {
  final String symbol;
  final String currency;
  final String code;
  final String description;
  final VoidCallback onTap;

  const _CurrencyCard({
    required this.symbol,
    required this.currency,
    required this.code,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              // ==================================================
              // SYMBOL
              // ==================================================

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1D9F7),
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B1FA2),
                  ),
                ),
              ),

              const SizedBox(width: 15),

              // ==================================================
              // INFORMATION
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3D004D),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$code • $description',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ARROW
              // ==================================================

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF6B1FA2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}