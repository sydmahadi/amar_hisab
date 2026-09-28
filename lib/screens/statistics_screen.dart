import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _period = 'monthly';

  DateTime? _startDate;
  DateTime? _endDate;

  double _income = 0;
  double _expense = 0;

  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];

  bool _loading = true;

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _setPeriodDates();
    _loadStatistics();
  }

  void _setPeriodDates() {
    final now = DateTime.now();

    if (_period == 'daily') {
      _startDate = DateTime(
        now.year,
        now.month,
        now.day,
      );

      _endDate = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
      );
    } else if (_period == 'weekly') {
      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final daysFromMonday = today.weekday - 1;

      _startDate = today.subtract(
        Duration(days: daysFromMonday),
      );

      _endDate = _startDate!.add(
        const Duration(
          days: 6,
          hours: 23,
          minutes: 59,
          seconds: 59,
          milliseconds: 999,
        ),
      );
    } else if (_period == 'yearly') {
      _startDate = DateTime(
        now.year,
        1,
        1,
      );

      _endDate = DateTime(
        now.year,
        12,
        31,
        23,
        59,
        59,
        999,
      );
    } else {
      _startDate = DateTime(
        now.year,
        now.month,
        1,
      );

      _endDate = DateTime(
        now.year,
        now.month + 1,
        0,
        23,
        59,
        59,
        999,
      );
    }
  }

  Future<void> _loadStatistics() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final income = await MoneyDb.instance.getTotalIncome(
        startDate: _startDate,
        endDate: _endDate,
      );

      final expense = await MoneyDb.instance.getTotalExpense(
        startDate: _startDate,
        endDate: _endDate,
      );

      final expenseCategories =
          await MoneyDb.instance.getExpenseByCategory(
        startDate: _startDate,
        endDate: _endDate,
      );

      final incomeCategories =
          await MoneyDb.instance.getIncomeByCategory(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      setState(() {
        _income = income;
        _expense = expense;
        _expenseCategories = expenseCategories;
        _incomeCategories = incomeCategories;
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

  Future<void> _changePeriod(String period) async {
    if (_period == period) return;

    setState(() {
      _period = period;
    });

    _setPeriodDates();

    await _loadStatistics();
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _periodLabel() {
    switch (_period) {
      case 'daily':
        return settings.t('today');

      case 'weekly':
        return settings.t('thisWeek');

      case 'yearly':
        return settings.t('thisYear');

      default:
        return settings.t('thisMonth');
    }
  }

  double get _difference => _income - _expense;

  bool get _isSurplus => _difference >= 0;

  Color _categoryColor(
    Map<String, dynamic> item,
    int index, {
    required bool isIncome,
  }) {
    final value = item['color'];

    if (value is int) {
      return Color(value);
    }

    if (value is num) {
      return Color(value.toInt());
    }

    final incomeColors = [
      const Color(0xFF176B45),
      const Color(0xFF2E8B68),
      const Color(0xFF3FA77A),
      const Color(0xFF5BB98D),
      const Color(0xFF74C69D),
      const Color(0xFF40916C),
      AppTheme.gold,
      const Color(0xFFB88A32),
    ];

    final expenseColors = [
      const Color(0xFFC0392B),
      const Color(0xFFE05A47),
      const Color(0xFFE67E22),
      const Color(0xFF8E44AD),
      const Color(0xFF2980B9),
      const Color(0xFF16A085),
      const Color(0xFFD35400),
      const Color(0xFF7F8C8D),
    ];

    final colors = isIncome ? incomeColors : expenseColors;

    return colors[index % colors.length];
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
              isError ? Colors.red.shade700 : AppTheme.green,
        ),
      );
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _periodButton(
            value: 'daily',
            label: settings.t('daily'),
          ),
          const SizedBox(width: 8),
          _periodButton(
            value: 'weekly',
            label: settings.t('weekly'),
          ),
          const SizedBox(width: 8),
          _periodButton(
            value: 'monthly',
            label: settings.t('monthly'),
          ),
          const SizedBox(width: 8),
          _periodButton(
            value: 'yearly',
            label: settings.t('yearly'),
          ),
        ],
      ),
    );
  }

  Widget _periodButton({
    required String value,
    required String label,
  }) {
    final selected = _period == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _changePeriod(value),
        selectedColor: AppTheme.green,
        backgroundColor: Theme.of(context).cardColor,
        side: BorderSide(
          color: selected
              ? AppTheme.green
              : Theme.of(context).dividerColor,
        ),
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight:
              selected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: settings.t('incomeTotal'),
                amount: _income,
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFF2E9D68),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: settings.t('expenseTotal'),
                amount: _expense,
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFD9534F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _differenceCard(),
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
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatNumber(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _differenceCard() {
    final color =
        _isSurplus ? const Color(0xFF2E9D68) : const Color(0xFFD9534F);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSurplus
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSurplus
                        ? settings.t('surplus')
                        : settings.t('deficit'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatNumber(
                      _difference.abs(),
                    ),
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _periodLabel(),
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> categories,
    required double total,
    required bool isIncome,
  }) {
    if (categories.isEmpty || total <= 0) {
      return _emptyChart(
        isIncome
            ? (settings.isBangla
                ? 'এই সময়ে কোনো আয়ের তথ্য নেই'
                : 'No income data for this period')
            : (settings.isBangla
                ? 'এই সময়ে কোনো ব্যয়ের তথ্য নেই'
                : 'No expense data for this period'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          14,
          16,
          14,
          16,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isIncome
                            ? Colors.green
                            : Colors.red)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color:
                        isIncome ? Colors.green : Colors.red,
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _animatedPieChart(
              categories: categories,
              total: total,
              isIncome: isIncome,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 10),
            _buildLegend(
              categories,
              total,
              isIncome,
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedPieChart({
    required List<Map<String, dynamic>> categories,
    required double total,
    required bool isIncome,
  }) {
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < categories.length; i++) {
      final item = categories[i];

      final value =
          (item['total'] as num?)?.toDouble() ?? 0;

      if (value <= 0) continue;

      final percentage =
          total > 0 ? (value / total) * 100 : 0;

      final color = _categoryColor(
        item,
        i,
        isIncome: isIncome,
      );

      sections.add(
        PieChartSectionData(
          value: value,
          color: color,
          radius: 78,
          showTitle: percentage >= 4,
          title: percentage >= 4
              ? '${percentage.toStringAsFixed(0)}%'
              : '',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          badgeWidget: null,
        ),
      );
    }

    return SizedBox(
      height: 275,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 62,
              sectionsSpace: 3,
              borderData: FlBorderData(
                show: false,
              ),
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (
                  FlTouchEvent event,
                  PieTouchResponse? response,
                ) {
                  if (!event.isInterestedForInteractions ||
                      response?.touchedSection == null) {
                    return;
                  }

                  final index = response!
                      .touchedSection!
                      .touchedSectionIndex;

                  if (index >= 0 &&
                      index < categories.length) {
                    _showCategoryDetails(
                      categories[index],
                      isIncome: isIncome,
                    );
                  }
                },
              ),
            ),
            swapAnimationDuration:
                const Duration(milliseconds: 650),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isIncome
                      ? (settings.isBangla
                          ? 'মোট আয়'
                          : 'Total Income')
                      : (settings.isBangla
                          ? 'মোট ব্যয়'
                          : 'Total Expense'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedSwitcher(
                  duration:
                      const Duration(milliseconds: 400),
                  child: Text(
                    _formatNumber(total),
                    key: ValueKey(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
    List<Map<String, dynamic>> categories,
    double total,
    bool isIncome,
  ) {
    return Column(
      children: List.generate(
        categories.length,
        (index) {
          final item = categories[index];

          final name =
              item['name']?.toString() ?? '';

          final value =
              (item['total'] as num?)?.toDouble() ?? 0;

          if (value <= 0) {
            return const SizedBox.shrink();
          }

          final percentage =
              total > 0 ? (value / total) * 100 : 0;

          final color = _categoryColor(
            item,
            index,
            isIncome: isIncome,
          );

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _showCategoryDetails(
                item,
                isIncome: isIncome,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 4,
              ),
              child: Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatNumber(value),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryProgressList(
    List<Map<String, dynamic>> categories,
    double total, {
    required bool isIncome,
  }) {
    if (categories.isEmpty) {
      return _emptyChart(
        settings.t('noData'),
      );
    }

    return Column(
      children: List.generate(
        categories.length,
        (index) {
          final item = categories[index];

          final name =
              item['name']?.toString() ?? '';

          final value =
              (item['total'] as num?)?.toDouble() ?? 0;

          final percentage =
              total > 0 ? value / total : 0.0;

          final color = _categoryColor(
            item,
            index,
            isIncome: isIncome,
          );

          return Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                _showCategoryDetails(
                  item,
                  isIncome: isIncome,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
                            child:
                                TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: percentage.clamp(
                                  0.0,
                                  1.0,
                                ),
                              ),
                              duration: const Duration(
                                milliseconds: 700,
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (
                                context,
                                value,
                                child,
                              ) {
                                return LinearProgressIndicator(
                                  value: value,
                                  minHeight: 5,
                                  backgroundColor:
                                      color.withValues(
                                    alpha: 0.10,
                                  ),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    color,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatNumber(value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyChart(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pie_chart_outline_rounded,
              size: 30,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
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

  Future<void> _showCategoryDetails(
    Map<String, dynamic> category, {
    required bool isIncome,
  }) async {
    final categoryId = category['id'];

    if (categoryId == null) return;

    final transactions =
        await MoneyDb.instance.getTransactions(
      categoryId: categoryId as int,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height:
                MediaQuery.of(sheetContext).size.height * 0.70,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        _formatNumber(
                          (category['total'] as num?)
                                  ?.toDouble() ??
                              0,
                        ),
                        style: TextStyle(
                          color: isIncome
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: transactions.isEmpty
                      ? Center(
                          child: Text(
                            settings.t('noTransactions'),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: transactions.length,
                          itemBuilder: (
                            context,
                            index,
                          ) {
                            final item =
                                transactions[index];

                            final amount =
                                (item['amount'] as num?)
                                        ?.toDouble() ??
                                    0;

                            final color = isIncome
                                ? Colors.green
                                : Colors.red;

                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    color.withValues(
                                  alpha: 0.10,
                                ),
                                child: Icon(
                                  isIncome
                                      ? Icons
                                          .arrow_downward_rounded
                                      : Icons
                                          .arrow_upward_rounded,
                                  color: color,
                                ),
                              ),
                              title: Text(
                                item['account_name']
                                        ?.toString() ??
                                    '',
                              ),
                              subtitle: Text(
                                item['note']
                                            ?.toString()
                                            .isNotEmpty ==
                                        true
                                    ? item['note'].toString()
                                    : item['transaction_date']
                                        .toString()
                                        .split('T')
                                        .first,
                              ),
                              trailing: Text(
                                _formatNumber(amount),
                                style: TextStyle(
                                  color: color,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          settings.t('statistics'),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  100,
                ),
                children: [
                  _buildPeriodSelector(),

                  const SizedBox(height: 18),

                  _buildSummaryCards(),

                  const SizedBox(height: 26),

                  _buildPieChartCard(
                    title: settings.isBangla
                        ? 'ব্যয়ের বিশ্লেষণ'
                        : 'Expense Analysis',
                    subtitle: settings.isBangla
                        ? 'কোন খাতে কত ব্যয় হয়েছে'
                        : 'Where your money was spent',
                    categories: _expenseCategories,
                    total: _expense,
                    isIncome: false,
                  ),

                  const SizedBox(height: 22),

                  _buildPieChartCard(
                    title: settings.isBangla
                        ? 'আয়ের বিশ্লেষণ'
                        : 'Income Analysis',
                    subtitle: settings.isBangla
                        ? 'কোন খাত থেকে কত আয় হয়েছে'
                        : 'Where your money came from',
                    categories: _incomeCategories,
                    total: _income,
                    isIncome: true,
                  ),

                  const SizedBox(height: 22),

                  Text(
                    settings.isBangla
                        ? 'ব্যয়ের বিস্তারিত'
                        : 'Expense Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildCategoryProgressList(
                    _expenseCategories,
                    _expense,
                    isIncome: false,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    settings.isBangla
                        ? 'আয়ের বিস্তারিত'
                        : 'Income Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildCategoryProgressList(
                    _incomeCategories,
                    _income,
                    isIncome: true,
                  ),
                ],
              ),
            ),
    );
  }
}
