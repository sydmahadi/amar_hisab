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

  double _income = 0;
  double _expense = 0;
  double _difference = 0;

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =========================================================
  // DATA
  // =========================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final now = DateTime.now();

      // চলতি মাসের শুরু
      final startDate = DateTime(
        now.year,
        now.month,
        1,
      );

      // পরের মাসের শুরু
      // End date হিসেবে exclusive boundary ব্যবহার করছি।
      final endDate = DateTime(
        now.year,
        now.month + 1,
        1,
      );

      final period = await _db.getPeriodTotals(
        startDate: startDate,
        endDate: endDate,
      );

      final accounts = await _db.getAccounts();

      final transactions = await _db.getTransactions();

      if (!mounted) return;

      setState(() {
        _income = _toDouble(period['income']);
        _expense = _toDouble(period['expense']);
        _difference = _toDouble(period['difference']);

        _accounts = List<Map<String, dynamic>>.from(
          accounts,
        );

        _recentTransactions = transactions
            .take(5)
            .toList();

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

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _money(double value) {
    return value.toStringAsFixed(2);
  }

  Color _alpha(
    Color color,
    double opacity,
  ) {
    return color.withValues(
      alpha: opacity,
    );
  }

  // =========================================================
  // TRANSACTION HELPERS
  // =========================================================

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

  String _transactionTitle(
    Map<String, dynamic> item,
  ) {
    final settings = AppSettings.instance;

    final note = item['note']
        ?.toString()
        .trim();

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

    final type = item['type']
        ?.toString()
        .toLowerCase();

    switch (type) {
      case 'income':
        return settings.isBangla
            ? 'আয়'
            : 'Income';

      case 'expense':
        return settings.isBangla
            ? 'ব্যয়'
            : 'Expense';

      case 'transfer':
        return settings.isBangla
            ? 'ট্রান্সফার'
            : 'Transfer';

      default:
        return settings.isBangla
            ? 'লেনদেন'
            : 'Transaction';
    }
  }

  String _transactionSubtitle(
    Map<String, dynamic> item,
  ) {
    final type = item['type']
        ?.toString()
        .toLowerCase();

    final settings = AppSettings.instance;

    if (type == 'transfer') {
      final from = item['from_account_name']
          ?.toString()
          .trim();

      final to = item['to_account_name']
          ?.toString()
          .trim();

      if (from != null &&
          from.isNotEmpty &&
          to != null &&
          to.isNotEmpty) {
        return '$from → $to';
      }

      return settings.isBangla
          ? 'অ্যাকাউন্ট ট্রান্সফার'
          : 'Account transfer';
    }

    final account = item['account_name']
        ?.toString()
        .trim();

    if (account != null && account.isNotEmpty) {
      return account;
    }

    return settings.isBangla
        ? 'লেনদেন'
        : 'Transaction';
  }

  String _formatDate(
    dynamic value,
  ) {
    final date = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _currentMonthName() {
    const monthsBn = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
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

    const monthsEn = [
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

    final month = DateTime.now().month;

    return AppSettings.instance.isBangla
        ? monthsBn[month - 1]
        : monthsEn[month - 1];
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  Future<void> _openAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddTransactionScreen(),
      ),
    );

    if (mounted) {
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

    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _openAccounts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AccountsScreen(),
      ),
    );

    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _openCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CategoriesScreen(),
      ),
    );

    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _openStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const StatisticsScreen(),
      ),
    );

    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _openReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ReportScreen(),
      ),
    );

    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SettingsScreen(),
      ),
    );

    if (mounted) {
      setState(() {});
      await _loadData();
    }
  }

  Future<void> _openAbout() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AboutScreen(),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final settings = AppSettings.instance;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      drawer: _buildDrawer(theme),

      floatingActionButton:
          _buildFloatingButton(),

      body: Stack(
        children: [
          Positioned.fill(
            child: _PremiumBackground(
              isDark: settings.isDarkMode,
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              color: AppTheme.green,
              onRefresh: _loadData,
              child: CustomScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(
                  parent:
                      BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child:
                        _buildTopBar(theme),
                  ),

                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      18,
                      4,
                      18,
                      110,
                    ),
                    sliver: SliverList(
                      delegate:
                          SliverChildListDelegate([
                        _buildMainBalanceCard(
                          theme,
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        _buildIncomeExpenseCards(
                          theme,
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        _buildQuickActions(
                          theme,
                        ),

                        const SizedBox(
                          height: 26,
                        ),

                        _buildSectionTitle(
                          theme,
                          settings.isBangla
                              ? 'সাম্প্রতিক লেনদেন'
                              : 'Recent Transactions',
                          actionText:
                              settings.isBangla
                                  ? 'সব দেখুন'
                                  : 'View All',
                          onAction:
                              _openTransactions,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildRecentTransactions(
                          theme,
                        ),

                        const SizedBox(
                          height: 26,
                        ),

                        _buildSectionTitle(
                          theme,
                          settings.isBangla
                              ? 'অ্যাকাউন্টসমূহ'
                              : 'Accounts',
                          actionText:
                              settings.isBangla
                                  ? 'সব দেখুন'
                                  : 'View All',
                          onAction:
                              _openAccounts,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildAccounts(
                          theme,
                        ),

                        const SizedBox(
                          height: 26,
                        ),

                        _buildSectionTitle(
                          theme,
                          settings.isBangla
                              ? 'প্রয়োজনীয় টুল'
                              : 'Useful Tools',
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildTools(
                          theme,
                        ),
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
                  color: theme
                      .scaffoldBackgroundColor
                      .withValues(
                    alpha: 0.25,
                  ),
                  child: const Center(
                    child:
                        CircularProgressIndicator(
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

  // =========================================================
  // TOP BAR
  // =========================================================

  Widget _buildTopBar(
    ThemeData theme,
  ) {
    final settings = AppSettings.instance;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10,
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return _topActionButton(
                theme,
                icon:
                    Icons.menu_rounded,
                onTap: () {
                  Scaffold.of(
                    context,
                  ).openDrawer();
                },
              );
            },
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
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurface,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  settings.isBangla
                      ? 'আপনার হিসাব, এক জায়গায়'
                      : 'Your finances, all in one place',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          _topActionButton(
            theme,
            icon:
                Icons.bar_chart_rounded,
            onTap:
                _openStatistics,
          ),

          const SizedBox(width: 8),

          _topActionButton(
            theme,
            icon:
                Icons.settings_outlined,
            onTap:
                _openSettings,
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
        borderRadius:
            BorderRadius.circular(14),
        child: Ink(
          width: 43,
          height: 43,
          decoration:
              BoxDecoration(
            color: theme
                .colorScheme
                .surface
                .withValues(
              alpha: theme.brightness ==
                      Brightness.dark
                  ? 0.78
                  : 0.88,
            ),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: theme
                  .colorScheme
                  .onSurface
                  .withValues(
                alpha: 0.07,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme
                .colorScheme
                .onSurface,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MAIN BALANCE CARD
  // =========================================================

  Widget _buildMainBalanceCard(
    ThemeData theme,
  ) {
    final settings =
        AppSettings.instance;

    final isSurplus =
        _difference >= 0;

    final statusColor = isSurplus
        ? AppTheme.incomeColor
        : AppTheme.expenseColor;

    final statusText =
        isSurplus
            ? (settings.isBangla
                ? 'উদ্বৃত্ত'
                : 'Surplus')
            : (settings.isBangla
                ? 'ঘাটি'
                : 'Deficit');

    return Container(
      padding:
          const EdgeInsets.all(22),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(30),
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            AppTheme.darkGreen,
            AppTheme.green,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.green
                .withValues(
              alpha: 0.20,
            ),
            blurRadius: 30,
            offset:
                const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -45,
            child: Container(
              width: 155,
              height: 155,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                border: Border.all(
                  color: Colors.white
                      .withValues(
                    alpha: 0.07,
                  ),
                  width: 22,
                ),
              ),
            ),
          ),

          Positioned(
            right: 15,
            bottom: -65,
            child: Container(
              width: 130,
              height: 130,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: AppTheme.gold
                    .withValues(
                  alpha: 0.08,
                ),
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
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(
                      color: Colors
                          .white
                          .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .account_balance_wallet_outlined,
                      color:
                          AppTheme.goldLight,
                      size: 20,
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        settings
                                .isBangla
                            ? 'চলতি মাসের অবস্থা'
                            : 'Current Month',
                        style:
                            TextStyle(
                          color: Colors
                              .white
                              .withValues(
                            alpha:
                                0.70,
                          ),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        _currentMonthName(),
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                statusText,
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.72,
                  ),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .end,
                children: [
                  Text(
                    '৳ ${_money(_difference.abs())}',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 32,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing:
                          -0.8,
                    ),
                  ),
                  const SizedBox(
                    width: 9,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 6,
                    ),
                    child:
                        Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            9,
                        vertical:
                            5,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            statusColor
                                .withValues(
                          alpha: 0.18,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child: Text(
                        isSurplus
                            ? '+'
                            : '-',
                        style:
                            TextStyle(
                          color:
                              statusColor,
                          fontWeight:
                              FontWeight
                                  .w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              Container(
                height: 1,
                color: Colors.white
                    .withValues(
                  alpha: 0.10,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        _mainCardStat(
                      icon: Icons
                          .arrow_downward_rounded,
                      title: settings
                              .isBangla
                          ? 'আয়'
                          : 'Income',
                      value:
                          '৳ ${_money(_income)}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white
                        .withValues(
                      alpha: 0.10,
                    ),
                  ),
                  Expanded(
                    child:
                        Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        left: 18,
                      ),
                      child:
                          _mainCardStat(
                        icon: Icons
                            .arrow_upward_rounded,
                        title: settings
                                .isBangla
                            ? 'ব্যয়'
                            : 'Expense',
                        value:
                            '৳ ${_money(_expense)}',
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

  Widget _mainCardStat({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration:
              BoxDecoration(
            color: Colors.white
                .withValues(
              alpha: 0.10,
            ),
            shape:
                BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white
                .withValues(
              alpha: 0.85,
            ),
            size: 16,
          ),
        ),
        const SizedBox(
          width: 9,
        ),
        Flexible(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.62,
                  ),
                  fontSize: 10,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                value,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INCOME / EXPENSE / DIFFERENCE
  // =========================================================

  Widget _buildIncomeExpenseCards(
    ThemeData theme,
  ) {
    final settings =
        AppSettings.instance;

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            theme,
            icon:
                Icons.south_west_rounded,
            title: settings.isBangla
                ? 'মোট আয়'
                : 'Income',
            value:
                '৳ ${_money(_income)}',
            color:
                AppTheme.incomeColor,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _metricCard(
            theme,
            icon:
                Icons.north_east_rounded,
            title: settings.isBangla
                ? 'মোট ব্যয়'
                : 'Expense',
            value:
                '৳ ${_money(_expense)}',
            color:
                AppTheme.expenseColor,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _metricCard(
            theme,
            icon: _difference >= 0
                ? Icons
                    .trending_up_rounded
                : Icons
                    .trending_down_rounded,
            title: _difference >= 0
                ? (settings.isBangla
                    ? 'উদ্বৃত্ত'
                    : 'Surplus')
                : (settings.isBangla
                    ? 'ঘাটি'
                    : 'Deficit'),
            value:
                '৳ ${_money(_difference.abs())}',
            color: _difference >= 0
                ? AppTheme.incomeColor
                : AppTheme.expenseColor,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      ),
      decoration:
          BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color: theme
              .colorScheme
              .onSurface
              .withValues(
            alpha: 0.055,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
              fontSize: 9.5,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: theme
                  .colorScheme
                  .onSurface,
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // QUICK ACTIONS
  // =========================================================

  Widget _buildQuickActions(
    ThemeData theme,
  ) {
    final settings =
        AppSettings.instance;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          theme,
          settings.isBangla
              ? 'দ্রুত লেনদেন'
              : 'Quick Actions',
        ),

        const SizedBox(
          height: 12,
        ),

        Row(
          children: [
            Expanded(
              child: _quickAction(
                theme,
                icon: Icons
                    .add_circle_outline_rounded,
                title: settings.isBangla
                    ? 'আয় যোগ করুন'
                    : 'Add Income',
                color:
                    AppTheme.incomeColor,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: _quickAction(
                theme,
                icon: Icons
                    .remove_circle_outline_rounded,
                title: settings.isBangla
                    ? 'ব্যয় যোগ করুন'
                    : 'Add Expense',
                color:
                    AppTheme.expenseColor,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: _quickAction(
                theme,
                icon: Icons
                    .swap_horiz_rounded,
                title: settings.isBangla
                    ? 'ট্রান্সফার'
                    : 'Transfer',
                color:
                    AppTheme.transferColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickAction(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            _openAddTransaction,
        borderRadius:
            BorderRadius.circular(20),
        child: Ink(
          padding:
              const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 5,
          ),
          decoration:
              BoxDecoration(
            color: theme.cardColor,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: theme
                  .colorScheme
                  .onSurface
                  .withValues(
                alpha: 0.055,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme
                      .colorScheme
                      .onSurface,
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

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
              color: theme
                  .colorScheme
                  .onSurface,
              fontSize: 17,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ),
        if (actionText != null &&
            onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 6,
              ),
            ),
            child: Text(
              actionText,
              style:
                  const TextStyle(
                color:
                    AppTheme.gold,
                fontSize: 11,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  // =========================================================
  // RECENT TRANSACTIONS
  // =========================================================

  Widget _buildRecentTransactions(
    ThemeData theme,
  ) {
    final settings =
        AppSettings.instance;

    if (_recentTransactions.isEmpty) {
      return _emptyCard(
        theme,
        icon:
            Icons.receipt_long_outlined,
        text: settings.isBangla
            ? 'এখনও কোনো লেনদেন নেই'
            : 'No transactions yet',
      );
    }

    return Container(
      decoration:
          BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: theme
              .colorScheme
              .onSurface
              .withValues(
            alpha: 0.055,
          ),
        ),
      ),
      child: Column(
        children: List.generate(
          _recentTransactions.length,
          (index) {
            final item =
                _recentTransactions[
                    index];

            final type =
                item['type']
                        ?.toString() ??
                    '';

            final color =
                _transactionColor(
              type,
            );

            final amount =
                _toDouble(
              item['amount'],
            );

            final date =
                item['transaction_date'] ??
                    item['transactionDate'];

            final isExpense =
                type.toLowerCase() ==
                    'expense';

            final isTransfer =
                type.toLowerCase() ==
                    'transfer';

            return Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 43,
                    height: 43,
                    decoration:
                        BoxDecoration(
                      color: color
                          .withValues(
                        alpha: 0.10,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child: Icon(
                      _transactionIcon(
                        type,
                      ),
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _transactionTitle(
                      item,
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme
                          .colorScheme
                          .onSurface,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  subtitle:
                      Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      top: 3,
                    ),
                    child: Text(
                      '${_transactionSubtitle(item)} • ${_formatDate(date)}',
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          TextStyle(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                  trailing: Text(
                    isTransfer
                        ? '৳ ${_money(amount)}'
                        : isExpense
                            ? '-৳ ${_money(amount)}'
                            : '+৳ ${_money(amount)}',
                    style:
                        TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
                if (index !=
                    _recentTransactions
                            .length -
                        1)
                  Divider(
                    height: 1,
                    indent: 70,
                    endIndent: 14,
                    color: theme
                        .colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.055,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // ACCOUNTS
  // =========================================================

  Widget _buildAccounts(
    ThemeData theme,
  ) {
    final settings =
        AppSettings.instance;

    if (_accounts.isEmpty) {
      return _emptyCard(
        theme,
        icon:
            Icons.account_balance_outlined,
        text: settings.isBangla
            ? 'কোনো অ্যাকাউন্ট নেই'
            : 'No accounts',
      );
    }

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            _accounts.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 10,
        ),
        itemBuilder:
            (context, index) {
          final account =
              _accounts[index];

          final balance =
              _toDouble(
            account['balance'],
          );

          final accountColor =
              _accountColor(
            account,
          );

          return Container(
            width: 166,
            padding:
                const EdgeInsets.all(
              15,
            ),
            decoration:
                BoxDecoration(
              color:
                  theme.cardColor,
              borderRadius:
                  BorderRadius.circular(
                21,
              ),
              border: Border.all(
                color: theme
                    .colorScheme
                    .onSurface
                    .withValues(
                  alpha: 0.055,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 37,
                      height: 37,
                      decoration:
                          BoxDecoration(
                        color:
                            accountColor
                                .withValues(
                          alpha:
                              0.10,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          11,
                        ),
                      ),
                      child: Icon(
                        _accountIcon(
                          account,
                        ),
                        color:
                            accountColor,
                        size: 19,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons
                          .chevron_right_rounded,
                      size: 18,
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ],
                ),

                const Spacer(),

                Text(
                  account['name']
                          ?.toString() ??
                      (settings.isBangla
                          ? 'অ্যাকাউন্ট'
                          : 'Account'),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  '৳ ${_money(balance)}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurface,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _accountColor(
    Map<String, dynamic> account,
  ) {
    final value =
        account['color'];

    if (value is int) {
      return Color(value);
    }

    if (value is num) {
      return Color(
        value.toInt(),
      );
    }

    return AppTheme.gold;
  }

  IconData _accountIcon(
    Map<String, dynamic> account,
  ) {
    final value =
        account['icon'];

    if (value is int) {
      return IconData(
        value,
        fontFamily:
            'MaterialIcons',
      );
    }

    if (value is num) {
      return IconData(
        value.toInt(),
        fontFamily:
            'MaterialIcons',
      );
    }

    return Icons
        .account_balance_wallet_outlined;
  }

  // =========================================================
  // TOOLS
  // =========================================================

  Widget _buildTools(
    ThemeData theme,
  ) {
    final settings =
        AppSettings.instance;

    return Row(
      children: [
        Expanded(
          child: _toolCard(
            theme,
            icon:
                Icons.category_outlined,
            title: settings.isBangla
                ? 'খাত'
                : 'Categories',
            onTap:
                _openCategories,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _toolCard(
            theme,
            icon:
                Icons.description_outlined,
            title: settings.isBangla
                ? 'রিপোর্ট'
                : 'Report',
            onTap: _openReport,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _toolCard(
            theme,
            icon:
                Icons.info_outline_rounded,
            title: settings.isBangla
                ? 'তথ্য'
                : 'About',
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
        borderRadius:
            BorderRadius.circular(18),
        child: Ink(
          padding:
              const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 5,
          ),
          decoration:
              BoxDecoration(
            color: theme.cardColor,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: theme
                  .colorScheme
                  .onSurface
                  .withValues(
                alpha: 0.055,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  color: AppTheme.gold
                      .withValues(
                    alpha: 0.09,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color:
                      AppTheme.gold,
                  size: 20,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme
                      .colorScheme
                      .onSurface,
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _emptyCard(
    ThemeData theme, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 28,
      ),
      decoration:
          BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: theme
              .colorScheme
              .onSurface
              .withValues(
            alpha: 0.055,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 30,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            text,
            style: TextStyle(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FLOATING BUTTON
  // =========================================================

  Widget _buildFloatingButton() {
    final settings =
        AppSettings.instance;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: FloatingActionButton.extended(
        heroTag:
            'amar_hisab_home_add',
        onPressed:
            _openAddTransaction,
        backgroundColor:
            AppTheme.green,
        foregroundColor:
            Colors.white,
        elevation: 8,
        icon: const Icon(
          Icons.add_rounded,
          size: 24,
        ),
        label: Text(
          settings.isBangla
              ? 'নতুন লেনদেন'
              : 'New Transaction',
          style: const TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DRAWER
  // =========================================================

  Drawer _buildDrawer(
    ThemeData theme,
  ) {
    final settings =
        AppSettings.instance;

    return Drawer(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(
                22,
                28,
                22,
                24,
              ),
              decoration:
                  const BoxDecoration(
                gradient:
                    LinearGradient(
                  colors: [
                    AppTheme.darkGreen,
                    AppTheme.green,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .account_balance_wallet_outlined,
                      color:
                          AppTheme.goldLight,
                      size: 27,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  Text(
                    settings
                        .t('appName'),
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 23,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    settings.isBangla
                        ? 'সহজে আপনার হিসাব রাখুন'
                        : 'Manage your money simply',
                    style:
                        TextStyle(
                      color: Colors
                          .white
                          .withValues(
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
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                children: [
                  _drawerItem(
                    theme,
                    icon: Icons
                        .dashboard_outlined,
                    title: settings
                            .isBangla
                        ? 'হোম'
                        : 'Home',
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                    },
                  ),

                  _drawerItem(
                    theme,
                    icon: Icons
                        .receipt_long_outlined,
                    title: settings
                            .isBangla
                        ? 'লেনদেন'
                        : 'Transactions',
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                      _openTransactions();
                    },
                  ),

                  _drawerItem(
                    theme,
                    icon: Icons
                        .account_balance_wallet_outlined,
                    title: settings
                            .isBangla
                        ? 'অ্যাকাউন্ট'
                        : 'Accounts',
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                      _openAccounts();
                    },
                  ),

                  _drawerItem(
                    theme,
                    icon: Icons
                        .category_outlined,
                    title: settings
                            .isBangla
                        ? 'খাত'
                        : 'Categories',
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                      _openCategories();
                    },
                  ),

                  _drawerItem(
                    theme,
                    icon: Icons
                        .bar_chart_rounded,
                    title: settings
                            .isBangla
                        ? 'পরিসংখ্যান'
                        : 'Statistics',
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                      _openStatistics();
                    },
                  ),

                  _drawerItem(
                    theme,
                    icon: Icons
                        .description_outlined,
                    title: settings
                            .isBangla
                        ? 'রিপোর্ট'
                        : 'Report',
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                      _openReport();
                    },
                  ),

                  _drawerItem(
                    theme,
                    icon: Icons
                        .settings_outlined,
                    title: settings
                            .isBangla
                        ? 'সেটিংস'
                        : 'Settings',
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                      _openSettings();
                    },
                  ),

                  _drawerItem(
                    theme,
                    icon: Icons
                        .info_outline_rounded,
                    title: settings
                            .isBangla
                        ? 'অ্যাপ সম্পর্কে'
                        : 'About',
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                      _openAbout();
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
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
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
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
      padding:
          const EdgeInsets.only(
        bottom: 3,
      ),
      child: ListTile(
        onTap: onTap,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
        leading: Icon(
          icon,
          size: 21,
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme
                .colorScheme
                .onSurface,
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 19,
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),
      ),
    );
  }
}

// ===========================================================
// PREMIUM BACKGROUND
// ===========================================================

class _PremiumBackground
    extends StatelessWidget {
  final bool isDark;

  const _PremiumBackground({
    required this.isDark,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return IgnorePointer(
      child: CustomPaint(
        painter:
            _PremiumBackgroundPainter(
          isDark: isDark,
        ),
        child:
            const SizedBox.expand(),
      ),
    );
  }
}

class _PremiumBackgroundPainter
    extends CustomPainter {
  final bool isDark;

  _PremiumBackgroundPainter({
    required this.isDark,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final bgPaint = Paint()
      ..style =
          PaintingStyle.fill
      ..color = isDark
          ? const Color(
              0xFF08120F,
            )
          : const Color(
              0xFFF4F1E9,
            );

    canvas.drawRect(
      Offset.zero & size,
      bgPaint,
    );

    final greenPaint = Paint()
      ..color = isDark
          ? const Color(
              0x121F7655,
            )
          : const Color(
              0x0D176B45,
            )
      ..style =
          PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        size.width * 0.98,
        size.height * 0.15,
      ),
      size.width * 0.62,
      greenPaint,
    );

    final goldPaint = Paint()
      ..color = isDark
          ? const Color(
              0x0CC9A45C,
            )
          : const Color(
              0x0FC9A45C,
            )
      ..style =
          PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        size.width * 0.04,
        size.height * 0.52,
      ),
      size.width * 0.38,
      goldPaint,
    );

    final ringPaint = Paint()
      ..color = isDark
          ? const Color(
              0x102D8A63,
            )
          : const Color(
              0x0A176B45,
            )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 34;

    canvas.drawCircle(
      Offset(
        size.width * 0.90,
        size.height * 0.74,
      ),
      size.width * 0.45,
      ringPaint,
    );

    final thinRingPaint = Paint()
      ..color = isDark
          ? const Color(
              0x0CC9A45C,
            )
          : const Color(
              0x0AC9A45C,
            )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      Offset(
        size.width * 0.08,
        size.height * 0.20,
      ),
      90,
      thinRingPaint,
    );

    final dotPaint = Paint()
      ..color = isDark
          ? const Color(
              0x16C9A45C,
            )
          : const Color(
              0x14B99550,
            )
      ..style =
          PaintingStyle.fill;

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
          ? const Color(
              0x071F7655,
            )
          : const Color(
              0x08176B45,
            )
      ..style =
          PaintingStyle.fill;

    canvas.drawPath(
      path,
      shapePaint,
    );

    final arcPaint = Paint()
      ..color = isDark
          ? const Color(
              0x18C9A45C,
            )
          : const Color(
              0x12C9A45C,
            )
      ..style =
          PaintingStyle.stroke
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
    covariant
        _PremiumBackgroundPainter
            oldDelegate,
  ) {
    return oldDelegate.isDark !=
        isDark;
  }
}
