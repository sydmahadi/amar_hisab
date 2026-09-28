import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class MoneyDb {
  MoneyDb._();

  static final MoneyDb instance = MoneyDb._();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'amar_hisab.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Database get db {
    if (_db == null) {
      throw Exception('Database is not initialized.');
    }
    return _db!;
  }

  Future<void> _onCreate(
    Database database,
    int version,
  ) async {
    await database.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        icon INTEGER,
        color INTEGER,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon INTEGER,
        color INTEGER,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

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
        updated_at TEXT NOT NULL
      )
    ''');

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

    await _insertDefaultAccounts(database);
    await _insertDefaultCategories(database);
  }

  // =========================================================
  // DEFAULT ACCOUNTS
  // =========================================================

  Future<void> _insertDefaultAccounts(
    Database database,
  ) async {
    final now = DateTime.now().toIso8601String();

    final accounts = [
      {
        'name': 'Cash',
        'type': 'cash',
        'icon': 0xe88a,
        'color': 0xFF176B45,
      },
      {
        'name': 'Bkash',
        'type': 'bkash',
        'icon': 0xe0b0,
        'color': 0xFFE91E63,
      },
      {
        'name': 'Nagad',
        'type': 'nagad',
        'icon': 0xe8a6,
        'color': 0xFFFF9800,
      },
      {
        'name': 'Bank Account',
        'type': 'bank',
        'icon': 0xe84f,
        'color': 0xFF2196F3,
      },
      {
        'name': 'Card',
        'type': 'card',
        'icon': 0xe870,
        'color': 0xFF9C27B0,
      },
    ];

    for (final account in accounts) {
      await database.insert(
        'accounts',
        {
          'name': account['name'],
          'type': account['type'],
          'balance': 0.0,
          'icon': account['icon'],
          'color': account['color'],
          'is_default': 1,
          'created_at': now,
        },
      );
    }
  }

  // =========================================================
  // DEFAULT CATEGORIES
  // =========================================================

  Future<void> _insertDefaultCategories(
    Database database,
  ) async {
    final now = DateTime.now().toIso8601String();

    final incomeCategories = [
      {
        'name': 'Salary',
        'icon': 0xe850,
        'color': 0xFF176B45,
      },
      {
        'name': 'Business',
        'icon': 0xe8f6,
        'color': 0xFF2196F3,
      },
      {
        'name': 'Bonus',
        'icon': 0xe8b6,
        'color': 0xFFFF9800,
      },
      {
        'name': 'Other Income',
        'icon': 0xe145,
        'color': 0xFF9C27B0,
      },
    ];

    final expenseCategories = [
      {
        'name': 'Food',
        'icon': 0xe56c,
        'color': 0xFFFF7043,
      },
      {
        'name': 'Shopping',
        'icon': 0xe8cc,
        'color': 0xFFE91E63,
      },
      {
        'name': 'Transport',
        'icon': 0xe531,
        'color': 0xFF2196F3,
      },
      {
        'name': 'Rent',
        'icon': 0xe88a,
        'color': 0xFF9C27B0,
      },
      {
        'name': 'Bills',
        'icon': 0xe8a1,
        'color': 0xFFFF9800,
      },
      {
        'name': 'Medical',
        'icon': 0xe3f3,
        'color': 0xFFF44336,
      },
      {
        'name': 'Education',
        'icon': 0xe80c,
        'color': 0xFF3F51B5,
      },
      {
        'name': 'Family',
        'icon': 0xe7ef,
        'color': 0xFF009688,
      },
      {
        'name': 'Other Expense',
        'icon': 0xe145,
        'color': 0xFF607D8B,
      },
    ];

    for (final category in incomeCategories) {
      await database.insert(
        'categories',
        {
          'name': category['name'],
          'type': 'income',
          'icon': category['icon'],
          'color': category['color'],
          'is_default': 1,
          'created_at': now,
        },
      );
    }

    for (final category in expenseCategories) {
      await database.insert(
        'categories',
        {
          'name': category['name'],
          'type': 'expense',
          'icon': category['icon'],
          'color': category['color'],
          'is_default': 1,
          'created_at': now,
        },
      );
    }
  }

  // =========================================================
  // ACCOUNTS
  // =========================================================

  Future<List<Map<String, dynamic>>> getAccounts() async {
    return db.query(
      'accounts',
      orderBy: 'is_default DESC, id ASC',
    );
  }

  Future<Map<String, dynamic>?> getAccount(
    int id,
  ) async {
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
    int? icon,
    int? color,
  }) async {
    return db.insert(
      'accounts',
      {
        'name': name.trim(),
        'type': type,
        'balance': balance,
        'icon': icon,
        'color': color,
        'is_default': 0,
        'created_at':
            DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> updateAccount(
    int id, {
    required String name,
    required String type,
    int? icon,
    int? color,
  }) async {
    final result = await db.update(
      'accounts',
      {
        'name': name.trim(),
        'type': type,
        'icon': icon,
        'color': color,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    return result;
  }

  Future<int> deleteAccount(int id) async {
    final account = await getAccount(id);

    if (account == null) return 0;

    if ((account['is_default'] as int? ?? 0) == 1) {
      throw Exception(
        'Default accounts cannot be deleted.',
      );
    }

    final count = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM transactions
      WHERE account_id = ?
         OR from_account_id = ?
         OR to_account_id = ?
      ''',
      [id, id, id],
    );

    final transactionCount =
        (count.first['total'] as num?)?.toInt() ?? 0;

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

  // =========================================================
  // CATEGORIES
  // =========================================================

  Future<List<Map<String, dynamic>>> getCategories({
    String? type,
  }) async {
    if (type == null) {
      return db.query(
        'categories',
        orderBy: 'is_default DESC, id ASC',
      );
    }

    return db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'is_default DESC, id ASC',
    );
  }

  Future<Map<String, dynamic>?> getCategory(
    int id,
  ) async {
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
    int? icon,
    int? color,
  }) async {
    return db.insert(
      'categories',
      {
        'name': name.trim(),
        'type': type,
        'icon': icon,
        'color': color,
        'is_default': 0,
        'created_at':
            DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> updateCategory(
    int id, {
    required String name,
    int? icon,
    int? color,
  }) async {
    return db.update(
      'categories',
      {
        'name': name.trim(),
        'icon': icon,
        'color': color,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final category = await getCategory(id);

    if (category == null) return 0;

    if ((category['is_default'] as int? ?? 0) == 1) {
      throw Exception(
        'Default categories cannot be deleted.',
      );
    }

    final count = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM transactions
      WHERE category_id = ?
      ''',
      [id],
    );

    final transactionCount =
        (count.first['total'] as num?)?.toInt() ?? 0;

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

  // =========================================================
  // TRANSACTIONS
  // =========================================================

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
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero.');
    }

    return db.transaction(
      (txn) async {
        final now =
            DateTime.now().toIso8601String();

        final id = await txn.insert(
          'transactions',
          {
            'type': type,
            'amount': amount,
            'category_id': categoryId,
            'account_id': accountId,
            'from_account_id': fromAccountId,
            'to_account_id': toAccountId,
            'note': note?.trim() ?? '',
            'transaction_date':
                transactionDate.toIso8601String(),
            'created_at': now,
            'updated_at': now,
          },
        );

        await _recalculateAllAccountBalances(
          txn,
        );

        return id;
      },
    );
  }

  Future<int> updateTransaction(
    int id, {
    required String type,
    required double amount,
    int? categoryId,
    int? accountId,
    int? fromAccountId,
    int? toAccountId,
    String? note,
    required DateTime transactionDate,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero.');
    }

    return db.transaction(
      (txn) async {
        final result = await txn.update(
          'transactions',
          {
            'type': type,
            'amount': amount,
            'category_id': categoryId,
            'account_id': accountId,
            'from_account_id': fromAccountId,
            'to_account_id': toAccountId,
            'note': note?.trim() ?? '',
            'transaction_date':
                transactionDate.toIso8601String(),
            'updated_at':
                DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );

        await _recalculateAllAccountBalances(
          txn,
        );

        return result;
      },
    );
  }

  Future<int> deleteTransaction(int id) async {
    return db.transaction(
      (txn) async {
        final result = await txn.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [id],
        );

        await _recalculateAllAccountBalances(
          txn,
        );

        return result;
      },
    );
  }

  Future<Map<String, dynamic>?> getTransaction(
    int id,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT
        t.*,
        c.name AS category_name,
        c.type AS category_type,
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

  Future<List<Map<String, dynamic>>> getTransactions({
    String? type,
    int? categoryId,
    int? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    final where = <String>[];
    final args = <dynamic>[];

    if (type != null &&
        type.isNotEmpty &&
        type != 'all') {
      where.add('t.type = ?');
      args.add(type);
    }

    if (categoryId != null) {
      where.add('t.category_id = ?');
      args.add(categoryId);
    }

    if (accountId != null) {
      where.add('''
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

    if (startDate != null) {
      where.add('t.transaction_date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.add('t.transaction_date <= ?');
      args.add(endDate.toIso8601String());
    }

    if (search != null &&
        search.trim().isNotEmpty) {
      where.add('''
        (
          t.note LIKE ?
          OR c.name LIKE ?
          OR a.name LIKE ?
          OR fa.name LIKE ?
          OR ta.name LIKE ?
        )
      ''');

      final value = '%${search.trim()}%';

      args.add(value);
      args.add(value);
      args.add(value);
      args.add(value);
      args.add(value);
    }

    final whereSql = where.isEmpty
        ? ''
        : 'WHERE ${where.join(' AND ')}';

    return db.rawQuery(
      '''
      SELECT
        t.*,
        c.name AS category_name,
        c.type AS category_type,
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
      $whereSql
      ORDER BY
        t.transaction_date DESC,
        t.id DESC
      ''',
      args,
    );
  }

  // =========================================================
  // BALANCE
  // =========================================================

  Future<void> _recalculateAllAccountBalances(
    DatabaseExecutor executor,
  ) async {
    final accounts =
        await executor.query('accounts');

    for (final account in accounts) {
      final accountId =
          account['id'] as int;

      double balance = 0;

      final incomeResult =
          await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM transactions
        WHERE type = 'income'
          AND account_id = ?
        ''',
        [accountId],
      );

      final expenseResult =
          await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM transactions
        WHERE type = 'expense'
          AND account_id = ?
        ''',
        [accountId],
      );

      final transferInResult =
          await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM transactions
        WHERE type = 'transfer'
          AND to_account_id = ?
        ''',
        [accountId],
      );

      final transferOutResult =
          await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM transactions
        WHERE type = 'transfer'
          AND from_account_id = ?
        ''',
        [accountId],
      );

      final income =
          (incomeResult.first['total'] as num?)
                  ?.toDouble() ??
              0;

      final expense =
          (expenseResult.first['total'] as num?)
                  ?.toDouble() ??
              0;

      final transferIn =
          (transferInResult.first['total'] as num?)
                  ?.toDouble() ??
              0;

      final transferOut =
          (transferOutResult.first['total'] as num?)
                  ?.toDouble() ??
              0;

      balance =
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

  Future<void> recalculateBalances() async {
    await db.transaction(
      (txn) async {
        await _recalculateAllAccountBalances(
          txn,
        );
      },
    );
  }

  // =========================================================
  // TOTALS
  // =========================================================

  Future<double> getTotalBalance() async {
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(balance), 0) AS total
      FROM accounts
      ''',
    );

    return (result.first['total'] as num?)
            ?.toDouble() ??
        0;
  }

  Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final where = <String>[
      "type = 'income'",
    ];

    final args = <dynamic>[];

    if (startDate != null) {
      where.add('transaction_date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.add('transaction_date <= ?');
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE ${where.join(' AND ')}
      ''',
      args,
    );

    return (result.first['total'] as num?)
            ?.toDouble() ??
        0;
  }

  Future<double> getTotalExpense({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final where = <String>[
      "type = 'expense'",
    ];

    final args = <dynamic>[];

    if (startDate != null) {
      where.add('transaction_date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.add('transaction_date <= ?');
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE ${where.join(' AND ')}
      ''',
      args,
    );

    return (result.first['total'] as num?)
            ?.toDouble() ??
        0;
  }

  // =========================================================
  // CATEGORY TOTALS
  // =========================================================

  Future<List<Map<String, dynamic>>>
      getIncomeByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _getCategoryTotals(
      type: 'income',
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<Map<String, dynamic>>>
      getExpenseByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _getCategoryTotals(
      type: 'expense',
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<Map<String, dynamic>>>
      _getCategoryTotals({
    required String type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final where = <String>[
      't.type = ?',
      'c.type = ?',
    ];

    final args = <dynamic>[
      type,
      type,
    ];

    if (startDate != null) {
      where.add('t.transaction_date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.add('t.transaction_date <= ?');
      args.add(endDate.toIso8601String());
    }

    return db.rawQuery(
      '''
      SELECT
        c.id,
        c.name,
        c.type,
        c.icon,
        c.color,
        COALESCE(SUM(t.amount), 0) AS total
      FROM categories c
      LEFT JOIN transactions t
        ON t.category_id = c.id
        AND ${where.join(' AND ')}
      WHERE c.type = ?
      GROUP BY
        c.id,
        c.name,
        c.type,
        c.icon,
        c.color
      HAVING total > 0
      ORDER BY total DESC
      ''',
      [
        ...args,
        type,
      ],
    );
  }

  // =========================================================
  // PERIOD TOTALS
  // =========================================================

  Future<Map<String, double>> getPeriodTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final income = await getTotalIncome(
      startDate: startDate,
      endDate: endDate,
    );

    final expense = await getTotalExpense(
      startDate: startDate,
      endDate: endDate,
    );

    return {
      'income': income,
      'expense': expense,
      'difference': income - expense,
    };
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<List<Map<String, dynamic>>> searchTransactions(
    String query,
  ) async {
    return getTransactions(
      search: query,
    );
  }

  // =========================================================
  // CLEAR ALL TRANSACTIONS
  // =========================================================

  Future<void> clearTransactions() async {
    await db.transaction(
      (txn) async {
        await txn.delete('transactions');

        await _recalculateAllAccountBalances(
          txn,
        );
      },
    );
  }

  // =========================================================
  // DATABASE CLOSE
  // =========================================================

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
