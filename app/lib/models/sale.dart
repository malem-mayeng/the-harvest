/// Data model representing a sale record.
class Sale {
  final int? id;
  final int buyerId;
  final String itemName;
  final String unitType; // 'count' or 'weight'
  final double quantity;
  final double totalAmount;
  final double advancePaid;
  final double totalPaid;
  final double dueAmount;
  final DateTime saleDate;
  final String status; // 'pending' or 'paid'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined field (not stored in sales table)
  final String? buyerName;
  final String? buyerCode;

  Sale({
    this.id,
    required this.buyerId,
    required this.itemName,
    required this.unitType,
    required this.quantity,
    required this.totalAmount,
    required this.advancePaid,
    double? totalPaid,
    double? dueAmount,
    DateTime? saleDate,
    this.status = 'pending',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.buyerName,
    this.buyerCode,
  })  : totalPaid = totalPaid ?? advancePaid,
        dueAmount = dueAmount ?? (totalAmount - (totalPaid ?? advancePaid)).clamp(0, double.infinity),
        saleDate = saleDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a Sale from a SQLite row map (may include joined buyer fields).
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      buyerId: map['buyer_id'] as int,
      itemName: map['item_name'] as String,
      unitType: map['unit_type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      advancePaid: (map['advance_paid'] as num).toDouble(),
      totalPaid: (map['total_paid'] as num?)?.toDouble() ?? (map['advance_paid'] as num).toDouble(),
      dueAmount: (map['due_amount'] as num).toDouble(),
      saleDate: DateTime.parse(map['sale_date'] as String),
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      buyerName: map['buyer_name'] as String?,
      buyerCode: map['buyer_code'] as String?,
    );
  }

  /// Convert this Sale to a map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'buyer_id': buyerId,
      'item_name': itemName,
      'unit_type': unitType,
      'quantity': quantity,
      'total_amount': totalAmount,
      'advance_paid': advancePaid,
      'total_paid': totalPaid,
      'due_amount': dueAmount,
      'sale_date': saleDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with optional overrides.
  Sale copyWith({
    int? id,
    int? buyerId,
    String? itemName,
    String? unitType,
    double? quantity,
    double? totalAmount,
    double? advancePaid,
    double? totalPaid,
    double? dueAmount,
    DateTime? saleDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? buyerName,
    String? buyerCode,
  }) {
    return Sale(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      itemName: itemName ?? this.itemName,
      unitType: unitType ?? this.unitType,
      quantity: quantity ?? this.quantity,
      totalAmount: totalAmount ?? this.totalAmount,
      advancePaid: advancePaid ?? this.advancePaid,
      totalPaid: totalPaid ?? this.totalPaid,
      dueAmount: dueAmount ?? this.dueAmount,
      saleDate: saleDate ?? this.saleDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      buyerName: buyerName ?? this.buyerName,
      buyerCode: buyerCode ?? this.buyerCode,
    );
  }

  /// Whether this sale still has an outstanding balance.
  bool get isPending => status == 'pending';

  @override
  String toString() => 'Sale(#$id: $itemName, ₹$totalAmount, due: ₹$dueAmount)';
}
