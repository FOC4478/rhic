import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/payment_settings_model.dart';
import '../../../models/giving_model.dart';
import '../../../models/order_model.dart';
import '../../../repositories/payment_repository.dart';
import '../../../repositories/giving_repository.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({
    super.key,
  });

  @override
  State<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState
    extends State<AdminPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _paymentTypes = [
    'shop',
    'giving',
    'church_projects',
  ];

  final List<String> _currencies = [
    'NGN',
    'USD',
    'GBP',
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _paymentTypeLabel(
    String type,
  ) {
    switch (type) {
      case 'shop':
        return 'Book Shop';
      case 'giving':
        return 'Church Giving';
      case 'church_projects':
        return 'Church Projects';
      default:
        return type;
    }
  }

  String _currencySymbol(
    String currency,
  ) {
    switch (currency) {
      case 'NGN':
        return '₦';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F4F9),
      child: SafeArea(
        child: Column(
          children: [
            // ============================================================
            // MENU ICON
            // ============================================================

            Container(
              width: double.infinity,
              height: 56,
              color: Colors.white,
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (menuContext) {
                  return IconButton(
                    tooltip: 'Menu',
                    onPressed: () {
                      Scaffold.maybeOf(
                        menuContext,
                      )?.openDrawer();
                    },
                    icon: const Icon(
                      Icons.menu,
                      color: Color(0xFF3D004D),
                    ),
                  );
                },
              ),
            ),

            // ============================================================
            // PAYMENT CONTENT
            // ============================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(
                      height: 24,
                    ),

                    _buildPaymentSettingsSection(),

                    const SizedBox(
                      height: 32,
                    ),

                    _buildTransactionsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6B1FA2),
            Color(0xFF3D004D),
          ],
        ),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage payment accounts and verify '
            'book purchases and church giving.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT SETTINGS
  // ============================================================

  Widget _buildPaymentSettingsSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Accounts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3D004D),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Configure where members should send '
          'payments for each service.',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 18),

        LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            int columns = 1;

            if (constraints.maxWidth >= 1200) {
              columns = 3;
            } else if (constraints.maxWidth >= 700) {
              columns = 2;
            }

            final width =
                (constraints.maxWidth -
                        ((columns - 1) * 16)) /
                    columns;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final type in _paymentTypes)
                  for (final currency in _currencies)
                    SizedBox(
                      width: width,
                      child: _PaymentSettingCard(
                        paymentType: type,
                        currency: currency,
                        title:
                            _paymentTypeLabel(
                          type,
                        ),
                        symbol:
                            _currencySymbol(
                          currency,
                        ),
                        onEdit: () {
                          _openPaymentEditor(
                            paymentType: type,
                            currency: currency,
                          );
                        },
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT EDITOR
  // ============================================================

  Future<void> _openPaymentEditor({
    required String paymentType,
    required String currency,
  }) async {
    final existing =
        await PaymentRepository
            .instance
            .getPaymentSettings(
      paymentType: paymentType,
      currency: currency,
    );

    if (!mounted) return;

    final bankController =
        TextEditingController(
      text: existing?.bankName ?? '',
    );

    final accountNameController =
        TextEditingController(
      text: existing?.accountName ?? '',
    );

    final accountNumberController =
        TextEditingController(
      text: existing?.accountNumber ?? '',
    );

    final instructionsController =
        TextEditingController(
      text: existing?.instructions ?? '',
    );

    bool isActive =
        existing?.isActive ?? true;

    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final screenSize =
            MediaQuery.sizeOf(dialogContext);

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              title: Text(
                '${_paymentTypeLabel(paymentType)} • $currency',
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      screenSize.width < 700
                          ? screenSize.width - 32
                          : 500,
                  maxHeight:
                      screenSize.height * 0.68,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      _field(
                        controller:
                            bankController,
                        label: 'Bank Name',
                        icon:
                            Icons.account_balance,
                      ),
                      const SizedBox(
                        height: 14,
                      ),

                      _field(
                        controller:
                            accountNameController,
                        label: 'Account Name',
                        icon:
                            Icons.person_outline,
                      ),
                      const SizedBox(
                        height: 14,
                      ),

                      _field(
                        controller:
                            accountNumberController,
                        label:
                            'Account Number',
                        icon:
                            Icons.numbers,
                        keyboardType:
                            TextInputType.number,
                      ),
                      const SizedBox(
                        height: 14,
                      ),

                      _field(
                        controller:
                            instructionsController,
                        label:
                            'Payment Instructions',
                        icon:
                            Icons.info_outline,
                        maxLines: 4,
                      ),
                      const SizedBox(
                        height: 8,
                      ),

                      SwitchListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title: const Text(
                          'Payment Active',
                        ),
                        subtitle: Text(
                          isActive
                              ? 'Members can use this account.'
                              : 'Members will not see this account.',
                        ),
                        value: isActive,
                        activeThumbColor:
                            const Color(
                          0xFF6B1FA2,
                        ),
                        onChanged: saving
                            ? null
                            : (value) {
                                setDialogState(
                                  () {
                                    isActive =
                                        value;
                                  },
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF6B1FA2,
                    ),
                    foregroundColor:
                        Colors.white,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final admin =
                              FirebaseAuth
                                  .instance
                                  .currentUser;

                          if (admin == null) {
                            _showMessage(
                              'Admin account could not be identified.',
                            );
                            return;
                          }

                          if (bankController
                              .text
                              .trim()
                              .isEmpty ||
                              accountNameController
                                  .text
                                  .trim()
                                  .isEmpty ||
                              accountNumberController
                                  .text
                                  .trim()
                                  .isEmpty) {
                            _showMessage(
                              'Please complete the bank details.',
                            );
                            return;
                          }

                          setDialogState(
                            () {
                              saving = true;
                            },
                          );

                          try {
                            await PaymentRepository
                                .instance
                                .savePaymentSettings(
                              paymentType:
                                  paymentType,
                              currency:
                                  currency,
                              bankName:
                                  bankController
                                      .text,
                              accountName:
                                  accountNameController
                                      .text,
                              accountNumber:
                                  accountNumberController
                                      .text,
                              instructions:
                                  instructionsController
                                      .text,
                              isActive:
                                  isActive,
                              adminId:
                                  admin.uid,
                            );

                            if (!context.mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                            );

                            _showMessage(
                              'Payment settings saved successfully.',
                            );

                            setState(() {});
                          } catch (e) {
                            setDialogState(
                              () {
                                saving = false;
                              },
                            );

                            _showMessage(
                              e
                                  .toString()
                                  .replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    bankController.dispose();
    accountNameController.dispose();
    accountNumberController.dispose();
    instructionsController.dispose();
  }

  // ============================================================
  // TRANSACTIONS
  // ============================================================

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Transactions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3D004D),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Review and verify payments made by members.',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 18),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              TabBar(
                controller:
                    _tabController,
                labelColor:
                    const Color(
                  0xFF6B1FA2,
                ),
                unselectedLabelColor:
                    Colors.black54,
                indicatorColor:
                    const Color(
                  0xFF6B1FA2,
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Shop'),
                  Tab(text: 'Giving'),
                ],
              ),
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller:
                      _tabController,
                  children: [
                    _buildAllTransactions(),
                    _buildShopTransactions(),
                    _buildGivingTransactions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ALL
  // ============================================================

  Widget _buildAllTransactions() {
    return StreamBuilder<List<OrderModel>>(
      stream: PaymentRepository
          .instance
          .adminOrdersStream(),
      builder: (
        context,
        orderSnapshot,
      ) {
        return StreamBuilder<List<GivingModel>>(
          stream: GivingRepository
              .instance
              .adminGivingStream(),
          builder: (
            context,
            givingSnapshot,
          ) {
            if (orderSnapshot.connectionState ==
                    ConnectionState.waiting ||
                givingSnapshot.connectionState ==
                    ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (orderSnapshot.hasError ||
                givingSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Text(
                    'Unable to load transactions.',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              );
            }

            final orders =
                orderSnapshot.data ??
                    <OrderModel>[];

            final givings =
                givingSnapshot.data ??
                    <GivingModel>[];

            return ListView(
              padding:
                  const EdgeInsets.all(16),
              children: [
                if (orders.isEmpty &&
                    givings.isEmpty)
                  _emptyTransactions(),

                ...orders.map(
                  (order) =>
                      _buildOrderCard(order),
                ),

                ...givings.map(
                  (giving) =>
                      _buildGivingCard(
                    giving,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SHOP
  // ============================================================

  Widget _buildShopTransactions() {
    return StreamBuilder<List<OrderModel>>(
      stream: PaymentRepository
          .instance
          .adminOrdersStream(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Unable to load shop transactions.',
            ),
          );
        }

        final orders =
            snapshot.data ?? <OrderModel>[];

        if (orders.isEmpty) {
          return _emptyTransactions();
        }

        return ListView(
          padding:
              const EdgeInsets.all(16),
          children: orders
              .map(
                _buildOrderCard,
              )
              .toList(),
        );
      },
    );
  }

  // ============================================================
  // GIVING
  // ============================================================

  Widget _buildGivingTransactions() {
    return StreamBuilder<List<GivingModel>>(
      stream: GivingRepository
          .instance
          .adminGivingStream(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Unable to load giving transactions.',
            ),
          );
        }

        final givings =
            snapshot.data ??
                <GivingModel>[];

        if (givings.isEmpty) {
          return _emptyTransactions();
        }

        return ListView(
          padding:
              const EdgeInsets.all(16),
          children: givings
              .map(
                _buildGivingCard,
              )
              .toList(),
        );
      },
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(
    OrderModel order,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment:
                  WrapAlignment.spaceBetween,
              crossAxisAlignment:
                  WrapCrossAlignment.center,
              children: [
                _typeBadge(
                  'BOOK SHOP',
                  const Color(
                    0xFF6B1FA2,
                  ),
                ),
                _statusBadge(
                  order.status,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              order.items
                  .map(
                    (item) =>
                        '${item.title} × ${item.quantity}',
                  )
                  .join(', '),
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Amount: ${_currencySymbol(order.currency)}'
              '${order.total.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 4),

            Text(
              'Payment reference: '
              '${order.paymentReference.isEmpty ? 'Not provided' : order.paymentReference}',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'User: ${order.userId}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),

            if (order.adminNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Admin note: ${order.adminNote}',
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ],

            if (order.status ==
                'pending') ...[
              const SizedBox(height: 14),
              _transactionActions(
                onApprove: () =>
                    _verifyOrder(
                  order,
                  true,
                ),
                onReject: () =>
                    _verifyOrder(
                  order,
                  false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GIVING CARD
  // ============================================================

  Widget _buildGivingCard(
    GivingModel giving,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment:
                  WrapAlignment.spaceBetween,
              crossAxisAlignment:
                  WrapCrossAlignment.center,
              children: [
                _typeBadge(
                  giving.type.toUpperCase(),
                  const Color(
                    0xFFF7931E,
                  ),
                ),
                _statusBadge(
                  giving.status,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              giving.userName,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              '${giving.currency} '
              '${giving.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Payment method: '
              '${giving.paymentMethod}',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),

            Text(
              'User ID: ${giving.userId}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),

            if (giving.adminNote !=
                    null &&
                giving.adminNote!
                    .isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Admin note: '
                '${giving.adminNote}',
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ],

            if (giving.status ==
                'pending') ...[
              const SizedBox(height: 14),
              _transactionActions(
                onApprove: () =>
                    _verifyGiving(
                  giving,
                  true,
                ),
                onReject: () =>
                    _verifyGiving(
                  giving,
                  false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VERIFY ORDER
  // ============================================================

  Future<void> _verifyOrder(
    OrderModel order,
    bool approve,
  ) async {
    final admin =
        FirebaseAuth.instance.currentUser;

    if (admin == null) {
      _showMessage(
        'Admin account could not be identified.',
      );
      return;
    }

    final note =
        await _askForAdminNote(
      approve: approve,
    );

    if (note == null) {
      return;
    }

    try {
      if (approve) {
        await PaymentRepository
            .instance
            .approveOrder(
          orderId: order.id,
          adminId: admin.uid,
          adminNote: note,
        );
      } else {
        await PaymentRepository
            .instance
            .rejectOrder(
          orderId: order.id,
          adminId: admin.uid,
          adminNote: note,
        );
      }

      _showMessage(
        approve
            ? 'Order approved.'
            : 'Order rejected.',
      );
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // VERIFY GIVING
  // ============================================================

  Future<void> _verifyGiving(
    GivingModel giving,
    bool approve,
  ) async {
    final admin =
        FirebaseAuth.instance.currentUser;

    if (admin == null) {
      _showMessage(
        'Admin account could not be identified.',
      );
      return;
    }

    final note =
        await _askForAdminNote(
      approve: approve,
    );

    if (note == null) {
      return;
    }

    try {
      if (approve) {
        await GivingRepository
            .instance
            .approveGiving(
          givingId: giving.id,
          adminId: admin.uid,
          adminNote: note,
        );
      } else {
        await GivingRepository
            .instance
            .rejectGiving(
          givingId: giving.id,
          adminId: admin.uid,
          adminNote: note,
        );
      }

      _showMessage(
        approve
            ? 'Giving approved.'
            : 'Giving rejected.',
      );
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // ADMIN NOTE
  // ============================================================

  Future<String?> _askForAdminNote({
    required bool approve,
  }) async {
    final controller =
        TextEditingController();

    final result =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            approve
                ? 'Approve Transaction'
                : 'Reject Transaction',
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration:
                const InputDecoration(
              labelText:
                  'Admin note (optional)',
              border:
                  OutlineInputBorder(),
              hintText:
                  'Add a note for this transaction',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
              ),
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    approve
                        ? const Color(
                            0xFF2E7D32,
                          )
                        : const Color(
                            0xFFC62828,
                          ),
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(
                context,
                controller.text.trim(),
              ),
              child: Text(
                approve
                    ? 'Approve'
                    : 'Reject',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  // ============================================================
  // WIDGET HELPERS
  // ============================================================

  Widget _transactionActions({
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(
              Icons.check,
              size: 18,
            ),
            label:
                const Text('Approve'),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(
                0xFF2E7D32,
              ),
              foregroundColor:
                  Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(
              Icons.close,
              size: 18,
            ),
            label:
                const Text('Reject'),
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(
                0xFFC62828,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.1,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    final isApproved =
        status == 'approved';
    final isRejected =
        status == 'rejected';

    final color = isApproved
        ? const Color(0xFF2E7D32)
        : isRejected
            ? const Color(0xFFC62828)
            : const Color(0xFFF7931E);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.1,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptyTransactions() {
    return const Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 50,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'No transactions found.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border:
            const OutlineInputBorder(),
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// ============================================================
// PAYMENT SETTING CARD
// ============================================================

class _PaymentSettingCard
    extends StatelessWidget {
  final String paymentType;
  final String currency;
  final String title;
  final String symbol;
  final VoidCallback onEdit;

  const _PaymentSettingCard({
    required this.paymentType,
    required this.currency,
    required this.title,
    required this.symbol,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        PaymentSettingsModel?>(
      stream: PaymentRepository
          .instance
          .paymentSettingsStream(
        paymentType:
            paymentType,
        currency: currency,
      ),
      builder: (
        context,
        snapshot,
      ) {
        final settings =
            snapshot.data;

        final configured =
            settings != null &&
                settings.bankName
                    .isNotEmpty &&
                settings.accountName
                    .isNotEmpty &&
                settings.accountNumber
                    .isNotEmpty;

        return Container(
          padding:
              const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: configured
                  ? const Color(
                      0xFF6B1FA2,
                    ).withValues(
                      alpha: 0.18,
                    )
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(
                      10,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFF6B1FA2,
                      ).withValues(
                        alpha: 0.1,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child: Text(
                      symbol,
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF6B1FA2,
                        ),
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          title,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        Text(
                          currency,
                          style:
                              const TextStyle(
                            color:
                                Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    configured
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    color: configured
                        ? const Color(
                            0xFF2E7D32,
                          )
                        : const Color(
                            0xFFF7931E,
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                configured
                    ? settings.bankName
                    : 'Not configured',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              if (configured) ...[
                const SizedBox(height: 4),
                Text(
                  settings
                      .accountName,
                  style:
                      const TextStyle(
                    color:
                        Colors.black54,
                  ),
                ),
                Text(
                  settings
                      .accountNumber,
                  style:
                      const TextStyle(
                    color:
                        Colors.black54,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                  ),
                  label: Text(
                    configured
                        ? 'Edit'
                        : 'Configure',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}