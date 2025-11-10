class CartItem {
  int? id;
  int ownerId;
  int productId;
  int quantity;
  String productName;
  double productPrice;
  String? productPhoto;

  CartItem({
    this.id,
    required this.ownerId,
    required this.productId,
    required this.quantity,
    required this.productName,
    required this.productPrice,
    this.productPhoto,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,          // ✅ snake_case
    'product_id': productId,      // ✅
    'quantity': quantity,
    'product_name': productName,  // ✅
    'product_price': productPrice,// ✅
    'product_photo': productPhoto,
  };

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
    id: m['id'] as int?,
    ownerId: m['owner_id'] as int,                        // ✅
    productId: m['product_id'] as int,                    // ✅
    quantity: m['quantity'] as int,
    productName: m['product_name'] as String,             // ✅
    productPrice: (m['product_price'] as num).toDouble(), // ✅
    productPhoto: m['product_photo'] as String?,
  );
}
