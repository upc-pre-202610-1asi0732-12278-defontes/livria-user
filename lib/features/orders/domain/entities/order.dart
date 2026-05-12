import 'dart:convert';

class Order {
  final int id;
  final String code;
  final double total;
  final String status;
  final bool isDelivery;
  final DateTime date;
  final ShippingDetails? shippingDetails;
  final List<OrderItem> items;

  final String userEmail;
  final String userFullName;
  final String userPhone;

  Order({
    required this.id,
    required this.code,
    required this.total,
    required this.status,
    required this.isDelivery,
    required this.date,
    this.shippingDetails,
    required this.items,
    required this.userEmail,
    required this.userFullName,
    required this.userPhone,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? 0,
      code: map['code'] ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      isDelivery: map['isDelivery'] ?? false,

      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),

      shippingDetails: (map['shipping'] != null || map['shippingDetails'] != null)
          ? ShippingDetails.fromMap(map['shipping'] ?? map['shippingDetails'])
          : null,

      items: map['items'] != null
          ? List<OrderItem>.from(map['items']?.map((x) => OrderItem.fromMap(x)))
          : [],

      userEmail: map['userEmail'] ?? '',
      userFullName: map['userFullName'] ?? '',
      userPhone: map['userPhone'] ?? '',
    );
  }

  static List<Order> listFromJson(String source) {
    final List<dynamic> list = json.decode(source);
    return list.map((e) => Order.fromMap(e)).toList();
  }
}

class ShippingDetails {
  final String address;
  final String city;
  final String district;
  final String reference;
  final double price;

  ShippingDetails({
    required this.address,
    required this.city,
    required this.district,
    required this.reference,
    required this.price
  });

  factory ShippingDetails.fromMap(Map<String, dynamic> map) {
    return ShippingDetails(
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      reference: map['reference'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0
    );

  }


  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'district': district,
      'reference': reference,
      'price': price,
    };
  }
}

class OrderItem {
  final int id;
  final String bookTitle;
  final double bookPrice;
  final String bookCover;
  final int quantity;
  final double itemTotal;

  OrderItem({
    required this.id,
    required this.bookTitle,
    required this.bookPrice,
    required this.bookCover,
    required this.quantity,
    required this.itemTotal,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? 0,
      bookTitle: map['bookTitle'] ?? '',
      bookPrice: (map['bookPrice'] as num?)?.toDouble() ?? 0.0,
      bookCover: map['bookCover'] ?? '',
      quantity: map['quantity'] ?? 0,
      itemTotal: (map['itemTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}