import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String bookId;
  final String title;
  final String author;

  // Private Backblaze B2 object key for the cover.
  // This is NOT a public URL.
  final String coverObjectKey;

  // Private Backblaze B2 object key for the ebook.
  // This is NOT a public URL.
  final String ebookObjectKey;

  final double price;
  final String currency;
  final int quantity;
  final DateTime? addedAt;

  const CartItemModel({
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverObjectKey,
    required this.ebookObjectKey,
    required this.price,
    required this.currency,
    required this.quantity,
    this.addedAt,
  });

  factory CartItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return CartItemModel(
      bookId: data['bookId']?.toString() ?? doc.id,

      title: data['title']?.toString() ?? '',

      author: data['author']?.toString() ?? '',

      // B2 object key only.
      coverObjectKey:
          data['coverObjectKey']?.toString() ?? '',

      // B2 ebook object key only.
      ebookObjectKey:
          data['ebookObjectKey']?.toString() ?? '',

      price: data['price'] is num
          ? (data['price'] as num).toDouble()
          : double.tryParse(
                data['price']?.toString() ?? '',
              ) ??
              0,

      currency:
          data['currency']?.toString() ?? 'NGN',

      quantity: data['quantity'] is int
          ? data['quantity'] as int
          : int.tryParse(
                data['quantity']?.toString() ?? '',
              ) ??
              1,

      addedAt: data['addedAt'] is Timestamp
          ? (data['addedAt'] as Timestamp).toDate()
          : null,
    );
  }

  double get total {
    return price * quantity;
  }

  String get formattedPrice {
    if (currency == 'NGN') {
      return '₦${price.toStringAsFixed(0)}';
    }

    return '$currency ${price.toStringAsFixed(2)}';
  }

  String get formattedTotal {
    if (currency == 'NGN') {
      return '₦${total.toStringAsFixed(0)}';
    }

    return '$currency ${total.toStringAsFixed(2)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'title': title,
      'author': author,
      'coverObjectKey': coverObjectKey,
      'ebookObjectKey': ebookObjectKey,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      'addedAt': addedAt,
    };
  }
}