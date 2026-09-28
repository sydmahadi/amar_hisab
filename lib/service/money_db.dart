import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class MoneyDb {
  MoneyDb._();

  static final MoneyDb instance = MoneyDb._();

  Database? _db;

  Database get db {
    if (_db == null) {
      throw Exception('MoneyDb has not been initialized.');
    }
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'amar_hisab.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await _createTables(database);
        await _insertDefaultAccounts(database);
        await _insertDefaultCategories(database);
      },
    );
  }

  // ============================================================
  // DATABASE TABLES
  // ============================================================

  Future<void> _createTables(Database database) async {
    // ----------------------------------------------------------
    // Accounts
    // ----------------------------------------------------------

    await database.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        icon TEXT,
        color INTEGER,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ----------------------------------------------------------
    // Categories
    // ----------------------------------------------------------

    await database.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color INTEGER,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ----------------------------------------------------------
    // Transactions
    // ----------------------------------------------------------

    await database.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER,
        account_id INTEGER,
        from_account_id INTEGER,
        to_account_id INTEGER,
        note TEXT,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id),
        FOREIGN KEY (account_id) REFERENCES accounts(id),
        FOREIGN KEY (from_account_id) REFERENCES accounts(id),
        FOREIGN KEY (to_account_id) REFERENCES accounts(id)
      )
    ''');

    // Indexes
    await database.execute('''
      CREATE INDEX idx_transactions_date
      ON transactions(transaction_date)
    ''');

    await database.execute('''
      CREATE INDEX idx_transactions_type
      ON transactions(type)
    ''');

    await database.execute('''
      CREATE INDEX idx_transactions_category
      ON transactions(category_id)
    ''');

    await database.execute('''
      CREATE INDEX idx_transactions_account
      ON transactions(account_id)
    ''');
  }

  // ============================================================
  // DEFAULT ACCOUNTS
  // ============================================================

  Future<void> _insertDefaultAccounts(Database database) async {
    final now = DateTime.now().toIso8601String();

    final accounts = [
      {
        'name': 'Cash',
        'type': 'cash',
        'balance': 0.0,
        'icon': 'account_balance_wallet',
        'color': 0xFF176B45,
        'is_default': 1,
      },
      {
        'name': 'Bkash',
        'type': 'bkash',
        'balance': 0.0,
        'icon': 'phone_android',
        'color': 0xFFE2136E,
        'is_default': 1,
      },
      {
        'name': 'Nagad',
        'type': 'nagad',
        'balance': 0.0,
        'icon': 'phone_android',
        'color': 0xFFF7941D,
        'is_default': 1,
      },
      {
        'name': 'Bank Account',
        'type': 'bank',
        'balance': 0.0,
        'icon': 'account_balance',
        'color': 0xFF246B4A,
        'is_default': 1,
      },
      {
        'name': 'Card',
        'type': 'card',
        'balance': 0.0,
        'icon': 'credit_card',
        'color': 0xFFC9A45C,
        'is_default': 1,
      },
    ];

    for (final account in accounts) {
      await database.insert(
        'accounts',
        {
          ...account,
          'created_at': now,
        },
      );
    }
  }

  // ============================================================
  // DEFAULT CATEGORIES
  // ============================================================

  Future<void> _insertDefaultCategories(Database database) async {
    final now = DateTime.now().toIso8601String();

    // ----------------------------------------------------------
    // Income Categories
    // ----------------------------------------------------------

    final incomeCategories = [
      {
        'name': 'Salary',
        'type': 'income',
        'icon': 'payments',
        'color': 0xFF176B45,
      },
      {
        'name': 'Business',
        'type': 'income',
        'icon': 'business_center',
        'color': 0xFF246B4A,
      },
      {
        'name': 'Bonus',
        'type': 'income',
        'icon': 'card_giftcard',
        'color': 0xFFC9A45C,
      },
      {
        'name': 'Other Income',
        'type': 'income',
        'icon': 'add_circle',
        'color': 0xFF2E7D32,
      },
    ];

    // ----------------------------------------------------------
    // Expense Categories
    // ----------------------------------------------------------

    final expenseCategories = [
      {
        'name': 'Food',
        'type': 'expense',
        'icon': 'restaurant',
        'color': 0xFFE57373,
      },
      {
        'name': 'Shopping',
        'type': 'expense',
        'icon': 'shopping_cart',
        'color': 0xFFBA68C8,
      },
      {
        'name': 'Transport',
        'type': 'expense',
        'icon': 'directions_car',
        'color': 0xFF64B5F6,
      },
      {
        'name': 'Rent',
        'type': 'expense',
        'icon': 'home',
        'color': 0xFFFFB74D,
      },
      {
        'name': 'Bills',
        'type': 'expense',
        'icon': 'receipt_long',
        'color': 0xFF4DB6AC,
      },
      {
        'name': 'Medical',
        'type': 'expense',
        'icon': 'medical_services',
        'color': 0xFFE57373,
      },
      {
        'name': 'Education',
        'type': 'expense',
        'icon': 'school',
        'color': 0xFF7986CB,
      },
      {
        'name': 'Family',
        'type': 'expense',
        'icon': 'family_restroom',
        'color': 0xFFF06292,
      },
      {
        'name': 'Other Expense',
        'type': 'expense',
        'icon': 'more_horiz',
        'color': 0xFF90A4AE,
      },
    ];

    for (final category in incomeCategories) {
      await database.insert(
        'categories',
        {
          ...category,
          'is_default': 1,
          'created_at': now,
        },
      );
    }

    for (final category in expenseCategories) {
      await database.insert(
        'categories',
        {
          ...category,
          'is_default': 1,
          'created_at': now,
        },
      );
    }
  }

  // ============================================================
  // ACCOUNT METHODS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAccounts() async {
    return db.query(
      'accounts',
      orderBy: 'id ASC',
    );
  }

  Future<Map<String, dynamic>?> getAccount(int id) async {
    final result = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  Future<int> addAccount({
    required String name,
    required String type,
    double balance = 0,
    String? icon,
    int? color,
  }) async {
    return db.insert(
      'accounts',
      {
        'name': name,
        'type': type,
        'balance': balance,
        'icon': icon,
        'color': color,
        'is_default': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> updateAccount({
    required int id,
    required String name,
    String? type,
    double? balance,
    String? icon,
    int? color,
  }) async {
    final data = <String, dynamic>{
      'name': name,
    };

    if (type != null) data['type'] = type;
    if (balance != null) data['balance'] = balance;
    if (icon != null) data['icon'] = icon;
    if (color != null) data['color'] = color;

    return db.update(
      'accounts',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final account = await getAccount(id);

    if (account == null) return 0;

    if ((account['is_default'] ?? 0) == 1) {
      throw Exception('Default accounts cannot be deleted.');
    }

    final transactionCount = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) 
            FROM transactions
            WHERE account_id = ?
               OR from_account_id = ?
               OR to_account_id = ?
            ''',
            [id, id, id],
          ),
        ) ??
        0;

    if (transactionCount > 0) {
      throw Exception(
        'This account has transactions and cannot be deleted.',
      );
    }

    return db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // CATEGORY METHODS
  // ============================================================

  Future<List<Map<String, dynamic>>> getCategories({
    String? type,
  }) async {
    if (type == null) {
      return db.query(
        'categories',
        orderBy: 'id ASC',
      );
    }

    return db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'id ASC',
    );
  }

  Future<Map<String, dynamic>?> getCategory(int id) async {
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  Future<int> addCategory({
    required String name,
    required String type,
    String? icon,
    int? color,
  }) async {
    return db.insert(
      'categories',
      {
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'is_default': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> updateCategory({
    required int id,
    required String name,
    String? icon,
    int? color,
  }) async {
    return db.update(
      'categories',
      {
        'name': name,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final category = await getCategory(id);

    if (category == null) return 0;

    if ((category['is_default'] ?? 0) == 1) {
      throw Exception('Default categories cannot be deleted.');
    }

    final transactionCount = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM transactions
            WHERE category_id = ?
            ''',
            [id],
          ),
        ) ??
        0;

    if (transactionCount > 0) {
      throw Exception(
        'This category has transactions and cannot be deleted.',
      );
    }

    return db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // TRANSACTION METHODS
  // ============================================================

  Future<int> addTransaction({
    required String type,
    required double amount,
    int? categoryId,
    int? accountId,
    int? fromAccountId,
    int? toAccountId,
    String? note,
    required DateTime transactionDate,
  }) async {
    return db.transaction((txn) async {
      final id = await txn.insert(
        'transactions',
        {
          'type': type,
          'amount': amount,
          'category_id': categoryId,
          'account_id': accountId,
          'from_account_id': fromAccountId,
          'to_account_id': toAccountId,
          'note': note,
          'transaction_date': transactionDate.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      await _recalculateAllAccountBalances(txn);

      return id;
    });
  }

  Future<int> updateTransaction({
    required int id,
    required String type,
    required double amount,
    int? categoryId,
    int? accountId,
    int? fromAccountId,
    int? toAccountId,
    String? note,
    required DateTime transactionDate,
  }) async {
    return db.transaction((txn) async {
      final result = await txn.update(
        'transactions',
        {
          'type': type,
          'amount': amount,
          'category_id': categoryId,
          'account_id': accountId,
          'from_account_id': fromAccountId,
          'to_account_id': toAccountId,
          'note': note,
          'transaction_date': transactionDate.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _recalculateAllAccountBalances(txn);

      return result;
    });
  }

  Future<int> deleteTransaction(int id) async {
    return db.transaction((txn) async {
      final result = await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );

      await _recalculateAllAccountBalances(txn);

      return result;
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    String? type,
    int? accountId,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      conditions.add('t.type = ?');
      args.add(type);
    }

    if (accountId != null) {
      conditions.add('''
        (
          t.account_id = ?
          OR t.from_account_id = ?
          OR t.to_account_id = ?
        )
      ''');

      args.add(accountId);
      args.add(accountId);
      args.add(accountId);
    }

    if (categoryId != null) {
      conditions.add('t.category_id = ?');
      args.add(categoryId);
    }

    if (startDate != null) {
      conditions.add('t.transaction_date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      conditions.add('t.transaction_date <= ?');
      args.add(endDate.toIso8601String());
    }

    final whereClause =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    return db.rawQuery(
      '''
      SELECT
        t.*,
        c.name AS category_name,
        c.icon AS category_icon,
        a.name AS account_name,
        fa.name AS from_account_name,
        ta.name AS to_account_name
      FROM transactions t
      LEFT JOIN categories c
        ON c.id = t.category_id
      LEFT JOIN accounts a
        ON a.id = t.account_id
      LEFT JOIN accounts fa
        ON fa.id = t.from_account_id
      LEFT JOIN accounts ta
        ON ta.id = t.to_account_id
      $whereClause
      ORDER BY t.transaction_date DESC, t.id DESC
      ''',
      args,
    );
  }

  Future<Map<String, dynamic>?> getTransaction(int id) async {
    final result = await db.rawQuery(
      '''
      SELECT
        t.*,
        c.name AS category_name,
        c.icon AS category_icon,
        a.name AS account_name,
        fa.name AS from_account_name,
        ta.name AS to_account_name
      FROM transactions t
      LEFT JOIN categories c
        ON c.id = t.category_id
      LEFT JOIN accounts a
        ON a.id = t.account_id
      LEFT JOIN accounts fa
        ON fa.id = t.from_account_id
      LEFT JOIN accounts ta
        ON ta.id = t.to_account_id
      WHERE t.id = ?
      LIMIT 1
      ''',
      [id],
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  // ============================================================
  // ACCOUNT BALANCE
  // ============================================================

  Future<void> _recalculateAllAccountBalances(
    DatabaseExecutor executor,
  ) async {
    final accounts = await executor.query('accounts');

    for (final account in accounts) {
      final accountId = account['id'] as int;

      final incomeResult = await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM transactions
        WHERE type = 'income'
        AND account_id = ?
        ''',
        [accountId],
      );

      final expenseResult = await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM transactions
        WHERE type = 'expense'
        AND account_id = ?
        ''',
        [accountId],
      );

      final transferInResult = await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM transactions
        WHERE type = 'transfer'
        AND to_account_id = ?
        ''',
        [accountId],
      );

      final transferOutResult = await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM transactions
        WHERE type = 'transfer'
        AND from_account_id = ?
        ''',
        [accountId],
      );

      final income =
          (incomeResult.first['total'] as num?)?.toDouble() ?? 0;

      final expense =
          (expenseResult.first['total'] as num?)?.toDouble() ?? 0;

      final transferIn =
          (transferInResult.first['total'] as num?)?.toDouble() ?? 0;

      final transferOut =
          (transferOutResult.first['total'] as num?)?.toDouble() ?? 0;

      final balance =
          income - expense + transferIn - transferOut;

      await executor.update(
        'accounts',
        {
          'balance': balance,
        },
        where: 'id = ?',
        whereArgs: [accountId],
      );
    }
  }

  Future<double> getTotalBalance() async {
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(balance), 0) AS total
      FROM accounts
      ''',
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _getTotalByType(
      'income',
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<double> getTotalExpense({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _getTotalByType(
      'expense',
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<double> _getTotalByType(
    String type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>['type = ?'];
    final args = <dynamic>[type];

    if (startDate != null) {
      conditions.add('transaction_date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      conditions.add('transaction_date <= ?');
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE ${conditions.join(' AND ')}
      ''',
      args,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getExpenseByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>["t.type = 'expense'"];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('t.transaction_date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      conditions.add('t.transaction_date <= ?');
      args.add(endDate.toIso8601String());
    }

    return db.rawQuery(
      '''
      SELECT
        c.id,
        c.name,
        c.icon,
        c.color,
        COALESCE(SUM(t.amount), 0) AS total
      FROM transactions t
      LEFT JOIN categories c
        ON c.id = t.category_id
      WHERE ${conditions.join(' AND ')}
      GROUP BY c.id
      ORDER BY total DESC
      ''',
      args,
    );
  }

  Future<List<Map<String, dynamic>>> getIncomeByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>["t.type = 'income'"];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('t.transaction_date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      conditions.add('t.transaction_date <= ?');
      args.add(endDate.toIso8601String());
    }

    return db.rawQuery(
      '''
      SELECT
        c.id,
        c.name,
        c.icon,
        c.color,
        COALESCE(SUM(t.amount), 0) AS total
      FROM transactions t
      LEFT JOIN categories c
        ON c.id = t.category_id
      WHERE ${conditions.join(' AND ')}
      GROUP BY c.id
      ORDER BY total DESC
      ''',
      args,
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<List<Map<String, dynamic>>> searchTransactions(
    String query,
  ) async {
    final search = '%$query%';

    return db.rawQuery(
      '''
      SELECT
        t.*,
        c.name AS category_name,
        a.name AS account_name,
        fa.name AS from_account_name,
        ta.name AS to_account_name
      FROM transactions t
      LEFT JOIN categories c
        ON c.id = t.category_id
      LEFT JOIN accounts a
        ON a.id = t.account_id
      LEFT JOIN accounts fa
        ON fa.id = t.from_account_id
      LEFT JOIN accounts ta
        ON ta.id = t.to_account_id
      WHERE
        t.note LIKE ?
        OR c.name LIKE ?
        OR a.name LIKE ?
        OR fa.name LIKE ?
        OR ta.name LIKE ?
      ORDER BY t.transaction_date DESC, t.id DESC
      ''',
      [
        search,
        search,
        search,
        search,
        search,
      ],
    );
  }

  // ============================================================
  // CLEAR DATABASE
  // ============================================================

  Future<void> clearAllTransactions() async {
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await _recalculateAllAccountBalances(txn);
    });
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
