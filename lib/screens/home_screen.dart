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
          backgroundColor:
              isError
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

    await _loadData();
  }

  Future<void> _openReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ReportScreen(),
      ),
    );

    await _loadData();
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

  // ------------------------------------------------------------
  // TOP HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        17,
        8,
        17,
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
        boxShadow: [
          BoxShadow(
            color: AppTheme.green
                .withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.gold
                  .withValues(alpha: 0.16),
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.gold
                    .withValues(alpha: 0.28),
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppTheme.goldLight,
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
                  settings.t('appName'),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  settings.t('appTagline'),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white
                        .withValues(alpha: 0.72),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          _headerIconButton(
            icon: settings.isBangla
                ? Icons.translate_rounded
                : Icons.translate_rounded,
            label: settings.isBangla
                ? 'EN'
                : 'বাং',
            onTap: () {
              settings.setLanguage(
                settings.isBangla
                    ? 'en'
                    : 'bn',
              );
            },
          ),

          const SizedBox(width: 2),

          _headerIconButton(
            icon: settings.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            onTap: () {
              settings.toggleTheme();
            },
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'settings') {
                _openSettings();
              } else if (value == 'about') {
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

  Widget _headerIconButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(
        alpha: 0.10,
      ),
      borderRadius:
          BorderRadius.circular(12),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: label == null ? 39 : 43,
          height: 39,
          child: Center(
            child: label != null
                ? Text(
                    label,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : Icon(
                    icon,
                    color:
                        AppTheme.goldLight,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BALANCE HERO
  // ------------------------------------------------------------

  Widget _buildBalanceCard() {
    final positive = _balance >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context)
                .cardColor
                .withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.gold
              .withValues(alpha: 0.16),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -25,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold
                    .withValues(alpha: 0.05),
              ),
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration:
                        BoxDecoration(
                      color: AppTheme.gold
                          .withValues(
                        alpha: 0.13,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .account_balance_wallet_rounded,
                      color:
                          AppTheme.gold,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.t(
                            'totalBalance',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          settings.isBangla
                              ? 'বর্তমান মোট ব্যালেন্স'
                              : 'Current total balance',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(
                                  alpha: 0.70,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color: positive
                          ? Colors.green
                              .withValues(
                              alpha: 0.10,
                            )
                          : Colors.red
                              .withValues(
                              alpha: 0.10,
                            ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          positive
                              ? Icons
                                  .trending_up_rounded
                              : Icons
                                  .trending_down_rounded,
                          size: 14,
                          color: positive
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(
                          width: 3,
                        ),
                        Text(
                          positive
                              ? (settings
                                      .isBangla
                                  ? 'উদ্বৃত্ত'
                                  : 'Positive')
                              : (settings
                                      .isBangla
                                  ? 'ঘাটতি'
                                  : 'Negative'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                            color: positive
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                _formatNumber(_balance),
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: -0.5,
                  color: positive
                      ? AppTheme.gold
                      : Colors.red.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INCOME / EXPENSE
  // ------------------------------------------------------------

  Widget _buildIncomeExpense() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title:
                settings.t('incomeTotal'),
            amount: _income,
            icon:
                Icons.south_west_rounded,
            color:
                const Color(0xFF2E9D68),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            title:
                settings.t('expenseTotal'),
            amount: _expense,
            icon:
                Icons.north_east_rounded,
            color:
                const Color(0xFFD9534F),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    color.withValues(
                  alpha: 0.11,
                ),
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
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
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatNumber(amount),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // QUICK ACTIONS
  // ------------------------------------------------------------

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
        icon:
            Icons.receipt_long_rounded,
        title:
            settings.t('transactions'),
        color: Colors.blue,
        onTap: _openTransactions,
      ),
      _ActionItem(
        icon:
            Icons.account_balance_wallet_rounded,
        title:
            settings.t('accounts'),
        color: Colors.orange,
        onTap: _openAccounts,
      ),
      _ActionItem(
        icon:
            Icons.category_rounded,
        title:
            settings.t('categories'),
        color: Colors.purple,
        onTap: _openCategories,
      ),
      _ActionItem(
        icon:
            Icons.bar_chart_rounded,
        title:
            settings.t('statistics'),
        color: Colors.teal,
        onTap: _openStatistics,
      ),
      _ActionItem(
        icon:
            Icons.assessment_rounded,
        title:
            settings.t('report'),
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
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 1.02,
      ),
      itemBuilder: (context, index) {
        final item = actions[index];

        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(18),
            onTap: item.onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 9,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration:
                        BoxDecoration(
                      color: item.color
                          .withValues(
                        alpha: 0.11,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: 23,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.title,
                    textAlign:
                        TextAlign.center,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
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

  // ------------------------------------------------------------
  // ACCOUNTS
  // ------------------------------------------------------------

  Widget _buildAccounts() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration:
                        BoxDecoration(
                      color: AppTheme.gold
                          .withValues(
                        alpha: 0.11,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),
                    child: const Icon(
                      Icons.wallet_rounded,
                      color:
                          AppTheme.gold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    settings.t('accounts'),
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
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

        const SizedBox(height: 7),

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
        bottom: 8,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: _openAccounts,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration:
                    BoxDecoration(
                  color: color.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  _accountIcon(
                    account['type']
                            ?.toString() ??
                        '',
                  ),
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _accountDisplayName(
                        account,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      settings.t('balance'),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodySmall
                            ?.color,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                _formatNumber(balance),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                  color: balance >= 0
                      ? color
                      : Colors.red.shade600,
                ),
              ),

              const SizedBox(width: 3),

              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FLOATING TRANSACTION BUTTON
  // ------------------------------------------------------------

  Widget _buildTransactionButton() {
    return Padding(
      padding: const EdgeInsets.only(
        right: 4,
        bottom: 4,
      ),
      child: FloatingActionButton.extended(
        heroTag: 'home_transactions',
        onPressed: _openTransactions,
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        elevation: 5,
        icon: const Icon(
          Icons.receipt_long_rounded,
          size: 19,
        ),
        label: Text(
          settings.isBangla
              ? 'লেনদেন'
              : 'Transactions',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
      floatingActionButton:
          _buildTransactionButton(),
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
              105,
            ),
            children: [
              _buildHeader(),

              const SizedBox(height: 14),

              if (_loading)
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10),
                  child:
                      const LinearProgressIndicator(
                    minHeight: 2,
                  ),
                ),

              if (_loading)
                const SizedBox(height: 12),

              _buildBalanceCard(),

              const SizedBox(height: 10),

              _buildIncomeExpense(),

              const SizedBox(height: 24),

              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration:
                        BoxDecoration(
                      color: AppTheme.green
                          .withValues(
                        alpha: 0.11,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .auto_awesome_rounded,
                      color:
                          AppTheme.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 9),
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
                ],
              ),

              const SizedBox(height: 10),

              _buildQuickActions(),

              const SizedBox(height: 24),

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
