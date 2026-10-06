/// A line of stock in a shopkeeper's store. Money in INR paise.
class ShopItem {
  final String id;
  final String shopId; // owner user id
  final String name;
  final String unit; // kg, packet, litre, bag
  final double quantity;
  final double reorderLevel; // below this the item is flagged "low"
  final int pricePaise; // selling price per unit
  final String supplier;
  final DateTime updatedAt;

  const ShopItem({
    required this.id,
    required this.shopId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.reorderLevel,
    required this.pricePaise,
    required this.supplier,
    required this.updatedAt,
  });

  bool get isOut => quantity <= 0;
  bool get isLow => !isOut && quantity <= reorderLevel;

  /// "12 kg", "3.5 litre" — whole numbers without a trailing ".0".
  String get quantityLabel {
    final q = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(1);
    return '$q $unit';
  }

  ShopItem copyWith({double? quantity}) => ShopItem(
    id: id,
    shopId: shopId,
    name: name,
    unit: unit,
    quantity: quantity ?? this.quantity,
    reorderLevel: reorderLevel,
    pricePaise: pricePaise,
    supplier: supplier,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'shop_id': shopId,
    'name': name,
    'unit': unit,
    'quantity': quantity,
    'reorder_level': reorderLevel,
    'price_paise': pricePaise,
    'supplier': supplier,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ShopItem.fromMap(Map<dynamic, dynamic> m) => ShopItem(
    id: m['id'] as String? ?? '',
    shopId: m['shop_id'] as String? ?? '',
    name: m['name'] as String? ?? '',
    unit: m['unit'] as String? ?? 'unit',
    quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
    reorderLevel: (m['reorder_level'] as num?)?.toDouble() ?? 0,
    pricePaise: (m['price_paise'] as num?)?.toInt() ?? 0,
    supplier: m['supplier'] as String? ?? '',
    updatedAt:
        DateTime.tryParse(m['updated_at'] as String? ?? '') ?? DateTime.now(),
  );
}

enum ShopOrderStatus { received, packed, delivered, cancelled }

extension ShopOrderStatusX on ShopOrderStatus {
  String get label => switch (this) {
    ShopOrderStatus.received => 'New',
    ShopOrderStatus.packed => 'Packed',
    ShopOrderStatus.delivered => 'Delivered',
    ShopOrderStatus.cancelled => 'Cancelled',
  };

  /// The next step a shopkeeper can move an order to, or null at the end.
  ShopOrderStatus? get next => switch (this) {
    ShopOrderStatus.received => ShopOrderStatus.packed,
    ShopOrderStatus.packed => ShopOrderStatus.delivered,
    _ => null,
  };

  String get nextActionLabel => switch (this) {
    ShopOrderStatus.received => 'Mark packed',
    ShopOrderStatus.packed => 'Mark delivered',
    _ => '',
  };

  bool get isOpen =>
      this == ShopOrderStatus.received || this == ShopOrderStatus.packed;

  static ShopOrderStatus fromId(String v) => ShopOrderStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => ShopOrderStatus.received,
  );
}

/// A customer's order placed with a shop.
class ShopOrder {
  final String id;
  final String shopId;
  final String customerName;
  final String customerPhone;
  final String itemsSummary; // "Rice 5 kg, Toor dal 1 kg"
  final int totalPaise;
  final ShopOrderStatus status;
  final bool paid;
  final DateTime createdAt;

  const ShopOrder({
    required this.id,
    required this.shopId,
    required this.customerName,
    required this.customerPhone,
    required this.itemsSummary,
    required this.totalPaise,
    required this.createdAt,
    this.status = ShopOrderStatus.received,
    this.paid = false,
  });

  ShopOrder copyWith({ShopOrderStatus? status, bool? paid}) => ShopOrder(
    id: id,
    shopId: shopId,
    customerName: customerName,
    customerPhone: customerPhone,
    itemsSummary: itemsSummary,
    totalPaise: totalPaise,
    createdAt: createdAt,
    status: status ?? this.status,
    paid: paid ?? this.paid,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'shop_id': shopId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'items_summary': itemsSummary,
    'total_paise': totalPaise,
    'status': status.name,
    'paid': paid,
    'created_at': createdAt.toIso8601String(),
  };

  factory ShopOrder.fromMap(Map<dynamic, dynamic> m) => ShopOrder(
    id: m['id'] as String? ?? '',
    shopId: m['shop_id'] as String? ?? '',
    customerName: m['customer_name'] as String? ?? '',
    customerPhone: m['customer_phone'] as String? ?? '',
    itemsSummary: m['items_summary'] as String? ?? '',
    totalPaise: (m['total_paise'] as num?)?.toInt() ?? 0,
    status: ShopOrderStatusX.fromId(m['status'] as String? ?? 'received'),
    paid: m['paid'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
