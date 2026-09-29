import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import '../services/money_db.dart';
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

  List<MoneyAccount> _accounts = [];
  List<MoneyTransaction> _recentTransactions = [];

  bool _loading = true;

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      await _db.init();

      final balance = await _db.getTotalBalance();
      final income = await _db.getTotalIncome();
      final expense = await _db.getTotalExpense();
      final accounts = await _db.getAccounts();
      final transactions = await _db.getTransactions();

      transactions.sort((a, b) {
        final ad = _parseDate(a.transactionDate);
        final bd = _parseDate(b.transactionDate);

        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;

        return bd.compareTo(ad);
      });

      if (!mounted) return;

      setState(() {
        _balance = balance;
        _income = income;
        _expense = expense;
        _accounts = accounts;
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

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
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
        builder: (_) => const TransactionsScreen(),
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

    await _loadData();
  }

  Future<void> _openAbout() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AboutScreen(),
      ),
    );

    await _loadData();
  }

  String _money(double value) {
    return value.abs().toStringAsFixed(2);
  }

  String _dateText(String? value) {
    final date = _parseDate(value);

    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkCard
        : AppTheme.lightCard;
  }

  Color _secondaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppTheme.secondaryTextDark
        : AppTheme.secondaryTextLight;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      floatingActionButton: _buildAddButton(context),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.green,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.gold,
                ),
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _buildBalanceCard(context),
                  const SizedBox(height: 16),
                  _buildIncomeExpenseCards(context),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                    context,
                    title: settings.t('quickActions'),
                    icon: Icons.flash_on_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildQuickActions(context),
                  const SizedBox(height: 22),
                  _buildSectionTitle(
                    context,
                    title: settings.t('recentTransactions'),
                    icon: Icons.receipt_long_rounded,
                    actionText: settings.t('viewAll'),
                    onAction: _openTransactions,
                  ),
                  const SizedBox(height: 10),
                  _buildRecentTransactions(context),
                  const SizedBox(height: 22),
                  _buildSectionTitle(
                    context,
                    title: settings.t('accounts'),
                    icon: Icons.account_balance_wallet_rounded,
                    actionText: settings.t('viewAll'),
                    onAction: _openAccounts,
                  ),
                  const SizedBox(height: 10),
                  _buildAccounts(context),
                  const SizedBox(height: 22),
                  _buildTools(context),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (context) {
          return IconButton(
            tooltip: settings.t('menu'),
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCard
                    : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.gold.withOpacity(0.25),
                ),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: AppTheme.gold,
              ),
            ),
          );
        },
      ),
      title: const SizedBox.shrink(),
      centerTitle: false,
      actions: [
        _topActionButton(
          context,
          icon: Icons.bar_chart_rounded,
          onTap: _openStatistics,
        ),
        const SizedBox(width: 4),
        _topActionButton(
          context,
          icon: Icons.settings_rounded,
          onTap: _openSettings,
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _topActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: onTap,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: AppTheme.gold.withOpacity(0.20),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark
              ? AppTheme.goldLight
              : AppTheme.darkGreen,
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.darkGreen,
                  AppTheme.green,
                ]
              : [
                  AppTheme.darkGreen,
                  AppTheme.green,
                ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGreen.withOpacity(
              isDark ? 0.28 : 0.16,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppTheme.goldLight.withOpacity(0.35),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.goldLight,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  settings.t('totalBalance'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppTheme.goldLight,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _money(_balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            settings.t('currentBalance'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _balanceMiniInfo(
                  icon: Icons.trending_up_rounded,
                  title: settings.t('income'),
                  amount: _money(_income),
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withOpacity(0.14),
              ),
              Expanded(
                child: _balanceMiniInfo(
                  icon: Icons.trending_down_rounded,
                  title: settings.t('expense'),
                  amount: _money(_expense),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceMiniInfo({
    required IconData icon,
    required String title,
    required String amount,
  }) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Icon(
          icon,
          color: AppTheme.goldLight,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            context,
            icon: Icons.arrow_downward_rounded,
            title: settings.t('income'),
            amount: _income,
            iconColor: AppTheme.green,
            onTap: _openTransactions,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            context,
            icon: Icons.arrow_upward_rounded,
            title: settings.t('expense'),
            amount: _expense,
            iconColor: AppTheme.gold,
            onTap: _openTransactions,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required double amount,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final cardColor = _cardColor(context);
    final secondary = _secondaryText(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iconColor.withOpacity(0.16),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _money(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final secondary = _secondaryText(context);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.circle,
            size: 8,
            color: AppTheme.gold,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleMedium?.color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.add_rounded,
            title: settings.t('addTransaction'),
            subtitle: settings.t('entry'),
            iconColor: AppTheme.green,
            onTap: _openAddTransaction,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.receipt_long_rounded,
            title: settings.t('transactions'),
            subtitle: settings.t('viewAll'),
            iconColor: AppTheme.gold,
            onTap: _openTransactions,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.bar_chart_rounded,
            title: settings.t('statistics'),
            subtitle: settings.t('viewAll'),
            iconColor: AppTheme.greenLight,
            onTap: _openStatistics,
          ),
        ),
      ],
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final cardColor = _cardColor(context);
    final secondary = _secondaryText(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 108,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: iconColor.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: secondary,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    if (_recentTransactions.isEmpty) {
      return _emptyCard(
        context,
        icon: Icons.receipt_long_outlined,
        text: settings.t('noTransactions'),
        buttonText: settings.t('addTransaction'),
        onPressed: _openAddTransaction,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _recentTransactions.length; i++) ...[
            _transactionItem(
              context,
              _recentTransactions[i],
            ),
            if (i != _recentTransactions.length - 1)
              Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: Theme.of(context).dividerColor.withOpacity(0.10),
              ),
          ],
        ],
      ),
    );
  }

  Widget _transactionItem(
    BuildContext context,
    MoneyTransaction transaction,
  ) {
    final isIncome = transaction.type.toLowerCase() == 'income';
    final isTransfer = transaction.type.toLowerCase() == 'transfer';

    final color = isIncome
        ? AppTheme.green
        : isTransfer
            ? AppTheme.gold
            : Colors.redAccent;

    final icon = isIncome
        ? Icons.arrow_downward_rounded
        : isTransfer
            ? Icons.swap_horiz_rounded
            : Icons.arrow_upward_rounded;

    final amountPrefix = isIncome ? '+' : '-';

    return InkWell(
      onTap: _openTransactions,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note?.trim().isNotEmpty == true
                        ? transaction.note!.trim()
                        : isIncome
                            ? settings.t('income')
                            : isTransfer
                                ? settings.t('transfer')
                                : settings.t('expense'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateText(transaction.transactionDate),
                    style: TextStyle(
                      color: _secondaryText(context),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$amountPrefix${_money(transaction.amount)}',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccounts(BuildContext context) {
    if (_accounts.isEmpty) {
      return _emptyCard(
        context,
        icon: Icons.account_balance_wallet_outlined,
        text: settings.t('noAccounts'),
        buttonText: settings.t('accounts'),
        onPressed: _openAccounts,
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final account = _accounts[index];

          return _accountCard(
            context,
            account,
          );
        },
      ),
    );
  }

  Widget _accountCard(
    BuildContext context,
    MoneyAccount account,
  ) {
    final cardColor = _cardColor(context);
    final secondary = _secondaryText(context);

    return InkWell(
      onTap: _openAccounts,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.gold.withOpacity(0.14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.wallet_rounded,
                    color: AppTheme.green,
                    size: 17,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.gold,
                  size: 18,
                ),
              ],
            ),
            const Spacer(),
            Text(
              account.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _money(account.balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              settings.t('balance'),
              style: TextStyle(
                color: secondary,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTools(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          _toolTile(
            context,
            icon: Icons.analytics_outlined,
            title: settings.t('statistics'),
            subtitle: settings.t('statisticsSubtitle'),
            onTap: _openStatistics,
          ),
          _toolDivider(context),
          _toolTile(
            context,
            icon: Icons.description_outlined,
            title: settings.t('report'),
            subtitle: settings.t('reportSubtitle'),
            onTap: _openReport,
          ),
          _toolDivider(context),
          _toolTile(
            context,
            icon: Icons.category_outlined,
            title: settings.t('categories'),
            subtitle: settings.t('categoriesSubtitle'),
            onTap: _openCategories,
          ),
          _toolDivider(context),
          _toolTile(
            context,
            icon: Icons.info_outline_rounded,
            title: settings.t('about'),
            subtitle: settings.t('aboutSubtitle'),
            onTap: _openAbout,
          ),
        ],
      ),
    );
  }

  Widget _toolTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final secondary = _secondaryText(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 9,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: AppTheme.gold,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.gold,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 54,
      color: Theme.of(context).dividerColor.withOpacity(0.10),
    );
  }

  Widget _emptyCard(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.gold.withOpacity(0.75),
            size: 34,
          ),
          const SizedBox(height: 9),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryText(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
            label: Text(buttonText),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.gold,
              side: BorderSide(
                color: AppTheme.gold.withOpacity(0.40),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'home_add_transaction',
      onPressed: _openAddTransaction,
      backgroundColor: AppTheme.green,
      foregroundColor: Colors.white,
      elevation: 7,
      tooltip: settings.t('addTransaction'),
      child: const Icon(
        Icons.add_rounded,
        size: 29,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark
          ? AppTheme.darkSurface
          : AppTheme.lightSurface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.darkGreen,
                    AppTheme.green,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.gold.withOpacity(0.35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.goldLight,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      settings.t('moneyManager'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                children: [
                  _drawerItem(
                    context,
                    icon: Icons.add_circle_outline_rounded,
                    title: settings.t('addTransaction'),
                    onTap: _openAddTransaction,
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: settings.t('transactions'),
                    onTap: _openTransactions,
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: settings.t('accounts'),
                    onTap: _openAccounts,
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.category_outlined,
                    title: settings.t('categories'),
                    onTap: _openCategories,
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.bar_chart_rounded,
                    title: settings.t('statistics'),
                    onTap: _openStatistics,
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.description_outlined,
                    title: settings.t('report'),
                    onTap: _openReport,
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    color: Theme.of(context)
                        .dividerColor
                        .withOpacity(0.15),
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: settings.t('settings'),
                    onTap: _openSettings,
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: settings.t('about'),
                    onTap: _openAbout,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Text(
                settings.t('appFooter'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryText(context),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      leading: Icon(
        icon,
        color: AppTheme.gold,
        size: 21,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
      ),
    );
  }
}
