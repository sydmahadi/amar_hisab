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
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _periodTotals = {
    'income': 0.0,
    'expense': 0.0,
    'difference': 0.0,
  };
  bool _loading = true;

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final txs = await MoneyDb.instance.getTransactions(
        startDate: _startDate,
        endDate: _endDate,
      );

      final totals = await MoneyDb.instance.getPeriodTotals(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      setState(() {
        _transactions = txs;
        _periodTotals = totals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadReportData();
    }
  }

  Future<void> _exportAndShareReport() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('=== Amar Hisab Report ===');
      buffer.writeln('Date Range: ${_formatDate(_startDate)} to ${_formatDate(_endDate)}');
      buffer.writeln('Total Income: ${_periodTotals['income']}');
      buffer.writeln('Total Expense: ${_periodTotals['expense']}');
      buffer.writeln('Net Difference: ${_periodTotals['difference']}');
      buffer.writeln('\n--- Transactions ---');

      for (final tx in _transactions) {
        buffer.writeln(
          '${tx['transaction_date']} | ${tx['type']} | Amount: ${tx['amount']} | Note: ${tx['note'] ?? ''}',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/amar_hisab_report.txt');
      await file.writeAsString(buffer.toString());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Amar Hisab Report (${_formatDate(_startDate)} - ${_formatDate(_endDate)})',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing report: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _colorFromValue(dynamic value) {
    if (value is int) return Color(value);
    if (value is num) return Color(value.toInt());
    return AppTheme.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(settings.isBangla ? 'রিপোর্ট' : 'Report'),
        actions: [
          IconButton(
            onPressed: _exportAndShareReport,
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.date_range, color: AppTheme.gold),
                    title: Text(
                      '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _selectDateRange,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(settings.t('totalIncome')),
                          Text(
                            '${_periodTotals['income']}',
                            style: const TextStyle(
                              color: AppTheme.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(settings.t('totalExpense')),
                          Text(
                            '${_periodTotals['expense']}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Balance',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_periodTotals['difference']}',
                            style: TextStyle(
                              color: (_periodTotals['difference'] ?? 0) >= 0
                                  ? AppTheme.green
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  settings.isBangla ? 'লেনদেনের তালিকা' : 'Transactions List',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._transactions.map((tx) {
                  final color = _colorFromValue(tx['color']);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.2),
                        child: Icon(Icons.receipt, color: color),
                      ),
                      title: Text(tx['note'] ?? tx['type'] ?? ''),
                      subtitle: Text(tx['transaction_date'] ?? ''),
                      trailing: Text(
                        '${tx['amount']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tx['type'] == 'income'
                              ? AppTheme.green
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
