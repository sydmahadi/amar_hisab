import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

import '../services/money_db.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ScreenshotController _screenshotController =
      ScreenshotController();

  String _period = 'monthly';

  DateTime _startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  DateTime _endDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
    23,
    59,
    59,
    999,
  );

  bool _loading = true;
  bool _saving = false;

  double _income = 0;
  double _expense = 0;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];

  List<Map<String, dynamic>> _loans = [];
  List<Map<String, dynamic>> _loanPeriodTransactions = [];

  static const Color _green = Color(0xFF176B45);
  static const Color _gold = Color(0xFFC9A45C);

  static const Color _incomeColor = Color(0xFF287A55);
  static const Color _expenseColor = Color(0xFFC35E5E);

  static const Color _loanGiveColor = Color(0xFF1976D2);
  static const Color _loanTakeColor = Color(0xFF9C27B0);
  static const Color _loanReceiveColor = Color(0xFF2E7D32);
  static const Color _loanPaidColor = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

  Future<void> _loadReport() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        MoneyDb.instance.getTotalIncome(
          startDate: _startDate,
          endDate: _endDate,
        ),
        MoneyDb.instance.getTotalExpense(
          startDate: _startDate,
          endDate: _endDate,
        ),
        MoneyDb.instance.getTransactions(
          startDate: _startDate,
          endDate: _endDate,
        ),
        MoneyDb.instance.getIncomeByCategory(
          startDate: _startDate,
          endDate: _endDate,
        ),
        MoneyDb.instance.getExpenseByCategory(
          startDate: _startDate,
          endDate: _endDate,
        ),
        MoneyDb.instance.getLoans(),
      ]);

      final transactions =
          List<Map<String, dynamic>>.from(
        results[2] as List,
      );

      final loans =
          List<Map<String, dynamic>>.from(
        results[5] as List,
      );

      final loanTransactions = transactions.where((tx) {
        final type = tx['type']?.toString() ?? '';

        return type == 'loan_given' ||
            type == 'loan_taken' ||
            type == 'loan_received' ||
            type == 'loan_paid';
      }).toList();

      if (!mounted) return;

      setState(() {
        _income = (results[0] as num).toDouble();
        _expense = (results[1] as num).toDouble();

        _transactions = transactions;

        _incomeCategories =
            List<Map<String, dynamic>>.from(
          results[3] as List,
        );

        _expenseCategories =
            List<Map<String, dynamic>>.from(
          results[4] as List,
        );

        _loans = loans;
        _loanPeriodTransactions = loanTransactions;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'রিপোর্ট লোড করা যায়নি: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // PERIOD
  // ============================================================

  void _changePeriod(String period) {
    final now = DateTime.now();

    late DateTime start;
    late DateTime end;

    switch (period) {
      case 'weekly':
        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        start = today.subtract(
          Duration(days: today.weekday - 1),
        );

        end = DateTime(
          start.year,
          start.month,
          start.day + 6,
          23,
          59,
          59,
          999,
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
    }

    setState(() {
      _period = period;
      _startDate = start;
      _endDate = end;
    });

    _loadReport();
  }

  Future<void> _pickCustomDate() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      helpText: 'রিপোর্টের সময় নির্বাচন করুন',
      saveText: 'নির্বাচন',
    );

    if (range == null || !mounted) return;

    setState(() {
      _period = 'custom';

      _startDate = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );

      _endDate = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
        999,
      );
    });

    _loadReport();
  }

  // ============================================================
  // BASIC HELPERS
  // ============================================================

  double get _difference => _income - _expense;

  bool get _isSurplus => _difference >= 0;

  String get _periodTitle {
    switch (_period) {
      case 'weekly':
        return 'সাপ্তাহিক রিপোর্ট';

      case 'yearly':
        return 'বার্ষিক রিপোর্ট';

      case 'custom':
        return 'নির্বাচিত সময়ের রিপোর্ট';

      default:
        return 'মাসিক রিপোর্ট';
    }
  }

  String _money(double value) {
    return '৳ ${value.toStringAsFixed(2)}';
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
          value?.toString() ?? '',
        ) ??
        DateTime.now();
  }

  String _transactionType(String type) {
    switch (type) {
      case 'income':
        return 'আয়';

      case 'expense':
        return 'ব্যয়';

      case 'transfer':
        return 'ট্রান্সফার';

      case 'loan_given':
        return 'ধার দিয়েছি';

      case 'loan_taken':
        return 'ধার নিয়েছি';

      case 'loan_received':
        return 'ধার ফেরত পেয়েছি';

      case 'loan_paid':
        return 'ধার শোধ করেছি';

      default:
        return type;
    }
  }

  Color _transactionColor(String type) {
    switch (type) {
      case 'income':
        return _incomeColor;

      case 'expense':
        return _expenseColor;

      case 'loan_given':
        return _loanGiveColor;

      case 'loan_taken':
        return _loanTakeColor;

      case 'loan_received':
        return _loanReceiveColor;

      case 'loan_paid':
        return _loanPaidColor;

      default:
        return _gold;
    }
  }

  IconData _transactionIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.arrow_downward;

      case 'expense':
        return Icons.arrow_upward;

      case 'loan_given':
        return Icons.call_made;

      case 'loan_taken':
        return Icons.call_received;

      case 'loan_received':
        return Icons.assignment_return;

      case 'loan_paid':
        return Icons.payments;

      default:
        return Icons.swap_horiz;
    }
  }

  String _loanPerson(Map<String, dynamic> tx) {
    return tx['loan_person_name']?.toString() ?? '';
  }

  // ============================================================
  // LOAN TOTALS
  // ============================================================

  double _sumLoanTransactions(String type) {
    return _loanPeriodTransactions
        .where(
          (tx) => tx['type']?.toString() == type,
        )
        .fold<double>(
          0,
          (sum, tx) =>
              sum +
              ((tx['amount'] as num?)?.toDouble() ?? 0),
        );
  }

  double get _loanGivenPeriod {
    return _sumLoanTransactions('loan_given');
  }

  double get _loanTakenPeriod {
    return _sumLoanTransactions('loan_taken');
  }

  double get _loanReceivedPeriod {
    return _sumLoanTransactions('loan_received');
  }

  double get _loanPaidPeriod {
    return _sumLoanTransactions('loan_paid');
  }

  double get _totalReceivable {
    return _loans
        .where(
          (loan) =>
              loan['type']?.toString() == 'receivable',
        )
        .fold<double>(
          0,
          (sum, loan) =>
              sum +
              ((loan['remaining'] as num?)?.toDouble() ?? 0),
        );
  }

  double get _totalPayable {
    return _loans
        .where(
          (loan) =>
              loan['type']?.toString() == 'payable',
        )
        .fold<double>(
          0,
          (sum, loan) =>
              sum +
              ((loan['remaining'] as num?)?.toDouble() ?? 0),
        );
  }

  // ============================================================
  // LOAN PERSON SUMMARY
  // ============================================================

  List<Map<String, dynamic>> get _loanPersonSummary {
    final Map<String, Map<String, dynamic>> data = {};

    for (final tx in _loanPeriodTransactions) {
      final rawPerson = _loanPerson(tx).trim();

      final person =
          rawPerson.isEmpty
              ? 'নাম উল্লেখ নেই'
              : rawPerson;

      final item = data.putIfAbsent(
        person,
        () => {
          'person': person,
          'given': 0.0,
          'taken': 0.0,
          'received': 0.0,
          'paid': 0.0,
          'receivable': 0.0,
          'payable': 0.0,
        },
      );

      final amount =
          ((tx['amount'] as num?)?.toDouble() ?? 0);

      switch (tx['type']?.toString()) {
        case 'loan_given':
          item['given'] =
              (item['given'] as double) + amount;
          break;

        case 'loan_taken':
          item['taken'] =
              (item['taken'] as double) + amount;
          break;

        case 'loan_received':
          item['received'] =
              (item['received'] as double) + amount;
          break;

        case 'loan_paid':
          item['paid'] =
              (item['paid'] as double) + amount;
          break;
      }
    }

    for (final loan in _loans) {
      final person =
          loan['person_name']?.toString().trim() ?? '';

      if (person.isEmpty) continue;

      final item = data.putIfAbsent(
        person,
        () => {
          'person': person,
          'given': 0.0,
          'taken': 0.0,
          'received': 0.0,
          'paid': 0.0,
          'receivable': 0.0,
          'payable': 0.0,
        },
      );

      final remaining =
          ((loan['remaining'] as num?)?.toDouble() ?? 0);

      if (loan['type']?.toString() == 'receivable') {
        item['receivable'] =
            (item['receivable'] as double) + remaining;
      } else {
        item['payable'] =
            (item['payable'] as double) + remaining;
      }
    }

    final list = data.values.toList();

    list.sort((a, b) {
      final aTotal =
          (a['receivable'] as double) +
              (a['payable'] as double) +
              (a['given'] as double) +
              (a['taken'] as double);

      final bTotal =
          (b['receivable'] as double) +
              (b['payable'] as double) +
              (b['given'] as double) +
              (b['taken'] as double);

      return bTotal.compareTo(aTotal);
    });

    return list;
  }

  // ============================================================
  // FULL LONG IMAGE CAPTURE
  // ============================================================

  Future<Uint8List> _captureReport() async {
    return _screenshotController.captureFromLongWidget(
      InheritedTheme.captureAll(
        context,
        Material(
          color: Colors.white,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _buildVoucher(
              exportMode: true,
            ),
          ),
        ),
      ),
      delay: const Duration(
        milliseconds: 500,
      ),
      context: context,
      pixelRatio: 2,
      constraints: const BoxConstraints(
        maxWidth: 850,
      ),
    );
  }

  // ============================================================
  // JPG
  // ============================================================

  Future<void> _saveJpg() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final pngBytes = await _captureReport();

      final decoded = img.decodeImage(pngBytes);

      if (decoded == null) {
        throw Exception(
          'রিপোর্টের ছবি তৈরি করা যায়নি।',
        );
      }

      final jpgBytes = Uint8List.fromList(
        img.encodeJpg(
          decoded,
          quality: 95,
        ),
      );

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/amar_hisab_report_'
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(
        jpgBytes,
        flush: true,
      );

      final result = await GallerySaver.saveImage(
        file.path,
        albumName: 'আমার হিসাব',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == true
                ? 'সম্পূর্ণ JPG রিপোর্ট Gallery-তে সংরক্ষণ হয়েছে।'
                : 'JPG সংরক্ষণ করা যায়নি।',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'JPG সংরক্ষণ করা যায়নি: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // PDF FONT
  // ============================================================

  Future<pw.Font> _loadPdfFont() async {
    try {
      final data = await rootBundle.load(
        'assets/fonts/NotoSansBengali-Regular.ttf',
      );

      return pw.Font.ttf(data);
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  // ============================================================
  // PDF
  // ============================================================

  Future<void> _savePdf() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final font = await _loadPdfFont();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.ltr,
          build: (context) {
            return _buildPdfOverview(font);
          },
          footer: (context) {
            return _pdfFooter(
              font,
              context.pageNumber,
              context.pagesCount,
            );
          },
        ),
      );

      if (_transactions.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            textDirection: pw.TextDirection.ltr,
            build: (context) {
              return [
                _pdfTransactionTitle(font),
                ..._buildAllPdfTransactions(font),
              ];
            },
            footer: (context) {
              return _pdfFooter(
                font,
                context.pageNumber,
                context.pagesCount,
              );
            },
          ),
        );
      }

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/amar_hisab_report_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      await file.writeAsBytes(
        await pdf.save(),
        flush: true,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'application/pdf',
            ),
          ],
          text: 'আমার হিসাব রিপোর্ট',
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF রিপোর্ট তৈরি হয়েছে।',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF তৈরি করা যায়নি: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // PDF FOOTER
  // ============================================================

  pw.Widget _pdfFooter(
    pw.Font font,
    int pageNumber,
    int pagesCount,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(
        top: 10,
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'আমার হিসাব অ্যাপ',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Developed by Sayeed Mahadi',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'mahadisayeed@gmail.com',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Text(
            'পৃষ্ঠা $pageNumber / $pagesCount',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF OVERVIEW
  // ============================================================

  List<pw.Widget> _buildPdfOverview(
    pw.Font font,
  ) {
    return [
      pw.Center(
        child: pw.Text(
          'আমার হিসাব',
          style: pw.TextStyle(
            font: font,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Center(
        child: pw.Text(
          _periodTitle,
          style: pw.TextStyle(
            font: font,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Center(
        child: pw.Text(
          '${_dateText(_startDate)} - '
          '${_dateText(_endDate)}',
          style: pw.TextStyle(
            font: font,
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
      ),
      pw.SizedBox(height: 18),
      _pdfSummary(font),
      pw.SizedBox(height: 18),
      _pdfCategorySection(
        font,
        'আয় খাত',
        _incomeCategories,
        PdfColors.green700,
      ),
      pw.SizedBox(height: 12),
      _pdfCategorySection(
        font,
        'ব্যয় খাত',
        _expenseCategories,
        PdfColors.red700,
      ),
      pw.SizedBox(height: 18),
      _pdfLoanReport(font),
    ];
  }

  pw.Widget _pdfSummary(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(6),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'আয় ও ব্যয়ের সারসংক্ষেপ',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfAmountBox(
                  font,
                  'মোট আয়',
                  _income,
                  PdfColors.green700,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _pdfAmountBox(
                  font,
                  'মোট ব্যয়',
                  _expense,
                  PdfColors.red700,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _pdfAmountBox(
                  font,
                  _isSurplus
                      ? 'উদ্বৃত্ত'
                      : 'ঘাটতি',
                  _difference.abs(),
                  _isSurplus
                      ? PdfColors.green700
                      : PdfColors.red700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfAmountBox(
    pw.Font font,
    String title,
    double amount,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(5),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _money(amount),
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF CATEGORY
  // ============================================================

  pw.Widget _pdfCategorySection(
    pw.Font font,
    String title,
    List<Map<String, dynamic>> categories,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(6),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 7),
          if (categories.isEmpty)
            pw.Text(
              'কোনো তথ্য নেই',
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                color: PdfColors.grey600,
              ),
            )
          else
            ...categories.map(
              (category) {
                final name =
                    category['category_name']
                        ?.toString() ??
                    category['name']?.toString() ??
                    'অন্যান্য';

                final amount =
                    ((category['total'] ??
                                category['amount'] ??
                                0) as num)
                        .toDouble();

                return pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey300,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          name,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Text(
                        _money(amount),
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 12,
                          fontWeight:
                              pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF LOAN REPORT
  // ============================================================

  pw.Widget _pdfLoanReport(
    pw.Font font,
  ) {
    final people = _loanPersonSummary;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(6),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Loan Report',
            style: pw.TextStyle(
              font: font,
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfLoanAmount(
                  font,
                  'ধার দিয়েছি',
                  _loanGivenPeriod,
                  PdfColors.blue700,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: _pdfLoanAmount(
                  font,
                  'ধার নিয়েছি',
                  _loanTakenPeriod,
                  PdfColors.purple700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfLoanAmount(
                  font,
                  'ফেরত পেয়েছি',
                  _loanReceivedPeriod,
                  PdfColors.green700,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: _pdfLoanAmount(
                  font,
                  'শোধ করেছি',
                  _loanPaidPeriod,
                  PdfColors.orange800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfLoanAmount(
                  font,
                  'বর্তমান পাওনা',
                  _totalReceivable,
                  PdfColors.blue700,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: _pdfLoanAmount(
                  font,
                  'বর্তমান দেনা',
                  _totalPayable,
                  PdfColors.red700,
                ),
              ),
            ],
          ),
          if (people.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              'ব্যক্তিভিত্তিক Loan',
              style: pw.TextStyle(
                font: font,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            _pdfLoanPeopleTable(
              font,
              people,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _pdfLoanAmount(
    pw.Font font,
    String title,
    double amount,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(4),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            _money(amount),
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfLoanPeopleTable(
    pw.Font font,
    List<Map<String, dynamic>> people,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
          ),
          children: [
            _pdfCell(
              font,
              'ব্যক্তি',
              bold: true,
            ),
            _pdfCell(
              font,
              'দিয়েছি',
              bold: true,
            ),
            _pdfCell(
              font,
              'নিয়েছি',
              bold: true,
            ),
            _pdfCell(
              font,
              'পাওনা',
              bold: true,
            ),
            _pdfCell(
              font,
              'দেনা',
              bold: true,
            ),
          ],
        ),
        ...people.map(
          (person) {
            return pw.TableRow(
              children: [
                _pdfCell(
                  font,
                  person['person']
                          ?.toString() ??
                      '',
                ),
                _pdfCell(
                  font,
                  _money(
                    person['given']
                        as double,
                  ),
                ),
                _pdfCell(
                  font,
                  _money(
                    person['taken']
                        as double,
                  ),
                ),
                _pdfCell(
                  font,
                  _money(
                    person['receivable']
                        as double,
                  ),
                ),
                _pdfCell(
                  font,
                  _money(
                    person['payable']
                        as double,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  pw.Widget _pdfCell(
    pw.Font font,
    String text, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 12,
          fontWeight: bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ============================================================
  // PDF TRANSACTIONS
  // ============================================================

  pw.Widget _pdfTransactionTitle(
    pw.Font font,
  ) {
    return pw.Column(
      crossAxisAlignment:
          pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'লেনদেনের বিস্তারিত',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${_dateText(_startDate)} - '
          '${_dateText(_endDate)}',
          style: pw.TextStyle(
            font: font,
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  List<pw.Widget> _buildAllPdfTransactions(
    pw.Font font,
  ) {
    return _transactions.map(
      (tx) {
        final date = _parseDate(
          tx['transaction_date'],
        );

        final type =
            tx['type']?.toString() ?? '';

        final amount =
            ((tx['amount'] as num?)?.toDouble() ?? 0);

        final category =
            tx['category_name']?.toString() ?? '';

        final account =
            tx['account_name']?.toString() ?? '';

        final note =
            tx['note']?.toString() ?? '';

        final person = _loanPerson(tx);

        String details = '';

        if (person.isNotEmpty) {
          details = 'ব্যক্তি: $person';
        }

        if (category.isNotEmpty) {
          if (details.isNotEmpty) {
            details += ' | ';
          }

          details += 'খাত: $category';
        }

        if (account.isNotEmpty) {
          if (details.isNotEmpty) {
            details += ' | ';
          }

          details += 'অ্যাকাউন্ট: $account';
        }

        if (note.isNotEmpty) {
          if (details.isNotEmpty) {
            details += ' | ';
          }

          details += 'বিবরণ: $note';
        }

        if (type == 'transfer') {
          final from =
              tx['from_account_name']
                      ?.toString() ??
                  '';

          final to =
              tx['to_account_name']
                      ?.toString() ??
                  '';

          details =
              'From: $from  →  To: $to';
        }

        return pw.Container(
          margin: const pw.EdgeInsets.only(
            bottom: 7,
          ),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.grey300,
            ),
            borderRadius:
                const pw.BorderRadius.all(
              pw.Radius.circular(5),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 65,
                child: pw.Text(
                  _dateText(date),
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _transactionType(type),
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),
                    if (details.isNotEmpty)
                      pw.Padding(
                        padding:
                            const pw.EdgeInsets.only(
                          top: 3,
                        ),
                        child: pw.Text(
                          details,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                            color:
                                PdfColors.grey700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                _money(amount),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    ).toList();
  }

  // ============================================================
  // UI VOUCHER
  // ============================================================

  Widget _buildVoucher({
    bool exportMode = false,
    List<Map<String, dynamic>>? transactions,
  }) {
    final txList =
        transactions ?? _transactions;

    return Container(
      width: exportMode ? 850 : double.infinity,
      color: Colors.white,
      padding: EdgeInsets.all(
        exportMode ? 28 : 16,
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildReportHeader(
              exportMode: exportMode,
            ),
            const SizedBox(height: 18),
            _buildSummarySection(
              exportMode: exportMode,
            ),
            const SizedBox(height: 18),
            _buildCategorySection(
              title: 'আয় খাত',
              categories: _incomeCategories,
              color: _incomeColor,
              exportMode: exportMode,
            ),
            const SizedBox(height: 12),
            _buildCategorySection(
              title: 'ব্যয় খাত',
              categories: _expenseCategories,
              color: _expenseColor,
              exportMode: exportMode,
            ),
            const SizedBox(height: 18),
            _buildLoanSection(
              exportMode: exportMode,
            ),
            const SizedBox(height: 18),
            _buildTransactionSection(
              transactions: txList,
              exportMode: exportMode,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            // REPORT FOOTER
            Center(
              child: Column(
                children: [
                  Text(
                    'আমার হিসাব অ্যাপ',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Developed by Sayeed Mahadi',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'mahadisayeed@gmail.com',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildReportHeader({
    bool exportMode = false,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'আমার হিসাব',
            style: TextStyle(
              fontSize: exportMode ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: _green,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _periodTitle,
            style: TextStyle(
              fontSize: exportMode ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '${_dateText(_startDate)} - '
            '${_dateText(_endDate)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummarySection({
    bool exportMode = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'আয় ও ব্যয়ের সারসংক্ষেপ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  title: 'মোট আয়',
                  amount: _income,
                  color: _incomeColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  title: 'মোট ব্যয়',
                  amount: _expense,
                  color: _expenseColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  title: _isSurplus
                      ? 'উদ্বৃত্ত'
                      : 'ঘাটতি',
                  amount: _difference.abs(),
                  color: _isSurplus
                      ? _incomeColor
                      : _expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _money(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Widget _buildCategorySection({
    required String title,
    required List<Map<String, dynamic>> categories,
    required Color color,
    bool exportMode = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 7),
          if (categories.isEmpty)
            const Text(
              'কোনো তথ্য নেই',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            )
          else
            ...categories.map(
              (category) {
                final name =
                    category['category_name']
                        ?.toString() ??
                    category['name']?.toString() ??
                    'অন্যান্য';

                final amount =
                    ((category['total'] ??
                                category['amount'] ??
                                0) as num)
                        .toDouble();

                return Container(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        _money(amount),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LOAN SECTION
  // ============================================================

  Widget _buildLoanSection({
    bool exportMode = false,
  }) {
    final people = _loanPersonSummary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Report',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _loanSummaryCard(
                  'ধার দিয়েছি',
                  _loanGivenPeriod,
                  _loanGiveColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _loanSummaryCard(
                  'ধার নিয়েছি',
                  _loanTakenPeriod,
                  _loanTakeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _loanSummaryCard(
                  'ফেরত পেয়েছি',
                  _loanReceivedPeriod,
                  _loanReceiveColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _loanSummaryCard(
                  'শোধ করেছি',
                  _loanPaidPeriod,
                  _loanPaidColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _loanSummaryCard(
                  'বর্তমান পাওনা',
                  _totalReceivable,
                  _loanGiveColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _loanSummaryCard(
                  'বর্তমান দেনা',
                  _totalPayable,
                  _loanTakeColor,
                ),
              ),
            ],
          ),
          if (people.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'ব্যক্তিভিত্তিক Loan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            ...people.map(
              _buildLoanPersonCard,
            ),
          ],
        ],
      ),
    );
  }

  Widget _loanSummaryCard(
    String title,
    double amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _money(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanPersonCard(
    Map<String, dynamic> person,
  ) {
    final name =
        person['person']?.toString() ?? '';

    final given =
        person['given'] as double;

    final taken =
        person['taken'] as double;

    final received =
        person['received'] as double;

    final paid =
        person['paid'] as double;

    final receivable =
        person['receivable'] as double;

    final payable =
        person['payable'] as double;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _loanPersonValue(
                'দিয়েছি',
                given,
                _loanGiveColor,
              ),
              _loanPersonValue(
                'নিয়েছি',
                taken,
                _loanTakeColor,
              ),
              _loanPersonValue(
                'ফেরত',
                received,
                _loanReceiveColor,
              ),
              _loanPersonValue(
                'শোধ',
                paid,
                _loanPaidColor,
              ),
              _loanPersonValue(
                'পাওনা',
                receivable,
                _loanGiveColor,
              ),
              _loanPersonValue(
                'দেনা',
                payable,
                _loanTakeColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loanPersonValue(
    String title,
    double amount,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        Text(
          _money(amount),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TRANSACTION SECTION
  // ============================================================

  Widget _buildTransactionSection({
    required List<Map<String, dynamic>> transactions,
    bool exportMode = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'লেনদেনের বিস্তারিত',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            const Text(
              'এই সময়ের মধ্যে কোনো লেনদেন নেই।',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            )
          else
            ...transactions.map(
              (tx) => _transactionRow(
                tx,
                exportMode: exportMode,
              ),
            ),
        ],
      ),
    );
  }

  Widget _transactionRow(
    Map<String, dynamic> tx, {
    bool exportMode = false,
  }) {
    final type =
        tx['type']?.toString() ?? '';

    final amount =
        ((tx['amount'] as num?)?.toDouble() ?? 0);

    final date = _parseDate(
      tx['transaction_date'],
    );

    final color =
        _transactionColor(type);

    final person =
        _loanPerson(tx);

    final category =
        tx['category_name']?.toString() ?? '';

    final account =
        tx['account_name']?.toString() ?? '';

    final note =
        tx['note']?.toString() ?? '';

    String subtitle = '';

    if (person.isNotEmpty) {
      subtitle = 'ব্যক্তি: $person';
    }

    if (category.isNotEmpty) {
      if (subtitle.isNotEmpty) {
        subtitle += ' • ';
      }

      subtitle += 'খাত: $category';
    }

    if (account.isNotEmpty) {
      if (subtitle.isNotEmpty) {
        subtitle += ' • ';
      }

      subtitle += 'অ্যাকাউন্ট: $account';
    }

    if (note.isNotEmpty) {
      if (subtitle.isNotEmpty) {
        subtitle += ' • ';
      }

      subtitle += note;
    }

    if (type == 'transfer') {
      final from =
          tx['from_account_name']
                  ?.toString() ??
              '';

      final to =
          tx['to_account_name']
                  ?.toString() ??
              '';

      subtitle =
          '$from → $to';
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 7,
      ),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.1,
              ),
              borderRadius:
                  BorderRadius.circular(6),
            ),
            child: Icon(
              _transactionIcon(type),
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _transactionType(type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      _money(amount),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _dateText(date),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERIOD BUTTON
  // ============================================================

  Widget _periodButton(
    String value,
    String title,
  ) {
    final selected =
        _period == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          _changePeriod(value);
        },
        borderRadius:
            BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _green
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? _green
                  : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EXPORT MENU
  // ============================================================

  void _showExportMenu() {
    if (_saving) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'রিপোর্ট Export করুন',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                ),
                title: const Text(
                  'PDF হিসেবে Save/Share',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _savePdf();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.image,
                  color: Colors.green,
                ),
                title: const Text(
                  'JPG হিসেবে Gallery-তে Save',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _saveJpg();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.share,
                  color: Colors.blue,
                ),
                title: const Text(
                  'ছবি Share করুন',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareReport();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SHARE IMAGE
  // ============================================================

  Future<void> _shareReport() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final bytes = await _captureReport();

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/amar_hisab_report_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'image/png',
            ),
          ],
          text: 'আমার হিসাব রিপোর্ট',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'রিপোর্ট Share করা যায়নি: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'রিপোর্ট',
        ),
        actions: [
          IconButton(
            tooltip: 'Export',
            onPressed:
                _saving ? null : _showExportMenu,
            icon: const Icon(
              Icons.file_download_outlined,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Row(
                    children: [
                      _periodButton(
                        'weekly',
                        'সাপ্তাহিক',
                      ),
                      const SizedBox(width: 6),
                      _periodButton(
                        'monthly',
                        'মাসিক',
                      ),
                      const SizedBox(width: 6),
                      _periodButton(
                        'yearly',
                        'বার্ষিক',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickCustomDate,
                    icon: const Icon(
                      Icons.date_range,
                      size: 18,
                    ),
                    label: Text(
                      _period == 'custom'
                          ? '${_dateText(_startDate)} - '
                              '${_dateText(_endDate)}'
                          : 'নিজের সময় নির্বাচন করুন',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Screenshot(
                    controller:
                        _screenshotController,
                    child: _buildVoucher(),
                  ),
                ],
              ),
            ),
    );
  }
}
