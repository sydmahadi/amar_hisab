import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedMonth = DateTime.now();

  double _income = 0;
  double _expense = 0;

  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];

  bool _loading = true;

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  DateTime get _startDate => DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
      );

  DateTime get _endDate => DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
        23,
        59,
        59,
        999,
      );

  Future<void> _loadReport() async {
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

      final incomeCategories =
          await MoneyDb.instance.getIncomeByCategory(
        startDate: _startDate,
        endDate: _endDate,
      );

      final expenseCategories =
          await MoneyDb.instance.getExpenseByCategory(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      setState(() {
        _income = income;
        _expense = expense;
        _incomeCategories = incomeCategories;
        _expenseCategories = expenseCategories;
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

  Future<void> _changeMonth(int amount) async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + amount,
        1,
      );
    });

    await _loadReport();
  }

  String _monthName(int month) {
    if (settings.isBangla) {
      const months = [
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

      return months[month - 1];
    }

    const months = [
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

    return months[month - 1];
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  double get _difference => _income - _expense;

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

  Future<void> _showCategoryTransactions(
    Map<String, dynamic> category,
  ) async {
    final id = category['id'];

    if (id == null) return;

    final transactions =
        await MoneyDb.instance.getTransactions(
      categoryId: id as int,
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
                          (category['total'] as num?)
                                  ?.toDouble() ??
                              0,
                        ),
                        style: TextStyle(
                          color:
                              category['type'] == 'income'
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
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
                            final transaction =
                                transactions[index];

                            final type =
                                transaction['type']
                                    ?.toString();

                            final amount =
                                (transaction['amount'] as num?)
                                        ?.toDouble() ??
                                    0;

                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    (type == 'income'
                                            ? Colors.green
                                            : Colors.red)
                                        .withOpacity(0.10),
                                child: Icon(
                                  type == 'income'
                                      ? Icons
                                          .arrow_downward_rounded
                                      : Icons
                                          .arrow_upward_rounded,
                                  color: type == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              title: Text(
                                transaction['account_name']
                                        ?.toString() ??
                                    '',
                              ),
                              subtitle: Text(
                                transaction['note']
                                            ?.toString()
                                            .isNotEmpty ==
                                        true
                                    ? transaction['note']
                                        .toString()
                                    : transaction[
                                            'transaction_date']
                                        .toString()
                                        .split('T')
                                        .first,
                              ),
                              trailing: Text(
                                _formatNumber(amount),
                                style: TextStyle(
                                  color: type == 'income'
                                      ? Colors.green
                                      : Colors.red,
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

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(
              Icons.chevron_left_rounded,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  settings.t('monthlyReport'),
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
                  '${_monthName(_selectedMonth.month)} '
                  '${_selectedMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final isSurplus = _difference >= 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                settings.t('incomeTotal'),
                _income,
                Icons.arrow_downward_rounded,
                Colors.green.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                settings.t('expenseTotal'),
                _expense,
                Icons.arrow_upward_rounded,
                Colors.red.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isSurplus
                            ? Colors.green
                            : Colors.red)
                        .withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSurplus
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isSurplus
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSurplus
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
                        _formatNumber(_difference.abs()),
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: isSurplus
                              ? Colors.green.shade600
                              : Colors.red.shade600,
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

  Widget _summaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(height: 10),
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

  Widget _buildCategorySection({
    required String title,
    required List<Map<String, dynamic>> categories,
    required bool income,
  }) {
    if (categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: Text(
              settings.t('noData'),
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(
          categories.length,
          (index) {
            final item = categories[index];

            final name =
                item['name']?.toString() ?? '';

            final total =
                (item['total'] as num?)?.toDouble() ?? 0;

            final totalBase =
                income ? _income : _expense;

            final percentage = totalBase > 0
                ? total / totalBase
                : 0.0;

            final color =
                _categoryColor(item, index);

            return Card(
              margin: const EdgeInsets.only(
                bottom: 9,
              ),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(16),
                onTap: () {
                  _showCategoryTransactions(item);
                },
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color:
                              color.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                          income
                              ? Icons
                                  .arrow_downward_rounded
                              : Icons
                                  .arrow_upward_rounded,
                          color: color,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                              child:
                                  LinearProgressIndicator(
                                value:
                                    percentage.clamp(
                                  0.0,
                                  1.0,
                                ),
                                minHeight: 5,
                                backgroundColor:
                                    color.withOpacity(
                                  0.10,
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
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatNumber(total),
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${(percentage * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(settings.t('report')),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReport,
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
                  _buildMonthSelector(),

                  const SizedBox(height: 18),

                  _buildSummary(),

                  const SizedBox(height: 24),

                  _buildCategorySection(
                    title: settings.t('incomeReport'),
                    categories: _incomeCategories,
                    income: true,
                  ),

                  const SizedBox(height: 16),

                  _buildCategorySection(
                    title: settings.t('expenseReport'),
                    categories: _expenseCategories,
                    income: false,
                  ),
                ],
              ),
            ),
    );
  }
}
