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
  final AppSettings _settings = AppSettings.instance;

  bool _loading = true;

  double _income = 0;
  double _expense = 0;
  double _difference = 0;
  double _accountBalance = 0;

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
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

      final accounts = await _db.getAccounts();
      final transactions = await _db.getTransactions();
      final totalBalance = await _db.getTotalBalance();

      if (!mounted) return;

      setState(() {
        _income = _toDouble(period['income']);
        _expense = _toDouble(period['expense']);
        _difference = _toDouble(period['difference']);
        _accountBalance = _toDouble(totalBalance);

        _accounts = accounts;
        _transactions = transactions.take(8).toList();

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
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(double value) {
    return value.toStringAsFixed(2);
  }

  String _transactionType(Map<String, dynamic> item) {
    return (item['type'] ?? '').toString().toLowerCase();
  }

  String _transactionTitle(Map<String, dynamic> item) {
    final type = _transactionType(item);

    if (type == 'transfer') {
      final from = (item['from_account_name'] ?? '').toString();
      final to = (item['to_account_name'] ?? '').toString();

      if (from.isNotEmpty && to.isNotEmpty) {
        return '$from → $to';
      }

      return 'Transfer';
    }

    final category = (item['category_name'] ?? '').toString();

    if (category.isNotEmpty) {
      return category;
    }

    return type == 'income' ? 'Income' : 'Expense';
  }

  String _transactionSubtitle(Map<String, dynamic> item) {
    final note = (item['note'] ?? '').toString();

    if (note.isNotEmpty) {
      return note;
    }

    final date = (item['transaction_date'] ?? '').toString();

    if (date.length >= 10) {
      return date.substring(0, 10);
    }

    return date;
  }

  IconData _transactionIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.south_west_rounded;
      case 'expense':
        return Icons.north_east_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _transactionColor(String type) {
    switch (type) {
      case 'income':
        return const Color(0xFF4F9A72);
      case 'expense':
        return const Color(0xFFC56B68);
      case 'transfer':
        return const Color(0xFFB99550);
      default:
        return const Color(0xFFB99550);
    }
  }

  String _transactionAmount(Map<String, dynamic> item) {
    final type = _transactionType(item);
    final amount = _toDouble(item['amount']);

    if (type == 'income') {
      return '+${_money(amount)}';
    }

    if (type == 'expense') {
      return '-${_money(amount)}';
    }

    return _money(amount);
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );

    if (result == true) {
      await _loadDashboard();
    }
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
    await _db.deleteTransaction(id);
    await _loadDashboard();
  }

  Future<void> _openScreen(Widget screen) async {
    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );

    await _loadDashboard();
  }

  void _showDeleteDialog(Map<String, dynamic> transaction) {
    final id = transaction['id'];

    if (id == null) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('লেনদেন মুছে ফেলবেন?'),
          content: const Text(
            'এই লেনদেনটি মুছে দিলে এটি আর ফিরে পাওয়া যাবে না।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deleteTransaction(
                  id is int ? id : int.parse(id.toString()),
                );
              },
              child: const Text('মুছে ফেলুন'),
            ),
          ],
        );
      },
    );
  }

  void _showSettings() {
    Navigator.pop(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final dark = _settings.isDarkMode;
            final bangla = _settings.isBangla;

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border.all(
                  color: const Color(0xFFB99550).withValues(alpha: .35),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB99550).withValues(
                            alpha: .55,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF176B45),
                                  Color(0xFF0F5132),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFFB99550),
                              ),
                            ),
                            child: const Icon(
                              Icons.settings_rounded,
                              color: Color(0xFFD8BB78),
                            ),
                          ),
                          const SizedBox(width: 13),
                          const Expanded(
                            child: Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _settingTile(
                        icon: dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: 'Theme',
                        subtitle: dark ? 'Dark Mode' : 'Light Mode',
                        trailing: Switch(
                          value: dark,
                          onChanged: (value) async {
                            await _settings.setDarkMode(value);

                            setState(() {});

                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _settingTile(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: bangla ? 'বাংলা' : 'English',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _languageButton(
                              label: 'বাংলা',
                              selected: bangla,
                              onTap: () async {
                                await _settings.setLanguage('bn');

                                setState(() {});

                                setSheetState(() {});
                              },
                            ),
                            const SizedBox(width: 6),
                            _languageButton(
                              label: 'EN',
                              selected: !bangla,
                              onTap: () async {
                                await _settings.setLanguage('en');

                                setState(() {});

                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFB99550).withValues(alpha: .20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF176B45).withValues(alpha: .18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFB99550),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _languageButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF176B45)
              : AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFFB99550)
                : const Color(0xFFB99550).withValues(alpha: .18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, mode, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          drawer: _buildDrawer(),
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: IslamicBackgroundPainter(
                    dark: AppTheme.isDark,
                  ),
                ),
              ),
              SafeArea(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDashboard,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildHeader(),
                            ),
                            SliverToBoxAdapter(
                              child: _buildBalanceCard(),
                            ),
                            SliverToBoxAdapter(
                              child: _buildQuickActions(),
                            ),
                            SliverToBoxAdapter(
                              child: _buildAccountSection(),
                            ),
                            SliverToBoxAdapter(
                              child: _buildRecentSection(),
                            ),
                            SliverToBoxAdapter(
                              child: _buildToolsSection(),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 28),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          _roundButton(
            icon: Icons.menu_rounded,
            onTap: _openDrawer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'হিসাব ও প্রয়োজনীয় টুল',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'আপনার আয়-ব্যয়ের হিসাব এক নজরে',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _roundButton(
            icon: Icons.refresh_rounded,
            onTap: _loadDashboard,
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFB99550).withValues(alpha: .28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppTheme.isDark ? .18 : .05,
                ),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFFB99550),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final positive = _difference >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF176B45),
            Color(0xFF0F5132),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD8BB78).withValues(alpha: .45),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5132).withValues(alpha: .28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD8BB78).withValues(alpha: .12),
                  width: 18,
                ),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -45,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD8BB78).withValues(alpha: .10),
                  width: 12,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFFD8BB78),
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'অ্যাকাউন্ট ব্যালেন্স',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                _money(_accountBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'সব অ্যাকাউন্টের বর্তমান ব্যালেন্স',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .70),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _balanceMini(
                      icon: Icons.arrow_downward_rounded,
                      title: 'এই মাসের আয়',
                      amount: _income,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _balanceMini(
                      icon: Icons.arrow_upward_rounded,
                      title: 'এই মাসের ব্যয়',
                      amount: _expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      positive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: const Color(0xFFD8BB78),
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      positive
                          ? 'বর্তমান উদ্বৃত্ত'
                          : 'বর্তমান ঘাটি',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _money(_difference.abs()),
                      style: const TextStyle(
                        color: Color(0xFFD8BB78),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceMini({
    required IconData icon,
    required String title,
    required double amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: .10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFD8BB78),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .65),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _money(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Row(
        children: [
          Expanded(
            child: _quickAction(
              icon: Icons.add_circle_outline_rounded,
              title: 'আয়',
              subtitle: 'নতুন আয়',
              color: const Color(0xFF4F9A72),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickAction(
              icon: Icons.remove_circle_outline_rounded,
              title: 'ব্যয়',
              subtitle: 'নতুন ব্যয়',
              color: const Color(0xFFC56B68),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickAction(
              icon: Icons.swap_horiz_rounded,
              title: 'Transfer',
              subtitle: 'অ্যাকাউন্ট',
              color: const Color(0xFFB99550),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openAddTransaction,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: color.withValues(alpha: .25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppTheme.isDark ? .14 : .04,
                ),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: .13),
                  border: Border.all(
                    color: color.withValues(alpha: .28),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            title: 'অ্যাকাউন্ট',
            icon: Icons.account_balance_wallet_rounded,
            onTap: () {
              _openScreen(const AccountsScreen());
            },
          ),
          const SizedBox(height: 10),
          if (_accounts.isEmpty)
            _emptyCard(
              icon: Icons.account_balance_wallet_outlined,
              text: 'কোনো অ্যাকাউন্ট পাওয়া যায়নি',
            )
          else
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _accounts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final account = _accounts[index];

                  final name =
                      (account['name'] ?? 'Account').toString();

                  final balance =
                      _toDouble(account['balance']);

                  return Container(
                    width: 150,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFB99550)
                            .withValues(alpha: .22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 31,
                              height: 31,
                              decoration: BoxDecoration(
                                color: const Color(0xFF176B45)
                                    .withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance_rounded,
                                color: Color(0xFFB99550),
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          _money(balance),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            title: 'সাম্প্রতিক লেনদেন',
            icon: Icons.receipt_long_rounded,
            onTap: () {
              _openScreen(const TransactionsScreen());
            },
          ),
          const SizedBox(height: 10),
          if (_transactions.isEmpty)
            _emptyCard(
              icon: Icons.receipt_long_outlined,
              text: 'এখনও কোনো লেনদেন যোগ করা হয়নি',
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFB99550)
                      .withValues(alpha: .20),
                ),
              ),
              child: Column(
                children: List.generate(
                  _transactions.length,
                  (index) {
                    final item = _transactions[index];

                    final type = _transactionType(item);
                    final color = _transactionColor(type);

                    final id = item['id'];

                    return Column(
                      children: [
                        if (index != 0)
                          Divider(
                            height: 1,
                            indent: 68,
                            endIndent: 16,
                            color: const Color(0xFFB99550)
                                .withValues(alpha: .10),
                          ),
                        Dismissible(
                          key: ValueKey(
                            'home_transaction_${id ?? index}',
                          ),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC56B68)
                                  .withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFC56B68),
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            _showDeleteDialog(item);
                            return false;
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: color.withValues(alpha: .25),
                                ),
                              ),
                              child: Icon(
                                _transactionIcon(type),
                                color: color,
                                size: 21,
                              ),
                            ),
                            title: Text(
                              _transactionTitle(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              _transactionSubtitle(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _transactionAmount(item),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  onSelected: (value) {
                                    final transactionId =
                                        id is int
                                            ? id
                                            : int.tryParse(
                                                id.toString(),
                                              );

                                    if (transactionId == null) {
                                      return;
                                    }

                                    if (value == 'edit') {
                                      _editTransaction(transactionId);
                                    }

                                    if (value == 'delete') {
                                      _showDeleteDialog(item);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_rounded,
                                            size: 19,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            size: 19,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            title: 'অন্যান্য',
            icon: Icons.grid_view_rounded,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: .92,
            children: [
              _toolCard(
                icon: Icons.bar_chart_rounded,
                title: 'পরিসংখ্যান',
                onTap: () {
                  _openScreen(const StatisticsScreen());
                },
              ),
              _toolCard(
                icon: Icons.assessment_rounded,
                title: 'রিপোর্ট',
                onTap: () {
                  _openScreen(const ReportScreen());
                },
              ),
              _toolCard(
                icon: Icons.category_rounded,
                title: 'খাত',
                onTap: () {
                  _openScreen(const CategoriesScreen());
                },
              ),
              _toolCard(
                icon: Icons.receipt_long_rounded,
                title: 'সব লেনদেন',
                onTap: () {
                  _openScreen(const TransactionsScreen());
                },
              ),
              _toolCard(
                icon: Icons.account_balance_rounded,
                title: 'অ্যাকাউন্ট',
                onTap: () {
                  _openScreen(const AccountsScreen());
                },
              ),
              _toolCard(
                icon: Icons.info_outline_rounded,
                title: 'সম্পর্কে',
                onTap: () {
                  _openScreen(const AboutScreen());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xFFB99550),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 26,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB99550).withValues(alpha: .18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: const Color(0xFFB99550).withValues(alpha: .22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppTheme.isDark ? .13 : .035,
                ),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF176B45),
                      Color(0xFF0F5132),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFB99550)
                        .withValues(alpha: .55),
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFD8BB78),
                  size: 23,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
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

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.background,
      width: MediaQuery.of(context).size.width * .82,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                children: [
                  _drawerItem(
                    icon: Icons.home_rounded,
                    title: 'হোম',
                    selected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'লেনদেন',
                    onTap: () {
                      _openScreen(const TransactionsScreen());
                    },
                  ),
                  _drawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'অ্যাকাউন্ট',
                    onTap: () {
                      _openScreen(const AccountsScreen());
                    },
                  ),
                  _drawerItem(
                    icon: Icons.category_rounded,
                    title: 'খাত',
                    onTap: () {
                      _openScreen(const CategoriesScreen());
                    },
                  ),
                  _drawerItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'পরিসংখ্যান',
                    onTap: () {
                      _openScreen(const StatisticsScreen());
                    },
                  ),
                  _drawerItem(
                    icon: Icons.assessment_rounded,
                    title: 'রিপোর্ট',
                    onTap: () {
                      _openScreen(const ReportScreen());
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Divider(),
                  ),
                  _drawerItem(
                    icon: Icons.settings_rounded,
                    title: 'সেটিংস',
                    onTap: _showSettings,
                  ),
                  _drawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'সম্পর্কে',
                    onTap: () {
                      _openScreen(const AboutScreen());
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Text(
                'সহজে হিসাব রাখুন',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF176B45),
            Color(0xFF0F5132),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD8BB78).withValues(alpha: .42),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .09),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD8BB78),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFFD8BB78),
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'হিসাব মেনু',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'হিসাব ও প্রয়োজনীয় টুল',
                  style: TextStyle(
                    color: Color(0xFFD8BB78),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF176B45).withValues(alpha: .14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: selected
            ? Border.all(
                color: const Color(0xFFB99550).withValues(alpha: .20),
              )
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF176B45)
                : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFB99550).withValues(
                alpha: selected ? .42 : .15,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: selected
                ? const Color(0xFFD8BB78)
                : AppTheme.textMuted,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: selected
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
        trailing: selected
            ? const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFB99550),
                size: 18,
              )
            : Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
      ),
    );
  }
}

class IslamicBackgroundPainter extends CustomPainter {
  final bool dark;

  IslamicBackgroundPainter({
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final baseColor = const Color(0xFFB99550).withValues(
      alpha: dark ? .045 : .035,
    );

    paint.color = baseColor;

    final spacing = 54.0;

    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );

      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFFB99550).withValues(
        alpha: dark ? .035 : .025,
      );

    final centers = [
      Offset(size.width * .88, size.height * .18),
      Offset(size.width * .10, size.height * .62),
      Offset(size.width * .72, size.height * .82),
    ];

    for (final center in centers) {
      canvas.drawCircle(center, 42, circlePaint);
      canvas.drawCircle(center, 58, circlePaint);
      canvas.drawCircle(center, 74, circlePaint);
    }

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFB99550).withValues(
        alpha: dark ? .06 : .035,
      );

    for (double y = 30; y < size.height; y += 82) {
      for (double x = 25; x < size.width; x += 82) {
        canvas.drawCircle(
          Offset(x, y),
          1.3,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant IslamicBackgroundPainter oldDelegate) {
    return oldDelegate.dark != dark;
  }
}
