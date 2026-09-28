import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';

enum ReportPeriod {
  day,
  week,
  month,
  year,
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedDate = DateTime.now();

  ReportPeriod _period = ReportPeriod.month;

  DateTime _startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  DateTime _endDate = DateTime.now();

  List<Map<String, dynamic>> _transactions = [];

  Map<String, double> _periodTotals = {
    'income': 0.0,
    'expense': 0.0,
    'difference': 0.0,
  };

  Map<String, double> _incomeByCategory = {};
  Map<String, double> _expenseByCategory = {};

  bool _loading = true;
  bool _exporting = false;

  final ScreenshotController _screenshotController =
      ScreenshotController();

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _updatePeriodDates();
    _loadReportData();
  }

  // ------------------------------------------------------------
  // DATE / PERIOD
  // ------------------------------------------------------------

  void _updatePeriodDates() {
    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    switch (_period) {
      case ReportPeriod.day:
        _startDate = DateTime(
          date.year,
          date.month,
          date.day,
        );

        _endDate = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
        );
        break;

      case ReportPeriod.week:
        final monday =
            date.subtract(Duration(days: date.weekday - 1));

        final sunday =
            monday.add(const Duration(days: 6));

        _startDate = DateTime(
          monday.year,
          monday.month,
          monday.day,
        );

        _endDate = DateTime(
          sunday.year,
          sunday.month,
          sunday.day,
          23,
          59,
          59,
        );
        break;

      case ReportPeriod.month:
        _startDate = DateTime(
          date.year,
          date.month,
          1,
        );

        _endDate = DateTime(
          date.year,
          date.month + 1,
          0,
          23,
          59,
          59,
        );
        break;

      case ReportPeriod.year:
        _startDate = DateTime(
          date.year,
          1,
          1,
        );

        _endDate = DateTime(
          date.year,
          12,
          31,
          23,
          59,
          59,
        );
        break;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _updatePeriodDates();
    });

    await _loadReportData();
  }

  Future<void> _changePeriod(
    ReportPeriod period,
  ) async {
    setState(() {
      _period = period;
      _updatePeriodDates();
    });

    await _loadReportData();
  }

  // ------------------------------------------------------------
  // LOAD REPORT
  // ------------------------------------------------------------

  Future<void> _loadReportData() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final transactions =
          await MoneyDb.instance.getTransactions(
        startDate: _startDate,
        endDate: _endDate,
      );

      final totals =
          await MoneyDb.instance.getPeriodTotals(
        startDate: _startDate,
        endDate: _endDate,
      );

      final income =
          await MoneyDb.instance.getIncomeByCategory(
        startDate: _startDate,
        endDate: _endDate,
      );

      final expense =
          await MoneyDb.instance.getExpenseByCategory(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _periodTotals = totals;
        _incomeByCategory = _convertCategoryMap(income);
        _expenseByCategory = _convertCategoryMap(expense);
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

  Map<String, double> _convertCategoryMap(
    dynamic data,
  ) {
    final result = <String, double>{};

    if (data is Map) {
      data.forEach((key, value) {
        result[key.toString()] =
            (value as num?)?.toDouble() ?? 0;
      });
    }

    return result;
  }

  // ------------------------------------------------------------
  // FORMATTING
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatAmount(dynamic value) {
    final amount =
        (value as num?)?.toDouble() ?? 0;

    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
  }

  String _periodTitle() {
    switch (_period) {
      case ReportPeriod.day:
        return settings.isBangla
            ? 'দৈনিক রিপোর্ট'
            : 'Daily Report';

      case ReportPeriod.week:
        return settings.isBangla
            ? 'সাপ্তাহিক রিপোর্ট'
            : 'Weekly Report';

      case ReportPeriod.month:
        return settings.isBangla
            ? 'মাসিক রিপোর্ট'
            : 'Monthly Report';

      case ReportPeriod.year:
        return settings.isBangla
            ? 'বার্ষিক রিপোর্ট'
            : 'Yearly Report';
    }
  }

  String _periodDateText() {
    if (_period == ReportPeriod.day) {
      return _formatDate(_startDate);
    }

    return '${_formatDate(_startDate)} - '
        '${_formatDate(_endDate)}';
  }

  String _differenceLabel() {
    final difference =
        _periodTotals['difference'] ?? 0;

    if (difference > 0) {
      return settings.isBangla
          ? 'উদ্বৃত্ত'
          : 'Surplus';
    }

    if (difference < 0) {
      return settings.isBangla
          ? 'ঘাটতি'
          : 'Deficit';
    }

    return settings.isBangla
        ? 'সমান'
        : 'Balanced';
  }

  Color _differenceColor() {
    final difference =
        _periodTotals['difference'] ?? 0;

    if (difference > 0) {
      return Colors.green.shade600;
    }

    if (difference < 0) {
      return Colors.red.shade600;
    }

    return AppTheme.gold;
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

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
  // PERIOD SELECTOR
  // ------------------------------------------------------------

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _periodButton(
                ReportPeriod.day,
                settings.isBangla
                    ? 'দিন'
                    : 'Day',
                Icons.today_outlined,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _periodButton(
                ReportPeriod.week,
                settings.isBangla
                    ? 'সপ্তাহ'
                    : 'Week',
                Icons.view_week_outlined,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _periodButton(
                ReportPeriod.month,
                settings.isBangla
                    ? 'মাস'
                    : 'Month',
                Icons.calendar_month_outlined,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _periodButton(
                ReportPeriod.year,
                settings.isBangla
                    ? 'বছর'
                    : 'Year',
                Icons.date_range_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodButton(
    ReportPeriod period,
    String label,
    IconData icon,
  ) {
    final selected = _period == period;

    return InkWell(
      onTap: () => _changePeriod(period),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.green
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? Colors.white
                  : AppTheme.gold,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.white
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE CARD
  // ------------------------------------------------------------

  Widget _buildDateCard() {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      AppTheme.gold.withValues(alpha: 0.14),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_rounded,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _periodDateText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
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
  // TOTAL SUMMARY
  // ------------------------------------------------------------

  Widget _buildSummary() {
    final income =
        _periodTotals['income'] ?? 0;

    final expense =
        _periodTotals['expense'] ?? 0;

    final difference =
        _periodTotals['difference'] ?? 0;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          settings.isBangla
              ? 'সারসংক্ষেপ'
              : 'Summary',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: settings.isBangla
                    ? 'মোট আয়'
                    : 'Total Income',
                amount: income,
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
                amount: expense,
                icon: Icons.arrow_upward_rounded,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _differenceColor()
                .withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _differenceColor()
                  .withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _differenceColor()
                      .withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  difference >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: _differenceColor(),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _differenceLabel(),
                      style: TextStyle(
                        fontSize: 13,
                        color: _differenceColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatAmount(difference.abs()),
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: _differenceColor(),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                difference >= 0
                    ? Icons.account_balance_wallet_outlined
                    : Icons.warning_amber_rounded,
                color: _differenceColor(),
                size: 28,
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatAmount(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CATEGORY REPORT
  // ------------------------------------------------------------

  Widget _buildCategorySection({
    required String title,
    required Map<String, double> categories,
    required Color color,
    required IconData icon,
  }) {
    final entries = categories.entries
        .where((entry) => entry.value > 0)
        .toList();

    entries.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = entries.fold<double>(
      0,
      (sum, item) => sum + item.value,
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(12),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (int i = 0;
                    i < entries.length;
                    i++) ...[
                  _buildCategoryRow(
                    name: entries[i].key,
                    amount: entries[i].value,
                    total: total,
                    color: color,
                  ),
                  if (i != entries.length - 1)
                    const Divider(height: 20),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow({
    required String name,
    required double amount,
    required double total,
    required Color color,
  }) {
    final percentage =
        total == 0 ? 0.0 : amount / total;

    return Column(
      children: [
        Row(
          children: [
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
            const SizedBox(width: 10),
            Text(
              _formatAmount(amount),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 7,
                  backgroundColor:
                      color.withValues(alpha: 0.10),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 42,
              child: Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TRANSACTIONS
  // ------------------------------------------------------------

  Widget _buildTransactions() {
    if (_transactions.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              settings.isBangla
                  ? 'এই সময়ের কোনো লেনদেন নেই'
                  : 'No transactions in this period',
              textAlign: TextAlign.center,
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

    return Card(
      elevation: 0,
      child: Column(
        children: [
          for (int i = 0;
              i < _transactions.length;
              i++)
            _buildTransactionItem(
              _transactions[i],
              i,
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    Map<String, dynamic> tx,
    int index,
  ) {
    final type =
        tx['type']?.toString() ?? '';

    final isIncome = type == 'income';
    final isTransfer = type == 'transfer';

    final color = isTransfer
        ? AppTheme.gold
        : isIncome
            ? Colors.green.shade600
            : Colors.red.shade600;

    final category =
        tx['category_name']?.toString();

    final note =
        tx['note']?.toString() ?? '';

    final account =
        tx['account_name']?.toString() ?? '';

    String title;

    if (isTransfer) {
      final from =
          tx['from_account_name']?.toString() ?? '';

      final to =
          tx['to_account_name']?.toString() ?? '';

      if (from.isNotEmpty && to.isNotEmpty) {
        title = '$from → $to';
      } else {
        title = settings.isBangla
            ? 'ট্রান্সফার'
            : 'Transfer';
      }
    } else if (category != null &&
        category.isNotEmpty) {
      title = category;
    } else {
      title = isIncome
          ? settings.t('income')
          : settings.t('expense');
    }

    final subtitleParts = <String>[];

    if (account.isNotEmpty) {
      subtitleParts.add(account);
    }

    if (note.isNotEmpty) {
      subtitleParts.add(note);
    }

    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 3,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : isTransfer
                      ? Icons.swap_horiz_rounded
                      : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: subtitleParts.isEmpty
              ? null
              : Text(
                  subtitleParts.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: Text(
            '${isIncome ? '+ ' : isTransfer ? '' : '- '}${_formatAmount(tx['amount'])}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        if (index != _transactions.length - 1)
          const Divider(
            height: 1,
            indent: 68,
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // EXPORT - JPG
  // ------------------------------------------------------------

  Future<void> _saveJpg() async {
    if (_exporting) return;

    setState(() {
      _exporting = true;
    });

    try {
      final Uint8List? image =
          await _screenshotController.capture(
        pixelRatio: 2.5,
      );

      if (image == null) {
        throw Exception(
          settings.isBangla
              ? 'JPG তৈরি করা যায়নি'
              : 'Could not create JPG',
        );
      }

      final directory =
          await getApplicationDocumentsDirectory();

      final fileName =
          'amar_hisab_report_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final file = File(
        '${directory.path}/$fileName',
      );

      await file.writeAsBytes(image);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text: settings.isBangla
              ? 'আমার হিসাব - রিপোর্ট'
              : 'Amar Hisab - Report',
        ),
      );

      _showMessage(
        settings.isBangla
            ? 'JPG রিপোর্ট তৈরি হয়েছে'
            : 'JPG report created',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // EXPORT - PDF
  // ------------------------------------------------------------

  Future<void> _savePdf() async {
    if (_exporting) return;

    setState(() {
      _exporting = true;
    });

    try {
      final pdf = pw.Document();

      final income =
          _periodTotals['income'] ?? 0;

      final expense =
          _periodTotals['expense'] ?? 0;

      final difference =
          _periodTotals['difference'] ?? 0;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) {
            return [
              pw.Text(
                'Amar Hisab',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                _periodTitleEnglish(),
                style: pw.TextStyle(
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
              ),
              pw.SizedBox(height: 20),

              pw.Container(
                padding:
                    const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                  ),
                  borderRadius:
                      pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _pdfSummaryRow(
                      'Total Income',
                      _formatAmount(income),
                    ),
                    _pdfSummaryRow(
                      'Total Expense',
                      _formatAmount(expense),
                    ),
                    _pdfSummaryRow(
                      difference >= 0
                          ? 'Surplus'
                          : 'Deficit',
                      _formatAmount(
                        difference.abs(),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 22),

              pw.Text(
                'Income by Category',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              ..._pdfCategoryRows(
                _incomeByCategory,
              ),

              pw.SizedBox(height: 18),

              pw.Text(
                'Expense by Category',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              ..._pdfCategoryRows(
                _expenseByCategory,
              ),

              pw.SizedBox(height: 22),

              pw.Text(
                'Transactions',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              ..._transactions.map(
                (tx) => pw.Padding(
                  padding:
                      const pw.EdgeInsets.only(
                    bottom: 5,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          _pdfTransactionTitle(tx),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        _formatAmount(
                          tx['amount'],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();

      final directory =
          await getApplicationDocumentsDirectory();

      final fileName =
          'amar_hisab_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(
        '${directory.path}/$fileName',
      );

      await file.writeAsBytes(bytes);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text: settings.isBangla
              ? 'আমার হিসাব - PDF রিপোর্ট'
              : 'Amar Hisab - PDF Report',
        ),
      );

      _showMessage(
        settings.isBangla
            ? 'PDF রিপোর্ট তৈরি হয়েছে'
            : 'PDF report created',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  String _periodTitleEnglish() {
    switch (_period) {
      case ReportPeriod.day:
        return 'Daily Report';
      case ReportPeriod.week:
        return 'Weekly Report';
      case ReportPeriod.month:
        return 'Monthly Report';
      case ReportPeriod.year:
        return 'Yearly Report';
    }
  }

  pw.Widget _pdfSummaryRow(
    String title,
    String value,
  ) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight:
                  pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _pdfCategoryRows(
    Map<String, double> categories,
  ) {
    final entries = categories.entries.toList();

    entries.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    if (entries.isEmpty) {
      return [
        pw.Text('No data'),
      ];
    }

    return entries.map(
      (entry) {
        return pw.Padding(
          padding:
              const pw.EdgeInsets.only(
            bottom: 5,
          ),
          child: pw.Row(
            mainAxisAlignment:
                pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(entry.key),
              ),
              pw.Text(
                _formatAmount(entry.value),
              ),
            ],
          ),
        );
      },
    ).toList();
  }

  String _pdfTransactionTitle(
    Map<String, dynamic> tx,
  ) {
    final type =
        tx['type']?.toString() ?? '';

    if (type == 'transfer') {
      final from =
          tx['from_account_name']?.toString() ?? '';

      final to =
          tx['to_account_name']?.toString() ?? '';

      if (from.isNotEmpty && to.isNotEmpty) {
        return '$from -> $to';
      }

      return 'Transfer';
    }

    final category =
        tx['category_name']?.toString() ?? '';

    if (category.isNotEmpty) {
      return category;
    }

    return type == 'income'
        ? 'Income'
        : 'Expense';
  }

  // ------------------------------------------------------------
  // EXPORT BUTTONS
  // ------------------------------------------------------------

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                _exporting ? null : _saveJpg,
            icon: const Icon(
              Icons.image_outlined,
            ),
            label: Text(
              settings.isBangla
                  ? 'JPG সেভ'
                  : 'Save JPG',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _exporting ? null : _savePdf,
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
            ),
            label: Text(
              settings.isBangla
                  ? 'PDF সেভ'
                  : 'Save PDF',
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BUILD REPORT
  // ------------------------------------------------------------

  Widget _buildReportContent() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildDateCard(),

          const SizedBox(height: 10),

          _buildPeriodSelector(),

          const SizedBox(height: 20),

          _buildSummary(),

          const SizedBox(height: 24),

          _buildCategorySection(
            title: settings.isBangla
                ? 'খাতভিত্তিক আয়'
                : 'Income by Category',
            categories: _incomeByCategory,
            color: Colors.green.shade600,
            icon: Icons.arrow_downward_rounded,
          ),

          if (_incomeByCategory.isNotEmpty)
            const SizedBox(height: 24),

          _buildCategorySection(
            title: settings.isBangla
                ? 'খাতভিত্তিক ব্যয়'
                : 'Expense by Category',
            categories: _expenseByCategory,
            color: Colors.red.shade600,
            icon: Icons.arrow_upward_rounded,
          ),

          if (_expenseByCategory.isNotEmpty)
            const SizedBox(height: 24),

          Text(
            settings.isBangla
                ? 'লেনদেনের তালিকা'
                : 'Transactions',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _buildTransactions(),

          const SizedBox(height: 24),

          _buildExportButtons(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

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
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  20,
                ),
                child: Screenshot(
                  controller:
                      _screenshotController,
                  child: _buildReportContent(),
                ),
              ),
            ),
    );
  }
}
