import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tables.dart';

/// Singleton helper for managing the SQLite database lifecycle.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  /// Get or create the database instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'the_harvest.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(Tables.createBuyersTable);
    await db.execute(Tables.createSalesTable);
    await db.execute(Tables.createPaymentsTable);
    await db.execute(Tables.createCustomItemsTable);
    await db.execute(Tables.createItemsTable);
    await _seedDefaultItems(db);
  }

  Future<void> _seedDefaultItems(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (var i = 0; i < Tables.defaultItemNames.length; i++) {
      await db.insert(
        Tables.itemsTable,
        {
          'item_name': Tables.defaultItemNames[i],
          'unit_price': 0,
          'price_unit': 'kg',
          'sort_order': i,
          'is_default': 1,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${Tables.salesTable} ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE ${Tables.salesTable} ADD COLUMN total_paid REAL NOT NULL DEFAULT 0');
      await db.execute('UPDATE ${Tables.salesTable} SET total_paid = advance_paid');
      await db.execute(Tables.createPaymentsTable);
      await db.execute(Tables.createCustomItemsTable);
    }
    if (oldVersion < 3) {
      await db.execute(Tables.createItemsTable);
      await _seedDefaultItems(db);
      final customItems = await db.query(Tables.customItemsTable);
      final now = DateTime.now().toIso8601String();
      for (var i = 0; i < customItems.length; i++) {
        final row = customItems[i];
        await db.insert(
          Tables.itemsTable,
          {
            'item_name': row['item_name'],
            'unit_price': 0,
            'price_unit': 'kg',
            'sort_order': Tables.defaultItemNames.length + i,
            'is_default': 0,
            'created_at': row['created_at'] ?? now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    if (oldVersion < 4) {
      // Check which columns already exist — the v3 path may have already created
      // the table with the new schema, so we must not add columns that are there.
      final colInfo = await db.rawQuery('PRAGMA table_info(${Tables.itemsTable})');
      final existingCols = colInfo.map((c) => c['name'] as String).toSet();

      if (!existingCols.contains('price_unit')) {
        await db.execute("ALTER TABLE ${Tables.itemsTable} ADD COLUMN price_unit TEXT DEFAULT 'kg'");
        await db.execute("UPDATE ${Tables.itemsTable} SET price_unit = 'kg' WHERE price_unit IS NULL");
      }
      if (!existingCols.contains('sort_order')) {
        await db.execute('ALTER TABLE ${Tables.itemsTable} ADD COLUMN sort_order INTEGER DEFAULT 0');
      }
      // Assign sort_order values regardless (idempotent — sets them to a stable order)
      final rows = await db.query(Tables.itemsTable, columns: ['id'], orderBy: 'is_default DESC, item_name ASC');
      for (var i = 0; i < rows.length; i++) {
        await db.update(Tables.itemsTable, {'sort_order': i}, where: 'id = ?', whereArgs: [rows[i]['id']]);
      }
    }
  }

  /// Close the database connection.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
