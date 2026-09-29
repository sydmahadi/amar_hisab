
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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

  static const Color _green = Color(0xFF176B45);
  static const Color _gold = Color(0xFFC9A45C);
  static const Color _incomeColor = Color(0xFF287A55);
  static const Color _expenseColor = Color(0xFFC35E5E);

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (mounted) {
      setState(() => _loading = true);
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
      ]);

      if (!mounted) return;

      setState(() {
        _income = (results[0] as num).toDouble();
        _expense = (results[1] as num).toDouble();

        _transactions =
            List<Map<String, dynamic>>.from(results[2] as List);

        _incomeCategories =
            List<Map<String, dynamic>>.from(results[3] as List);

        _expenseCategories =
            List<Map<String, dynamic>>.from(results[4] as List);

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('রিপোর্ট লোড করা যায়নি: $e')),
      );
    }
  }

  void _changePeriod(String period) {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    switch (period) {
      case 'weekly':
        final today = DateTime(now.year, now.month, now.day);
        start = today.subtract(Duration(days: today.weekday - 1));
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
        end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        break;

      default:
        start = DateTime(now.year, now.month, 1);
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
        end: _endDate.isBefore(_startDate)
            ? _startDate
            : _endDate,
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

  String _money(double value) => '৳ ${value.toStringAsFixed(2)}';

  String _dateText(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;

    return DateTime.tryParse(value?.toString() ?? '') ??
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

  Future<Uint8List> _captureReport() async {
    return _screenshotController.captureFromWidget(
      Material(
        color: Colors.white,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: _buildVoucher(exportMode: true),
        ),
      ),
      delay: const Duration(milliseconds: 300),
      pixelRatio: 2,
    );
  }

  Future<void> _saveJpg() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final pngBytes = await _captureReport();
      final decoded = img.decodeImage(pngBytes);

      if (decoded == null) {
        throw Exception('রিপোর্টের ছবি তৈরি করা যায়নি।');
      }

      final jpgBytes = Uint8List.fromList(
        img.encodeJpg(decoded, quality: 95),
      );

      final directory = await getTemporaryDirectory();

      final file = File(
        '${directory.path}/amar_hisab_report_'
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(jpgBytes, flush: true);

      final result = await GallerySaver.saveImage(
        file.path,
        albumName: 'আমার হিসাব',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == true
                ? 'JPG রিপোর্ট Gallery-তে সংরক্ষণ হয়েছে।'
                : 'JPG সংরক্ষণ করা যায়নি।',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JPG সংরক্ষণে সমস্যা: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePdf() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final imageBytes = await _captureReport();

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          // PdfPageFormat belongs to package:pdf/pdf.dart.
          // It is intentionally NOT prefixed with pw.
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (context) => pw.Center(
            child: pw.Image(
              pdfImage,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      );

      final directory = await getTemporaryDirectory();

      final file = File(
        '${directory.path}/amar_hisab_report_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      await file.writeAsBytes(await pdf.save(), flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path, mimeType: 'application/pdf'),
          ],
          subject: 'আমার হিসাব - $_periodTitle',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF তৈরি করতে সমস্যা: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareReport() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final bytes = await _captureReport();
      final directory = await getTemporaryDirectory();

      final file = File(
        '${directory.path}/amar_hisab_report_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: 'আমার হিসাব - $_periodTitle',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('শেয়ার করতে সমস্যা: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showExportMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF হিসেবে তৈরি ও শেয়ার'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _savePdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('JPG হিসেবে Gallery-তে সংরক্ষণ'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _saveJpg();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('রিপোর্ট শেয়ার করুন'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareReport();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucher({bool exportMode = false}) {
    final double outerPadding = exportMode ? 24 : 14;

    return Container(
      width: exportMode ? 800 : double.infinity,
      color: exportMode ? Colors.white : Colors.transparent,
      padding: EdgeInsets.all(outerPadding),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _gold.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(exportMode ? 0 : 18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              color: _green,
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
                  const SizedBox(height: 6),
                  Text(
                    _periodTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_dateText(_startDate)} — ${_dateText(_endDate)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _summaryBox(
                          title: 'মোট আয়',
                          amount: _income,
                          color: _incomeColor,
                          icon: Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryBox(
                          title: 'মোট ব্যয়',
                          amount: _expense,
                          color: _expenseColor,
                          icon: Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isSurplus
                          ? const Color(0xFFE8F4ED)
                          : const Color(0xFFF9E9E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSurplus
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: _isSurplus
                              ? _incomeColor
                              : _expenseColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isSurplus ? 'উদ্বৃত্ত' : 'ঘাটি',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _money(_difference.abs()),
                          style: TextStyle(
                            color: _isSurplus
                                ? _incomeColor
                                : _expenseColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _sectionTitle('খাত অনুযায়ী আয়', Icons.account_balance_wallet),
            _categorySection(_incomeCategories, income: true),
            _sectionTitle('খাত অনুযায়ী ব্যয়', Icons.receipt_long),
            _categorySection(_expenseCategories, income: false),
            _sectionTitle('লেনদেনের বিবরণ', Icons.list_alt),
            _transactionSection(),
            Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.only(top: 14),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE4DCCB)),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    'আমার হিসাব অ্যাপ',
                    style: TextStyle(
                      color: Color(0x66888888),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'mahadisayeed@gmail.com',
                    style: TextStyle(
                      color: Color(0x44888888),
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
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF222222),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
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
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Text(
          'এই সময়ের মধ্যে কোনো তথ্য নেই।',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final double total = categories.fold<double>(
      0.0,
      (sum, item) =>
          sum + ((item['total'] as num?)?.toDouble() ?? 0.0),
    );

    final color = income ? _incomeColor : _expenseColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9E2D2)),
        ),
        child: Column(
          children: [
            for (final item in categories)
              Builder(
                builder: (context) {
                  final double value =
                      (item['total'] as num?)?.toDouble() ?? 0.0;

                  final double percentage = total <= 0
                      ? 0.0
                      : (value / total).clamp(0.0, 1.0).toDouble();

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['name']?.toString() ?? 'অন্যান্য',
                                style: const TextStyle(
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _money(value),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE7E3DA),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'সর্বমোট',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _money(total),
                    style: TextStyle(
                      color: color,
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
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Text(
          'এই সময়ের মধ্যে কোনো লেনদেন নেই।',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9E2D2)),
        ),
        child: Column(
          children: [
            for (final tx in _transactions) _transactionRow(tx),
          ],
        ),
      ),
    );
  }

  Widget _transactionRow(Map<String, dynamic> tx) {
    final type = tx['type']?.toString() ?? '';
    final double amount =
        (tx['amount'] as num?)?.toDouble() ?? 0.0;

    final date = _parseDate(tx['transaction_date']);
    final category = tx['category_name']?.toString() ?? '';
    final note = tx['note']?.toString() ?? '';
    final account = tx['account_name']?.toString() ?? '';
    final from = tx['from_account_name']?.toString() ?? '';
    final to = tx['to_account_name']?.toString() ?? '';

    final Color color;
    final IconData icon;

    if (type == 'income') {
      color = _incomeColor;
      icon = Icons.arrow_downward;
    } else if (type == 'expense') {
      color = _expenseColor;
      icon = Icons.arrow_upward;
    } else {
      color = _gold;
      icon = Icons.swap_horiz;
    }

    final String subtitle = type == 'transfer'
        ? '$from → $to'
        : [
            category,
            account,
            note.trim(),
          ].where((part) => part.isNotEmpty).join(' • ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFECE7DC)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _transactionType(type),
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _money(amount),
                      style: TextStyle(
                        color: color,
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
                    fontSize: 11,
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
                      fontSize: 11,
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

  Widget _periodButton(String label, String value) {
    final selected = _period == value;

    return OutlinedButton(
      onPressed: value == 'custom'
          ? _pickCustomDate
          : () => _changePeriod(value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? _green : null,
        foregroundColor: selected ? Colors.white : null,
        side: BorderSide(
          color: selected
              ? _green
              : Theme.of(context).colorScheme.outline,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'রিপোর্ট',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'রিপোর্ট Export',
            onPressed: _loading || _saving ? null : _showExportMenu,
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 30),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _periodButton('মাসিক', 'monthly'),
                          const SizedBox(width: 7),
                          _periodButton('সাপ্তাহিক', 'weekly'),
                          const SizedBox(width: 7),
                          _periodButton('বার্ষিক', 'yearly'),
                          const SizedBox(width: 7),
                          _periodButton('তারিখ নির্বাচন', 'custom'),
                        ],
                      ),
                    ),
                  ),
                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: LinearProgressIndicator(),
                    ),
                  Screenshot(
                    controller: _screenshotController,
                    child: _buildVoucher(),
                  ),
                ],
              ),
            ),
    );
  }
}
