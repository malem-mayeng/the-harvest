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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(Tables.createBuyersTable);
    await db.execute(Tables.createSalesTable);
    await db.execute(Tables.createPaymentsTable);
    await db.execute(Tables.createCustomItemsTable);
  }

  /// Migrate from version 1 to version 2.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add notes column to sales
      await db.execute(
        'ALTER TABLE ${Tables.salesTable} ADD COLUMN notes TEXT',
      );
      // Add total_paid column to sales
      await db.execute(
        'ALTER TABLE ${Tables.salesTable} ADD COLUMN total_paid REAL NOT NULL DEFAULT 0',
      );
      // Backfill total_paid from advance_paid for existing rows
      await db.execute(
        'UPDATE ${Tables.salesTable} SET total_paid = advance_paid',
      );
      // Create new tables
      await db.execute(Tables.createPaymentsTable);
      await db.execute(Tables.createCustomItemsTable);
    }
  }

  /// Close the database connection.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
