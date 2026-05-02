import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/buyer.dart';

/// Repository for buyer CRUD operations against SQLite.
class BuyerRepository {
  final DatabaseHelper _dbHelper;

  BuyerRepository(this._dbHelper);

  /// Insert a new buyer and return the auto-generated id.
  Future<int> insert(Buyer buyer) async {
    final db = await _dbHelper.database;
    return await db.insert(Tables.buyersTable, buyer.toMap());
  }

  /// Get all buyers ordered by name.
  Future<List<Buyer>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      Tables.buyersTable,
      orderBy: 'buyer_name ASC',
    );
    return maps.map((map) => Buyer.fromMap(map)).toList();
  }

  /// Get a single buyer by id.
  Future<Buyer?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      Tables.buyersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Buyer.fromMap(maps.first);
  }

  /// Search buyers by name (case-insensitive partial match).
  Future<List<Buyer>> searchByName(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      Tables.buyersTable,
      where: 'buyer_name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'buyer_name ASC',
    );
    return maps.map((map) => Buyer.fromMap(map)).toList();
  }

  /// Generate the next buyer code (B001, B002, ...).
  Future<String> getNextBuyerCode() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${Tables.buyersTable}',
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return 'B${(count + 1).toString().padLeft(3, '0')}';
  }

  /// Update a buyer's name.
  Future<int> updateName(int buyerId, String newName) async {
    final db = await _dbHelper.database;
    return await db.update(
      Tables.buyersTable,
      {'buyer_name': newName.trim()},
      where: 'id = ?',
      whereArgs: [buyerId],
    );
  }

  /// Delete a buyer by id.
  Future<int> delete(int buyerId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      Tables.buyersTable,
      where: 'id = ?',
      whereArgs: [buyerId],
    );
  }
}
