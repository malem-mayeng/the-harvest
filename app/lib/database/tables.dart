/// SQL constants for creating and managing database tables.
class Tables {
  Tables._();

  static const String buyersTable = 'buyers';
  static const String salesTable = 'sales';
  static const String paymentsTable = 'payments';
  static const String customItemsTable = 'custom_items';

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
      total_paid REAL NOT NULL DEFAULT 0,
      due_amount REAL NOT NULL,
      sale_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (buyer_id) REFERENCES $buyersTable (id)
    )
  ''';

  /// SQL to create the payments table.
  static const String createPaymentsTable = '''
    CREATE TABLE $paymentsTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      payment_date TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (sale_id) REFERENCES $salesTable (id) ON DELETE CASCADE
    )
  ''';

  /// SQL to create the custom items table.
  static const String createCustomItemsTable = '''
    CREATE TABLE $customItemsTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_name TEXT UNIQUE NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';
}
