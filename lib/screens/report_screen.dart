import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  DateTime _endDate = DateTime.now();

  String _period = 'monthly';

  List<Map<String, dynamic>> _transactions = [];

  double _income = 0;
  double _expense = 0;

  bool _loading = true;

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  // ------------------------------------------------------------
  // DATE / PERIOD
  // ------------------------------------------------------------

  void _setPeriod(String period) {
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    switch (period) {
      case 'weekly':
        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        final daysFromMonday = today.weekday - 1;

        start = today.subtract(
          Duration(days: daysFromMonday),
        );

        end = start.add(
          const Duration(
            days: 6,
            hours: 23,
            minutes: 59,
            seconds: 59,
            milliseconds: 999,
          ),
        );
        break;

      case 'yearly':
        start = DateTime(
          now.year,
          1,
          1,
        );

        end = DateTime(
          now.year,
          12,
          31,
          23,
          59,
          59,
          999,
        );
        break;

      case 'custom':
        return;

      case 'monthly':
      default:
        start = DateTime(
          now.year,
          now.month,
          1,
        );

        end = DateTime(
          now.year,
          now.month + 1,
          0,
          23,
          59,
          59,
          999,
        );
        break;
    }

    setState(() {
      _period = period;
      _startDate = start;
      _endDate = end;
    });

    _loadReportData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked == null) return;

    setState(() {
      _period = 'custom';
      _startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );

      _endDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
        999,
      );
    });

    await _loadReportData();
  }

  // ------------------------------------------------------------
  // LOAD DATA
  // ------------------------------------------------------------

  Future<void> _loadReportData() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final transactions = await MoneyDb.instance.getTransactions(
        startDate: _startDate,
        endDate: _endDate,
      );

      double income = 0;
      double expense = 0;

      for (final tx in transactions) {
        final amount =
            (tx['amount'] as num?)?.toDouble() ?? 0;

        final type = tx['type']?.toString();

        if (type == 'income') {
          income += amount;
        } else if (type == 'expense') {
          expense += amount;
        }
      }

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _income = income;
        _expense = expense;
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

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  double get _difference => _income - _expense;

  bool get _isSurplus => _difference >= 0;

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _periodTitle() {
    switch (_period) {
      case 'weekly':
        return settings.isBangla
            ? 'এই সপ্তাহ'
            : 'This Week';

      case 'yearly':
        return settings.isBangla
            ? 'এই বছর'
            : 'This Year';

      case 'custom':
        return settings.isBangla
            ? 'নির্বাচিত সময়'
            : 'Custom Period';

      case 'monthly':
      default:
        return settings.isBangla
            ? 'এই মাস'
            : 'This Month';
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

  // ------------------------------------------------------------
  // CATEGORY TOTALS
  // ------------------------------------------------------------

  Map<String, double> _categoryTotals(
    String type,
  ) {
    final Map<String, double> result = {};

    for (final tx in _transactions) {
      if (tx['type']?.toString() != type) {
        continue;
      }

      final category =
          tx['category_name']?.toString().trim();

      final name = category == null || category.isEmpty
          ? (settings.isBangla
              ? 'অন্যান্য'
              : 'Other')
          : category;

      final amount =
          (tx['amount'] as num?)?.toDouble() ?? 0;

      result[name] = (result[name] ?? 0) + amount;
    }

    return result;
  }

  // ------------------------------------------------------------
  // PERIOD SELECTOR
  // ------------------------------------------------------------

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _periodChip(
            value: 'weekly',
            title: settings.isBangla
                ? 'সাপ্তাহিক'
                : 'Weekly',
          ),
          const SizedBox(width: 8),
          _periodChip(
            value: 'monthly',
            title: settings.isBangla
                ? 'মাসিক'
                : 'Monthly',
          ),
          const SizedBox(width: 8),
          _periodChip(
            value: 'yearly',
            title: settings.isBangla
                ? 'বার্ষিক'
                : 'Yearly',
          ),
          const SizedBox(width: 8),
          _periodChip(
            value: 'custom',
            title: settings.isBangla
                ? 'তারিখ নির্বাচন'
                : 'Custom',
          ),
        ],
      ),
    );
  }

  Widget _periodChip({
    required String value,
    required String title,
  }) {
    final selected = _period == value;

    return ChoiceChip(
      label: Text(title),
      selected: selected,
      onSelected: (_) {
        if (value == 'custom') {
          _selectDateRange();
        } else {
          _setPeriod(value);
        }
      },
      selectedColor: AppTheme.green,
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color,
        fontWeight:
            selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE CARD
  // ------------------------------------------------------------

  Widget _buildDateCard() {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _selectDateRange,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _periodTitle(),
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
                      '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.edit_calendar_rounded,
                color: AppTheme.gold,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY
  // ------------------------------------------------------------

  Widget _buildSummary() {
    final differenceColor = _isSurplus
        ? Colors.green.shade600
        : Colors.red.shade600;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: settings.isBangla
                    ? 'মোট আয়'
                    : 'Total Income',
                value: _income,
                icon: Icons.arrow_downward_rounded,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                title: settings.isBangla
                    ? 'মোট ব্যয়'
                    : 'Total Expense',
                value: _expense,
                icon: Icons.arrow_upward_rounded,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: differenceColor.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSurplus
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: differenceColor,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSurplus
                            ? (settings.isBangla
                                ? 'উদ্বৃত্ত'
                                : 'Surplus')
                            : (settings.isBangla
                                ? 'ঘাটতি'
                                : 'Deficit'),
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: differenceColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
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
                color: color.withValues(alpha: 0.12),
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
              overflow: TextOverflow.ellipsis,
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
              _formatNumber(value),
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

  // ------------------------------------------------------------
  // CATEGORY REPORT
  // ------------------------------------------------------------

  Widget _buildCategoryReport() {
    final incomeCategories =
        _categoryTotals('income');

    final expenseCategories =
        _categoryTotals('expense');

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          settings.isBangla
              ? 'খাতভিত্তিক হিসাব'
              : 'Category-wise Report',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        _categorySection(
          title: settings.isBangla
              ? 'আয়'
              : 'Income',
          categories: incomeCategories,
          total: _income,
          color: Colors.green.shade600,
          icon: Icons.arrow_downward_rounded,
        ),

        const SizedBox(height: 14),

        _categorySection(
          title: settings.isBangla
              ? 'ব্যয়'
              : 'Expense',
          categories: expenseCategories,
          total: _expense,
          color: Colors.red.shade600,
          icon: Icons.arrow_upward_rounded,
        ),
      ],
    );
  }

  Widget _categorySection({
    required String title,
    required Map<String, double> categories,
    required double total,
    required Color color,
    required IconData icon,
  }) {
    if (categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
              ),
              const SizedBox(width: 10),
              Text(
                settings.isBangla
                    ? '$title-এর কোনো তথ্য নেই'
                    : 'No $title data',
              ),
            ],
          ),
        ),
      );
    }

    final entries = categories.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(
              entries.length,
              (index) {
                final entry = entries[index];

                final percentage = total > 0
                    ? entry.value / total
                    : 0.0;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _formatNumber(
                              entry.value,
                            ),
                            style: TextStyle(
                              color: color,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${(percentage * 100).toStringAsFixed(1)}%',
                              textAlign:
                                  TextAlign.end,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                )
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                        child:
                            LinearProgressIndicator(
                          value: percentage,
                          minHeight: 6,
                          backgroundColor:
                              color.withValues(
                            alpha: 0.10,
                          ),
                          valueColor:
                              AlwaysStoppedAnimation<
                                  Color>(
                            color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TRANSACTIONS
  // ------------------------------------------------------------

  Widget _buildTransactions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          settings.isBangla
              ? 'লেনদেনের তালিকা'
              : 'Transactions',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (_transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Center(
                child: Text(
                  settings.t('noTransactions'),
                ),
              ),
            ),
          )
        else
          ..._transactions.map(
            (tx) => _transactionTile(tx),
          ),
      ],
    );
  }

  Widget _transactionTile(
    Map<String, dynamic> tx,
  ) {
    final type = tx['type']?.toString() ?? '';

    final amount =
        (tx['amount'] as num?)?.toDouble() ?? 0;

    final isIncome = type == 'income';

    final color = isIncome
        ? Colors.green.shade600
        : Colors.red.shade600;

    final category =
        tx['category_name']?.toString() ?? '';

    final note =
        tx['note']?.toString() ?? '';

    final date =
        tx['transaction_date']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 2,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: color,
          ),
        ),
        title: Text(
          category.isEmpty
              ? (isIncome
                  ? settings.t('income')
                  : settings.t('expense'))
              : category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          note.isEmpty
              ? date.split('T').first
              : note,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${isIncome ? '+ ' : '- '}${_formatNumber(amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SHARE
  // ------------------------------------------------------------

  Future<void> _shareReport() async {
    try {
      final incomeCategories =
          _categoryTotals('income');

      final expenseCategories =
          _categoryTotals('expense');

      final buffer = StringBuffer();

      buffer.writeln(
        settings.isBangla
            ? 'আমার হিসাব - রিপোর্ট'
            : 'Amar Hisab - Report',
      );

      buffer.writeln(
        '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
      );

      buffer.writeln();

      buffer.writeln(
        '${settings.isBangla ? 'মোট আয়' : 'Total Income'}: ${_formatNumber(_income)}',
      );

      buffer.writeln(
        '${settings.isBangla ? 'মোট ব্যয়' : 'Total Expense'}: ${_formatNumber(_expense)}',
      );

      buffer.writeln(
        '${_isSurplus ? (settings.isBangla ? 'উদ্বৃত্ত' : 'Surplus') : (settings.isBangla ? 'ঘাটতি' : 'Deficit')}: ${_formatNumber(_difference.abs())}',
      );

      buffer.writeln();

      buffer.writeln(
        settings.isBangla
            ? '--- আয় খাতভিত্তিক ---'
            : '--- Income by Category ---',
      );

      incomeCategories.forEach(
        (key, value) {
          buffer.writeln(
            '$key: ${_formatNumber(value)}',
          );
        },
      );

      buffer.writeln();

      buffer.writeln(
        settings.isBangla
            ? '--- ব্যয় খাতভিত্তিক ---'
            : '--- Expense by Category ---',
      );

      expenseCategories.forEach(
        (key, value) {
          buffer.writeln(
            '$key: ${_formatNumber(value)}',
          );
        },
      );

      final tempDir =
          await getTemporaryDirectory();

      final file = File(
        '${tempDir.path}/amar_hisab_report.txt',
      );

      await file.writeAsString(
        buffer.toString(),
      );

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text: settings.isBangla
              ? 'আমার হিসাব রিপোর্ট'
              : 'Amar Hisab Report',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString(),
        isError: true,
      );
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          settings.isBangla
              ? 'রিপোর্ট'
              : 'Report',
        ),
        actions: [
          IconButton(
            tooltip: settings.isBangla
                ? 'শেয়ার'
                : 'Share',
            onPressed: _shareReport,
            icon: const Icon(
              Icons.share_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReportData,
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  100,
                ),
                children: [
                  _buildPeriodSelector(),

                  const SizedBox(height: 14),

                  _buildDateCard(),

                  const SizedBox(height: 16),

                  _buildSummary(),

                  const SizedBox(height: 24),

                  _buildCategoryReport(),

                  const SizedBox(height: 24),

                  _buildTransactions(),
                ],
              ),
      ),
    );
  }
}
