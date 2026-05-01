/// Represents an item in the items table (default or custom), with a stored unit price.
class ItemEntry {
  final int? id;
  final String name;
  final double unitPrice;
  final String priceUnit; // 'kg' or 'piece'
  final int sortOrder;
  final bool isDefault;

  const ItemEntry({
    this.id,
    required this.name,
    this.unitPrice = 0,
    this.priceUnit = 'kg',
    this.sortOrder = 0,
    this.isDefault = false,
  });

  factory ItemEntry.fromMap(Map<String, dynamic> map) {
    return ItemEntry(
      id: map['id'] as int?,
      name: map['item_name'] as String,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      priceUnit: (map['price_unit'] as String?) ?? 'kg',
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isDefault: (map['is_default'] as int?) == 1,
    );
  }

  ItemEntry copyWith({String? name, double? unitPrice, String? priceUnit, int? sortOrder}) {
    return ItemEntry(
      id: id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      priceUnit: priceUnit ?? this.priceUnit,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault,
    );
  }
}
