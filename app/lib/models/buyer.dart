/// Data model representing a buyer in the system.
class Buyer {
  final int? id;
  final String buyerCode;
  final String buyerName;
  final DateTime createdAt;

  Buyer({
    this.id,
    required this.buyerCode,
    required this.buyerName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a Buyer from a SQLite row map.
  factory Buyer.fromMap(Map<String, dynamic> map) {
    return Buyer(
      id: map['id'] as int?,
      buyerCode: map['buyer_code'] as String,
      buyerName: map['buyer_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert this Buyer to a map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'buyer_code': buyerCode,
      'buyer_name': buyerName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with optional overrides.
  Buyer copyWith({
    int? id,
    String? buyerCode,
    String? buyerName,
    DateTime? createdAt,
  }) {
    return Buyer(
      id: id ?? this.id,
      buyerCode: buyerCode ?? this.buyerCode,
      buyerName: buyerName ?? this.buyerName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Buyer($buyerCode: $buyerName)';
}
