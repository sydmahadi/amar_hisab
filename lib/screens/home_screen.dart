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
  AppSettings get settings => AppSettings.instance;

  double _balance = 0;
  double _income = 0;
  double _expense = 0;

  List<Map<String, dynamic>> _accounts = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    settings.addListener(_settingsChanged);
    _loadData();
  }

  @override
  void dispose() {
    settings.removeListener(_settingsChanged);
    super.dispose();
  }

  void _settingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      await MoneyDb.instance.init();
      await MoneyDb.instance.recalculateBalances();

      final balance =
          await MoneyDb.instance.getTotalBalance();

      final income =
          await MoneyDb.instance.getTotalIncome();

      final expense =
          await MoneyDb.instance.getTotalExpense();

      final accounts =
          await MoneyDb.instance.getAccounts();

      if (!mounted) return;

      setState(() {
        _balance = balance;
        _income = income;
        _expense = expense;
        _accounts = accounts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.red.shade700
              : AppTheme.green,
        ),
      );
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddTransactionScreen(),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _openTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const TransactionsScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _openAccounts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AccountsScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _openCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CategoriesScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _openStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const StatisticsScreen(),
      ),
    );
  }

  Future<void> _openReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ReportScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SettingsScreen(),
      ),
    );
  }

  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AboutScreen(),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  IconData _accountIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.payments_rounded;

      case 'bkash':
        return Icons.phone_android_rounded;

      case 'nagad':
        return Icons.account_balance_wallet_rounded;

      case 'bank':
        return Icons.account_balance_rounded;

      case 'card':
        return Icons.credit_card_rounded;

      default:
        return Icons.wallet_rounded;
    }
  }

  Color _accountColor(
    Map<String, dynamic> account,
  ) {
    final value = account['color'];

    if (value is int) {
      return Color(value);
    }

    if (value is num) {
      return Color(value.toInt());
    }

    return AppTheme.green;
  }

  String _accountDisplayName(
    Map<String, dynamic> account,
  ) {
    final name =
        account['name']?.toString() ?? '';

    switch (name.toLowerCase()) {
      case 'cash':
        return settings.isBangla
            ? 'ক্যাশ'
            : 'Cash';

      case 'bkash':
        return settings.isBangla
            ? 'বিকাশ'
            : 'Bkash';

      case 'nagad':
        return settings.isBangla
            ? 'নগদ'
            : 'Nagad';

      case 'bank account':
        return settings.isBangla
            ? 'ব্যাংক অ্যাকাউন্ট'
            : 'Bank Account';

      case 'card':
        return settings.isBangla
            ? 'কার্ড'
            : 'Card';

      default:
        return name;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        10,
        18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.darkGreen,
            AppTheme.green,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                  style: TextStyle(
                    color: AppTheme.goldLight,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  settings.t('appName'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  settings.t('appTagline'),
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.78),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Material(
            color: Colors.white
                .withOpacity(0.10),
            borderRadius:
                BorderRadius.circular(12),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(12),
              onTap: () {
                settings.toggleLanguage();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  settings.isBangla
                      ? 'EN'
                      : 'বাং',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          IconButton(
            tooltip: settings.darkMode
                ? 'Light Theme'
                : 'Dark Theme',
            onPressed: () {
              settings.toggleTheme();
            },
            icon: Icon(
              settings.darkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: AppTheme.goldLight,
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'settings') {
                _openSettings();
              }

              if (value == 'about') {
                _openAbout();
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.settings_rounded,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        settings.t('settings'),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'about',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        settings.t('about'),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final positive = _balance >= 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.gold
                        .withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons
                        .account_balance_wallet_rounded,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    settings.t('totalBalance'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatNumber(_balance),
              style: TextStyle(
                fontSize: 30,
                fontWeight:
                    FontWeight.bold,
                color: positive
                    ? AppTheme.gold
                    : Colors.red.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpense() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title:
                settings.t('incomeTotal'),
            amount: _income,
            icon:
                Icons.arrow_downward_rounded,
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            title:
                settings.t('expenseTotal'),
            amount: _expense,
            icon:
                Icons.arrow_upward_rounded,
            color: Colors.red.shade600,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    color.withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              title,
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
            const SizedBox(height: 3),
            Text(
              _formatNumber(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _ActionItem(
        icon:
            Icons.add_circle_outline_rounded,
        title:
            settings.t('addTransaction'),
        color: AppTheme.green,
        onTap: _openAddTransaction,
      ),
      _ActionItem(
        icon: Icons.receipt_long_rounded,
        title:
            settings.t('transactions'),
        color: Colors.blue,
        onTap: _openTransactions,
      ),
      _ActionItem(
        icon:
            Icons.account_balance_wallet_rounded,
        title: settings.t('accounts'),
        color: Colors.orange,
        onTap: _openAccounts,
      ),
      _ActionItem(
        icon: Icons.category_rounded,
        title:
            settings.t('categories'),
        color: Colors.purple,
        onTap: _openCategories,
      ),
      _ActionItem(
        icon: Icons.bar_chart_rounded,
        title:
            settings.t('statistics'),
        color: Colors.teal,
        onTap: _openStatistics,
      ),
      _ActionItem(
        icon: Icons.assessment_rounded,
        title: settings.t('report'),
        color: AppTheme.gold,
        onTap: _openReport,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final item = actions[index];

        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(16),
            onTap: item.onTap,
            child: Padding(
              padding:
                  const EdgeInsets.all(9),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration:
                        BoxDecoration(
                      color: item.color
                          .withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    textAlign:
                        TextAlign.center,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccounts() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                settings.t('accounts'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: _openAccounts,
              child: Text(
                settings.isBangla
                    ? 'সব দেখুন'
                    : 'View All',
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        if (_accounts.isEmpty)
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(22),
              child: Center(
                child: Text(
                  settings.t('noData'),
                ),
              ),
            ),
          )
        else
          ..._accounts.map(
            _buildAccountTile,
          ),
      ],
    );
  }

  Widget _buildAccountTile(
    Map<String, dynamic> account,
  ) {
    final color =
        _accountColor(account);

    final balance =
        (account['balance'] as num?)
                ?.toDouble() ??
            0;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 3,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color:
                color.withOpacity(0.12),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            _accountIcon(
              account['type']
                      ?.toString() ??
                  '',
            ),
            color: color,
          ),
        ),
        title: Text(
          _accountDisplayName(account),
          style: const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle: Text(
          settings.t('balance'),
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
        trailing: Text(
          _formatNumber(balance),
          style: TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.bold,
            color: balance >= 0
                ? color
                : Colors.red.shade600,
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
          onRefresh: _loadData,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              35,
            ),
            children: [
              _buildHeader(),

              const SizedBox(height: 14),

              if (_loading)
                const LinearProgressIndicator(
                  minHeight: 2,
                ),

              const SizedBox(height: 12),

              _buildBalanceCard(),

              const SizedBox(height: 12),

              _buildIncomeExpense(),

              const SizedBox(height: 22),

              Text(
                settings.isBangla
                    ? 'দ্রুত কাজ'
                    : 'Quick Actions',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _buildQuickActions(),

              const SizedBox(height: 22),

              _buildAccounts(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}
