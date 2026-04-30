/// Data model representing a payment transaction against a sale.
class Payment {
  final int? id;
  final int saleId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;

  // Joined fields (not stored in payments table)
  final String? itemName;
  final String? buyerName;

  Payment({
    this.id,
    required this.saleId,
    required this.amount,
    DateTime? paymentDate,
    this.notes,
    DateTime? createdAt,
    this.itemName,
    this.buyerName,
  })  : paymentDate = paymentDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Create a Payment from a SQLite row map.
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      itemName: map['item_name'] as String?,
      buyerName: map['buyer_name'] as String?,
    );
  }

  /// Convert this Payment to a map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sale_id': saleId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'Payment(#$id: ₹$amount for sale#$saleId)';
}
