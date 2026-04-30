import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/sale.dart';

/// Repository for sale CRUD operations against SQLite.
class SaleRepository {
  final DatabaseHelper _dbHelper;

  SaleRepository(this._dbHelper);

  /// Insert a new sale record and return the auto-generated id.
  Future<int> insert(Sale sale) async {
    final db = await _dbHelper.database;
    return await db.insert(Tables.salesTable, sale.toMap());
  }

  /// Update an existing sale record.
  Future<int> update(Sale sale) async {
    final db = await _dbHelper.database;
    return await db.update(
      Tables.salesTable,
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  /// Delete a sale record by id.
  Future<int> delete(int saleId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      Tables.salesTable,
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  /// Delete all sales for a specific buyer.
  Future<int> deleteByBuyerId(int buyerId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      Tables.salesTable,
      where: 'buyer_id = ?',
      whereArgs: [buyerId],
    );
  }

  /// Get all sales for a specific buyer, with buyer info joined.
  Future<List<Sale>> getByBuyerId(int buyerId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT s.*, b.buyer_name, b.buyer_code
      FROM ${Tables.salesTable} s
      INNER JOIN ${Tables.buyersTable} b ON s.buyer_id = b.id
      WHERE s.buyer_id = ?
      ORDER BY s.sale_date DESC
    ''', [buyerId]);
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  /// Get all pending (unpaid) sales, with buyer info joined.
  Future<List<Sale>> getPendingSales() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT s.*, b.buyer_name, b.buyer_code
      FROM ${Tables.salesTable} s
      INNER JOIN ${Tables.buyersTable} b ON s.buyer_id = b.id
      WHERE s.status = 'pending'
      ORDER BY s.sale_date DESC
    ''');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  /// Mark a sale as fully paid.
  Future<int> markAsPaid(int saleId) async {
    final db = await _dbHelper.database;
    return await db.update(
      Tables.salesTable,
      {
        'due_amount': 0,
        'status': 'paid',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  /// Update payment totals on a sale after a payment is recorded.
  Future<int> updatePaymentTotals({
    required int saleId,
    required double totalPaid,
    required double dueAmount,
    required String status,
  }) async {
    final db = await _dbHelper.database;
    return await db.update(
      Tables.salesTable,
      {
        'total_paid': totalPaid,
        'due_amount': dueAmount < 0 ? 0 : dueAmount,
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  /// Get a single sale by id with buyer info.
  Future<Sale?> getById(int saleId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT s.*, b.buyer_name, b.buyer_code
      FROM ${Tables.salesTable} s
      INNER JOIN ${Tables.buyersTable} b ON s.buyer_id = b.id
      WHERE s.id = ?
      LIMIT 1
    ''', [saleId]);
    if (maps.isEmpty) return null;
    return Sale.fromMap(maps.first);
  }
}
