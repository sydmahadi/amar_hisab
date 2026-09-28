import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppSettings settings = AppSettings.instance;

  bool _loading = true;

  double _balance = 0;
  double _income = 0;
  double _expense = 0;

  List<Map<String, dynamic>> _accounts = [];

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
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final balance = await MoneyDb.instance.getTotalBalance();
      final income = await MoneyDb.instance.getTotalIncome();
      final expense = await MoneyDb.instance.getTotalExpense();
      final accounts = await MoneyDb.instance.getAccounts();

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
    }
  }

  String _money(double value) {
    return value.toStringAsFixed(2);
  }

  IconData _accountIcon(String? type) {
    switch (type) {
      case 'cash':
        return Icons.account_balance_wallet_rounded;

      case 'bkash':
        return Icons.phone_android_rounded;

      case 'nagad':
        return Icons.phone_android_rounded;

      case 'bank':
        return Icons.account_balance_rounded;

      case 'card':
        return Icons.credit_card_rounded;

      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color _accountColor(int? colorValue) {
    if (colorValue == null) {
      return AppTheme.gold;
    }

    return Color(colorValue);
  }

  Future<void> _openLanguageSelector() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  settings.t('language'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 16),

                _languageOption(
                  context,
                  languageCode: 'bn',
                  title: 'বাংলা',
                ),

                const SizedBox(height: 8),

                _languageOption(
                  context,
                  languageCode: 'en',
                  title: 'English',
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await settings.setLanguage(selected);
    }
  }

  Widget _languageOption(
    BuildContext context, {
    required String languageCode,
    required String title,
  }) {
    final selected = settings.language == languageCode;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pop(context, languageCode);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.gold
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? AppTheme.gold
                  : Theme.of(context).iconTheme.color,
            ),

            const SizedBox(width: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          settings.isBangla
              ? '$title খুব শিগগিরই যুক্ত করা হবে।'
              : '$title will be available soon.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ==================================================
              // HEADER
              // ==================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                              style: TextStyle(
                                color: AppTheme.gold,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              settings.t('appName'),
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.gold,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              settings.t('appTagline'),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      // Language
                      IconButton(
                        tooltip: settings.t('language'),
                        onPressed: _openLanguageSelector,
                        icon: const Icon(
                          Icons.language_rounded,
                        ),
                      ),

                      // Theme
                      IconButton(
                        tooltip: settings.t('theme'),
                        onPressed: () async {
                          await settings.toggleTheme();
                        },
                        icon: Icon(
                          settings.darkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // BALANCE CARD
              // ==================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    8,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.darkGreen,
                          AppTheme.green,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.darkGreen.withOpacity(
                            0.25,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.t('totalBalance'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        _loading
                            ? const SizedBox(
                                height: 38,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _money(_balance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),

              // ==================================================
              // INCOME / EXPENSE
              // ==================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.arrow_downward_rounded,
                          title: settings.t('incomeTotal'),
                          amount: _income,
                          iconColor: Colors.green,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _summaryCard(
                          icon: Icons.arrow_upward_rounded,
                          title: settings.t('expenseTotal'),
                          amount: _expense,
                          iconColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // QUICK ACTIONS
              // ==================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    8,
                  ),
                  child: Text(
                    settings.t('moneyManager'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  4,
                  18,
                  10,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate(
                    [
                      _menuCard(
                        icon: Icons.add_circle_outline_rounded,
                        title: settings.t('addTransaction'),
                        onTap: () {
                          _showComingSoon(
                            settings.t('addTransaction'),
                          );
                        },
                      ),

                      _menuCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: settings.t('accounts'),
                        onTap: () {
                          _showComingSoon(
                            settings.t('accounts'),
                          );
                        },
                      ),

                      _menuCard(
                        icon: Icons.category_outlined,
                        title: settings.t('categories'),
                        onTap: () {
                          _showComingSoon(
                            settings.t('categories'),
                          );
                        },
                      ),

                      _menuCard(
                        icon: Icons.bar_chart_rounded,
                        title: settings.t('statistics'),
                        onTap: () {
                          _showComingSoon(
                            settings.t('statistics'),
                          );
                        },
                      ),

                      _menuCard(
                        icon: Icons.receipt_long_outlined,
                        title: settings.t('transactions'),
                        onTap: () {
                          _showComingSoon(
                            settings.t('transactions'),
                          );
                        },
                      ),

                      _menuCard(
                        icon: Icons.picture_as_pdf_outlined,
                        title: settings.t('report'),
                        onTap: () {
                          _showComingSoon(
                            settings.t('report'),
                          );
                        },
                      ),
                    ],
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                ),
              ),

              // ==================================================
              // ACCOUNTS
              // ==================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          settings.t('accounts'),
                          style:
                              theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          _showComingSoon(
                            settings.t('accounts'),
                          );
                        },
                        child: Text(
                          settings.isBangla
                              ? 'সব দেখুন'
                              : 'View all',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_accounts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      settings.t('noData'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    4,
                    18,
                    24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final account = _accounts[index];

                        final name =
                            account['name']?.toString() ?? '';

                        final type =
                            account['type']?.toString();

                        final balance =
                            (account['balance'] as num?)
                                    ?.toDouble() ??
                                0;

                        final colorValue =
                            account['color'] as int?;

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius:
                                BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  theme.dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _accountColor(
                                    colorValue,
                                  ).withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _accountIcon(type),
                                  color: _accountColor(
                                    colorValue,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 13),

                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),

                              Text(
                                _money(balance),
                                style: TextStyle(
                                  color: balance >= 0
                                      ? AppTheme.gold
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: _accounts.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required double amount,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: 5),

          Text(
            _money(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.gold,
                  size: 25,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
