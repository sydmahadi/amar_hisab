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

  late DateTime _startDate;
  late DateTime _endDate;

  bool _loading = true;
  bool _saving = false;

  double _income = 0;
  double _expense = 0;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _loans = [];
  List<Map<String, dynamic>> _loanPeriodTransactions = [];

  final Color _green = const Color(0xFF176B45);
  final Color _gold = const Color(0xFFC9A45C);

  final Color _incomeColor = const Color(0xFF2E8B57);
  final Color _expenseColor = const Color(0xFFC94C4C);

  final Color _loanGiveColor = const Color(0xFFD08B2E);
  final Color _loanTakeColor = const Color(0xFF8B5CF6);
  final Color _loanReceiveColor = const Color(0xFF168AAD);
  final Color _loanPaidColor = const Color(0xFF2A9D8F);

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

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

    _loadReport();
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

  Future<void> _loadReport() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final db = MoneyDb.instance;

      final income = await db.getTotalIncome(
        _startDate,
        _endDate,
      );

      final expense = await db.getTotalExpense(
        _startDate,
        _endDate,
      );

      final transactions = await db.getTransactions(
        _startDate,
        _endDate,
      );

      final incomeCategories =
          await db.getIncomeByCategory(
        _startDate,
        _endDate,
      );

      final expenseCategories =
          await db.getExpenseByCategory(
        _startDate,
        _endDate,
      );

      final loans = await db.getLoans();

      final loanPeriodTransactions =
          transactions.where((tx) {
        final type = _transactionType(tx);

        return type == 'loan_given' ||
            type == 'loan_taken' ||
            type == 'loan_received' ||
            type == 'loan_paid';
      }).toList();

      if (!mounted) return;

      setState(() {
        _income = income;
        _expense = expense;

        _transactions = transactions;

        _incomeCategories = incomeCategories;
        _expenseCategories = expenseCategories;

        _loans = loans;
        _loanPeriodTransactions =
            loanPeriodTransactions;

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
            'রিপোর্ট লোড করতে সমস্যা হয়েছে: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // PERIOD
  // ============================================================

  Future<void> _changePeriod(String period) async {
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    if (period == 'weekly') {
      final weekday = now.weekday;

      start = DateTime(
        now.year,
        now.month,
        now.day - (weekday - 1),
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
    } else if (period == 'yearly') {
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
    } else {
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

    await _loadReport();
  }

  Future<void> _pickCustomDate() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      helpText: 'রিপোর্টের সময় নির্বাচন করুন',
      saveText: 'নির্বাচন করুন',
      cancelText: 'বাতিল',
    );

    if (range == null) return;

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

    await _loadReport();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double get _difference {
    return _income - _expense;
  }

  bool get _isSurplus {
    return _difference >= 0;
  }

  String get _periodTitle {
    switch (_period) {
      case 'weekly':
        return 'সাপ্তাহিক রিপোর্ট';

      case 'yearly':
        return 'বার্ষিক রিপোর্ট';

      case 'custom':
        return 'নির্বাচিত সময়ের রিপোর্ট';

      case 'monthly':
      default:
        return 'মাসিক রিপোর্ট';
    }
  }

  String _money(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(
              value?.toString() ?? '',
            ) ??
            0;

    return '৳${number.toStringAsFixed(2)}';
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _transactionType(
    Map<String, dynamic> tx,
  ) {
    return (tx['type'] ??
            tx['transaction_type'] ??
            '')
        .toString()
        .toLowerCase();
  }

  Color _transactionColor(
    Map<String, dynamic> tx,
  ) {
    final type = _transactionType(tx);

    switch (type) {
      case 'income':
        return _incomeColor;

      case 'expense':
        return _expenseColor;

      case 'transfer':
        return Colors.blue;

      case 'loan_given':
        return _loanGiveColor;

      case 'loan_taken':
        return _loanTakeColor;

      case 'loan_received':
        return _loanReceiveColor;

      case 'loan_paid':
        return _loanPaidColor;

      default:
        return _green;
    }
  }

  IconData _transactionIcon(
    Map<String, dynamic> tx,
  ) {
    final type = _transactionType(tx);

    switch (type) {
      case 'income':
        return Icons.arrow_downward_rounded;

      case 'expense':
        return Icons.arrow_upward_rounded;

      case 'transfer':
        return Icons.swap_horiz_rounded;

      case 'loan_given':
        return Icons.person_add_alt_1_rounded;

      case 'loan_taken':
        return Icons.person_outline_rounded;

      case 'loan_received':
        return Icons.payments_rounded;

      case 'loan_paid':
        return Icons.assignment_return_rounded;

      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _loanPerson(
    Map<String, dynamic> loan,
  ) {
    return (loan['person_name'] ??
            loan['person'] ??
            loan['name'] ??
            loan['contact_name'] ??
            'অজানা ব্যক্তি')
        .toString();
  }

  double _loanRemaining(
    Map<String, dynamic> loan,
  ) {
    return double.tryParse(
          (loan['remaining'] ??
                  loan['remaining_amount'] ??
                  loan['amount'] ??
                  0)
              .toString(),
        ) ??
        0;
  }

  // ============================================================
  // LOAN TOTALS
  // ============================================================

  double get _loanGivenPeriod {
    return _loanPeriodTransactions
        .where(
          (tx) => _transactionType(tx) == 'loan_given',
        )
        .fold(
          0,
          (sum, tx) =>
              sum +
              (double.tryParse(
                    (tx['amount'] ?? 0).toString(),
                  ) ??
                  0),
        );
  }

  double get _loanTakenPeriod {
    return _loanPeriodTransactions
        .where(
          (tx) => _transactionType(tx) == 'loan_taken',
        )
        .fold(
          0,
          (sum, tx) =>
              sum +
              (double.tryParse(
                    (tx['amount'] ?? 0).toString(),
                  ) ??
                  0),
        );
  }

  double get _loanReceivedPeriod {
    return _loanPeriodTransactions
        .where(
          (tx) =>
              _transactionType(tx) ==
              'loan_received',
        )
        .fold(
          0,
          (sum, tx) =>
              sum +
              (double.tryParse(
                    (tx['amount'] ?? 0).toString(),
                  ) ??
                  0),
        );
  }

  double get _loanPaidPeriod {
    return _loanPeriodTransactions
        .where(
          (tx) =>
              _transactionType(tx) ==
              'loan_paid',
        )
        .fold(
          0,
          (sum, tx) =>
              sum +
              (double.tryParse(
                    (tx['amount'] ?? 0).toString(),
                  ) ??
                  0),
        );
  }

  double get _totalReceivable {
    return _loans
        .where(
          (loan) =>
              (loan['type'] ?? '')
                  .toString()
                  .toLowerCase() ==
              'receivable',
        )
        .fold(
          0,
          (sum, loan) =>
              sum + _loanRemaining(loan),
        );
  }

  double get _totalPayable {
    return _loans
        .where(
          (loan) =>
              (loan['type'] ?? '')
                  .toString()
                  .toLowerCase() ==
              'payable',
        )
        .fold(
          0,
          (sum, loan) =>
              sum + _loanRemaining(loan),
        );
  }

  // ============================================================
  // CURRENT PERSONAL LOAN SUMMARY
  // ============================================================

  List<Map<String, dynamic>>
      get _receivablePeople {
    return _loans
        .where(
          (loan) =>
              (loan['type'] ?? '')
                      .toString()
                      .toLowerCase() ==
                  'receivable' &&
              _loanRemaining(loan) > 0,
        )
        .map(
          (loan) => {
            'person': _loanPerson(loan),
            'amount': _loanRemaining(loan),
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> get _payablePeople {
    return _loans
        .where(
          (loan) =>
              (loan['type'] ?? '')
                      .toString()
                      .toLowerCase() ==
                  'payable' &&
              _loanRemaining(loan) > 0,
        )
        .map(
          (loan) => {
            'person': _loanPerson(loan),
            'amount': _loanRemaining(loan),
          },
        )
        .toList();
  }

  // ============================================================
  // TRANSACTION DETAILS
  // ============================================================

  void _openTransactionDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailsScreen(
          transactions: _transactions,
          startDate: _startDate,
          endDate: _endDate,
          periodTitle: _periodTitle,
        ),
      ),
    );
  }

  // ============================================================
  // REPORT SCREENSHOT
  // ============================================================

  Future<Uint8List?> _captureReport() async {
    try {
      return await _screenshotController
          .captureFromLongWidget(
        _buildVoucher(
          exportMode: true,
        ),
        delay: const Duration(
          milliseconds: 300,
        ),
        pixelRatio: 2.0,
        context: context,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'রিপোর্টের ছবি তৈরি করা যায়নি: $e',
            ),
          ),
        );
      }

      return null;
    }
  }

  // ============================================================
  // SAVE JPG
  // ============================================================

  Future<void> _saveJpg() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final pngBytes = await _captureReport();

      if (pngBytes == null) {
        return;
      }

      final decoded = img.decodeImage(
        pngBytes,
      );

      if (decoded == null) {
        throw Exception(
          'ছবি প্রসেস করা যায়নি',
        );
      }

      final jpgBytes = img.encodeJpg(
        decoded,
        quality: 95,
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

      await GallerySaver.saveImage(
        file.path,
        albumName: 'আমার হিসাব',
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'রিপোর্ট Gallery-তে সংরক্ষণ করা হয়েছে',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'ছবি সংরক্ষণ করা যায়নি: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // SHARE IMAGE
  // ============================================================

  Future<void> _shareImage() async {
    try {
      final bytes = await _captureReport();

      if (bytes == null) return;

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/amar_hisab_report.jpg',
      );

      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        throw Exception(
          'ছবি তৈরি করা যায়নি',
        );
      }

      final jpg = img.encodeJpg(
        decoded,
        quality: 95,
      );

      await file.writeAsBytes(
        jpg,
        flush: true,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text: 'আমার হিসাব - $_periodTitle',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'ছবি শেয়ার করা যায়নি: $e',
            ),
          ),
        );
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

      return pw.Font.ttf(
        data.buffer.asByteData(),
      );
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  // ============================================================
  // SAVE PDF
  // ============================================================

  Future<void> _savePdf() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final font = await _loadPdfFont();

      final pdf = pw.Document();

      // MAIN REPORT PDF ONLY.
      // Transaction details are intentionally NOT added here.
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: font,
          ),
          header: (context) {
            return _pdfHeader(font);
          },
          footer: (context) {
            return _pdfFooter(
              context,
              font,
            );
          },
          build: (context) {
            return _buildPdfOverview(
              font,
            );
          },
        ),
      );

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
            XFile(file.path),
          ],
          text: 'আমার হিসাব - $_periodTitle PDF',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'PDF তৈরি করা যায়নি: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // PDF HEADER
  // ============================================================

  pw.Widget _pdfHeader(
    pw.Font font,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(
        bottom: 12,
      ),
      padding: const pw.EdgeInsets.only(
        bottom: 8,
      ),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            width: 1,
            color: PdfColors.grey400,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'আমার হিসাব',
            style: pw.TextStyle(
              font: font,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            _periodTitle,
            style: pw.TextStyle(
              font: font,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF FOOTER
  // ============================================================

  pw.Widget _pdfFooter(
    pw.Context context,
    pw.Font font,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(
        top: 12,
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'আমার হিসাব অ্যাপ',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                ),
              ),
              pw.Text(
                'Developed by Sayeed Mahadi',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 7,
                ),
              ),
              pw.Text(
                'mahadisayeed@gmail.com',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 7,
                ),
              ),
            ],
          ),
          pw.Text(
            'পৃষ্ঠা ${context.pageNumber} / '
            '${context.pagesCount}',
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
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
      pw.Text(
        'রিপোর্টের সময়',
        style: pw.TextStyle(
          font: font,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        '${_dateText(_startDate)} - '
        '${_dateText(_endDate)}',
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
        ),
      ),
      pw.SizedBox(height: 15),

      _pdfSummaryBoxes(font),

      pw.SizedBox(height: 18),

      _pdfCategorySection(
        font,
        'আয়ের খাতসমূহ',
        _incomeCategories,
        true,
      ),

      pw.SizedBox(height: 15),

      _pdfCategorySection(
        font,
        'ব্যয়ের খাতসমূহ',
        _expenseCategories,
        false,
      ),

      pw.SizedBox(height: 15),

      _pdfLoanReport(font),

      // IMPORTANT:
      // No transaction list here.
    ];
  }

  // ============================================================
  // PDF SUMMARY
  // ============================================================

  pw.Widget _pdfSummaryBoxes(
    pw.Font font,
  ) {
    return pw.Row(
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
                : 'ঘাটি',
            _difference.abs(),
            _isSurplus
                ? PdfColors.green700
                : PdfColors.red700,
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfAmountBox(
    pw.Font font,
    String title,
    double amount,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius:
            pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 5),
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
    bool income,
  ) {
    if (categories.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.grey300,
          ),
        ),
        child: pw.Text(
          '$title\nকোনো তথ্য নেই',
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment:
          pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 7),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration:
                  const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              children: [
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'খাত',
                    style: pw.TextStyle(
                      font: font,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'পরিমাণ',
                    style: pw.TextStyle(
                      font: font,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            ...categories.map(
              (item) {
                final category =
                    (item['category'] ??
                            item['name'] ??
                            item['category_name'] ??
                            'অন্যান্য')
                        .toString();

                final amount =
                    double.tryParse(
                          (item['total'] ??
                                  item['amount'] ??
                                  item['sum'] ??
                                  0)
                              .toString(),
                        ) ??
                        0;

                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding:
                          const pw.EdgeInsets.all(
                        6,
                      ),
                      child: pw.Text(
                        category,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding:
                          const pw.EdgeInsets.all(
                        6,
                      ),
                      child: pw.Text(
                        _money(amount),
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // PDF LOAN REPORT
  // ============================================================

  pw.Widget _pdfLoanReport(
    pw.Font font,
  ) {
    return pw.Column(
      crossAxisAlignment:
          pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ব্যক্তিগত Loan',
          style: pw.TextStyle(
            font: font,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 8),

        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _pdfLoanAmount(
              font,
              'দিয়েছি',
              _loanGivenPeriod,
            ),
            _pdfLoanAmount(
              font,
              'নিয়েছি',
              _loanTakenPeriod,
            ),
            _pdfLoanAmount(
              font,
              'ফেরত পেয়েছি',
              _loanReceivedPeriod,
            ),
            _pdfLoanAmount(
              font,
              'ফেরত দিয়েছি',
              _loanPaidPeriod,
            ),
            _pdfLoanAmount(
              font,
              'আমি পাব',
              _totalReceivable,
            ),
            _pdfLoanAmount(
              font,
              'আমার কাছে পাবে',
              _totalPayable,
            ),
          ],
        ),

        pw.SizedBox(height: 14),

        if (_receivablePeople.isNotEmpty)
          _pdfOutstandingPeople(
            font,
            'আমি কার কাছে পাব',
            _receivablePeople,
          ),

        if (_receivablePeople.isNotEmpty &&
            _payablePeople.isNotEmpty)
          pw.SizedBox(height: 12),

        if (_payablePeople.isNotEmpty)
          _pdfOutstandingPeople(
            font,
            'আমার কাছে কারা পাবে',
            _payablePeople,
          ),

        if (_receivablePeople.isEmpty &&
            _payablePeople.isEmpty)
          pw.Container(
            padding:
                const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.grey300,
              ),
            ),
            child: pw.Text(
              'বর্তমানে কোনো বকেয়া ব্যক্তিগত Loan নেই।',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _pdfLoanAmount(
    pw.Font font,
    String title,
    double amount,
  ) {
    return pw.Container(
      width: 155,
      padding:
          const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey300,
        ),
        borderRadius:
            pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            _money(amount),
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              fontWeight:
                  pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfOutstandingPeople(
    pw.Font font,
    String title,
    List<Map<String, dynamic>> people,
  ) {
    return pw.Column(
      crossAxisAlignment:
          pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration:
                  const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              children: [
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'ব্যক্তি',
                    style: pw.TextStyle(
                      font: font,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'বকেয়া',
                    style: pw.TextStyle(
                      font: font,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            ...people.map(
              (person) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding:
                        const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      person['person']
                          .toString(),
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding:
                        const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      _money(
                        person['amount'],
                      ),
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // MAIN REPORT VOUCHER
  // ============================================================

  Widget _buildVoucher({
    bool exportMode = false,
  }) {
    return Material(
      color: Colors.white,
      child: Container(
        width: 850,
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Container(
              padding:
                  const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _green,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'আমার হিসাব',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight:
                          FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _periodTitle,
                    style: TextStyle(
                      color: _gold,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_dateText(_startDate)} - '
                    '${_dateText(_endDate)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // SUMMARY
            _buildSummaryCards(
              exportMode: exportMode,
            ),

            const SizedBox(height: 20),

            // CATEGORIES
            _buildCategorySection(
              title: 'আয়ের খাতসমূহ',
              categories: _incomeCategories,
              color: _incomeColor,
            ),

            const SizedBox(height: 16),

            _buildCategorySection(
              title: 'ব্যয়ের খাতসমূহ',
              categories: _expenseCategories,
              color: _expenseColor,
            ),

            const SizedBox(height: 20),

            // LOAN
            _buildLoanSection(
              exportMode: exportMode,
            ),

            const SizedBox(height: 18),

            // IMPORTANT:
            // Transaction details are NOT shown here.
            // This makes the main report much shorter.

            Container(
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Text(
                'আমার হিসাব অ্যাপ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards({
    bool exportMode = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            exportMode
                ? (constraints.maxWidth - 24) / 3
                : (constraints.maxWidth - 16) / 3;

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'মোট আয়',
                amount: _income,
                icon: Icons.arrow_downward_rounded,
                color: _incomeColor,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'মোট ব্যয়',
                amount: _expense,
                icon: Icons.arrow_upward_rounded,
                color: _expenseColor,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: _isSurplus
                    ? 'উদ্বৃত্ত'
                    : 'ঘাটি',
                amount: _difference.abs(),
                icon: _isSurplus
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: _isSurplus
                    ? _incomeColor
                    : _expenseColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _money(amount),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY SECTION
  // ============================================================

  Widget _buildCategorySection({
    required String title,
    required List<Map<String, dynamic>>
        categories,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: _green,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (categories.isEmpty)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Text(
                'কোনো তথ্য নেই',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...categories.map(
              (item) {
                final name =
                    (item['category'] ??
                            item['name'] ??
                            item['category_name'] ??
                            'অন্যান্য')
                        .toString();

                final amount =
                    double.tryParse(
                          (item['total'] ??
                                  item['amount'] ??
                                  item['sum'] ??
                                  0)
                              .toString(),
                        ) ??
                        0;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style:
                              const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        _money(amount),
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 13,
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
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.handshake_rounded,
                color: _gold,
              ),
              const SizedBox(width: 7),
              Text(
                'ব্যক্তিগত Loan',
                style: TextStyle(
                  color: _green,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _loanCard(
                'দিয়েছি',
                _loanGivenPeriod,
                _loanGiveColor,
              ),
              _loanCard(
                'নিয়েছি',
                _loanTakenPeriod,
                _loanTakeColor,
              ),
              _loanCard(
                'ফেরত পেয়েছি',
                _loanReceivedPeriod,
                _loanReceiveColor,
              ),
              _loanCard(
                'ফেরত দিয়েছি',
                _loanPaidPeriod,
                _loanPaidColor,
              ),
              _loanCard(
                'আমি পাব',
                _totalReceivable,
                _loanReceiveColor,
              ),
              _loanCard(
                'আমার কাছে পাবে',
                _totalPayable,
                _loanPaidColor,
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_receivablePeople.isNotEmpty)
            _outstandingPeopleCard(
              title: 'আমি কার কাছে পাব',
              subtitle:
                  'এই ব্যক্তিদের কাছ থেকে আমার টাকা পাওনা আছে',
              people: _receivablePeople,
              color: _loanReceiveColor,
            ),

          if (_receivablePeople.isNotEmpty &&
              _payablePeople.isNotEmpty)
            const SizedBox(height: 10),

          if (_payablePeople.isNotEmpty)
            _outstandingPeopleCard(
              title: 'আমার কাছে কারা পাবে',
              subtitle:
                  'এই ব্যক্তিদের টাকা আমাকে পরিশোধ করতে হবে',
              people: _payablePeople,
              color: _loanPaidColor,
            ),

          if (_receivablePeople.isEmpty &&
              _payablePeople.isEmpty)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Text(
                'বর্তমানে কোনো বকেয়া ব্যক্তিগত Loan নেই।',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _loanCard(
    String title,
    double amount,
    Color color,
  ) {
    return Container(
      width: 145,
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color: color.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _money(amount),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _outstandingPeopleCard({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>>
        people,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.05,
        ),
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 7),

          ...people.map(
            (person) => Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      person['person']
                          .toString(),
                      style:
                          const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _money(
                      person['amount'],
                    ),
                    style: TextStyle(
                      color: color,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXPORT MENU
  // ============================================================

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  'রিপোর্ট সংরক্ষণ / শেয়ার',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ListTile(
                  leading: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red.shade700,
                  ),
                  title: const Text(
                    'PDF তৈরি ও শেয়ার',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _savePdf();
                  },
                ),

                ListTile(
                  leading: Icon(
                    Icons.image,
                    color: _green,
                  ),
                  title: const Text(
                    'JPG হিসেবে Gallery-তে সংরক্ষণ',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _saveJpg();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.share,
                  ),
                  title: const Text(
                    'ছবি শেয়ার',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _shareImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MAIN BUILD
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
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            onPressed: _loading
                ? null
                : _loadReport,
          ),
          IconButton(
            tooltip: 'Export',
            icon: const Icon(
              Icons.ios_share_rounded,
            ),
            onPressed: _loading
                ? null
                : _showExportMenu,
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: ListView(
                padding:
                    const EdgeInsets.all(14),
                children: [
                  // PERIOD SELECTOR
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        10,
                      ),
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection:
                                Axis.horizontal,
                            child: Row(
                              children: [
                                _periodButton(
                                  'সাপ্তাহিক',
                                  'weekly',
                                ),
                                _periodButton(
                                  'মাসিক',
                                  'monthly',
                                ),
                                _periodButton(
                                  'বার্ষিক',
                                  'yearly',
                                ),
                                _periodButton(
                                  'কাস্টম',
                                  'custom',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            '${_dateText(_startDate)} - '
                            '${_dateText(_endDate)}',
                            style:
                                const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // SEPARATE TRANSACTION DETAILS BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _openTransactionDetails,
                      icon: const Icon(
                        Icons.receipt_long_rounded,
                      ),
                      label: const Text(
                        'লেনদেনের বিস্তারিত',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            _green,
                        side: BorderSide(
                          color: _green,
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // REPORT PREVIEW
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,
                      child: _buildVoucher(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _periodButton(
    String text,
    String value,
  ) {
    final selected =
        _period == value;

    return Padding(
      padding:
          const EdgeInsets.only(
        right: 6,
      ),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        onSelected: (_) {
          if (value == 'custom') {
            _pickCustomDate();
          } else {
            _changePeriod(value);
          }
        },
      ),
    );
  }
}

// ===================================================================
// TRANSACTION DETAILS SCREEN
// ===================================================================

class TransactionDetailsScreen
    extends StatefulWidget {
  final List<Map<String, dynamic>>
      transactions;

  final DateTime startDate;
  final DateTime endDate;
  final String periodTitle;

  const TransactionDetailsScreen({
    super.key,
    required this.transactions,
    required this.startDate,
    required this.endDate,
    required this.periodTitle,
  });

  @override
  State<TransactionDetailsScreen>
      createState() =>
          _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends State<TransactionDetailsScreen> {
  final ScreenshotController
      _screenshotController =
      ScreenshotController();

  bool _saving = false;

  final Color _green =
      const Color(0xFF176B45);

  final Color _gold =
      const Color(0xFFC9A45C);

  final Color _incomeColor =
      const Color(0xFF2E8B57);

  final Color _expenseColor =
      const Color(0xFFC94C4C);

  final Color _loanGiveColor =
      const Color(0xFFD08B2E);

  final Color _loanTakeColor =
      const Color(0xFF8B5CF6);

  final Color _loanReceiveColor =
      const Color(0xFF168AAD);

  final Color _loanPaidColor =
      const Color(0xFF2A9D8F);

  // ============================================================
  // HELPERS
  // ============================================================

  String _money(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(
              value?.toString() ?? '',
            ) ??
            0;

    return '৳${number.toStringAsFixed(2)}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _transactionType(
    Map<String, dynamic> tx,
  ) {
    return (tx['type'] ??
            tx['transaction_type'] ??
            '')
        .toString()
        .toLowerCase();
  }

  Color _transactionColor(
    Map<String, dynamic> tx,
  ) {
    switch (_transactionType(tx)) {
      case 'income':
        return _incomeColor;

      case 'expense':
        return _expenseColor;

      case 'transfer':
        return Colors.blue;

      case 'loan_given':
        return _loanGiveColor;

      case 'loan_taken':
        return _loanTakeColor;

      case 'loan_received':
        return _loanReceiveColor;

      case 'loan_paid':
        return _loanPaidColor;

      default:
        return _green;
    }
  }

  IconData _transactionIcon(
    Map<String, dynamic> tx,
  ) {
    switch (_transactionType(tx)) {
      case 'income':
        return Icons.arrow_downward_rounded;

      case 'expense':
        return Icons.arrow_upward_rounded;

      case 'transfer':
        return Icons.swap_horiz_rounded;

      case 'loan_given':
        return Icons.person_add_alt_1_rounded;

      case 'loan_taken':
        return Icons.person_outline_rounded;

      case 'loan_received':
        return Icons.payments_rounded;

      case 'loan_paid':
        return Icons.assignment_return_rounded;

      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _typeText(
    Map<String, dynamic> tx,
  ) {
    switch (_transactionType(tx)) {
      case 'income':
        return 'আয়';

      case 'expense':
        return 'ব্যয়';

      case 'transfer':
        return 'Transfer';

      case 'loan_given':
        return 'Loan দিয়েছি';

      case 'loan_taken':
        return 'Loan নিয়েছি';

      case 'loan_received':
        return 'Loan ফেরত পেয়েছি';

      case 'loan_paid':
        return 'Loan ফেরত দিয়েছি';

      default:
        return 'লেনদেন';
    }
  }

  String _loanPerson(
    Map<String, dynamic> tx,
  ) {
    return (tx['person_name'] ??
            tx['person'] ??
            tx['name'] ??
            tx['contact_name'] ??
            '')
        .toString();
  }

  String _category(
    Map<String, dynamic> tx,
  ) {
    return (tx['category_name'] ??
            tx['category'] ??
            '')
        .toString();
  }

  String _account(
    Map<String, dynamic> tx,
  ) {
    return (tx['account_name'] ??
            tx['account'] ??
            '')
        .toString();
  }

  String _note(
    Map<String, dynamic> tx,
  ) {
    return (tx['note'] ??
            tx['description'] ??
            tx['details'] ??
            '')
        .toString();
  }

  // ============================================================
  // TRANSACTION ROW
  // ============================================================

  Widget _transactionRow(
    Map<String, dynamic> tx, {
    bool exportMode = false,
  }) {
    final color =
        _transactionColor(tx);

    final type =
        _transactionType(tx);

    final amount =
        double.tryParse(
              (tx['amount'] ?? 0)
                  .toString(),
            ) ??
            0;

    final date =
        _parseDate(
          tx['date'] ??
              tx['transaction_date'] ??
              tx['created_at'],
        );

    final person =
        _loanPerson(tx);

    final category =
        _category(tx);

    final account =
        _account(tx);

    final note =
        _note(tx);

    final transferFrom =
        (tx['from_account_name'] ??
                tx['from_account'] ??
                '')
            .toString();

    final transferTo =
        (tx['to_account_name'] ??
                tx['to_account'] ??
                '')
            .toString();

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _transactionIcon(tx),
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _typeText(tx),
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _money(amount),
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                if (date != null)
                  Text(
                    _dateText(date),
                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),

                if (type == 'transfer') ...[
                  if (transferFrom
                          .isNotEmpty ||
                      transferTo
                          .isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 4,
                      ),
                      child: Text(
                        '${transferFrom.isEmpty ? '-' : transferFrom}'
                        '  →  '
                        '${transferTo.isEmpty ? '-' : transferTo}',
                        style:
                            const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                ] else ...[
                  if (person.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 3,
                      ),
                      child: Text(
                        'ব্যক্তি: $person',
                        style:
                            const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                        ),
                      ),
                    ),

                  if (category.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 2,
                      ),
                      child: Text(
                        'খাত: $category',
                        style:
                            const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ),

                  if (account.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 2,
                      ),
                      child: Text(
                        'অ্যাকাউন্ট: $account',
                        style:
                            const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],

                if (note.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 3,
                    ),
                    child: Text(
                      'নোট: $note',
                      style:
                          const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
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

  // ============================================================
  // DETAILS EXPORT WIDGET
  // ============================================================

  Widget _buildTransactionDetailsExport() {
    return Material(
      color: Colors.white,
      child: Container(
        width: 850,
        color: Colors.white,
        padding:
            const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Container(
              padding:
                  const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _green,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    'আমার হিসাব',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'লেনদেনের বিস্তারিত',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_dateText(widget.startDate)} - '
                    '${_dateText(widget.endDate)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (widget.transactions.isEmpty)
              Container(
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        Colors.grey.shade300,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Text(
                  'এই সময়ের মধ্যে কোনো লেনদেন নেই।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              )
            else
              ...widget.transactions.map(
                (tx) => _transactionRow(
                  tx,
                  exportMode: true,
                ),
              ),

            const SizedBox(height: 10),

            const Text(
              'আমার হিসাব অ্যাপ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CAPTURE TRANSACTION DETAILS
  // ============================================================

  Future<Uint8List?>
      _captureTransactions() async {
    try {
      return await _screenshotController
          .captureFromLongWidget(
        _buildTransactionDetailsExport(),
        delay: const Duration(
          milliseconds: 300,
        ),
        pixelRatio: 2.0,
        context: context,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'লেনদেনের ছবি তৈরি করা যায়নি: $e',
            ),
          ),
        );
      }

      return null;
    }
  }

  // ============================================================
  // SAVE TRANSACTION JPG
  // ============================================================

  Future<void> _saveTransactionJpg() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final png =
          await _captureTransactions();

      if (png == null) return;

      final decoded =
          img.decodeImage(png);

      if (decoded == null) {
        throw Exception(
          'ছবি প্রসেস করা যায়নি',
        );
      }

      final jpg =
          img.encodeJpg(
        decoded,
        quality: 95,
      );

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/amar_hisab_transactions_'
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(
        jpg,
        flush: true,
      );

      await GallerySaver.saveImage(
        file.path,
        albumName: 'আমার হিসাব',
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'লেনদেনের বিস্তারিত Gallery-তে সংরক্ষণ করা হয়েছে',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'ছবি সংরক্ষণ করা যায়নি: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // SHARE TRANSACTIONS IMAGE
  // ============================================================

  Future<void> _shareTransactions() async {
    try {
      final png =
          await _captureTransactions();

      if (png == null) return;

      final decoded =
          img.decodeImage(png);

      if (decoded == null) {
        throw Exception(
          'ছবি তৈরি করা যায়নি',
        );
      }

      final jpg =
          img.encodeJpg(
        decoded,
        quality: 95,
      );

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/amar_hisab_transactions.jpg',
      );

      await file.writeAsBytes(
        jpg,
        flush: true,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text:
              'আমার হিসাব - লেনদেনের বিস্তারিত',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'শেয়ার করা যায়নি: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // PDF TRANSACTIONS
  // ============================================================

  Future<pw.Font>
      _loadPdfFont() async {
    try {
      final data =
          await rootBundle.load(
        'assets/fonts/NotoSansBengali-Regular.ttf',
      );

      return pw.Font.ttf(
        data.buffer.asByteData(),
      );
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  Future<void>
      _saveTransactionPdf() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final font =
          await _loadPdfFont();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat:
              PdfPageFormat.a4,
          margin:
              const pw.EdgeInsets.all(
            24,
          ),
          theme:
              pw.ThemeData.withFont(
            base: font,
          ),
          header: (context) {
            return pw.Container(
              margin:
                  const pw.EdgeInsets.only(
                bottom: 12,
              ),
              padding:
                  const pw.EdgeInsets.only(
                bottom: 8,
              ),
              decoration:
                  const pw.BoxDecoration(
                border: pw.Border(
                  bottom:
                      pw.BorderSide(
                    color:
                        PdfColors.grey400,
                  ),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'আমার হিসাব',
                    style:
                        pw.TextStyle(
                      font: font,
                      fontSize: 20,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(
                    height: 3,
                  ),
                  pw.Text(
                    'লেনদেনের বিস্তারিত',
                    style:
                        pw.TextStyle(
                      font: font,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(
                    height: 3,
                  ),
                  pw.Text(
                    '${_dateText(widget.startDate)} - '
                    '${_dateText(widget.endDate)}',
                    style:
                        pw.TextStyle(
                      font: font,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            );
          },
          footer: (context) {
            return pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,
              children: [
                pw.Text(
                  'আমার হিসাব অ্যাপ',
                  style:
                      pw.TextStyle(
                    font: font,
                    fontSize: 8,
                  ),
                ),
                pw.Text(
                  'পৃষ্ঠা ${context.pageNumber} / '
                  '${context.pagesCount}',
                  style:
                      pw.TextStyle(
                    font: font,
                    fontSize: 8,
                  ),
                ),
              ],
            );
          },
          build: (context) {
            if (widget.transactions
                .isEmpty) {
              return [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.all(
                    15,
                  ),
                  child: pw.Text(
                    'এই সময়ের মধ্যে কোনো লেনদেন নেই।',
                    style:
                        pw.TextStyle(
                      font: font,
                      fontSize: 11,
                    ),
                  ),
                ),
              ];
            }

            return widget.transactions
                .map(
                  (tx) =>
                      _pdfTransactionRow(
                    tx,
                    font,
                  ),
                )
                .toList();
          },
        ),
      );

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/amar_hisab_transactions_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      await file.writeAsBytes(
        await pdf.save(),
        flush: true,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text:
              'আমার হিসাব - লেনদেনের বিস্তারিত PDF',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'PDF তৈরি করা যায়নি: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // PDF TRANSACTION ROW
  // ============================================================

  pw.Widget _pdfTransactionRow(
    Map<String, dynamic> tx,
    pw.Font font,
  ) {
    final type =
        _transactionType(tx);

    final amount =
        double.tryParse(
              (tx['amount'] ?? 0)
                  .toString(),
            ) ??
            0;

    final date =
        _parseDate(
          tx['date'] ??
              tx['transaction_date'] ??
              tx['created_at'],
        );

    final person =
        _loanPerson(tx);

    final category =
        _category(tx);

    final account =
        _account(tx);

    final note =
        _note(tx);

    final from =
        (tx['from_account_name'] ??
                tx['from_account'] ??
                '')
            .toString();

    final to =
        (tx['to_account_name'] ??
                tx['to_account'] ??
                '')
            .toString();

    String details = '';

    if (type == 'transfer') {
      details =
          'From: ${from.isEmpty ? '-' : from}  '
          'To: ${to.isEmpty ? '-' : to}';
    } else {
      final parts = <String>[];

      if (person.isNotEmpty) {
        parts.add(
          'ব্যক্তি: $person',
        );
      }

      if (category.isNotEmpty) {
        parts.add(
          'খাত: $category',
        );
      }

      if (account.isNotEmpty) {
        parts.add(
          'অ্যাকাউন্ট: $account',
        );
      }

      if (note.isNotEmpty) {
        parts.add(
          'নোট: $note',
        );
      }

      details = parts.join(' | ');
    }

    return pw.Container(
      margin:
          const pw.EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey300,
        ),
        borderRadius:
            pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment:
                pw.MainAxisAlignment
                    .spaceBetween,
            children: [
              pw.Text(
                _typeText(tx),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _money(amount),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          if (date != null)
            pw.Padding(
              padding:
                  const pw.EdgeInsets.only(
                top: 3,
              ),
              child: pw.Text(
                _dateText(date),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color:
                      PdfColors.grey700,
                ),
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
                  fontSize: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _typeText(
    Map<String, dynamic> tx,
  ) {
    switch (_transactionType(tx)) {
      case 'income':
        return 'আয়';

      case 'expense':
        return 'ব্যয়';

      case 'transfer':
        return 'Transfer';

      case 'loan_given':
        return 'Loan দিয়েছি';

      case 'loan_taken':
        return 'Loan নিয়েছি';

      case 'loan_received':
        return 'Loan ফেরত পেয়েছি';

      case 'loan_paid':
        return 'Loan ফেরত দিয়েছি';

      default:
        return 'লেনদেন';
    }
  }

  // ============================================================
  // TRANSACTION EXPORT MENU
  // ============================================================

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  'লেনদেনের বিস্তারিত',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                ListTile(
                  leading: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red.shade700,
                  ),
                  title: const Text(
                    'PDF তৈরি ও শেয়ার',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _saveTransactionPdf();
                  },
                ),

                ListTile(
                  leading: Icon(
                    Icons.image,
                    color: _green,
                  ),
                  title: const Text(
                    'JPG হিসেবে Gallery-তে সংরক্ষণ',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _saveTransactionJpg();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.share,
                  ),
                  title: const Text(
                    'ছবি শেয়ার',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _shareTransactions();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD TRANSACTION DETAILS SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'লেনদেনের বিস্তারিত',
        ),
        actions: [
          IconButton(
            tooltip: 'Export',
            icon: const Icon(
              Icons.ios_share_rounded,
            ),
            onPressed: _showExportMenu,
          ),
        ],
      ),

      body: widget.transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 55,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'এই সময়ের মধ্যে কোনো লেনদেন নেই।',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(14),
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _green.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.periodTitle,
                        style: TextStyle(
                          color: _green,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_dateText(widget.startDate)} - '
                        '${_dateText(widget.endDate)}',
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'মোট ${widget.transactions.length}টি লেনদেন',
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                ...widget.transactions.map(
                  (tx) => _transactionRow(tx),
                ),
              ],
            ),
    );
  }
}
