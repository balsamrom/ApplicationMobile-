class Order {
  int? id;
  int ownerId;
  String orderDate;     // garde String si tu veux
  double totalAmount;
  String status;
  String? deliveryAddress;
  Order({
    this.id,
    required this.ownerId,
    required this.orderDate,
    required this.totalAmount,
    this.status = 'En cours',
    this.deliveryAddress,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,            // ✅ snake_case
    'order_date': orderDate,        // ✅
    'total_amount': totalAmount,    // ✅
    'status': status,
    'delivery_address': deliveryAddress,
  };
  factory Order.fromMap(Map<String, dynamic> map) => Order(
    id: map['id'] as int?,
    ownerId: map['owner_id'] as int,                       // ✅
    orderDate: map['order_date'] as String,                // ✅
    totalAmount: (map['total_amount'] as num).toDouble(),  // ✅
    status: (map['status'] as String?) ?? 'En cours',
    deliveryAddress: map['delivery_address'] as String?,
  );
}
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
    'order_id': orderId,           // ✅ snake_case
    'product_id': productId,       // ✅
    'product_name': productName,   // ✅
    'quantity': quantity,
    'price': price,
  };
  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    id: map['id'] as int?,
    orderId: map['order_id'] as int?,                      // ✅
    productId: map['product_id'] as int,                   // ✅
    productName: map['product_name'] as String,            // ✅
    quantity: map['quantity'] as int,
    price: (map['price'] as num).toDouble(),               // ✅
  );
  double get totalPrice => price * quantity;
}
