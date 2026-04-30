import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';

/// Repository for custom item CRUD operations against SQLite.
class CustomItemRepository {
  final DatabaseHelper _dbHelper;

  CustomItemRepository(this._dbHelper);

  /// Insert a custom item name. Ignores duplicates via UNIQUE constraint.
  Future<void> insert(String itemName) async {
    final db = await _dbHelper.database;
    await db.insert(
      Tables.customItemsTable,
      {
        'item_name': itemName.trim(),
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Get all custom item names, ordered alphabetically.
  Future<List<String>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      Tables.customItemsTable,
      orderBy: 'item_name ASC',
    );
    return maps.map((map) => map['item_name'] as String).toList();
  }

  /// Delete all custom items (reset to defaults).
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete(Tables.customItemsTable);
  }
}
