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

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final MoneyDb _db = MoneyDb.instance;
  final AppSettings _settings = AppSettings.instance;

  double _income = 0;
  double _expense = 0;
  double _difference = 0;
  double _totalAccountBalance = 0;

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
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
      ).subtract(const Duration(microseconds: 1));

      final period = await _db.getPeriodTotals(
        startDate: startDate,
        endDate: endDate,
      );

      final totalAccountBalance = await _db.getTotalBalance();
      final accounts = await _db.getAccounts();
      final transactions = await _db.getTransactions();

      final income =
          (period['income'] as num?)?.toDouble() ?? 0.0;

      final expense =
          (period['expense'] as num?)?.toDouble() ?? 0.0;

      final difference = income - expense;

      if (!mounted) return;

      setState(() {
        _income = income;
        _expense = expense;
        _difference = difference;
        _totalAccountBalance = totalAccountBalance;
        _accounts = accounts;
        _recentTransactions = transactions.take(6).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  bool get _isBangla => _settings.isBangla;

  String _t(String key) {
    return _settings.t(key);
  }

  String _monthName(int month) {
    const banglaMonths = [
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

    const englishMonths = [
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

    return _isBangla
        ? banglaMonths[month - 1]
        : englishMonths[month - 1];
  }

  String _currentMonthLabel() {
    final now = DateTime.now();
    return '${_monthName(now.month)} ${now.year}';
  }

  String _formatMoney(double amount) {
    final value = amount.abs();

    if (value == value.roundToDouble()) {
      return '৳ ${value.toStringAsFixed(0)}';
    }

    return '৳ ${value.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    DateTime? date;

    if (value is DateTime) {
      date = value;
    } else {
      date = DateTime.tryParse(value.toString());
    }

    if (date == null) return value.toString();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatShortMoney(double amount) {
    final value = amount.abs();

    if (value >= 10000000) {
      return '৳ ${(value / 10000000).toStringAsFixed(1)}Cr';
    }

    if (value >= 100000) {
      return '৳ ${(value / 100000).toStringAsFixed(1)}L';
    }

    if (value >= 1000) {
      return '৳ ${(value / 1000).toStringAsFixed(1)}K';
    }

    return _formatMoney(amount);
  }

  String _transactionType(dynamic type) {
    final value = type?.toString().toLowerCase() ?? '';

    if (value == 'income') {
      return _isBangla ? 'আয়' : 'Income';
    }

    if (value == 'expense') {
      return _isBangla ? 'ব্যয়' : 'Expense';
    }

    if (value == 'transfer') {
      return _isBangla ? 'ট্রান্সফার' : 'Transfer';
    }

    return value;
  }

  Color _transactionColor(
    String type,
    ThemeData theme,
  ) {
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
        return Icons.receipt_long_rounded;
    }
  }

  String _transactionTitle(Map<String, dynamic> item) {
    final note = item['note']?.toString().trim();

    if (note != null && note.isNotEmpty) {
      return note;
    }

    final type = item['type']?.toString().toLowerCase() ?? '';

    if (type == 'transfer') {
      final from =
          item['from_account_name']?.toString().trim() ?? '';

      final to =
          item['to_account_name']?.toString().trim() ?? '';

      if (from.isNotEmpty && to.isNotEmpty) {
        return '$from → $to';
      }

      return _isBangla ? 'অ্যাকাউন্ট ট্রান্সফার' : 'Account Transfer';
    }

    final category =
        item['category_name']?.toString().trim();

    if (category != null && category.isNotEmpty) {
      return category;
    }

    return _transactionType(type);
  }

  String _transactionAccount(Map<String, dynamic> item) {
    final type = item['type']?.toString().toLowerCase() ?? '';

    if (type == 'transfer') {
      final from =
          item['from_account_name']?.toString().trim() ?? '';

      final to =
          item['to_account_name']?.toString().trim() ?? '';

      if (from.isNotEmpty && to.isNotEmpty) {
        return '$from → $to';
      }
    }

    final account =
        item['account_name']?.toString().trim();

    if (account != null && account.isNotEmpty) {
      return account;
    }

    return '';
  }

  IconData _accountIcon(Map<String, dynamic> account) {
    final raw = account['icon'];

    if (raw is int) {
      return IconData(
        raw,
        fontFamily: 'MaterialIcons',
      );
    }

    final codePoint = int.tryParse(raw?.toString() ?? '');

    if (codePoint != null) {
      return IconData(
        codePoint,
        fontFamily: 'MaterialIcons',
      );
    }

    return Icons.account_balance_wallet_outlined;
  }

  Color _accountColor(
    Map<String, dynamic> account,
    ThemeData theme,
  ) {
    final raw = account['color'];

    if (raw is int) {
      return Color(raw);
    }

    final value = int.tryParse(raw?.toString() ?? '');

    if (value != null) {
      return Color(value);
    }

    return AppTheme.green;
  }

  Future<void> _openAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _openTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TransactionScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _openAccounts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AccountsScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _openCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CategoriesScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _openStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StatisticsScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _openReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {});

    await _loadData();
  }

  Future<void> _openAbout() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AboutScreen(),
      ),
    );
  }

  Future<void> _editTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final id = transaction['id'];

    if (id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          transactionId: id as int,
        ),
      ),
    );

    await _loadData();
  }

  Future<void> _deleteTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final id = transaction['id'];

    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          title: Text(
            _isBangla
                ? 'লেনদেন মুছে ফেলবেন?'
                : 'Delete transaction?',
          ),
          content: Text(
            _isBangla
                ? 'এই লেনদেনটি স্থায়ীভাবে মুছে যাবে।'
                : 'This transaction will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                _isBangla ? 'না' : 'Cancel',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.expenseColor,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                _isBangla ? 'মুছে ফেলুন' : 'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _db.deleteTransaction(id as int);

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBangla
                ? 'লেনদেন মুছে ফেলা হয়েছে'
                : 'Transaction deleted',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBangla
                ? 'লেনদেন মুছে ফেলা যায়নি'
                : 'Could not delete transaction',
          ),
        ),
      );
    }
  }

  void _showTransactionMenu(
    Map<String, dynamic> transaction,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.edit_rounded,
                  ),
                  title: Text(
                    _isBangla
                        ? 'লেনদেন এডিট করুন'
                        : 'Edit transaction',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _editTransaction(transaction);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.expenseColor,
                  ),
                  title: Text(
                    _isBangla
                        ? 'লেনদেন মুছে ফেলুন'
                        : 'Delete transaction',
                    style: TextStyle(
                      color: AppTheme.expenseColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _deleteTransaction(transaction);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(theme),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HomeBackgroundPainter(
                  isDark: theme.brightness == Brightness.dark,
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildTopBar(theme),
                  ),
                  SliverToBoxAdapter(
                    child: _buildMainSummary(theme),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSummaryCards(theme),
                  ),
                  SliverToBoxAdapter(
                    child: _buildQuickActions(theme),
                  ),
                  SliverToBoxAdapter(
                    child: _buildAccountsSection(theme),
                  ),
                  SliverToBoxAdapter(
                    child: _buildRecentTransactions(theme),
                  ),
                  SliverToBoxAdapter(
                    child: _buildToolsSection(theme),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: theme.scaffoldBackgroundColor
                    .withValues(alpha: 0.35),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        backgroundColor: AppTheme.gold,
        foregroundColor: AppTheme.darkGreen,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: Text(
          _isBangla ? 'লেনদেন' : 'Transaction',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        8,
      ),
      child: Row(
        children: [
          _topIconButton(
            theme,
            Icons.menu_rounded,
            _openDrawer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBangla ? 'আমার হিসাব' : 'Amar Hisab',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentMonthLabel(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _topIconButton(
            theme,
            Icons.bar_chart_rounded,
            _openStatistics,
          ),
          const SizedBox(width: 8),
          _topIconButton(
            theme,
            Icons.settings_outlined,
            _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _topIconButton(
    ThemeData theme,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: theme.cardColor.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildMainSummary(ThemeData theme) {
    final positive = _difference >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        14,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkGreen,
              AppTheme.green,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              offset: const Offset(0, 10),
              color: AppTheme.darkGreen.withValues(
                alpha: 0.25,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(
                      alpha: 0.18,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppTheme.gold.withValues(
                        alpha: 0.28,
                      ),
                    ),
                  ),
                  child: Icon(
                    positive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: AppTheme.goldLight,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isBangla
                            ? 'এই মাসের হিসাব'
                            : 'This month',
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.72,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        positive
                            ? (_isBangla
                                ? 'বর্তমান উদ্বৃত্ত'
                                : 'Current Surplus')
                            : (_isBangla
                                ? 'বর্তমান ঘাটি'
                                : 'Current Deficit'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _monthName(DateTime.now().month),
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.85,
                      ),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _formatMoney(_difference),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isBangla
                  ? 'এই মাসের আয় − এই মাসের ব্যয়'
                  : 'This month income − this month expense',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.66,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _mainSummaryMini(
                    icon: Icons.south_west_rounded,
                    title: _isBangla ? 'আয়' : 'Income',
                    amount: _income,
                  ),
                ),
                Container(
                  width: 1,
                  height: 42,
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ),
                ),
                Expanded(
                  child: _mainSummaryMini(
                    icon: Icons.north_east_rounded,
                    title: _isBangla ? 'ব্যয়' : 'Expense',
                    amount: _expense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainSummaryMini({
    required IconData icon,
    required String title,
    required double amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.goldLight,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.60,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatShortMoney(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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

  Widget _buildSummaryCards(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        18,
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              theme: theme,
              icon: Icons.south_west_rounded,
              title: _isBangla ? 'আয়' : 'Income',
              subtitle: _isBangla ? 'এই মাস' : 'This month',
              amount: _income,
              color: AppTheme.incomeColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
              theme: theme,
              icon: Icons.north_east_rounded,
              title: _isBangla ? 'ব্যয়' : 'Expense',
              subtitle: _isBangla ? 'এই মাস' : 'This month',
              amount: _expense,
              color: AppTheme.expenseColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
              theme: theme,
              icon: _difference >= 0
                  ? Icons.add_circle_outline_rounded
                  : Icons.remove_circle_outline_rounded,
              title: _difference >= 0
                  ? (_isBangla ? 'উদ্বৃত্ত' : 'Surplus')
                  : (_isBangla ? 'ঘাটি' : 'Deficit'),
              subtitle: _isBangla ? 'এই মাস' : 'This month',
              amount: _difference,
              color: _difference >= 0
                  ? AppTheme.incomeColor
                  : AppTheme.expenseColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 132,
      ),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 9,
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatShortMoney(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            theme,
            _isBangla ? 'দ্রুত লেনদেন' : 'Quick Actions',
            null,
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _quickAction(
                  theme: theme,
                  icon: Icons.add_rounded,
                  title: _isBangla ? 'আয়' : 'Income',
                  color: AppTheme.incomeColor,
                  onTap: _openAddTransaction,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickAction(
                  theme: theme,
                  icon: Icons.remove_rounded,
                  title: _isBangla ? 'ব্যয়' : 'Expense',
                  color: AppTheme.expenseColor,
                  onTap: _openAddTransaction,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickAction(
                  theme: theme,
                  icon: Icons.swap_horiz_rounded,
                  title: _isBangla ? 'ট্রান্সফার' : 'Transfer',
                  color: AppTheme.transferColor,
                  onTap: _openAddTransaction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: theme.cardColor.withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 8,
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 24,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: _sectionHeader(
              theme,
              _isBangla
                  ? 'অ্যাকাউন্ট ব্যালেন্স'
                  : 'Account Balances',
              () {
                _openAccounts();
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: theme.dividerColor.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppTheme.gold,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isBangla
                              ? 'সব অ্যাকাউন্টের বর্তমান ব্যালেন্স'
                              : 'Current balance of all accounts',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isBangla
                              ? 'ট্রান্সফারসহ'
                              : 'Including transfers',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            color: theme
                                .textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatMoney(_totalAccountBalance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          if (_accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: _emptyCard(
                theme,
                _isBangla
                    ? 'কোনো অ্যাকাউন্ট পাওয়া যায়নি'
                    : 'No accounts found',
              ),
            )
          else
            SizedBox(
              height: 135,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _accounts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _buildAccountCard(
                    theme,
                    _accounts[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    ThemeData theme,
    Map<String, dynamic> account,
  ) {
    final balance =
        (account['balance'] as num?)?.toDouble() ?? 0;

    final color = _accountColor(
      account,
      theme,
    );

    final icon = _accountIcon(account);

    final name =
        account['name']?.toString() ??
        (_isBangla ? 'অ্যাকাউন্ট' : 'Account');

    return SizedBox(
      width: 170,
      child: Material(
        color: theme.cardColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: _openAccounts,
          borderRadius: BorderRadius.circular(21),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 19,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: theme.iconTheme.color
                          ?.withValues(alpha: 0.35),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatShortMoney(balance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: balance < 0
                        ? AppTheme.expenseColor
                        : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24,
      ),
      child: Column(
        children: [
          _sectionHeader(
            theme,
            _isBangla
                ? 'সাম্প্রতিক লেনদেন'
                : 'Recent Transactions',
            _recentTransactions.isEmpty
                ? null
                : _openTransactions,
          ),
          const SizedBox(height: 10),
          if (_recentTransactions.isEmpty)
            _emptyTransactions(theme)
          else
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(
                  alpha: 0.88,
                ),
                borderRadius: BorderRadius.circular(23),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(
                  _recentTransactions.length,
                  (index) {
                    final transaction =
                        _recentTransactions[index];

                    return _buildTransactionTile(
                      theme,
                      transaction,
                      index ==
                          _recentTransactions.length - 1,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    ThemeData theme,
    Map<String, dynamic> transaction,
    bool last,
  ) {
    final type =
        transaction['type']?.toString() ?? '';

    final color = _transactionColor(
      type,
      theme,
    );

    final amount =
        (transaction['amount'] as num?)?.toDouble() ?? 0;

    final title = _transactionTitle(
      transaction,
    );

    final account = _transactionAccount(
      transaction,
    );

    final date =
        _formatDate(transaction['transaction_date']);

    String amountText;

    if (type.toLowerCase() == 'income') {
      amountText = '+${_formatMoney(amount)}';
    } else if (type.toLowerCase() == 'expense') {
      amountText = '-${_formatMoney(amount)}';
    } else {
      amountText = '⇄ ${_formatMoney(amount)}';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _editTransaction(transaction);
        },
        onLongPress: () {
          _showTransactionMenu(transaction);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            13,
            12,
            13,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _transactionIcon(type),
                      color: color,
                      size: 20,
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
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (account.isNotEmpty) ...[
                              Flexible(
                                child: Text(
                                  account,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    fontSize: 10,
                                    color: theme
                                        .textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: theme
                                      .textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.35),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              date,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                fontSize: 10,
                                color: theme
                                    .textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _transactionType(type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: theme.iconTheme.color
                        ?.withValues(alpha: 0.28),
                  ),
                ],
              ),
              if (!last)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 54,
                    top: 12,
                  ),
                  child: Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyTransactions(ThemeData theme) {
    return _emptyCard(
      theme,
      _isBangla
          ? 'এখনও কোনো লেনদেন যোগ করা হয়নি'
          : 'No transactions yet',
      icon: Icons.receipt_long_outlined,
      action: _openAddTransaction,
    );
  }

  Widget _emptyCard(
    ThemeData theme,
    String text, {
    IconData icon = Icons.info_outline_rounded,
    VoidCallback? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 25,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(
          alpha: 0.82,
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 31,
            color: theme.iconTheme.color?.withValues(
              alpha: 0.38,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color
                  ?.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 13),
            OutlinedButton(
              onPressed: action,
              child: Text(
                _isBangla
                    ? 'প্রথম লেনদেন যোগ করুন'
                    : 'Add first transaction',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolsSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            theme,
            _isBangla ? 'প্রয়োজনীয় টুল' : 'Useful Tools',
            null,
          ),
          const SizedBox(height: 11),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.08,
            children: [
              _toolCard(
                theme: theme,
                icon: Icons.category_outlined,
                title: _isBangla ? 'খাত' : 'Categories',
                onTap: _openCategories,
              ),
              _toolCard(
                theme: theme,
                icon: Icons.assessment_outlined,
                title: _isBangla ? 'রিপোর্ট' : 'Report',
                onTap: _openReport,
              ),
              _toolCard(
                theme: theme,
                icon: Icons.bar_chart_outlined,
                title: _isBangla ? 'পরিসংখ্যান' : 'Statistics',
                onTap: _openStatistics,
              ),
              _toolCard(
                theme: theme,
                icon: Icons.account_balance_wallet_outlined,
                title: _isBangla ? 'অ্যাকাউন্ট' : 'Accounts',
                onTap: _openAccounts,
              ),
              _toolCard(
                theme: theme,
                icon: Icons.receipt_long_outlined,
                title: _isBangla ? 'সব লেনদেন' : 'Transactions',
                onTap: _openTransactions,
              ),
              _toolCard(
                theme: theme,
                icon: Icons.info_outline_rounded,
                title: _isBangla ? 'সম্পর্কে' : 'About',
                onTap: _openAbout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: theme.cardColor.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 25,
                color: AppTheme.gold,
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    ThemeData theme,
    String title,
    VoidCallback? onViewAll,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.gold,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              tapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _isBangla ? 'সব দেখুন' : 'View all',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                16,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkGreen,
                      AppTheme.green,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(
                          alpha: 0.16,
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppTheme.goldLight,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'আমার হিসাব',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _isBangla
                                ? 'সহজে আপনার হিসাব রাখুন'
                                : 'Manage your money simply',
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: 0.65,
                              ),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                children: [
                  _drawerItem(
                    theme,
                    icon: Icons.home_rounded,
                    title: _isBangla ? 'হোম' : 'Home',
                    selected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.receipt_long_outlined,
                    title: _isBangla
                        ? 'সব লেনদেন'
                        : 'Transactions',
                    onTap: () {
                      Navigator.pop(context);
                      _openTransactions();
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.account_balance_wallet_outlined,
                    title: _isBangla
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
                    title: _isBangla ? 'খাত' : 'Categories',
                    onTap: () {
                      Navigator.pop(context);
                      _openCategories();
                    },
                  ),
                  const SizedBox(height: 8),
                  _drawerDivider(theme),
                  _drawerItem(
                    theme,
                    icon: Icons.bar_chart_outlined,
                    title: _isBangla
                        ? 'পরিসংখ্যান'
                        : 'Statistics',
                    onTap: () {
                      Navigator.pop(context);
                      _openStatistics();
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.assessment_outlined,
                    title: _isBangla ? 'রিপোর্ট' : 'Report',
                    onTap: () {
                      Navigator.pop(context);
                      _openReport();
                    },
                  ),
                  const SizedBox(height: 8),
                  _drawerDivider(theme),
                  _drawerItem(
                    theme,
                    icon: Icons.settings_outlined,
                    title: _isBangla
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
                    title: _isBangla
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
                18,
              ),
              child: Text(
                _isBangla
                    ? 'আপনার হিসাব, আপনার নিয়ন্ত্রণ'
                    : 'Your money, your control',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 5,
      ),
      child: Divider(
        color: theme.dividerColor.withValues(
          alpha: 0.08,
        ),
      ),
    );
  }

  Widget _drawerItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: Material(
        color: selected
            ? AppTheme.green.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? AppTheme.gold
                      : theme.iconTheme.color
                          ?.withValues(alpha: 0.70),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: selected
                          ? AppTheme.gold
                          : null,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBackgroundPainter extends CustomPainter {
  final bool isDark;

  _HomeBackgroundPainter({
    required this.isDark,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final opacity = isDark ? 0.055 : 0.035;

    paint.color = AppTheme.green.withValues(
      alpha: opacity,
    );

    final circleOne = Offset(
      size.width * 0.90,
      size.height * 0.10,
    );

    canvas.drawCircle(
      circleOne,
      math.min(size.width, size.height) * 0.34,
      paint,
    );

    paint.color = AppTheme.gold.withValues(
      alpha: isDark ? 0.035 : 0.025,
    );

    final circleTwo = Offset(
      size.width * 0.05,
      size.height * 0.42,
    );

    canvas.drawCircle(
      circleTwo,
      math.min(size.width, size.height) * 0.25,
      paint,
    );

    paint.color = AppTheme.green.withValues(
      alpha: isDark ? 0.035 : 0.022,
    );

    final circleThree = Offset(
      size.width * 0.95,
      size.height * 0.76,
    );

    canvas.drawCircle(
      circleThree,
      math.min(size.width, size.height) * 0.30,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _HomeBackgroundPainter oldDelegate,
  ) {
    return oldDelegate.isDark != isDark;
  }
}
