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

      final expenseCategories = await MoneyDb.instance.getExpenseByCategory(
        startDate: _startDate,
        endDate: _endDate,
      );

      final incomeCategories = await MoneyDb.instance.getIncomeByCategory(
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
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _changePeriod(String period) async {
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
    int index,
  ) {
    final value = item['color'];

    if (value is int) {
      return Color(value);
    }

    if (value is num) {
      return Color(value.toInt());
    }

    final colors = [
      AppTheme.green,
      AppTheme.gold,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
      Colors.cyan,
    ];

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
      height: 44,
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

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _changePeriod(value),
      selectedColor: AppTheme.green,
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: settings.t('expenseTotal'),
                amount: _expense,
                icon: Icons.arrow_upward_rounded,
                color: Colors.red.shade600,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
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
    final color = _isSurplus ? Colors.green.shade600 : Colors.red.shade600;

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
                      color: Theme.of(context).textTheme.bodySmall?.color,
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
              style: TextStyle(
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

  Widget _buildPieChart() {
    final categories = _expenseCategories;

    if (categories.isEmpty) {
      return _emptyChart(
        settings.isBangla
            ? 'এই সময়ে কোনো ব্যয়ের তথ্য নেই'
            : 'No expense data for this period',
      );
    }

    final sections = <PieChartSectionData>[];

    for (int i = 0; i < categories.length; i++) {
      final item = categories[i];

      final total = (item['total'] as num?)?.toDouble() ?? 0;

      if (total <= 0) continue;

      final percentage = _expense == 0 ? 0 : (total / _expense) * 100;

      sections.add(
        PieChartSectionData(
          value: total,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
          color: _categoryColor(item, i),
          radius: 75,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 48,
          sectionsSpace: 2,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    List<Map<String, dynamic>> categories,
  ) {
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

          final name = item['name']?.toString() ?? '';

          final total = (item['total'] as num?)?.toDouble() ?? 0;

          final percentage =
              categories.isEmpty ? 0.0 : (_expense > 0 ? total / _expense : 0.0);

          final color = _categoryColor(item, index);

          return Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                _showCategoryDetails(
                  item,
                  isIncome: false,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                            child: LinearProgressIndicator(
                              value: percentage.clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: color.withValues(
                                alpha: 0.10,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatNumber(total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color,
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

  Widget _buildIncomeList() {
    if (_incomeCategories.isEmpty) {
      return _emptyChart(
        settings.isBangla
            ? 'এই সময়ে কোনো আয়ের তথ্য নেই'
            : 'No income data for this period',
      );
    }

    return Column(
      children: List.generate(
        _incomeCategories.length,
        (index) {
          final item = _incomeCategories[index];

          final name = item['name']?.toString() ?? '';

          final total = (item['total'] as num?)?.toDouble() ?? 0;

          final percentage = _income > 0 ? total / _income : 0.0;

          final color = _categoryColor(item, index);

          return Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage.clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 5,
                            backgroundColor: color.withValues(
                              alpha: 0.10,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatNumber(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyChart(String message) {
    return Container(
      height: 190,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 45,
            color: AppTheme.gold.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
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

    final transactions = await MoneyDb.instance.getTransactions(
      categoryId: categoryId as int,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.70,
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
                          (category['total'] as num?)?.toDouble() ?? 0,
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
                          itemBuilder: (context, index) {
                            final item = transactions[index];

                            final amount =
                                (item['amount'] as num?)?.toDouble() ?? 0;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    (isIncome ? Colors.green : Colors.red)
                                        .withValues(
                                  alpha: 0.10,
                                ),
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color:
                                      isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                item['account_name']?.toString() ?? '',
                              ),
                              subtitle: Text(
                                item['note']?.toString().isNotEmpty == true
                                    ? item['note'].toString()
                                    : item['transaction_date']
                                        .toString()
                                        .split('T')
                                        .first,
                              ),
                              trailing: Text(
                                _formatNumber(amount),
                                style: TextStyle(
                                  color:
                                      isIncome ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
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
        title: Text(settings.t('statistics')),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                  const SizedBox(height: 24),
                  Text(
                    settings.isBangla
                        ? 'ব্যয়ের বিশ্লেষণ'
                        : 'Expense Analysis',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          _buildPieChart(),
                          if (_expenseCategories.isNotEmpty) ...[
                            const Divider(),
                            const SizedBox(height: 10),
                            _buildCategoryList(
                              _expenseCategories,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    settings.isBangla
                        ? 'আয়ের বিশ্লেষণ'
                        : 'Income Analysis',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildIncomeList(),
                ],
              ),
            ),
    );
  }
}
