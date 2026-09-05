import 'package:flutter/material.dart';

class OrderSuccessScreen
    extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
  });

  static const Color purple =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration:
                    const BoxDecoration(
                  color: Color(0xFFEDE0F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 55,
                  color: purple,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Payment Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: darkPurple,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Your payment has been submitted successfully. An administrator will verify the transfer before your books are made available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color:
                      Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Order ID: $orderId',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      (route) =>
                          route.isFirst,
                    );
                  },
                  style: ElevatedButton
                      .styleFrom(
                    backgroundColor: purple,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        26,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Back to Shop',
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
    );
  }
}