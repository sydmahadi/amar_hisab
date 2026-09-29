import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'accounts_screen.dart';
import 'add_transaction_screen.dart';
import 'categories_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MoneyDb _db = MoneyDb.instance;

  double _balance = 0;
  double _income = 0;
  double _expense = 0;

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final balance = await _db.getTotalBalance();
      final income = await _db.getTotalIncome();
      final expense = await _db.getTotalExpense();
      final accounts = await _db.getAccounts();
      final transactions = await _db.getTransactions();

      transactions.sort((a, b) {
        final aDate = DateTime.tryParse(
              (a['transaction_date'] ??
                      a['transactionDate'] ??
                      '')
                  .toString(),
            ) ??
            DateTime(2000);

        final bDate = DateTime.tryParse(
              (b['transaction_date'] ??
                      b['transactionDate'] ??
                      '')
                  .toString(),
            ) ??
            DateTime(2000);

        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        _balance = _toDouble(balance);
        _income = _toDouble(income);
        _expense = _toDouble(expense);
        _accounts = List<Map<String, dynamic>>.from(accounts);
        _recentTransactions = transactions.take(5).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(double value) {
    return value.toStringAsFixed(2);
  }

  Color _alpha(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  Color _transactionColor(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return AppTheme.incomeColor;

      case 'expense':
        return AppTheme.expenseColor;

      case 'transfer':
        return AppTheme.transferColor;

      default:
        return AppTheme.gold;
    }
  }

  IconData _transactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return Icons.arrow_downward_rounded;

      case 'expense':
        return Icons.arrow_upward_rounded;

      case 'transfer':
        return Icons.swap_horiz_rounded;

      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  String _transactionTitle(Map<String, dynamic> item) {
    final note = item['note']?.toString().trim();

    if (note != null && note.isNotEmpty) {
      return note;
    }

    final category = item['category_name'] ??
        item['categoryName'] ??
        item['category'];

    if (category != null &&
        category.toString().trim().isNotEmpty) {
      return category.toString();
    }

    final type = item['type']?.toString().toLowerCase();

    switch (type) {
      case 'income':
        return AppSettings.instance.isBangla ? 'আয়' : 'Income';

      case 'expense':
        return AppSettings.instance.isBangla ? 'ব্যয়' : 'Expense';

      case 'transfer':
        return AppSettings.instance.isBangla
            ? 'ট্রান্সফার'
            : 'Transfer';

      default:
        return AppSettings.instance.isBangla
            ? 'লেনদেন'
            : 'Transaction';
    }
  }

  String _accountName(Map<String, dynamic> account) {
    return account['name']?.toString() ??
        (AppSettings.instance.isBangla
            ? 'অ্যাকাউন্ট'
            : 'Account');
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _openAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );

    if (mounted) {
      _loadData();
    }
  }

  Future<void> _openTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TransactionsScreen(),
      ),
    );

    if (mounted) {
      _loadData();
    }
  }

  Future<void> _openAccounts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AccountsScreen(),
      ),
    );

    if (mounted) {
      _loadData();
    }
  }

  Future<void> _openCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CategoriesScreen(),
      ),
    );
  }

  Future<void> _openStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StatisticsScreen(),
      ),
    );
  }

  Future<void> _openReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportScreen(),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openAbout() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AboutScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppSettings.instance;
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: _buildFloatingButton(theme),
      drawer: _buildDrawer(theme),
      body: Stack(
        children: [
          Positioned.fill(
            child: _PremiumBackground(
              isDark: isDark,
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: AppTheme.green,
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildTopBar(theme),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      8,
                      18,
                      110,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildBalanceCard(theme),
                        const SizedBox(height: 18),
                        _buildSummary(theme),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          theme,
                          settings.isBangla
                              ? 'দ্রুত কাজ'
                              : 'Quick Actions',
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActions(theme),
                        const SizedBox(height: 26),
                        _buildSectionTitle(
                          theme,
                          settings.isBangla
                              ? 'সাম্প্রতিক লেনদেন'
                              : 'Recent Transactions',
                          actionText: settings.isBangla
                              ? 'সব দেখুন'
                              : 'View All',
                          onAction: _openTransactions,
                        ),
                        const SizedBox(height: 12),
                        _buildRecentTransactions(theme),
                        const SizedBox(height: 26),
                        _buildSectionTitle(
                          theme,
                          settings.isBangla
                              ? 'অ্যাকাউন্টসমূহ'
                              : 'Accounts',
                          actionText: settings.isBangla
                              ? 'সব দেখুন'
                              : 'View All',
                          onAction: _openAccounts,
                        ),
                        const SizedBox(height: 12),
                        _buildAccounts(theme),
                        const SizedBox(height: 26),
                        _buildSectionTitle(
                          theme,
                          settings.isBangla
                              ? 'প্রয়োজনীয় টুল'
                              : 'Useful Tools',
                        ),
                        const SizedBox(height: 12),
                        _buildTools(theme),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: _alpha(
                    theme.scaffoldBackgroundColor,
                    0.25,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        8,
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return _topActionButton(
                theme,
                icon: Icons.menu_rounded,
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          const Spacer(),
          _topActionButton(
            theme,
            icon: Icons.bar_chart_rounded,
            onTap: _openStatistics,
          ),
          const SizedBox(width: 8),
          _topActionButton(
            theme,
            icon: Icons.settings_outlined,
            onTap: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _topActionButton(
    ThemeData theme, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _alpha(
              theme.colorScheme.surface,
              Theme.of(context).brightness == Brightness.dark
                  ? 0.78
                  : 0.88,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _alpha(
                theme.colorScheme.onSurface,
                0.07,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 21,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme) {
    final settings = AppSettings.instance;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkGreen,
            AppTheme.green,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.green.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 20,
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -50,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold.withValues(alpha: 0.09),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white.withValues(alpha: 0.82),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    settings.isBangla
                        ? 'মোট ব্যালেন্স'
                        : 'Total Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                '৳ ${_money(_balance)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 17),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.10),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _balanceMini(
                      theme,
                      icon: Icons.arrow_downward_rounded,
                      title: settings.isBangla
                          ? 'আয়'
                          : 'Income',
                      value: '৳ ${_money(_income)}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: _balanceMini(
                        theme,
                        icon: Icons.arrow_upward_rounded,
                        title: settings.isBangla
                            ? 'ব্যয়'
                            : 'Expense',
                        value: '৳ ${_money(_expense)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceMini(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.85),
            size: 16,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(ThemeData theme) {
    final settings = AppSettings.instance;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            theme,
            icon: Icons.trending_down_rounded,
            title: settings.isBangla ? 'মোট আয়' : 'Income',
            value: '৳ ${_money(_income)}',
            color: AppTheme.incomeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            theme,
            icon: Icons.trending_up_rounded,
            title: settings.isBangla ? 'মোট ব্যয়' : 'Expense',
            value: '৳ ${_money(_expense)}',
            color: AppTheme.expenseColor,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _alpha(
            theme.colorScheme.onSurface,
            0.055,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _alpha(color, 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    ThemeData theme,
    String title, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText,
              style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    final settings = AppSettings.instance;

    return Row(
      children: [
        Expanded(
          child: _quickAction(
            theme,
            icon: Icons.add_rounded,
            title: settings.isBangla ? 'আয়' : 'Income',
            color: AppTheme.incomeColor,
            onTap: _openAddTransaction,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            theme,
            icon: Icons.remove_rounded,
            title: settings.isBangla ? 'ব্যয়' : 'Expense',
            color: AppTheme.expenseColor,
            onTap: _openAddTransaction,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            theme,
            icon: Icons.swap_horiz_rounded,
            title: settings.isBangla
                ? 'ট্রান্সফার'
                : 'Transfer',
            color: AppTheme.transferColor,
            onTap: _openAddTransaction,
          ),
        ),
      ],
    );
  }

  Widget _quickAction(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _alpha(
                theme.colorScheme.onSurface,
                0.055,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: _alpha(color, 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeData theme) {
    final settings = AppSettings.instance;

    if (_recentTransactions.isEmpty) {
      return _emptyCard(
        theme,
        icon: Icons.receipt_long_outlined,
        text: settings.isBangla
            ? 'এখনও কোনো লেনদেন নেই'
            : 'No transactions yet',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _alpha(
            theme.colorScheme.onSurface,
            0.055,
          ),
        ),
      ),
      child: Column(
        children: List.generate(
          _recentTransactions.length,
          (index) {
            final item = _recentTransactions[index];
            final type = item['type']?.toString() ?? '';
            final color = _transactionColor(type);
            final amount = _toDouble(item['amount']);

            final date = item['transaction_date'] ??
                item['transactionDate'];

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _alpha(color, 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _transactionIcon(type),
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _transactionTitle(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  trailing: Text(
                    type.toLowerCase() == 'expense'
                        ? '-৳ ${_money(amount)}'
                        : '+৳ ${_money(amount)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (index != _recentTransactions.length - 1)
                  Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 15,
                    color: _alpha(
                      theme.colorScheme.onSurface,
                      0.055,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccounts(ThemeData theme) {
    if (_accounts.isEmpty) {
      return _emptyCard(
        theme,
        icon: Icons.account_balance_outlined,
        text: AppSettings.instance.isBangla
            ? 'কোনো অ্যাকাউন্ট নেই'
            : 'No accounts',
      );
    }

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _accounts.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 10);
        },
        itemBuilder: (context, index) {
          final account = _accounts[index];
          final balance = _toDouble(account['balance']);

          return Container(
            width: 155,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _alpha(
                  theme.colorScheme.onSurface,
                  0.055,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _alpha(AppTheme.gold, 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.gold,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Text(
                  _accountName(account),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '৳ ${_money(balance)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTools(ThemeData theme) {
    final settings = AppSettings.instance;

    return Row(
      children: [
        Expanded(
          child: _toolCard(
            theme,
            icon: Icons.category_outlined,
            title: settings.isBangla ? 'খাত' : 'Categories',
            onTap: _openCategories,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _toolCard(
            theme,
            icon: Icons.description_outlined,
            title: settings.isBangla ? 'রিপোর্ট' : 'Report',
            onTap: _openReport,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _toolCard(
            theme,
            icon: Icons.info_outline_rounded,
            title: settings.isBangla ? 'তথ্য' : 'About',
            onTap: _openAbout,
          ),
        ),
      ],
    );
  }

  Widget _toolCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 6,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _alpha(
                theme.colorScheme.onSurface,
                0.055,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppTheme.gold,
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(
    ThemeData theme, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _alpha(
            theme.colorScheme.onSurface,
            0.055,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 30,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton(
        heroTag: 'add_transaction_fab',
        onPressed: _openAddTransaction,
        elevation: 8,
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add_rounded,
          size: 29,
        ),
      ),
    );
  }

  Drawer _buildDrawer(ThemeData theme) {
    final settings = AppSettings.instance;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                22,
                28,
                22,
                24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkGreen,
                    AppTheme.green,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppTheme.goldLight,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    settings.t('appName'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settings.isBangla
                        ? 'সহজে আপনার হিসাব রাখুন'
                        : 'Manage your money simply',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.68,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                children: [
                  _drawerItem(
                    theme,
                    icon: Icons.dashboard_outlined,
                    title: settings.isBangla
                        ? 'হোম'
                        : 'Home',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.receipt_long_outlined,
                    title: settings.isBangla
                        ? 'লেনদেন'
                        : 'Transactions',
                    onTap: () {
                      Navigator.pop(context);
                      _openTransactions();
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.account_balance_wallet_outlined,
                    title: settings.isBangla
                        ? 'অ্যাকাউন্ট'
                        : 'Accounts',
                    onTap: () {
                      Navigator.pop(context);
                      _openAccounts();
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.category_outlined,
                    title: settings.isBangla
                        ? 'খাত'
                        : 'Categories',
                    onTap: () {
                      Navigator.pop(context);
                      _openCategories();
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.bar_chart_rounded,
                    title: settings.isBangla
                        ? 'পরিসংখ্যান'
                        : 'Statistics',
                    onTap: () {
                      Navigator.pop(context);
                      _openStatistics();
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.description_outlined,
                    title: settings.isBangla
                        ? 'রিপোর্ট'
                        : 'Report',
                    onTap: () {
                      Navigator.pop(context);
                      _openReport();
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.settings_outlined,
                    title: settings.isBangla
                        ? 'সেটিংস'
                        : 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      _openSettings();
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.info_outline_rounded,
                    title: settings.isBangla
                        ? 'অ্যাপ সম্পর্কে'
                        : 'About',
                    onTap: () {
                      Navigator.pop(context);
                      _openAbout();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20,
              ),
              child: Text(
                settings.isBangla
                    ? 'আমার হিসাব'
                    : 'Amar Hisab',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Icon(
          icon,
          size: 21,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 19,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  final bool isDark;

  const _PremiumBackground({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PremiumBackgroundPainter(
          isDark: isDark,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PremiumBackgroundPainter extends CustomPainter {
  final bool isDark;

  _PremiumBackgroundPainter({
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark
          ? const Color(0xFF08120F)
          : const Color(0xFFF4F1E9);

    canvas.drawRect(
      Offset.zero & size,
      bgPaint,
    );

    // বড় সবুজ soft shape
    final greenPaint = Paint()
      ..color = isDark
          ? const Color(0x121F7655)
          : const Color(0x0D176B45)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        size.width * 0.98,
        size.height * 0.16,
      ),
      size.width * 0.62,
      greenPaint,
    );

    // Gold shape
    final goldPaint = Paint()
      ..color = isDark
          ? const Color(0x0CC9A45C)
          : const Color(0x0FC9A45C)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        size.width * 0.04,
        size.height * 0.52,
      ),
      size.width * 0.38,
      goldPaint,
    );

    // বড় curved ring
    final ringPaint = Paint()
      ..color = isDark
          ? const Color(0x102D8A63)
          : const Color(0x0A176B45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34;

    canvas.drawCircle(
      Offset(
        size.width * 0.90,
        size.height * 0.74,
      ),
      size.width * 0.45,
      ringPaint,
    );

    // পাতলা গোল shape
    final thinRingPaint = Paint()
      ..color = isDark
          ? const Color(0x0CC9A45C)
          : const Color(0x0AC9A45C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      Offset(
        size.width * 0.08,
        size.height * 0.20,
      ),
      90,
      thinRingPaint,
    );

    // ছোট decorative dots
    final dotPaint = Paint()
      ..color = isDark
          ? const Color(0x16C9A45C)
          : const Color(0x14B99550)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        size.width * 0.82,
        size.height * 0.34,
      ),
      5,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.88,
        size.height * 0.37,
      ),
      3,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.15,
        size.height * 0.67,
      ),
      4,
      dotPaint,
    );

    // উপরের curved shape
    final path = Path();

    path.moveTo(
      size.width * 0.65,
      0,
    );

    path.cubicTo(
      size.width * 0.80,
      size.height * 0.08,
      size.width * 0.78,
      size.height * 0.20,
      size.width * 0.98,
      size.height * 0.27,
    );

    path.lineTo(
      size.width,
      size.height * 0.34,
    );

    path.lineTo(
      size.width,
      0,
    );

    path.close();

    final shapePaint = Paint()
      ..color = isDark
          ? const Color(0x071F7655)
          : const Color(0x08176B45)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      path,
      shapePaint,
    );

    // Gold arc
    final arcPaint = Paint()
      ..color = isDark
          ? const Color(0x18C9A45C)
          : const Color(0x12C9A45C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(
          size.width * 0.12,
          size.height * 0.82,
        ),
        radius: 48,
      ),
      -math.pi * 0.25,
      math.pi * 0.95,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PremiumBackgroundPainter oldDelegate,
  ) {
    return oldDelegate.isDark != isDark;
  }
}
