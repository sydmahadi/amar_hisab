import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'accounts_screen.dart';
import 'add_transaction_screen.dart';
import 'categories_screen.dart';
import 'report_screen.dart';
import 'statistics_screen.dart';
import 'transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MoneyDb _db = MoneyDb.instance;

  bool _loading = true;

  double _income = 0;
  double _expense = 0;
  double _difference = 0;
  double _accountBalance = 0;

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final now = DateTime.now();

      final startDate = DateTime(
        now.year,
        now.month,
        1,
      );

      final endDate = DateTime(
        now.year,
        now.month + 1,
        1,
      ).subtract(
        const Duration(microseconds: 1),
      );

      final period = await _db.getPeriodTotals(
        startDate: startDate,
        endDate: endDate,
      );

      final accounts = await _db.getAccounts();
      final transactions = await _db.getTransactions();

      final income =
          (period['income'] as num?)?.toDouble() ?? 0;

      final expense =
          (period['expense'] as num?)?.toDouble() ?? 0;

      final accountBalance = await _db.getTotalBalance();

      if (!mounted) return;

      setState(() {
        _income = income;
        _expense = expense;
        _difference = income - expense;
        _accountBalance = accountBalance;
        _accounts = accounts;
        _transactions = transactions.take(8).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  String _formatMoney(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _formatAccountMoney(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;

    return _formatMoney(amount);
  }

  String _monthName(int month) {
    const bnMonths = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];

    const enMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return settings.isBangla
        ? bnMonths[month - 1]
        : enMonths[month - 1];
  }

  String _currentMonthLabel() {
    final now = DateTime.now();

    return settings.isBangla
        ? '${_monthName(now.month)} ${now.year}'
        : '${_monthName(now.month)} ${now.year}';
  }

  String _transactionTitle(
    Map<String, dynamic> item,
  ) {
    final type = item['type']?.toString();

    if (type == 'transfer') {
      final from =
          item['from_account_name']?.toString() ?? '';

      final to =
          item['to_account_name']?.toString() ?? '';

      if (from.isNotEmpty && to.isNotEmpty) {
        return '$from → $to';
      }

      return settings.isBangla
          ? 'অ্যাকাউন্ট ট্রান্সফার'
          : 'Account Transfer';
    }

    final category =
        item['category_name']?.toString() ?? '';

    if (category.isNotEmpty) {
      return category;
    }

    if (type == 'income') {
      return settings.isBangla ? 'আয়' : 'Income';
    }

    return settings.isBangla ? 'ব্যয়' : 'Expense';
  }

  String _transactionSubtitle(
    Map<String, dynamic> item,
  ) {
    final type = item['type']?.toString();

    if (type == 'transfer') {
      final note = item['note']?.toString() ?? '';
      return note;
    }

    final account =
        item['account_name']?.toString() ?? '';

    final note = item['note']?.toString() ?? '';

    if (account.isNotEmpty && note.isNotEmpty) {
      return '$account • $note';
    }

    if (account.isNotEmpty) {
      return account;
    }

    return note;
  }

  Color _transactionColor(String type) {
    if (type == 'income') {
      return Colors.green.shade600;
    }

    if (type == 'expense') {
      return Colors.red.shade600;
    }

    return AppTheme.gold;
  }

  IconData _transactionIcon(String type) {
    if (type == 'income') {
      return Icons.arrow_downward_rounded;
    }

    if (type == 'expense') {
      return Icons.arrow_upward_rounded;
    }

    return Icons.swap_horiz_rounded;
  }

  Future<void> _openAddTransaction({
    String? type,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialType: type,
        ),
      ),
    );

    if (result == true) {
      await _loadDashboard();
    }
  }

  Future<void> _openTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TransactionsScreen(),
      ),
    );

    await _loadDashboard();
  }

  Future<void> _editTransaction(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          transactionId: id,
        ),
      ),
    );

    if (result == true) {
      await _loadDashboard();
    }
  }

  Future<void> _deleteTransaction(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            settings.isBangla
                ? 'লেনদেন মুছে ফেলবেন?'
                : 'Delete transaction?',
          ),
          content: Text(
            settings.isBangla
                ? 'এই লেনদেনটি স্থায়ীভাবে মুছে যাবে।'
                : 'This transaction will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                settings.isBangla
                    ? 'বাতিল'
                    : 'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: Text(
                settings.isBangla
                    ? 'মুছে ফেলুন'
                    : 'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _db.deleteTransaction(id);
      await _loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              settings.isBangla
                  ? 'লেনদেন মুছে ফেলা হয়েছে'
                  : 'Transaction deleted',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkGreen,
            AppTheme.green,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(
                    alpha: 0.18,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppTheme.gold.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.gold,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.isBangla
                          ? 'আমার হিসাব'
                          : 'Amar Hisab',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      settings.isBangla
                          ? 'সহজে আপনার হিসাব রাখুন'
                          : 'Manage your money simply',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.75,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: settings.isBangla
                    ? 'সব লেনদেন'
                    : 'All Transactions',
                onPressed: _openTransactions,
                icon: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            settings.isBangla
                ? 'বর্তমান মাসের হিসাব'
                : 'Current Month',
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.75,
              ),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _currentMonthLabel(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.10,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _difference >= 0
                        ? Colors.green.withValues(
                            alpha: 0.18,
                          )
                        : Colors.red.withValues(
                            alpha: 0.18,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _difference >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: _difference >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _difference >= 0
                            ? (settings.isBangla
                                ? 'বর্তমান উদ্বৃত্ত'
                                : 'Current Surplus')
                            : (settings.isBangla
                                ? 'বর্তমান ঘাটি'
                                : 'Current Deficit'),
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.75,
                          ),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatMoney(
                          _difference.abs(),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      settings.isBangla
                          ? 'এই মাস'
                          : 'This month',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.65,
                        ),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _difference >= 0 ? '+' : '-',
                      style: TextStyle(
                        color: _difference >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              title: settings.isBangla
                  ? 'আয়'
                  : 'Income',
              amount: _income,
              color: Colors.green.shade600,
              icon: Icons.south_west_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
              title: settings.isBangla
                  ? 'ব্যয়'
                  : 'Expense',
              amount: _expense,
              color: Colors.red.shade600,
              icon: Icons.north_east_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(
                alpha: 0.35,
              ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatMoney(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            settings.isBangla
                ? 'দ্রুত এন্ট্রি'
                : 'Quick Entry',
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _quickAction(
                  title: settings.isBangla
                      ? 'আয়'
                      : 'Income',
                  icon: Icons.add_circle_outline_rounded,
                  color: Colors.green.shade600,
                  onTap: () {
                    _openAddTransaction(
                      type: 'income',
                    );
                  },
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _quickAction(
                  title: settings.isBangla
                      ? 'ব্যয়'
                      : 'Expense',
                  icon: Icons.remove_circle_outline_rounded,
                  color: Colors.red.shade600,
                  onTap: () {
                    _openAddTransaction(
                      type: 'expense',
                    );
                  },
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _quickAction(
                  title: settings.isBangla
                      ? 'ট্রান্সফার'
                      : 'Transfer',
                  icon: Icons.swap_horiz_rounded,
                  color: AppTheme.gold,
                  onTap: () {
                    _openAddTransaction(
                      type: 'transfer',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: color.withValues(
                alpha: 0.22,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountBalance() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        22,
        16,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  settings.isBangla
                      ? 'অ্যাকাউন্ট ব্যালেন্স'
                      : 'Account Balance',
                ),
              ),
              TextButton(
                onPressed: () {
                  _openScreen(
                    const AccountsScreen(),
                  );
                },
                child: Text(
                  settings.isBangla
                      ? 'সব দেখুন'
                      : 'View All',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.darkGreen.withValues(
                    alpha: 0.95,
                  ),
                  AppTheme.green.withValues(
                    alpha: 0.85,
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.gold,
                      size: 22,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        settings.isBangla
                            ? 'সব অ্যাকাউন্টের মোট বর্তমান ব্যালেন্স'
                            : 'Current balance of all accounts',
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.80,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatMoney(
                      _accountBalance,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_accounts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 62,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _accounts.length,
                      separatorBuilder: (_, __) {
                        return const SizedBox(width: 8);
                      },
                      itemBuilder: (context, index) {
                        final account =
                            _accounts[index];

                        final name =
                            account['name']?.toString() ??
                                '';

                        final balance =
                            account['balance'];

                        return Container(
                          width: 125,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(13),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white
                                      .withValues(
                                    alpha: 0.72,
                                  ),
                                  fontSize: 10,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatAccountMoney(
                                  balance,
                                ),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        22,
        16,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  settings.isBangla
                      ? 'সাম্প্রতিক লেনদেন'
                      : 'Recent Transactions',
                ),
              ),
              TextButton(
                onPressed: _openTransactions,
                child: Text(
                  settings.isBangla
                      ? 'সব দেখুন'
                      : 'View All',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_transactions.isEmpty)
            _buildNoTransactions()
          else
            ..._transactions.map(
              _buildTransactionCard,
            ),
        ],
      ),
    );
  }

  Widget _buildNoTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: AppTheme.gold,
          ),
          const SizedBox(height: 10),
          Text(
            settings.isBangla
                ? 'এখনো কোনো লেনদেন নেই'
                : 'No transactions yet',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            settings.isBangla
                ? 'নিচের বাটন থেকে আপনার প্রথম হিসাব যোগ করুন।'
                : 'Add your first transaction below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> item,
  ) {
    final type =
        item['type']?.toString() ?? 'expense';

    final amount =
        (item['amount'] as num?)?.toDouble() ?? 0;

    final color = _transactionColor(type);

    final title = _transactionTitle(item);

    final subtitle =
        _transactionSubtitle(item);

    final id = item['id'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: InkWell(
        onTap: () {
          _editTransaction(id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  _transactionIcon(type),
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    type == 'income'
                        ? '+ ${_formatMoney(amount)}'
                        : type == 'expense'
                            ? '- ${_formatMoney(amount)}'
                            : _formatMoney(amount),
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(
                      minWidth: 42,
                      minHeight: 35,
                    ),
                    iconSize: 20,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTransaction(id);
                      }

                      if (value == 'delete') {
                        _deleteTransaction(id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 19,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              settings.isBangla
                                  ? 'এডিট'
                                  : 'Edit',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 19,
                              color:
                                  Colors.red.shade600,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              settings.isBangla
                                  ? 'ডিলিট'
                                  : 'Delete',
                              style: TextStyle(
                                color:
                                    Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTools() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        25,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            settings.isBangla
                ? 'অন্যান্য'
                : 'More',
          ),
          const SizedBox(height: 11),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 1.12,
            children: [
              _toolButton(
                icon: Icons.bar_chart_rounded,
                title: settings.isBangla
                    ? 'পরিসংখ্যান'
                    : 'Statistics',
                onTap: () {
                  _openScreen(
                    const StatisticsScreen(),
                  );
                },
              ),
              _toolButton(
                icon: Icons.description_outlined,
                title: settings.isBangla
                    ? 'রিপোর্ট'
                    : 'Report',
                onTap: () {
                  _openScreen(
                    const ReportScreen(),
                  );
                },
              ),
              _toolButton(
                icon: Icons.account_balance_wallet_outlined,
                title: settings.isBangla
                    ? 'অ্যাকাউন্ট'
                    : 'Accounts',
                onTap: () {
                  _openScreen(
                    const AccountsScreen(),
                  );
                },
              ),
              _toolButton(
                icon: Icons.category_outlined,
                title: settings.isBangla
                    ? 'খাত'
                    : 'Categories',
                onTap: () {
                  _openScreen(
                    const CategoriesScreen(),
                  );
                },
              ),
              _toolButton(
                icon: Icons.receipt_long_outlined,
                title: settings.isBangla
                    ? 'লেনদেন'
                    : 'Transactions',
                onTap: _openTransactions,
              ),
              _toolButton(
                icon: Icons.info_outline_rounded,
                title: settings.isBangla
                    ? 'সম্পর্কে'
                    : 'About',
                onTap: () {
                  _openScreen(
                    const AboutScreen(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppTheme.gold,
                size: 25,
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        20,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () {
            _openAddTransaction();
          },
          icon: const Icon(
            Icons.add_rounded,
          ),
          label: Text(
            settings.isBangla
                ? 'নতুন লেনদেন যোগ করুন'
                : 'Add New Transaction',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildSummaryCards(),
                      _buildQuickActions(),
                      _buildAccountBalance(),
                      _buildRecentTransactions(),
                      _buildTools(),
                      _buildBottomAddButton(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
