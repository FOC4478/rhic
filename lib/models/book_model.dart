import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String category;
  final String coverUrl;
  final String ebookUrl;
  final double price;
  final String currency;
  final bool isPublished;
  final bool isFeatured;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.category,
    required this.coverUrl,
    required this.ebookUrl,
    required this.price,
    required this.currency,
    required this.isPublished,
    required this.isFeatured,
    this.createdAt,
    this.updatedAt,
  });

  factory BookModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return BookModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      author: data['author']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'General',
      coverUrl: data['coverUrl']?.toString() ?? '',
      ebookUrl: data['ebookUrl']?.toString() ?? '',
      price: _toDouble(data['price']),
      currency: data['currency']?.toString() ?? 'NGN',
      isPublished: data['isPublished'] == true,
      isFeatured: data['isFeatured'] == true,
      createdAt: _timestampToDate(data['createdAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'category': category,
      'coverUrl': coverUrl,
      'ebookUrl': ebookUrl,
      'price': price,
      'currency': currency,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
    };
  }

  String get formattedPrice {
    if (currency == 'NGN') {
      return '₦${price.toStringAsFixed(0)}';
    }

    return '$currency ${price.toStringAsFixed(2)}';
  }
}