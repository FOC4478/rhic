import 'package:flutter/material.dart';

import 'giving_currency_screen.dart';

class GivingScreen extends StatelessWidget {
  const GivingScreen({
    super.key,
  });

  // ============================================================
  // OPEN CURRENCY SCREEN
  // ============================================================

  void _openGiving(
    BuildContext context,
    String type,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GivingCurrencyScreen(
          givingType: type,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF9F6FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'Giving',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF3D004D),
        elevation: 0,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: ListView(
        physics:
            const BouncingScrollPhysics(),

        padding:
            const EdgeInsets.fromLTRB(
          20,
          25,
          20,
          30,
        ),

        children: [
          // ======================================================
          // HEADER
          // ======================================================

          const Text(
            'Give to RHIC',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Choose what you would like to give towards.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 25),

          // ======================================================
          // TITHES
          // ======================================================

          _GivingCard(
            icon:
                Icons.volunteer_activism_outlined,
            title: 'Tithes',
            description:
                'Give your tithe faithfully and support the work of God.',
            onTap: () {
              _openGiving(
                context,
                'Tithes',
              );
            },
          ),

          // ======================================================
          // FIRST FRUIT
          // ======================================================

          _GivingCard(
            icon:
                Icons.spa_outlined,
            title: 'First Fruit',
            description:
                'Give your first fruit as an expression of gratitude.',
            onTap: () {
              _openGiving(
                context,
                'First Fruit',
              );
            },
          ),

          // ======================================================
          // PROPHET SEED
          // ======================================================

          _GivingCard(
            icon:
                Icons.auto_awesome_outlined,
            title: 'Prophet Seed',
            description:
                'Give towards a prophetic seed.',
            onTap: () {
              _openGiving(
                context,
                'Prophet Seed',
              );
            },
          ),

          // ======================================================
          // CHURCH PROJECTS
          // ======================================================

          _GivingCard(
            icon:
                Icons.business_outlined,
            title: 'Church Projects',
            description:
                'Support ongoing RHIC church projects.',
            onTap: () {
              _openGiving(
                context,
                'Church Projects',
              );
            },
          ),

          // ======================================================
          // CHURCH GIVING
          // ======================================================

          _GivingCard(
            icon:
                Icons.church_outlined,
            title: 'Church Giving',
            description:
                'Support the general needs and ministry of RHIC.',
            onTap: () {
              _openGiving(
                context,
                'Church Giving',
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================================================================
// GIVING CARD
// ================================================================

class _GivingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _GivingCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.03),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(20),

        child: Padding(
          padding:
              const EdgeInsets.all(17),

          child: Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 54,
                height: 54,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFF1D9F7),

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: Icon(
                  icon,

                  color:
                      const Color(0xFF6B1FA2),

                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              // ==================================================
              // CONTENT
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF3D004D),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      description,

                      style:
                          TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // ARROW
              // ==================================================

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color:
                    Color(0xFF6B1FA2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}