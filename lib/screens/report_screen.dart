import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../services/money_db.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ScreenshotController _screenshotController =
      ScreenshotController();

  final Color _green = const Color(0xFF176B45);
  final Color _darkGreen = const Color(0xFF0F5132);
  final Color _gold = const Color(0xFFC9A45C);
  final Color _goldLight = const Color(0xFFE4C987);

  final Color _incomeColor = const Color(0xFF35B77A);
  final Color _expenseColor = const Color(0xFFE56B6F);

  final Color _loanGiveColor = const Color(0xFF4CAF50);
  final Color _loanTakeColor = const Color(0xFFFFA726);
  final Color _loanReceiveColor = const Color(0xFF42A5F5);
  final Color _loanPaidColor = const Color(0xFFAB47BC);

  String _period = 'monthly';

  DateTime _startDate =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

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

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  // =========================================================
  // LOAD REPORT
  // =========================================================

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

      final transactions = await MoneyDb.instance.getTransactions(
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

      final loans = await MoneyDb.instance.getLoans();

      final loanPeriodTransactions = transactions.where((tx) {
        final type = _value(tx, ['type']).toLowerCase();

        return type == 'loan_given' ||
            type == 'loan_taken' ||
            type == 'loan_received' ||
            type == 'loan_paid';
      }).toList();

      if (!mounted) return;

      setState(() {
        _income = _toDouble(income);
        _expense = _toDouble(expense);

        _transactions = List<Map<String, dynamic>>.from(
          transactions,
        );

        _incomeCategories =
            List<Map<String, dynamic>>.from(incomeCategories);

        _expenseCategories =
            List<Map<String, dynamic>>.from(expenseCategories);

        _loans = List<Map<String, dynamic>>.from(loans);

        _loanPeriodTransactions =
            List<Map<String, dynamic>>.from(
          loanPeriodTransactions,
        );

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('রিপোর্ট লোড করা যায়নি: $e'),
        ),
      );
    }
  }

  // =========================================================
  // PERIOD
  // =========================================================

  void _changePeriod(String value) {
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    if (value == 'weekly') {
      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final monday =
          today.subtract(Duration(days: today.weekday - 1));

      start = DateTime(
        monday.year,
        monday.month,
        monday.day,
      );

      final sunday = monday.add(const Duration(days: 6));

      end = DateTime(
        sunday.year,
        sunday.month,
        sunday.day,
        23,
        59,
        59,
        999,
      );
    } else if (value == 'yearly') {
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
      _period = value;
      _startDate = start;
      _endDate = end;
    });

    _loadReport();
  }

  Future<void> _pickCustomDate() async {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);

    final pickedStart = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'শুরুর তারিখ নির্বাচন করুন',
    );

    if (pickedStart == null || !mounted) return;

    final pickedEnd = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: pickedStart,
      lastDate: lastDate,
      helpText: 'শেষের তারিখ নির্বাচন করুন',
    );

    if (pickedEnd == null || !mounted) return;

    setState(() {
      _period = 'custom';

      _startDate = DateTime(
        pickedStart.year,
        pickedStart.month,
        pickedStart.day,
      );

      _endDate = DateTime(
        pickedEnd.year,
        pickedEnd.month,
        pickedEnd.day,
        23,
        59,
        59,
        999,
      );
    });

    _loadReport();
  }

  // =========================================================
  // BASIC HELPERS
  // =========================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().replaceAll(',', '').trim() ?? '',
        ) ??
        0;
  }

  String _value(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }

  String _money(double value) {
    final text = value.abs() == value.abs().roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    return '৳$text';
  }

  String _dateText(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');

    return '$d/$m/${date.year}';
  }

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

  double get _difference {
    return _income - _expense;
  }

  bool get _isSurplus {
    return _difference >= 0;
  }

  // =========================================================
  // LOAN TOTALS
  // =========================================================

  double _loanPeriodTotal(String type) {
    double total = 0;

    for (final tx in _loanPeriodTransactions) {
      final txType = _value(tx, ['type']).toLowerCase();

      if (txType == type) {
        total += _toDouble(
          tx['amount'],
        );
      }
    }

    return total;
  }

  double get _loanGivenPeriod {
    return _loanPeriodTotal('loan_given');
  }

  double get _loanTakenPeriod {
    return _loanPeriodTotal('loan_taken');
  }

  double get _loanReceivedPeriod {
    return _loanPeriodTotal('loan_received');
  }

  double get _loanPaidPeriod {
    return _loanPeriodTotal('loan_paid');
  }

  double get _totalReceivable {
    double total = 0;

    for (final loan in _loans) {
      final type =
          _value(loan, ['type']).toLowerCase();

      if (type == 'receivable') {
        total += _loanRemaining(loan);
      }
    }

    return total;
  }

  double get _totalPayable {
    double total = 0;

    for (final loan in _loans) {
      final type =
          _value(loan, ['type']).toLowerCase();

      if (type == 'payable') {
        total += _loanRemaining(loan);
      }
    }

    return total;
  }

  double _loanRemaining(Map<String, dynamic> loan) {
    final remaining = loan['remaining'];

    if (remaining != null) {
      return _toDouble(remaining);
    }

    return _toDouble(
      loan['amount'],
    );
  }

  String _loanPerson(
    Map<String, dynamic> loan,
  ) {
    return _value(
      loan,
      [
        'person',
        'person_name',
        'name',
        'party',
        'customer',
      ],
    );
  }

  // =========================================================
  // CURRENT OUTSTANDING PERSON SUMMARY
  // =========================================================

  Map<String, double> _buildOutstandingByPerson(
    String type,
  ) {
    final result = <String, double>{};

    for (final loan in _loans) {
      final loanType =
          _value(loan, ['type']).toLowerCase();

      if (loanType != type) {
        continue;
      }

      final person =
          _loanPerson(loan).trim().isEmpty
              ? 'নাম নেই'
              : _loanPerson(loan).trim();

      final amount = _loanRemaining(loan);

      if (amount <= 0) {
        continue;
      }

      result[person] =
          (result[person] ?? 0) + amount;
    }

    return result;
  }

  Map<String, double> get _receivableByPerson {
    return _buildOutstandingByPerson(
      'receivable',
    );
  }

  Map<String, double> get _payableByPerson {
    return _buildOutstandingByPerson(
      'payable',
    );
  }

  // =========================================================
  // CATEGORY HELPERS
  // =========================================================

  String _categoryName(
    Map<String, dynamic> data,
  ) {
    return _value(
      data,
      [
        'category',
        'category_name',
        'name',
      ],
    );
  }

  double _categoryAmount(
    Map<String, dynamic> data,
  ) {
    return _toDouble(
      data['total'] ??
          data['amount'] ??
          data['sum'],
    );
  }

  // =========================================================
  // MAIN REPORT CAPTURE
  // =========================================================

  Future<Uint8List?> _captureReport() async {
    return _screenshotController.captureFromLongWidget(
      _buildExportReport(),
      delay: const Duration(
        milliseconds: 100,
      ),
      context: context,
    );
  }

  Future<File?> _createJpgFile(
    Uint8List bytes,
    String prefix,
  ) async {
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return null;
    }

    final jpgBytes = img.encodeJpg(
      decoded,
      quality: 95,
    );

    final directory =
        await getTemporaryDirectory();

    final file = File(
      '${directory.path}/'
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await file.writeAsBytes(jpgBytes);

    return file;
  }

  Future<void> _saveJpg() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final bytes = await _captureReport();

      if (bytes == null) {
        throw Exception('ছবি তৈরি করা যায়নি');
      }

      final file = await _createJpgFile(
        bytes,
        'amar_hisab_report',
      );

      if (file == null) {
        throw Exception('JPG তৈরি করা যায়নি');
      }

      await GallerySaver.saveImage(
        file.path,
        albumName: 'আমার হিসাব',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'রিপোর্ট JPG হিসেবে Gallery-তে সংরক্ষণ হয়েছে',
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

  Future<void> _shareReport() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final bytes = await _captureReport();

      if (bytes == null) {
        throw Exception('ছবি তৈরি করা যায়নি');
      }

      final file = await _createJpgFile(
        bytes,
        'amar_hisab_report_share',
      );

      if (file == null) {
        throw Exception('JPG তৈরি করা যায়নি');
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text:
              'আমার হিসাব - $_periodTitle\n'
              '${_dateText(_startDate)} - '
              '${_dateText(_endDate)}',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'রিপোর্ট শেয়ার করা যায়নি: $e',
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

  // =========================================================
  // PDF
  // =========================================================

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

  Future<void> _savePdf() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final font = await _loadPdfFont();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: font,
          ),
          footer: (context) {
            return _pdfFooter(
              context,
              font,
            );
          },
          build: (context) {
            return [
              _buildPdfOverview(font),
            ];
          },
        ),
      );

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/'
        'amar_hisab_report_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      await file.writeAsBytes(
        await pdf.save(),
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text:
              'আমার হিসাব - $_periodTitle PDF রিপোর্ট',
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

  pw.Widget _pdfFooter(
    pw.Context context,
    pw.Font font,
  ) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(
        top: 12,
      ),
      child: pw.Text(
        'আমার হিসাব অ্যাপ • '
        'Developed by Sayeed Mahadi • '
        'mahadisayeed@gmail.com • '
        'পৃষ্ঠা ${context.pageNumber}/${context.pagesCount}',
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          color: PdfColors.grey700,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // =========================================================
  // MAIN REPORT PDF
  // =========================================================

  pw.Widget _buildPdfOverview(
    pw.Font font,
  ) {
    return pw.Column(
      crossAxisAlignment:
          pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            'আমার হিসাব',
            style: pw.TextStyle(
              font: font,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),

        pw.SizedBox(height: 5),

        pw.Center(
          child: pw.Text(
            _periodTitle,
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
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
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ),

        pw.SizedBox(height: 18),

        _pdfSummaryTable(font),

        pw.SizedBox(height: 18),

        _pdfCategorySection(
          font,
          'আয়ের খাত',
          _incomeCategories,
        ),

        pw.SizedBox(height: 14),

        _pdfCategorySection(
          font,
          'ব্যয়ের খাত',
          _expenseCategories,
        ),

        pw.SizedBox(height: 18),

        _pdfLoanReport(font),
      ],
    );
  }

  pw.Widget _pdfSummaryTable(
    pw.Font font,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey400,
      ),
      children: [
        pw.TableRow(
          children: [
            _pdfCell(
              'মোট আয়',
              font,
              bold: true,
            ),
            _pdfCell(
              _money(_income),
              font,
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _pdfCell(
              'মোট ব্যয়',
              font,
              bold: true,
            ),
            _pdfCell(
              _money(_expense),
              font,
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _pdfCell(
              _isSurplus
                  ? 'উদ্বৃত্ত'
                  : 'ঘাটতি',
              font,
              bold: true,
            ),
            _pdfCell(
              _money(_difference.abs()),
              font,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfCell(
    String text,
    pw.Font font, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          fontWeight: bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _pdfCategorySection(
    pw.Font font,
    String title,
    List<Map<String, dynamic>> categories,
  ) {
    if (categories.isEmpty) {
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
          pw.SizedBox(height: 5),
          pw.Text(
            'কোনো তথ্য নেই',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
            ),
          ),
        ],
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
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey400,
          ),
          children: [
            pw.TableRow(
              children: [
                _pdfCell(
                  'খাত',
                  font,
                  bold: true,
                ),
                _pdfCell(
                  'পরিমাণ',
                  font,
                  bold: true,
                ),
              ],
            ),
            ...categories.map(
              (item) {
                return pw.TableRow(
                  children: [
                    _pdfCell(
                      _categoryName(item),
                      font,
                    ),
                    _pdfCell(
                      _money(
                        _categoryAmount(item),
                      ),
                      font,
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

  pw.Widget _pdfLoanReport(
    pw.Font font,
  ) {
    final receivable =
        _receivableByPerson.entries.toList();

    final payable =
        _payableByPerson.entries.toList();

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

        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey400,
          ),
          children: [
            pw.TableRow(
              children: [
                _pdfCell(
                  'দিয়েছি',
                  font,
                  bold: true,
                ),
                _pdfCell(
                  'নিয়েছি',
                  font,
                  bold: true,
                ),
                _pdfCell(
                  'ফেরত পেয়েছি',
                  font,
                  bold: true,
                ),
                _pdfCell(
                  'পরিশোধ করেছি',
                  font,
                  bold: true,
                ),
              ],
            ),
            pw.TableRow(
              children: [
                _pdfCell(
                  _money(_loanGivenPeriod),
                  font,
                ),
                _pdfCell(
                  _money(_loanTakenPeriod),
                  font,
                ),
                _pdfCell(
                  _money(_loanReceivedPeriod),
                  font,
                ),
                _pdfCell(
                  _money(_loanPaidPeriod),
                  font,
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 10),

        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey400,
          ),
          children: [
            pw.TableRow(
              children: [
                _pdfCell(
                  'আমি পাব',
                  font,
                  bold: true,
                ),
                _pdfCell(
                  'আমার কাছে পাবে',
                  font,
                  bold: true,
                ),
              ],
            ),
            pw.TableRow(
              children: [
                _pdfCell(
                  _money(_totalReceivable),
                  font,
                ),
                _pdfCell(
                  _money(_totalPayable),
                  font,
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 10),

        if (receivable.isNotEmpty)
          _pdfOutstandingTable(
            font,
            'আমি পাব',
            receivable,
          ),

        if (receivable.isNotEmpty &&
            payable.isNotEmpty)
          pw.SizedBox(height: 10),

        if (payable.isNotEmpty)
          _pdfOutstandingTable(
            font,
            'আমার কাছে পাবে',
            payable,
          ),

        if (receivable.isEmpty &&
            payable.isEmpty)
          pw.Text(
            'বর্তমানে কোনো বকেয়া Loan নেই।',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
            ),
          ),
      ],
    );
  }

  pw.Widget _pdfOutstandingTable(
    pw.Font font,
    String title,
    List<MapEntry<String, double>> items,
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
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey400,
          ),
          children: [
            pw.TableRow(
              children: [
                _pdfCell(
                  'ব্যক্তি',
                  font,
                  bold: true,
                ),
                _pdfCell(
                  'বকেয়া',
                  font,
                  bold: true,
                ),
              ],
            ),
            ...items.map(
              (entry) {
                return pw.TableRow(
                  children: [
                    _pdfCell(
                      entry.key,
                      font,
                    ),
                    _pdfCell(
                      _money(entry.value),
                      font,
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

  // =========================================================
  // MAIN REPORT WIDGET
  // =========================================================

  Widget _buildExportReport() {
    return Material(
      color: Colors.white,
      child: Container(
        width: 850,
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: _buildReportContent(
          exportMode: true,
        ),
      ),
    );
  }

  Widget _buildReportContent({
    bool exportMode = false,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _buildReportHeader(
          exportMode: exportMode,
        ),

        const SizedBox(height: 16),

        _buildSummaryCards(
          exportMode: exportMode,
        ),

        const SizedBox(height: 16),

        _buildCategorySection(
          title: 'আয়ের খাত',
          categories: _incomeCategories,
          icon: Icons.arrow_downward_rounded,
          color: _incomeColor,
          exportMode: exportMode,
        ),

        const SizedBox(height: 12),

        _buildCategorySection(
          title: 'ব্যয়ের খাত',
          categories: _expenseCategories,
          icon: Icons.arrow_upward_rounded,
          color: _expenseColor,
          exportMode: exportMode,
        ),

        const SizedBox(height: 16),

        _buildLoanSection(
          exportMode: exportMode,
        ),

        const SizedBox(height: 18),

        _buildReportFooter(),
      ],
    );
  }

  Widget _buildReportHeader({
    bool exportMode = false,
  }) {
    return Container(
      padding: EdgeInsets.all(
        exportMode ? 18 : 16,
      ),
      decoration: BoxDecoration(
        color: _darkGreen,
        borderRadius: BorderRadius.circular(
          exportMode ? 16 : 18,
        ),
        border: Border.all(
          color: _gold.withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _goldLight,
              fontSize: exportMode ? 16 : 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'আমার হিসাব',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: exportMode ? 24 : 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _periodTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.9,
              ),
              fontSize: exportMode ? 13 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            '${_dateText(_startDate)} - '
            '${_dateText(_endDate)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _goldLight,
              fontSize: exportMode ? 11 : 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    bool exportMode = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'মোট আয়',
            amount: _income,
            icon: Icons.arrow_downward_rounded,
            color: _incomeColor,
            exportMode: exportMode,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _summaryCard(
            title: 'মোট ব্যয়',
            amount: _expense,
            icon: Icons.arrow_upward_rounded,
            color: _expenseColor,
            exportMode: exportMode,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _summaryCard(
            title: _isSurplus
                ? 'উদ্বৃত্ত'
                : 'ঘাটতি',
            amount: _difference.abs(),
            icon: _isSurplus
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: _isSurplus
                ? _incomeColor
                : _expenseColor,
            exportMode: exportMode,
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
    bool exportMode = false,
  }) {
    return Container(
      padding: EdgeInsets.all(
        exportMode ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(
          exportMode ? 12 : 14,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: exportMode ? 21 : 20,
          ),

          const SizedBox(height: 4),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: exportMode ? 10 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          FittedBox(
            child: Text(
              _money(amount),
              style: TextStyle(
                color: color,
                fontSize: exportMode ? 15 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required List<Map<String, dynamic>> categories,
    required IconData icon,
    required Color color,
    bool exportMode = false,
  }) {
    return Container(
      padding: EdgeInsets.all(
        exportMode ? 13 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(
          exportMode ? 12 : 14,
        ),
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
                icon,
                color: color,
                size: exportMode ? 19 : 20,
              ),

              const SizedBox(width: 7),

              Text(
                title,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: exportMode ? 13 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (categories.isEmpty)
            Text(
              'কোনো তথ্য নেই',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            )
          else
            ...categories.map(
              (item) {
                final name =
                    _categoryName(item);

                final amount =
                    _categoryAmount(item);

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 3,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty
                              ? 'অন্যান্য'
                              : name,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        _money(amount),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
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

  // =========================================================
  // LOAN UI
  // =========================================================

  Widget _buildLoanSection({
    bool exportMode = false,
  }) {
    final receivable =
        _receivableByPerson.entries.toList();

    final payable =
        _payableByPerson.entries.toList();

    return Container(
      padding: EdgeInsets.all(
        exportMode ? 14 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(
          exportMode ? 14 : 16,
        ),
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
                Icons.account_balance_wallet_rounded,
                color: _gold,
                size: exportMode ? 20 : 21,
              ),
              const SizedBox(width: 7),
              Text(
                'ব্যক্তিগত Loan',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: exportMode ? 14 : 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _buildLoanPeriodGrid(
            exportMode: exportMode,
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _outstandingTotalCard(
                  title: 'আমি পাব',
                  amount: _totalReceivable,
                  color: _loanReceiveColor,
                  icon:
                      Icons.call_received_rounded,
                  exportMode: exportMode,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _outstandingTotalCard(
                  title: 'আমার কাছে পাবে',
                  amount: _totalPayable,
                  color: _loanPaidColor,
                  icon:
                      Icons.call_made_rounded,
                  exportMode: exportMode,
                ),
              ),
            ],
          ),

          if (receivable.isNotEmpty) ...[
            const SizedBox(height: 10),
            _personOutstandingList(
              title: 'আমি পাব',
              entries: receivable,
              color: _loanReceiveColor,
              exportMode: exportMode,
            ),
          ],

          if (payable.isNotEmpty) ...[
            const SizedBox(height: 10),
            _personOutstandingList(
              title: 'আমার কাছে পাবে',
              entries: payable,
              color: _loanPaidColor,
              exportMode: exportMode,
            ),
          ],

          if (receivable.isEmpty &&
              payable.isEmpty) ...[
            const SizedBox(height: 9),
            Text(
              'বর্তমানে কোনো বকেয়া Loan নেই।',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoanPeriodGrid({
    bool exportMode = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: _loanSmallCard(
            title: 'দিয়েছি',
            amount: _loanGivenPeriod,
            color: _loanGiveColor,
            exportMode: exportMode,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _loanSmallCard(
            title: 'নিয়েছি',
            amount: _loanTakenPeriod,
            color: _loanTakeColor,
            exportMode: exportMode,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _loanSmallCard(
            title: 'ফেরত পেয়েছি',
            amount: _loanReceivedPeriod,
            color: _loanReceiveColor,
            exportMode: exportMode,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _loanSmallCard(
            title: 'পরিশোধ',
            amount: _loanPaidPeriod,
            color: _loanPaidColor,
            exportMode: exportMode,
          ),
        ),
      ],
    );
  }

  Widget _loanSmallCard({
    required String title,
    required double amount,
    required Color color,
    bool exportMode = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: exportMode ? 5 : 5,
        vertical: exportMode ? 8 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          9,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black87,
              fontSize: exportMode ? 8 : 8,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            child: Text(
              _money(amount),
              style: TextStyle(
                color: color,
                fontSize: exportMode ? 10 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outstandingTotalCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    bool exportMode = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.09,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: exportMode ? 18 : 19,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _money(amount),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personOutstandingList({
    required String title,
    required List<MapEntry<String, double>> entries,
    required Color color,
    bool exportMode = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          10,
        ),
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
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: exportMode ? 11 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          ...entries.map(
            (entry) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 2.5,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      _money(entry.value),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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

  Widget _buildReportFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          color: _gold.withValues(
            alpha: 0.30,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'আমার হিসাব অ্যাপ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Developed by Sayeed Mahadi • '
          'mahadisayeed@gmail.com',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black45,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD SCREEN
  // =========================================================

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
            onPressed:
                _loading ? null : _loadReport,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'pdf') {
                _savePdf();
              } else if (value == 'jpg') {
                _saveJpg();
              } else if (value == 'share') {
                _shareReport();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading:
                        Icon(Icons.picture_as_pdf),
                    title: Text('PDF সংরক্ষণ / শেয়ার'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'jpg',
                  child: ListTile(
                    leading:
                        Icon(Icons.image_rounded),
                    title: Text('JPG হিসেবে Gallery-তে রাখুন'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading:
                        Icon(Icons.share_rounded),
                    title: Text('রিপোর্ট শেয়ার করুন'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReport,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  14,
                  14,
                  14,
                  30,
                ),
                children: [
                  _buildPeriodSelector(),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(18),
                      child: Container(
                        padding:
                            const EdgeInsets.all(12),
                        color: Colors.white,
                        child:
                            _buildReportContent(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =================================================
                  // TRANSACTION DETAILS BUTTON
                  // =================================================

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TransactionDetailsScreen(
                              transactions:
                                  _transactions,
                              startDate:
                                  _startDate,
                              endDate:
                                  _endDate,
                              periodTitle:
                                  _periodTitle,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.receipt_long_rounded,
                      ),
                      label: const Text(
                        'লেনদেনের বিস্তারিত',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            _darkGreen,
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (_saving)
                    const Padding(
                      padding:
                          EdgeInsets.only(top: 8),
                      child:
                          LinearProgressIndicator(),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'রিপোর্টের সময় নির্বাচন করুন',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _period == 'custom'
                ? null
                : _period,
            decoration: InputDecoration(
              labelText: 'সময়কাল',
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'weekly',
                child: Text(
                  'সাপ্তাহিক',
                ),
              ),
              DropdownMenuItem(
                value: 'monthly',
                child: Text(
                  'মাসিক',
                ),
              ),
              DropdownMenuItem(
                value: 'yearly',
                child: Text(
                  'বার্ষিক',
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _changePeriod(value);
              }
            },
          ),

          const SizedBox(height: 9),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickCustomDate,
              icon: const Icon(
                Icons.date_range_rounded,
              ),
              label: Text(
                _period == 'custom'
                    ? '${_dateText(_startDate)} - '
                        '${_dateText(_endDate)}'
                    : 'Custom Date নির্বাচন করুন',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TRANSACTION DETAILS SCREEN
// ============================================================================

class TransactionDetailsScreen
    extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
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
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends State<TransactionDetailsScreen> {
  final ScreenshotController
      _screenshotController =
      ScreenshotController();

  bool _saving = false;

  final Color _darkGreen =
      const Color(0xFF0F5132);

  final Color _gold =
      const Color(0xFFC9A45C);

  final Color _incomeColor =
      const Color(0xFF35B77A);

  final Color _expenseColor =
      const Color(0xFFE56B6F);

  // =========================================================
  // HELPERS
  // =========================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().replaceAll(',', '').trim() ?? '',
        ) ??
        0;
  }

  String _value(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }

  String _money(double value) {
    final text = value.abs() ==
            value.abs().roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    return '৳$text';
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(
          value,
        );
      } catch (_) {}
    }

    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return DateTime.now();
    }

    final parsed = DateTime.tryParse(text);

    if (parsed != null) {
      return parsed;
    }

    final parts = text.split(
      RegExp(r'[-/]'),
    );

    if (parts.length == 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);

      if (a != null &&
          b != null &&
          c != null) {
        if (a > 31) {
          return DateTime(a, b, c);
        }

        return DateTime(c, b, a);
      }
    }

    return DateTime.now();
  }

  String _dateText(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');

    return '$d/$m/${date.year}';
  }

  String _transactionTypeText(
    String type,
  ) {
    switch (type.toLowerCase()) {
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
        return 'ধার পরিশোধ';

      default:
        return type.isEmpty
            ? 'লেনদেন'
            : type;
    }
  }

  Color _transactionColor(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'income':
        return _incomeColor;

      case 'expense':
        return _expenseColor;

      case 'loan_given':
        return const Color(0xFF4CAF50);

      case 'loan_taken':
        return const Color(0xFFFFA726);

      case 'loan_received':
        return const Color(0xFF42A5F5);

      case 'loan_paid':
        return const Color(0xFFAB47BC);

      case 'transfer':
        return const Color(0xFF607D8B);

      default:
        return _darkGreen;
    }
  }

  IconData _transactionIcon(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'income':
        return Icons.arrow_downward_rounded;

      case 'expense':
        return Icons.arrow_upward_rounded;

      case 'transfer':
        return Icons.swap_horiz_rounded;

      case 'loan_given':
        return Icons.call_made_rounded;

      case 'loan_taken':
        return Icons.call_received_rounded;

      case 'loan_received':
        return Icons.keyboard_double_arrow_down_rounded;

      case 'loan_paid':
        return Icons.keyboard_double_arrow_up_rounded;

      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _accountName(
    Map<String, dynamic> tx,
  ) {
    return _value(
      tx,
      [
        'account',
        'account_name',
        'source_account',
      ],
    );
  }

  String _categoryName(
    Map<String, dynamic> tx,
  ) {
    return _value(
      tx,
      [
        'category',
        'category_name',
      ],
    );
  }

  String _personName(
    Map<String, dynamic> tx,
  ) {
    return _value(
      tx,
      [
        'person',
        'person_name',
        'party',
        'customer',
        'name',
      ],
    );
  }

  String _noteText(
    Map<String, dynamic> tx,
  ) {
    return _value(
      tx,
      [
        'note',
        'details',
        'description',
        'remark',
      ],
    );
  }

  String _fromAccount(
    Map<String, dynamic> tx,
  ) {
    return _value(
      tx,
      [
        'fromAccount',
        'from_account',
        'sourceAccount',
        'source_account',
      ],
    );
  }

  String _toAccount(
    Map<String, dynamic> tx,
  ) {
    return _value(
      tx,
      [
        'toAccount',
        'to_account',
        'destinationAccount',
        'destination_account',
      ],
    );
  }

  // =========================================================
  // CAPTURE
  // =========================================================

  Widget _buildExportWidget() {
    return Material(
      color: Colors.white,
      child: Container(
        width: 850,
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            _buildExportHeader(),

            const SizedBox(height: 14),

            ...widget.transactions.map(
              (tx) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                child: _buildTransactionCard(
                  tx,
                  exportMode: true,
                ),
              ),
            ),

            if (widget.transactions.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.all(30),
                child: Text(
                  'এই সময়ের মধ্যে কোনো লেনদেন নেই।',
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 15),

            const Divider(),

            const SizedBox(height: 5),

            const Text(
              'আমার হিসাব অ্যাপ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 2),

            const Text(
              'Developed by Sayeed Mahadi • '
              'mahadisayeed@gmail.com',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black45,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _darkGreen,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
            style: TextStyle(
              color: Color(0xFFE4C987),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'আমার হিসাব',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'লেনদেনের বিস্তারিত',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            widget.periodTitle,
            style: const TextStyle(
              color: Color(0xFFE4C987),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            '${_dateText(widget.startDate)} - '
            '${_dateText(widget.endDate)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _captureTransactions() async {
    return _screenshotController
        .captureFromLongWidget(
      _buildExportWidget(),
      delay: const Duration(
        milliseconds: 100,
      ),
      context: context,
    );
  }

  Future<File?> _createJpgFile(
    Uint8List bytes,
    String prefix,
  ) async {
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return null;
    }

    final jpgBytes = img.encodeJpg(
      decoded,
      quality: 95,
    );

    final directory =
        await getTemporaryDirectory();

    final file = File(
      '${directory.path}/'
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await file.writeAsBytes(jpgBytes);

    return file;
  }

  Future<void> _saveJpg() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final bytes =
          await _captureTransactions();

      if (bytes == null) {
        throw Exception(
          'ছবি তৈরি করা যায়নি',
        );
      }

      final file = await _createJpgFile(
        bytes,
        'amar_hisab_transactions',
      );

      if (file == null) {
        throw Exception(
          'JPG তৈরি করা যায়নি',
        );
      }

      await GallerySaver.saveImage(
        file.path,
        albumName: 'আমার হিসাব',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'লেনদেনের বিস্তারিত JPG হিসেবে Gallery-তে সংরক্ষণ হয়েছে',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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

  Future<void> _shareTransactions() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final bytes =
          await _captureTransactions();

      if (bytes == null) {
        throw Exception(
          'ছবি তৈরি করা যায়নি',
        );
      }

      final file = await _createJpgFile(
        bytes,
        'amar_hisab_transactions_share',
      );

      if (file == null) {
        throw Exception(
          'JPG তৈরি করা যায়নি',
        );
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text:
              'আমার হিসাব - লেনদেনের বিস্তারিত\n'
              '${widget.periodTitle}',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'শেয়ার করা যায়নি: $e',
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

  // =========================================================
  // TRANSACTION PDF
  // =========================================================

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

  Future<void> _savePdf() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final font = await _loadPdfFont();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: font,
          ),
          footer: (context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin:
                  const pw.EdgeInsets.only(
                top: 10,
              ),
              child: pw.Text(
                'আমার হিসাব অ্যাপ • '
                'Developed by Sayeed Mahadi • '
                'mahadisayeed@gmail.com • '
                'পৃষ্ঠা ${context.pageNumber}/${context.pagesCount}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
                textAlign:
                    pw.TextAlign.center,
              ),
            );
          },
          build: (context) {
            return [
              _pdfTransactionHeader(font),

              pw.SizedBox(height: 15),

              if (widget.transactions.isEmpty)
                pw.Center(
                  child: pw.Text(
                    'এই সময়ের মধ্যে কোনো লেনদেন নেই।',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 11,
                    ),
                  ),
                ),

              ...widget.transactions.map(
                (tx) {
                  return _pdfTransaction(
                    tx,
                    font,
                  );
                },
              ),
            ];
          },
        ),
      );

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/'
        'amar_hisab_transactions_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      await file.writeAsBytes(
        await pdf.save(),
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
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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

  pw.Widget _pdfTransactionHeader(
    pw.Font font,
  ) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'আমার হিসাব',
            style: pw.TextStyle(
              font: font,
              fontSize: 21,
              fontWeight:
                  pw.FontWeight.bold,
            ),
          ),
        ),

        pw.SizedBox(height: 4),

        pw.Center(
          child: pw.Text(
            'লেনদেনের বিস্তারিত',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight:
                  pw.FontWeight.bold,
            ),
          ),
        ),

        pw.SizedBox(height: 3),

        pw.Center(
          child: pw.Text(
            widget.periodTitle,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
            ),
          ),
        ),

        pw.Center(
          child: pw.Text(
            '${_dateText(widget.startDate)} - '
            '${_dateText(widget.endDate)}',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfTransaction(
    Map<String, dynamic> tx,
    pw.Font font,
  ) {
    final type =
        _value(tx, ['type']);

    final date =
        _parseDate(
      tx['date'] ??
          tx['transaction_date'] ??
          tx['created_at'],
    );

    final amount =
        _toDouble(tx['amount']);

    final category =
        _categoryName(tx);

    final account =
        _accountName(tx);

    final person =
        _personName(tx);

    final note =
        _noteText(tx);

    final from =
        _fromAccount(tx);

    final to =
        _toAccount(tx);

    return pw.Container(
      margin:
          const pw.EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius:
            pw.BorderRadius.circular(7),
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
                _transactionTypeText(type),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _money(amount),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 4),

          pw.Text(
            'তারিখ: ${_dateText(date)}',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
            ),
          ),

          if (category.isNotEmpty)
            pw.Text(
              'খাত: $category',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
              ),
            ),

          if (account.isNotEmpty)
            pw.Text(
              'অ্যাকাউন্ট: $account',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
              ),
            ),

          if (person.isNotEmpty)
            pw.Text(
              'ব্যক্তি: $person',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
              ),
            ),

          if (from.isNotEmpty ||
              to.isNotEmpty)
            pw.Text(
              'ট্রান্সফার: '
              '${from.isEmpty ? '-' : from}'
              ' → '
              '${to.isEmpty ? '-' : to}',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
              ),
            ),

          if (note.isNotEmpty)
            pw.Text(
              'বিবরণ: $note',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // TRANSACTION CARD
  // =========================================================

  Widget _buildTransactionCard(
    Map<String, dynamic> tx, {
    bool exportMode = false,
  }) {
    final type =
        _value(tx, ['type']);

    final date =
        _parseDate(
      tx['date'] ??
          tx['transaction_date'] ??
          tx['created_at'],
    );

    final amount =
        _toDouble(tx['amount']);

    final color =
        _transactionColor(type);

    final icon =
        _transactionIcon(type);

    final category =
        _categoryName(tx);

    final account =
        _accountName(tx);

    final person =
        _personName(tx);

    final note =
        _noteText(tx);

    final from =
        _fromAccount(tx);

    final to =
        _toAccount(tx);

    return Container(
      padding: EdgeInsets.all(
        exportMode ? 12 : 12,
      ),
      decoration: BoxDecoration(
        color: exportMode
            ? Colors.white
            : Colors.white,
        borderRadius:
            BorderRadius.circular(
          exportMode ? 12 : 14,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.22,
          ),
        ),
        boxShadow: exportMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black
                      .withValues(
                    alpha: 0.04,
                  ),
                  blurRadius: 8,
                  offset:
                      const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:
                    exportMode ? 38 : 40,
                height:
                    exportMode ? 38 : 40,
                decoration:
                    BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size:
                      exportMode ? 20 : 21,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      _transactionTypeText(
                        type,
                      ),
                      style: TextStyle(
                        color: color,
                        fontSize:
                            exportMode
                                ? 12
                                : 13,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      _dateText(date),
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                _money(amount),
                style: TextStyle(
                  color: color,
                  fontSize:
                      exportMode ? 13 : 14,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          if (category.isNotEmpty ||
              account.isNotEmpty ||
              person.isNotEmpty ||
              note.isNotEmpty ||
              from.isNotEmpty ||
              to.isNotEmpty)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 7,
              ),
              child: Divider(
                height: 1,
              ),
            ),

          if (category.isNotEmpty)
            _detailRow(
              'খাত',
              category,
              exportMode,
            ),

          if (account.isNotEmpty)
            _detailRow(
              'অ্যাকাউন্ট',
              account,
              exportMode,
            ),

          if (person.isNotEmpty)
            _detailRow(
              'ব্যক্তি',
              person,
              exportMode,
            ),

          if (from.isNotEmpty ||
              to.isNotEmpty)
            _detailRow(
              'ট্রান্সফার',
              '${from.isEmpty ? '-' : from}'
              ' → '
              '${to.isEmpty ? '-' : to}',
              exportMode,
            ),

          if (note.isNotEmpty)
            _detailRow(
              'বিবরণ',
              note,
              exportMode,
            ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    bool exportMode,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 2.5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: exportMode ? 65 : 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SCREEN BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'লেনদেনের বিস্তারিত',
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'jpg') {
                _saveJpg();
              } else if (value == 'pdf') {
                _savePdf();
              } else if (value == 'share') {
                _shareTransactions();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'jpg',
                  child: ListTile(
                    leading:
                        Icon(Icons.image_rounded),
                    title: Text(
                      'JPG হিসেবে Gallery-তে রাখুন',
                    ),
                    contentPadding:
                        EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading:
                        Icon(Icons.picture_as_pdf),
                    title: Text(
                      'PDF সংরক্ষণ / শেয়ার',
                    ),
                    contentPadding:
                        EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading:
                        Icon(Icons.share_rounded),
                    title: Text(
                      'ছবি শেয়ার করুন',
                    ),
                    contentPadding:
                        EdgeInsets.zero,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding:
                const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              30,
            ),
            children: [
              _buildDetailsHeader(),

              const SizedBox(height: 12),

              if (widget.transactions.isEmpty)
                Container(
                  padding:
                      const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    border: Border.all(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color:
                            Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'এই সময়ের মধ্যে কোনো লেনদেন নেই।',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...widget.transactions.map(
                  (tx) => Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 9,
                    ),
                    child:
                        _buildTransactionCard(
                      tx,
                    ),
                  ),
                ),

              if (_saving)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    top: 8,
                  ),
                  child:
                      LinearProgressIndicator(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkGreen,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: _gold.withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
            style: TextStyle(
              color: Color(0xFFE4C987),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'লেনদেনের বিস্তারিত',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            widget.periodTitle,
            style: const TextStyle(
              color: Color(0xFFE4C987),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            '${_dateText(widget.startDate)} - '
            '${_dateText(widget.endDate)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'মোট লেনদেন: '
            '${widget.transactions.length} টি',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
