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

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  bool _loading = true;

  double _income = 0;
  double _expense = 0;

  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];

  String get _monthName {
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

    final language = AppSettings.instance.language;

    if (language == 'bn') {
      return '${monthsBn[_selectedMonth.month - 1]} ${_selectedMonth.year}';
    }

    return '${monthsEn[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  DateTime get _startDate {
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
  }

  DateTime get _endDate {
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
      23,
      59,
      59,
      999,
    );
  }

  double get _difference => _income - _expense;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
    });

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });

    _loadReport();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });

    _loadReport();
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(2);
  }

  String _categoryName(Map<String, dynamic> item) {
    return (item['category_name'] ??
            item['name'] ??
            item['categoryName'] ??
            'Unknown')
        .toString();
  }

  double _categoryAmount(Map<String, dynamic> item) {
    final value = item['total'] ?? item['amount'] ?? 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  double _percentage(
    double amount,
    double total,
  ) {
    if (total <= 0) return 0;
    return amount / total;
  }

  Future<void> _showCategoryTransactions(
    Map<String, dynamic> item,
    bool isIncome,
  ) async {
    final categoryId = item['category_id'] ?? item['id'];

    if (categoryId == null) return;

    final transactions =
        await MoneyDb.instance.getTransactions(
      categoryId: categoryId is int
          ? categoryId
          : int.tryParse(categoryId.toString()),
      startDate: _startDate,
      endDate: _endDate,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade500,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _categoryName(item),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _formatMoney(
                        _categoryAmount(item),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isIncome
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Text(
                          AppSettings.instance.t(
                            'noTransactions',
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];

                          final amount =
                              (tx['amount'] as num?)?.toDouble() ??
                                  double.tryParse(
                                    tx['amount']
                                            ?.toString() ??
                                        '0',
                                  ) ??
                                  0;

                          final note =
                              tx['note']?.toString() ?? '';

                          final date =
                              tx['transaction_date']
                                  ?.toString() ??
                              '';

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    (isIncome
                                            ? Colors.green
                                            : Colors.red)
                                        .withValues(alpha: 0.12),
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isIncome
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              title: Text(
                                _formatMoney(amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (date.isNotEmpty) date,
                                  if (note.isNotEmpty) note,
                                ].join(' • '),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportPdf() async {
    try {
      final pdf = pw.Document();

      final isBangla =
          AppSettings.instance.language == 'bn';

      final title = isBangla
          ? 'আমার হিসাব - মাসিক রিপোর্ট'
          : 'Amar Hisab - Monthly Report';

      final monthText = _monthName;

      final incomeTitle =
          isBangla ? 'মোট আয়' : 'Total Income';

      final expenseTitle =
          isBangla ? 'মোট ব্যয়' : 'Total Expense';

      final differenceTitle = _difference >= 0
          ? (isBangla ? 'উদ্বৃত্ত' : 'Surplus')
          : (isBangla ? 'ঘাটতি' : 'Deficit');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) {
            return [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                monthText,
                style: const pw.TextStyle(
                  fontSize: 14,
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                ),
                children: [
                  pw.TableRow(
                    children: [
                      _pdfCell(
                        incomeTitle,
                        bold: true,
                      ),
                      _pdfCell(
                        expenseTitle,
                        bold: true,
                      ),
                      _pdfCell(
                        differenceTitle,
                        bold: true,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell(
                        _formatMoney(_income),
                      ),
                      _pdfCell(
                        _formatMoney(_expense),
                      ),
                      _pdfCell(
                        _formatMoney(
                          _difference.abs(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 25),

              pw.Text(
                isBangla
                    ? 'আয়ের খাত'
                    : 'Income Categories',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 8),

              if (_incomeCategories.isEmpty)
                pw.Text(
                  isBangla
                      ? 'কোনো তথ্য নেই'
                      : 'No data',
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                  ),
                  children: [
                    pw.TableRow(
                      children: [
                        _pdfCell(
                          isBangla ? 'খাত' : 'Category',
                          bold: true,
                        ),
                        _pdfCell(
                          isBangla ? 'পরিমাণ' : 'Amount',
                          bold: true,
                        ),
                      ],
                    ),
                    ..._incomeCategories.map(
                      (item) {
                        return pw.TableRow(
                          children: [
                            _pdfCell(
                              _categoryName(item),
                            ),
                            _pdfCell(
                              _formatMoney(
                                _categoryAmount(item),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

              pw.SizedBox(height: 25),

              pw.Text(
                isBangla
                    ? 'ব্যয়ের খাত'
                    : 'Expense Categories',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 8),

              if (_expenseCategories.isEmpty)
                pw.Text(
                  isBangla
                      ? 'কোনো তথ্য নেই'
                      : 'No data',
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                  ),
                  children: [
                    pw.TableRow(
                      children: [
                        _pdfCell(
                          isBangla ? 'খাত' : 'Category',
                          bold: true,
                        ),
                        _pdfCell(
                          isBangla ? 'পরিমাণ' : 'Amount',
                          bold: true,
                        ),
                      ],
                    ),
                    ..._expenseCategories.map(
                      (item) {
                        return pw.TableRow(
                          children: [
                            _pdfCell(
                              _categoryName(item),
                            ),
                            _pdfCell(
                              _formatMoney(
                                _categoryAmount(item),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

              pw.SizedBox(height: 30),

              pw.Divider(),

              pw.SizedBox(height: 8),

              pw.Text(
                isBangla
                    ? 'আমার হিসাব'
                    : 'Amar Hisab',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ];
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'amar_hisab_${_selectedMonth.year}_${_selectedMonth.month}.pdf',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppSettings.instance.t(
              'reportSaved',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF Error: $e',
          ),
        ),
      );
    }
  }

  pw.Widget _pdfCell(
    String text, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight:
              bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _exportJpg() async {
    try {
      final Uint8List? image =
          await _screenshotController.capture(
        pixelRatio: 2.5,
      );

      if (image == null) {
        throw Exception('Could not create image');
      }

      final directory =
          await getApplicationDocumentsDirectory();

      final file = File(
        '${directory.path}/'
        'amar_hisab_${_selectedMonth.year}_'
        '${_selectedMonth.month}.jpg',
      );

      await file.writeAsBytes(image);

      await SharePlus.instance.share(
        [
          XFile(
            file.path,
            mimeType: 'image/jpeg',
          ),
        ],
        text: AppSettings.instance.language == 'bn'
            ? 'আমার হিসাব - মাসিক রিপোর্ট'
            : 'Amar Hisab - Monthly Report',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppSettings.instance.t(
              'reportSaved',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'JPG Error: $e',
          ),
        ),
      );
    }
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMoney(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySection({
    required String title,
    required List<Map<String, dynamic>> categories,
    required double total,
    required bool isIncome,
  }) {
    final color =
        isIncome ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
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

          const SizedBox(height: 14),

          if (categories.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppSettings.instance.t(
                  'noData',
                ),
              ),
            )
          else
            ...categories.map(
              (item) {
                final amount =
                    _categoryAmount(item);

                final percentage =
                    _percentage(
                  amount,
                  total,
                );

                return InkWell(
                  borderRadius:
                      BorderRadius.circular(12),
                  onTap: () {
                    _showCategoryTransactions(
                      item,
                      isIncome,
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 9,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _categoryName(item),
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _formatMoney(amount),
                              style: TextStyle(
                                color: color,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(percentage * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 7),

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10),
                          child:
                              LinearProgressIndicator(
                            value: percentage,
                            minHeight: 7,
                            backgroundColor:
                                color.withValues(alpha: 0.10),
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
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final differenceColor =
        _difference >= 0
            ? Colors.green
            : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppSettings.instance.t(
            'report',
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'PDF',
            icon: const Icon(
              Icons.picture_as_pdf,
            ),
            onPressed:
                _loading ? null : _exportPdf,
          ),
          IconButton(
            tooltip: 'JPG',
            icon: const Icon(
              Icons.image_outlined,
            ),
            onPressed:
                _loading ? null : _exportJpg,
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: Screenshot(
                controller:
                    _screenshotController,
                child: Container(
                  color: Theme.of(context)
                      .scaffoldBackgroundColor,
                  child: ListView(
                    padding:
                        const EdgeInsets.all(16),
                    children: [
                      // Month selector
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context)
                                  .cardColor,
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed:
                                  _previousMonth,
                              icon: const Icon(
                                Icons
                                    .chevron_left,
                              ),
                            ),

                            Expanded(
                              child: Center(
                                child: Text(
                                  _monthName,
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed:
                                  _nextMonth,
                              icon: const Icon(
                                Icons
                                    .chevron_right,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Summary
                      Row(
                        children: [
                          _summaryCard(
                            title:
                                AppSettings.instance
                                    .t('incomeTotal'),
                            amount: _income,
                            icon: Icons
                                .arrow_downward,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 10),
                          _summaryCard(
                            title:
                                AppSettings.instance
                                    .t('expenseTotal'),
                            amount: _expense,
                            icon: Icons
                                .arrow_upward,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 10),
                          _summaryCard(
                            title:
                                _difference >= 0
                                    ? AppSettings
                                        .instance
                                        .t(
                                        'surplus',
                                      )
                                    : AppSettings
                                        .instance
                                        .t(
                                        'deficit',
                                      ),
                            amount:
                                _difference.abs(),
                            icon: _difference >= 0
                                ? Icons
                                    .trending_up
                                : Icons
                                    .trending_down,
                            color:
                                differenceColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _categorySection(
                        title: AppSettings
                            .instance
                            .t(
                          'incomeCategories',
                        ),
                        categories:
                            _incomeCategories,
                        total: _income,
                        isIncome: true,
                      ),

                      _categorySection(
                        title: AppSettings
                            .instance
                            .t(
                          'expenseCategories',
                        ),
                        categories:
                            _expenseCategories,
                        total: _expense,
                        isIncome: false,
                      ),

                      const SizedBox(height: 15),

                      Center(
                        child: Text(
                          AppSettings.instance
                              .language ==
                              'bn'
                              ? 'আমার হিসাব'
                              : 'Amar Hisab',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(
                                  alpha: 0.6,
                                ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
