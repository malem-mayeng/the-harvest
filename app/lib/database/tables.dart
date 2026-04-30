/// SQL constants for creating and managing database tables.
class Tables {
  Tables._();

  static const String buyersTable = 'buyers';
  static const String salesTable = 'sales';

  /// SQL to create the buyers table.
  static const String createBuyersTable = '''
    CREATE TABLE $buyersTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      buyer_code TEXT UNIQUE NOT NULL,
      buyer_name TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  /// SQL to create the sales table.
  static const String createSalesTable = '''
    CREATE TABLE $salesTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      buyer_id INTEGER NOT NULL,
      item_name TEXT NOT NULL,
      unit_type TEXT NOT NULL,
      quantity REAL NOT NULL,
      total_amount REAL NOT NULL,
      advance_paid REAL NOT NULL DEFAULT 0,
      due_amount REAL NOT NULL,
      sale_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (buyer_id) REFERENCES $buyersTable (id)
    )
  ''';
}
