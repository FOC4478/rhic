import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String bookId;
  final String title;
  final String author;
  final String coverUrl;
  final double price;
  final String currency;
  final int quantity;

  const OrderItemModel({
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.price,
    required this.currency,
    required this.quantity,
  });

  factory OrderItemModel.fromMap(
    Map<String, dynamic> data,
  ) {
    return OrderItemModel(
      bookId: data['bookId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      author: data['author']?.toString() ?? '',
      coverUrl: data['coverUrl']?.toString() ?? '',
      price: data['price'] is num
          ? (data['price'] as num).toDouble()
          : double.tryParse(
                data['price']?.toString() ?? '',
              ) ??
              0,
      currency: data['currency']?.toString() ?? 'NGN',
      quantity: data['quantity'] is int
          ? data['quantity'] as int
          : int.tryParse(
                data['quantity']?.toString() ?? '',
              ) ??
              1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'price': price,
      'currency': currency,
      'quantity': quantity,
    };
  }

  double get total => price * quantity;
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItemModel> items;
  final double total;
  final String currency;
  final String status;
  final String paymentMethod;
  final String paymentReference;
  final String adminNote;
  final String? verifiedBy;
  final DateTime? createdAt;
  final DateTime? verifiedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.paymentReference,
    required this.adminNote,
    required this.verifiedBy,
    required this.createdAt,
    required this.verifiedAt,
  });

  factory OrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final rawItems = data['items'];

    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => OrderItemModel.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <OrderItemModel>[];

    return OrderModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      items: items,
      total: data['total'] is num
          ? (data['total'] as num).toDouble()
          : double.tryParse(
                data['total']?.toString() ?? '',
              ) ??
              0,
      currency: data['currency']?.toString() ?? 'NGN',
      status: data['status']?.toString() ?? 'pending',
      paymentMethod:
          data['paymentMethod']?.toString() ??
              'bank_transfer',
      paymentReference:
          data['paymentReference']?.toString() ?? '',
      adminNote: data['adminNote']?.toString() ?? '',
      verifiedBy: data['verifiedBy']?.toString(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      verifiedAt: data['verifiedAt'] is Timestamp
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
    );
  }
}