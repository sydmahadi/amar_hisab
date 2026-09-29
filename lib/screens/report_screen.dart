import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  // ============================================================
  // LOAD REPORT
  // ============================================================

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

      final transactions =
          await MoneyDb.instance.getTransactions(
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
        _transactions = transactions;
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
          content: Text('রিপোর্ট লোড করা যায়নি: $e'),
        ),
      );
    }
  }

  // ============================================================
  // PERIOD
  // ============================================================

  void _changePeriod(String period) {
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    switch (period) {
      case 'weekly':
        final today =
            DateTime(now.year, now.month, now.day);

        final weekday = today.weekday;

        start = today.subtract(
          Duration(days: weekday - 1),
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
        start = DateTime(now.year, 1, 1);

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

    _loadReport();
  }

  // ============================================================
  // CALCULATIONS
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
      case 'monthly':
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
    if (value is DateTime) return value;

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
      default:
        return type;
    }
  }

  // ============================================================
  // SCREENSHOT
  // ============================================================

  Future<Uint8List> _captureReport() async {
    return _screenshotController.captureFromWidget(
      Material(
        color: Colors.white,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: _buildVoucher(
            exportMode: true,
          ),
        ),
      ),
      delay: const Duration(milliseconds: 250),
      pixelRatio: 2.5,
    );
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

      final fileName =
          'amar_hisab_report_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final file = File(
        '${directory.path}/$fileName',
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

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'JPG রিপোর্ট Gallery-তে সংরক্ষণ হয়েছে।',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'JPG সংরক্ষণ করা যায়নি।',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'JPG সংরক্ষণে সমস্যা: $e',
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
  // SAVE PDF
  // ============================================================

  Future<void> _savePdf() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final imageBytes = await _captureReport();

      final pdf = pw.Document();

      final pdfImage = pw.MemoryImage(
        imageBytes,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (context) {
            return pw.Center(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      final directory =
          await getTemporaryDirectory();

      final fileName =
          'amar_hisab_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(
        '${directory.path}/$fileName',
      );

      await file.writeAsBytes(
        await pdf.save(),
        flush: true,
      );

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'application/pdf',
          ),
        ],
        subject: 'আমার হিসাব - $_periodTitle',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF রিপোর্ট প্রস্তুত হয়েছে।',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF তৈরি করতে সমস্যা: $e',
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
  // SHARE
  // ============================================================

  Future<void> _shareReport() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final pngBytes = await _captureReport();

      final directory =
          await getTemporaryDirectory();

      final fileName =
          'amar_hisab_report_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(
        '${directory.path}/$fileName',
      );

      await file.writeAsBytes(
        pngBytes,
        flush: true,
      );

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'image/png',
          ),
        ],
        subject: 'আমার হিসাব - $_periodTitle',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'শেয়ার করতে সমস্যা: $e',
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
  // EXPORT MENU
  // ============================================================

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'রিপোর্ট সংরক্ষণ / শেয়ার',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.picture_as_pdf,
                    ),
                  ),
                  title: const Text(
                    'PDF হিসেবে সংরক্ষণ',
                  ),
                  subtitle: const Text(
                    'PDF তৈরি করে শেয়ার/সেভ করুন',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _savePdf();
                  },
                ),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.image,
                    ),
                  ),
                  title: const Text(
                    'JPG হিসেবে Gallery-তে সংরক্ষণ',
                  ),
                  subtitle: const Text(
                    'রিপোর্টের voucher JPG হিসেবে Save হবে',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _saveJpg();
                  },
                ),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.share,
                    ),
                  ),
                  title: const Text(
                    'রিপোর্ট শেয়ার করুন',
                  ),
                  subtitle: const Text(
                    'Messenger, WhatsApp ইত্যাদিতে পাঠান',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _shareReport();
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
  // VOUCHER
  // ============================================================

  Widget _buildVoucher({
    bool exportMode = false,
  }) {
    final theme = Theme.of(context);

    final background =
        exportMode ? Colors.white : theme.scaffoldBackgroundColor;

    final primary = const Color(0xFF176B45);
    final gold = const Color(0xFFB99550);

    return Container(
      width: exportMode ? 900 : double.infinity,
      color: background,
      padding: EdgeInsets.all(
        exportMode ? 34 : 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            exportMode ? 0 : 22,
          ),
          border: Border.all(
            color: gold.withOpacity(0.45),
            width: 1.4,
          ),
          boxShadow: exportMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(
                22,
                22,
                22,
                18,
              ),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    exportMode ? 0 : 22,
                  ),
                  topRight: Radius.circular(
                    exportMode ? 0 : 22,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'আমার হিসাব',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _periodTitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_dateText(_startDate)}  —  ${_dateText(_endDate)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SUMMARY
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _summaryBox(
                          title: 'মোট আয়',
                          amount: _income,
                          icon: Icons.arrow_downward,
                          color: const Color(0xFF287A55),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryBox(
                          title: 'মোট ব্যয়',
                          amount: _expense,
                          icon: Icons.arrow_upward,
                          color: const Color(0xFFC35E5E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: _isSurplus
                          ? const Color(0xFFE8F4ED)
                          : const Color(0xFFF9E9E9),
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: _isSurplus
                            ? const Color(0xFFB6DCC5)
                            : const Color(0xFFE8BABA),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSurplus
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: _isSurplus
                              ? const Color(0xFF287A55)
                              : const Color(0xFFC35E5E),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isSurplus
                                ? 'উদ্বৃত্ত'
                                : 'ঘাটি',
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _money(_difference.abs()),
                          style: TextStyle(
                            color: _isSurplus
                                ? const Color(0xFF287A55)
                                : const Color(0xFFC35E5E),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _sectionTitle(
              'খাত অনুযায়ী আয়',
              Icons.account_balance_wallet,
            ),

            _categorySection(
              _incomeCategories,
              income: true,
            ),

            _sectionTitle(
              'খাত অনুযায়ী ব্যয়',
              Icons.receipt_long,
            ),

            _categorySection(
              _expenseCategories,
              income: false,
            ),

            _sectionTitle(
              'লেনদেনের বিবরণ',
              Icons.list_alt,
            ),

            _transactionSection(),

            // FOOTER / WATERMARK
            Container(
              margin: const EdgeInsets.fromLTRB(
                18,
                20,
                18,
                20,
              ),
              padding: const EdgeInsets.only(
                top: 16,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE4DCCB),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'আমার হিসাব অ্যাপ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primary.withOpacity(0.28),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'mahadisayeed@gmail.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.20),
                      fontSize: 10,
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

  Widget _summaryBox({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.18),
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
                size: 17,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              _money(amount),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        3,
        18,
        10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFF176B45),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF222222),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySection(
    List<Map<String, dynamic>> categories, {
    required bool income,
  }) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          12,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'এই সময়ের মধ্যে কোনো তথ্য নেই।',
            style: TextStyle(
              color: Color(0xFF777777),
            ),
          ),
        ),
      );
    }

    final total = categories.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((item['total'] as num?)?.toDouble() ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE9E2D2),
          ),
        ),
        child: Column(
          children: [
            ...categories.map(
              (item) {
                final value =
                    (item['total'] as num?)
                            ?.toDouble() ??
                        0;

                final percentage =
                    total <= 0
                        ? 0
                        : value / total;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    11,
                    14,
                    4,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: income
                                  ? const Color(0xFF287A55)
                                  : const Color(0xFFC35E5E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              item['name']?.toString() ??
                                  'অন্যান্য',
                              style: const TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _money(value),
                            style: const TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 5,
                          backgroundColor:
                              const Color(0xFFE7E3DA),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            income
                                ? const Color(0xFF287A55)
                                : const Color(0xFFC35E5E),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                9,
                14,
                13,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'সর্বমোট',
                      style: TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    _money(total),
                    style: TextStyle(
                      color: income
                          ? const Color(0xFF287A55)
                          : const Color(0xFFC35E5E),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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

  Widget _transactionSection() {
    if (_transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          10,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'এই সময়ের মধ্যে কোনো লেনদেন নেই।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF777777),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE9E2D2),
          ),
        ),
        child: Column(
          children: _transactions
              .map(
                (tx) => _transactionRow(tx),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _transactionRow(
    Map<String, dynamic> tx,
  ) {
    final type =
        tx['type']?.toString() ?? '';

    final amount =
        (tx['amount'] as num?)?.toDouble() ?? 0;

    final date =
        _parseDate(tx['transaction_date']);

    final category =
        tx['category_name']?.toString();

    final note =
        tx['note']?.toString() ?? '';

    final account =
        tx['account_name']?.toString();

    final fromAccount =
        tx['from_account_name']?.toString();

    final toAccount =
        tx['to_account_name']?.toString();

    Color color;

    IconData icon;

    if (type == 'income') {
      color = const Color(0xFF287A55);
      icon = Icons.arrow_downward;
    } else if (type == 'expense') {
      color = const Color(0xFFC35E5E);
      icon = Icons.arrow_upward;
    } else {
      color = const Color(0xFFB99550);
      icon = Icons.swap_horiz;
    }

    String subtitle = '';

    if (type == 'transfer') {
      subtitle =
          '${fromAccount ?? '—'} → ${toAccount ?? '—'}';
    } else {
      final parts = <String>[];

      if (category != null &&
          category.isNotEmpty) {
        parts.add(category);
      }

      if (account != null &&
          account.isNotEmpty) {
        parts.add(account);
      }

      if (note.trim().isNotEmpty) {
        parts.add(note.trim());
      }

      subtitle = parts.join(' • ');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFECE7DC),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 17,
              color: color,
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
                        _transactionType(type),
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      _money(amount),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _dateText(date),
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 10,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 10.5,
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
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'রিপোর্ট',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Export',
            onPressed:
                _loading || _saving
                    ? null
                    : _showExportMenu,
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
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  bottom: 30,
                ),
                children: [
                  // PERIOD SELECTOR
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      10,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _periodButton(
                            'মাসিক',
                            'monthly',
                          ),
                          const SizedBox(width: 8),
                          _periodButton(
                            'সাপ্তাহিক',
                            'weekly',
                          ),
                          const SizedBox(width: 8),
                          _periodButton(
                            'বার্ষিক',
                            'yearly',
                          ),
                          const SizedBox(width: 8),
                          _periodButton(
                            'তারিখ নির্বাচন',
                            'custom',
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        10,
                      ),
                      child: LinearProgressIndicator(),
                    ),

                  // REPORT
                  Screenshot(
                    controller: _screenshotController,
                    child: _buildVoucher(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _periodButton(
    String label,
    String value,
  ) {
    final selected = _period == value;

    return OutlinedButton(
      onPressed: value == 'custom'
          ? _pickCustomDate
          : () => _changePeriod(value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? const Color(0xFF176B45)
            : null,
        foregroundColor: selected
            ? Colors.white
            : null,
        side: BorderSide(
          color: selected
              ? const Color(0xFF176B45)
              : Theme.of(context)
                  .colorScheme
                  .outline,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }
}
