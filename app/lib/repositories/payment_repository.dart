import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/payment.dart';

/// Repository for payment CRUD operations against SQLite.
class PaymentRepository {
  final DatabaseHelper _dbHelper;

  PaymentRepository(this._dbHelper);

  /// Insert a new payment and return the auto-generated id.
  Future<int> insert(Payment payment) async {
    final db = await _dbHelper.database;
    return await db.insert(Tables.paymentsTable, payment.toMap());
  }

  /// Get all payments for a specific sale, ordered by date descending.
  Future<List<Payment>> getBySaleId(int saleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      Tables.paymentsTable,
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'payment_date DESC',
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  /// Get all payments for all sales of a specific buyer, with sale item info.
  /// Includes the sale's item_name for context in payment history.
  Future<List<Payment>> getByBuyerId(int buyerId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT p.*, s.item_name, b.buyer_name
      FROM ${Tables.paymentsTable} p
      INNER JOIN ${Tables.salesTable} s ON p.sale_id = s.id
      INNER JOIN ${Tables.buyersTable} b ON s.buyer_id = b.id
      WHERE s.buyer_id = ?
      ORDER BY p.payment_date DESC, p.created_at DESC
    ''', [buyerId]);
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  /// Delete all payments for a specific sale.
  Future<int> deleteBySaleId(int saleId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      Tables.paymentsTable,
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
  }

  /// Delete all payments for all sales of a specific buyer.
  Future<int> deleteByBuyerId(int buyerId) async {
    final db = await _dbHelper.database;
    return await db.rawDelete('''
      DELETE FROM ${Tables.paymentsTable}
      WHERE sale_id IN (
        SELECT id FROM ${Tables.salesTable} WHERE buyer_id = ?
      )
    ''', [buyerId]);
  }
}
