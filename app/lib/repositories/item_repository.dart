import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/tables.dart';
import '../models/item_entry.dart';

/// Repository for the unified items table (defaults + custom, with price memory).
class ItemRepository {
  final DatabaseHelper _dbHelper;

  ItemRepository(this._dbHelper);

  /// Get all items ordered by sort_order.
  Future<List<ItemEntry>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(Tables.itemsTable, orderBy: 'sort_order ASC');
    return maps.map(ItemEntry.fromMap).toList();
  }

  /// Get just the names for the dropdown, in sort order.
  Future<List<String>> getAllNames() async {
    final items = await getAll();
    return items.map((e) => e.name).toList();
  }

  /// Get the stored unit price for a given item name. Returns 0 if not found.
  Future<double> getPrice(String itemName) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      Tables.itemsTable,
      columns: ['unit_price'],
      where: 'item_name = ?',
      whereArgs: [itemName],
      limit: 1,
    );
    if (result.isEmpty) return 0;
    return (result.first['unit_price'] as num).toDouble();
  }

  /// Upsert unit price for an item. Never overwrites with 0.
  Future<void> upsertPrice(String itemName, double price) async {
    if (price <= 0) return;
    final db = await _dbHelper.database;
    final existing = await db.query(
      Tables.itemsTable,
      where: 'item_name = ?',
      whereArgs: [itemName],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        Tables.itemsTable,
        {'unit_price': price},
        where: 'item_name = ?',
        whereArgs: [itemName],
      );
    } else {
      // Custom name typed via 'Other' — insert it
      final count = (await db.rawQuery('SELECT COUNT(*) as c FROM ${Tables.itemsTable}'))[0]['c'] as int;
      await db.insert(
        Tables.itemsTable,
        {
          'item_name': itemName,
          'unit_price': price,
          'price_unit': 'kg',
          'sort_order': count,
          'is_default': 0,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Add a new custom item.
  Future<void> addCustomItem(String name, {double price = 0, String priceUnit = 'kg'}) async {
    final db = await _dbHelper.database;
    final count = (await db.rawQuery('SELECT COUNT(*) as c FROM ${Tables.itemsTable}'))[0]['c'] as int;
    await db.insert(
      Tables.itemsTable,
      {
        'item_name': name.trim(),
        'unit_price': price,
        'price_unit': priceUnit,
        'sort_order': count,
        'is_default': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Update an item's name, price, and/or price_unit. All items are editable.
  Future<void> updateItem(int id, {String? name, double? price, String? priceUnit}) async {
    final db = await _dbHelper.database;
    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) updates['item_name'] = name.trim();
    if (price != null) updates['unit_price'] = price;
    if (priceUnit != null) updates['price_unit'] = priceUnit;
    if (updates.isEmpty) return;
    await db.update(Tables.itemsTable, updates, where: 'id = ?', whereArgs: [id]);
  }

  /// Persist the new order by updating sort_order for each id in the given order.
  Future<void> reorderItems(List<int> orderedIds) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        Tables.itemsTable,
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Delete a custom item by id.
  Future<void> deleteItem(int id) async {
    final db = await _dbHelper.database;
    await db.delete(Tables.itemsTable, where: 'id = ? AND is_default = 0', whereArgs: [id]);
  }
}
