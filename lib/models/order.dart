
class Order {
  int? id;
  int ownerId;
  String orderDate;
  double totalAmount;
  String status;
  String? deliveryAddress;
  String? phoneNumber;
  String? deliveryMethod;
  String? paymentMethod;
  String? notes;

  Order({
    this.id,
    required this.ownerId,
    required this.orderDate,
    required this.totalAmount,
    this.status = 'En cours',
    this.deliveryAddress,
    this.phoneNumber,
    this.deliveryMethod,
    this.paymentMethod,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'order_date': orderDate,
    'total_amount': totalAmount,
    'status': status,
    'delivery_address': deliveryAddress,
    'phone_number': phoneNumber,
    'delivery_method': deliveryMethod,
    'payment_method': paymentMethod,
    'notes': notes,
  };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
    id: map['id'] as int?,
    ownerId: map['owner_id'] as int,
    orderDate: map['order_date'] as String,
    totalAmount: (map['total_amount'] as num).toDouble(),
    status: (map['status'] as String?) ?? 'En cours',
    deliveryAddress: map['delivery_address'] as String?,
    phoneNumber: map['phone_number'] as String?,
    deliveryMethod: map['delivery_method'] as String?,
    paymentMethod: map['payment_method'] as String?,
    notes: map['notes'] as String?,
  );

  // Helper pour obtenir DateTime depuis String
  DateTime get parsedDate => DateTime.parse(orderDate);

  // Helper pour formater la date
  String get formattedDate {
    try {
      final date = parsedDate;
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return orderDate;
    }
  }

  // ✅ MÉTHODE COPYWITH
  Order copyWith({
    int? id,
    int? ownerId,
    String? orderDate,
    double? totalAmount,
    String? status,
    String? deliveryAddress,
    String? phoneNumber,
    String? deliveryMethod,
    String? paymentMethod,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      orderDate: orderDate ?? this.orderDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }
}

// ==================== OrderItem ====================

class OrderItem {
  int? id;
  int? orderId;
  int productId;
  String productName;
  int quantity;
  double price;

  OrderItem({
    this.id,
    this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'order_id': orderId,
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'price': price,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    id: map['id'] as int?,
    orderId: map['order_id'] as int?,
    productId: map['product_id'] as int,
    productName: map['product_name'] as String,
    quantity: map['quantity'] as int,
    price: (map['price'] as num).toDouble(),
  );

  double get totalPrice => price * quantity;
}