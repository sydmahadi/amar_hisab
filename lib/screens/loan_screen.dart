import 'package:flutter/material.dart';

import '../services/money_db.dart';
import '../theme/app_theme.dart';
import 'add_transaction_screen.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  final MoneyDb _db = MoneyDb.instance;
  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, dynamic>> _loans = [];

  bool _loading = true;

  String _typeFilter = 'all';
  String _statusFilter = 'all';

  DateTime? _selectedDate;
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadLoans();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final loans = await _db.getLoans(
        type: _typeFilter == 'all' ? null : _typeFilter,
        activeOnly: _statusFilter == 'active',
      );

      final search = _searchController.text.trim().toLowerCase();

      List<Map<String, dynamic>> filtered = loans.where((loan) {
        if (search.isEmpty) {
          return true;
        }

        final person =
            (loan['person_name'] ?? '').toString().toLowerCase();

        final note =
            (loan['note'] ?? '').toString().toLowerCase();

        return person.contains(search) || note.contains(search);
      }).toList();

      if (_statusFilter == 'completed') {
        filtered = filtered.where((loan) {
          return _toDouble(loan['remaining']) <= 0;
        }).toList();
      }

      if (_selectedDate != null) {
        filtered = filtered.where((loan) {
          final date = _parseDate(loan['created_at']);

          if (date == null) {
            return false;
          }

          return date.year == _selectedDate!.year &&
              date.month == _selectedDate!.month &&
              date.day == _selectedDate!.day;
        }).toList();
      }

      if (_selectedMonth != null) {
        filtered = filtered.where((loan) {
          final date = _parseDate(loan['created_at']);

          if (date == null) {
            return false;
          }

          return date.year == _selectedMonth!.year &&
              date.month == _selectedMonth!.month;
        }).toList();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _loans = filtered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loans = [];
        _loading = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  String _money(double amount) {
    return amount.toStringAsFixed(2);
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _monthName(int month) {
    const months = [
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

    return months[month - 1];
  }

  String _filterLabel() {
    if (_selectedDate != null) {
      return 'তারিখ: ${_formatDate(_selectedDate)}';
    }

    if (_selectedMonth != null) {
      return 'মাস: ${_monthName(_selectedMonth!.month)} '
          '${_selectedMonth!.year}';
    }

    if (_statusFilter == 'active') {
      return 'চলমান';
    }

    if (_statusFilter == 'completed') {
      return 'সম্পন্ন';
    }

    if (_typeFilter == 'receivable') {
      return 'পাওনা';
    }

    if (_typeFilter == 'payable') {
      return 'দেনা';
    }

    return 'সব লোন';
  }

  bool get _hasFilter {
    return _typeFilter != 'all' ||
        _statusFilter != 'all' ||
        _selectedDate != null ||
        _selectedMonth != null;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'তারিখ নির্বাচন করুন',
    );

    if (date == null) {
      return;
    }

    setState(() {
      _selectedDate = date;
      _selectedMonth = null;
    });

    _loadLoans();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();

    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        int year = _selectedMonth?.year ?? now.year;
        int month = _selectedMonth?.month ?? now.month;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('মাস নির্বাচন করুন'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: year,
                    decoration: const InputDecoration(
                      labelText: 'বছর',
                    ),
                    items: List.generate(
                      21,
                      (index) {
                        final y = now.year - 10 + index;

                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text('$y'),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        year = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: month,
                    decoration: const InputDecoration(
                      labelText: 'মাস',
                    ),
                    items: List.generate(
                      12,
                      (index) {
                        final m = index + 1;

                        return DropdownMenuItem<int>(
                          value: m,
                          child: Text(_monthName(m)),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        month = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('বাতিল'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DateTime(year, month),
                    );
                  },
                  child: const Text('নির্বাচন'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedMonth = selected;
      _selectedDate = null;
    });

    _loadLoans();
  }

  void _clearFilters() {
    setState(() {
      _typeFilter = 'all';
      _statusFilter = 'all';
      _selectedDate = null;
      _selectedMonth = null;
    });

    _loadLoans();
  }

  Future<void> _showFilterMenu() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'লোন ফিল্টার',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ধরন',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _filterTile(
                    title: 'সব লোন',
                    selected: _typeFilter == 'all',
                    onTap: () {
                      setState(() {
                        _typeFilter = 'all';
                      });

                      Navigator.pop(context);
                      _loadLoans();
                    },
                  ),
                  _filterTile(
                    title: 'আমার পাওনা',
                    selected: _typeFilter == 'receivable',
                    onTap: () {
                      setState(() {
                        _typeFilter = 'receivable';
                      });

                      Navigator.pop(context);
                      _loadLoans();
                    },
                  ),
                  _filterTile(
                    title: 'আমার দেনা',
                    selected: _typeFilter == 'payable',
                    onTap: () {
                      setState(() {
                        _typeFilter = 'payable';
                      });

                      Navigator.pop(context);
                      _loadLoans();
                    },
                  ),
                  const Divider(height: 24),
                  const Text(
                    'অবস্থা',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _filterTile(
                    title: 'সব',
                    selected: _statusFilter == 'all',
                    onTap: () {
                      setState(() {
                        _statusFilter = 'all';
                      });

                      Navigator.pop(context);
                      _loadLoans();
                    },
                  ),
                  _filterTile(
                    title: 'চলমান',
                    selected: _statusFilter == 'active',
                    onTap: () {
                      setState(() {
                        _statusFilter = 'active';
                      });

                      Navigator.pop(context);
                      _loadLoans();
                    },
                  ),
                  _filterTile(
                    title: 'সম্পন্ন',
                    selected: _statusFilter == 'completed',
                    onTap: () {
                      setState(() {
                        _statusFilter = 'completed';
                      });

                      Navigator.pop(context);
                      _loadLoans();
                    },
                  ),
                  const Divider(height: 24),
                  const Text(
                    'তারিখ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_today_outlined,
                    ),
                    title: const Text(
                      'নির্দিষ্ট তারিখ',
                    ),
                    subtitle: _selectedDate == null
                        ? null
                        : Text(
                            _formatDate(_selectedDate),
                          ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickDate();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_month_outlined,
                    ),
                    title: const Text(
                      'নির্দিষ্ট মাস',
                    ),
                    subtitle: _selectedMonth == null
                        ? null
                        : Text(
                            '${_monthName(_selectedMonth!.month)} '
                            '${_selectedMonth!.year}',
                          ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickMonth();
                    },
                  ),
                  if (_hasFilter)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearFilters();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text(
                          'সব ফিল্টার মুছে দিন',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _filterTile({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_off,
        color: selected ? AppTheme.gold : null,
      ),
      title: Text(title),
      onTap: onTap,
    );
  }

  Future<void> _showLoanDetails(
    Map<String, dynamic> loan,
  ) async {
    final loanId = loan['id'] as int?;

    if (loanId == null) {
      return;
    }

    final transactions =
        await _db.getLoanTransactions(loanId);

    if (!mounted) {
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: _LoanDetailsSheet(
              loan: loan,
              transactions: transactions,
              onEdit: (transactionId) async {
                Navigator.pop(context);

                await _openLoanEdit(
                  loanId,
                  transactionId,
                );
              },
              onDelete: (transactionId) async {
                Navigator.pop(context);

                await _deleteLoanTransaction(
                  transactionId,
                );
              },
              onRepayment: () async {
                Navigator.pop(context);

                await _addRepayment(loan);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLoanEdit(
    int loanId,
    int? transactionId,
  ) async {
    if (transactionId == null) {
      return;
    }

    final transactions =
        await _db.getLoanTransactions(loanId);

    if (!mounted) {
      return;
    }

    if (transactions.isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          transactionId: transactionId,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadLoans();
  }

  Future<void> _deleteLoanTransaction(
    int transactionId,
  ) async {
    try {
      await _db.deleteTransaction(transactionId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'লেনদেন মুছে ফেলা হয়েছে',
          ),
        ),
      );

      await _loadLoans();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteLoan(
    Map<String, dynamic> loan,
  ) async {
    final loanId = loan['id'] as int?;

    if (loanId == null) {
      return;
    }

    final transactions =
        await _db.getLoanTransactions(loanId);

    if (!mounted) {
      return;
    }

    final hasRepayment = transactions.any(
      (transaction) {
        final type =
            (transaction['type'] ?? '').toString();

        return type == 'loan_received' ||
            type == 'loan_paid';
      },
    );

    if (hasRepayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'এই লোনের ফেরত/শোধের লেনদেন আছে। '
            'আগে সেগুলো মুছে ফেলুন।',
          ),
        ),
      );

      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'লোন মুছে ফেলবেন?',
          ),
          content: Text(
            '${loan['person_name'] ?? 'এই লেনদেন'}-এর '
            'লোনটি মুছে যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('মুছে ফেলুন'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      Map<String, dynamic>? original;

      for (final transaction in transactions) {
        final type =
            (transaction['type'] ?? '').toString();

        if (type == 'loan_given' ||
            type == 'loan_taken') {
          original = transaction;
          break;
        }
      }

      if (original == null) {
        return;
      }

      final transactionId =
          original['id'] as int?;

      if (transactionId == null) {
        return;
      }

      await _db.deleteTransaction(transactionId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'লোন মুছে ফেলা হয়েছে',
          ),
        ),
      );

      await _loadLoans();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _addRepayment(
    Map<String, dynamic> loan,
  ) async {
    final loanId = loan['id'] as int?;

    if (loanId == null) {
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _RepaymentSheet(
          loan: loan,
          db: _db,
        );
      },
    );

    if (result == true && mounted) {
      await _loadLoans();
    }
  }

  Future<void> _openAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadLoans();
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required bool positive,
  }) {
    final color =
        positive ? Colors.green : Colors.red;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '৳ ${_money(amount)}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(
    Map<String, dynamic> loan,
  ) {
    final type =
        (loan['type'] ?? '').toString();

    final person =
        (loan['person_name'] ?? 'নাম নেই').toString();

    final principal =
        _toDouble(loan['principal']);

    final remaining =
        _toDouble(loan['remaining']);

    final isReceivable =
        type == 'receivable';

    final color =
        isReceivable ? Colors.green : Colors.red;

    final title =
        isReceivable ? 'আমার পাওনা' : 'আমার দেনা';

    final status =
        remaining <= 0 ? 'সম্পন্ন' : 'চলমান';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showLoanDetails(loan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isReceivable
                          ? Icons.call_received_rounded
                          : Icons.call_made_rounded,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          person,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editLoan(loan);
                      } else if (value == 'delete') {
                        _deleteLoan(loan);
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                              ),
                              SizedBox(width: 10),
                              Text('এডিট'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                              ),
                              SizedBox(width: 10),
                              Text('মুছে ফেলুন'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _amountColumn(
                      'মোট',
                      principal,
                    ),
                  ),
                  Expanded(
                    child: _amountColumn(
                      'বাকি',
                      remaining,
                      color: color,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: remaining <= 0
                          ? Colors.green
                              .withValues(alpha: 0.10)
                          : Colors.orange
                              .withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: remaining <= 0
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDate(loan['created_at']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'বিস্তারিত দেখুন',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right,
                    size: 17,
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountColumn(
    String title,
    double amount, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '৳ ${_money(amount)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _editLoan(
    Map<String, dynamic> loan,
  ) async {
    final loanId = loan['id'] as int?;

    if (loanId == null) {
      return;
    }

    final transactions =
        await _db.getLoanTransactions(loanId);

    if (!mounted) {
      return;
    }

    if (transactions.isEmpty) {
      return;
    }

    Map<String, dynamic>? original;

    for (final transaction in transactions) {
      final type =
          (transaction['type'] ?? '').toString();

      if (type == 'loan_given' ||
          type == 'loan_taken') {
        original = transaction;
        break;
      }
    }

    if (original == null) {
      return;
    }

    final transactionId =
        original['id'] as int?;

    if (transactionId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          transactionId: transactionId,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadLoans();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalReceivable = _loans
        .where(
          (loan) =>
              (loan['type'] ?? '').toString() ==
              'receivable',
        )
        .fold<double>(
          0,
          (sum, loan) =>
              sum + _toDouble(loan['remaining']),
        );

    final totalPayable = _loans
        .where(
          (loan) =>
              (loan['type'] ?? '').toString() ==
              'payable',
        )
        .fold<double>(
          0,
          (sum, loan) =>
              sum + _toDouble(loan['remaining']),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'দেনা-পাওনা',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'রিফ্রেশ',
            onPressed: _loadLoans,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        icon: const Icon(Icons.add),
        label: const Text('নতুন লেনদেন'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLoans,
        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  0,
                ),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      title: 'আমার পাওনা',
                      amount: totalReceivable,
                      icon:
                          Icons.arrow_downward_rounded,
                      positive: true,
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryCard(
                      title: 'আমার দেনা',
                      amount: totalPayable,
                      icon:
                          Icons.arrow_upward_rounded,
                      positive: false,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'নাম বা নোট দিয়ে খুঁজুন',
                    prefixIcon:
                        const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController
                                      .clear();
                                },
                                icon: const Icon(
                                  Icons.clear,
                                ),
                              ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.55),
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                        alignment:
                            Alignment.centerLeft,
                        child: Text(
                          _filterLabel(),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: _showFilterMenu,
                        icon: const Icon(
                          Icons.filter_list,
                          size: 18,
                        ),
                        label: const Text('ফিল্টার'),
                        style:
                            OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_loans.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  100,
                ),
                sliver: SliverList(
                  delegate:
                      SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildLoanCard(
                        _loans[index],
                      );
                    },
                    childCount: _loans.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.handshake_outlined,
                size: 40,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'কোনো দেনা-পাওনা পাওয়া যায়নি',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasFilter
                  ? 'বর্তমান ফিল্টার পরিবর্তন করে দেখুন।'
                  : 'নতুন লেনদেন থেকে ধার দেওয়া বা নেওয়ার হিসাব যোগ করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            if (_hasFilter) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _clearFilters,
                child: const Text(
                  'ফিল্টার মুছে দিন',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoanDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> loan;
  final List<Map<String, dynamic>> transactions;
  final Future<void> Function(int transactionId)
      onEdit;
  final Future<void> Function(int transactionId)
      onDelete;
  final Future<void> Function() onRepayment;

  const _LoanDetailsSheet({
    required this.loan,
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
    required this.onRepayment,
  });

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(double value) {
    return value.toStringAsFixed(2);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  String _date(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _transactionTitle(String type) {
    switch (type) {
      case 'loan_given':
        return 'ধার দিয়েছি';
      case 'loan_taken':
        return 'ধার নিয়েছি';
      case 'loan_received':
        return 'ধার ফেরত পেয়েছি';
      case 'loan_paid':
        return 'ধার শোধ করেছি';
      default:
        return 'লোন লেনদেন';
    }
  }

  Color _transactionColor(String type) {
    switch (type) {
      case 'loan_given':
        return Colors.orange;
      case 'loan_taken':
        return Colors.red;
      case 'loan_received':
        return Colors.green;
      case 'loan_paid':
        return Colors.blue;
      default:
        return AppTheme.gold;
    }
  }

  bool _isRepayment(String type) {
    return type == 'loan_received' ||
        type == 'loan_paid';
  }

  @override
  Widget build(BuildContext context) {
    final type =
        (loan['type'] ?? '').toString();

    final person =
        (loan['person_name'] ?? 'নাম নেই').toString();

    final principal =
        _toDouble(loan['principal']);

    final remaining =
        _toDouble(loan['remaining']);

    final receivable = type == 'receivable';

    final color =
        receivable ? Colors.green : Colors.red;

    return Material(
      color: Theme.of(context)
          .scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              10,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        receivable
                            ? Icons.call_received_rounded
                            : Icons.call_made_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            person,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            receivable
                                ? 'আমার পাওনা'
                                : 'আমার দেনা',
                            style: TextStyle(
                              color: color,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _summary(
                        'মোট',
                        principal,
                      ),
                    ),
                    Expanded(
                      child: _summary(
                        'বাকি',
                        remaining,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (remaining > 0)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRepayment,
                      icon: Icon(
                        receivable
                            ? Icons.call_received
                            : Icons.payments_outlined,
                      ),
                      label: Text(
                        receivable
                            ? 'ফেরত পেয়েছি'
                            : 'ধার শোধ করেছি',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Text(
                      'কোনো লেনদেন নেই',
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      30,
                    ),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _transactionTile(
                        context,
                        transactions[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summary(
    String title,
    double amount, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '৳ ${_money(amount)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _transactionTile(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final type =
        (transaction['type'] ?? '').toString();

    final amount =
        _toDouble(transaction['amount']);

    final color =
        _transactionColor(type);

    final id = transaction['id'] as int?;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isRepayment(type)
                  ? Icons.check_circle_outline
                  : Icons.swap_horiz_rounded,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _transactionTitle(type),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _date(
                    transaction[
                        'transaction_date'] ??
                        transaction['date'] ??
                        transaction['created_at'],
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                if ((transaction['note'] ?? '')
                    .toString()
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    transaction['note'].toString(),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                '৳ ${_money(amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (id != null)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit(id);
                    } else if (value == 'delete') {
                      _confirmDelete(
                        context,
                        id,
                      );
                    }
                  },
                  itemBuilder: (_) {
                    return const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('এডিট'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('মুছে ফেলুন'),
                      ),
                    ];
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    int id,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'লেনদেন মুছে ফেলবেন?',
          ),
          content: const Text(
            'এই লোন লেনদেনটি স্থায়ীভাবে মুছে যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('মুছে ফেলুন'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    await onDelete(id);
  }
}

class _RepaymentSheet extends StatefulWidget {
  final Map<String, dynamic> loan;
  final MoneyDb db;

  const _RepaymentSheet({
    required this.loan,
    required this.db,
  });

  @override
  State<_RepaymentSheet> createState() =>
      _RepaymentSheetState();
}

class _RepaymentSheetState
    extends State<_RepaymentSheet> {
  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _noteController =
      TextEditingController();

  List<Map<String, dynamic>> _accounts = [];

  int? _selectedAccountId;

  DateTime _date = DateTime.now();

  bool _saving = false;

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get _remaining {
    return _toDouble(widget.loan['remaining']);
  }

  bool get _receivable {
    return (widget.loan['type'] ?? '').toString() ==
        'receivable';
  }

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final accounts =
        await widget.db.getAccounts();

    if (!mounted) {
      return;
    }

    setState(() {
      _accounts = accounts;

      if (_accounts.isNotEmpty) {
        _selectedAccountId =
            _accounts.first['id'] as int?;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _date = picked;
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    final amount =
        double.tryParse(
              _amountController.text.trim(),
            ) ??
            0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'সঠিক পরিমাণ লিখুন',
          ),
        ),
      );
      return;
    }

    if (amount > _remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'বাকি টাকার চেয়ে বেশি পরিমাণ দেওয়া যাবে না',
          ),
        ),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'একটি অ্যাকাউন্ট নির্বাচন করুন',
          ),
        ),
      );
      return;
    }

    final loanId =
        widget.loan['id'] as int?;

    if (loanId == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.db.addLoanRepayment(
        loanId: loanId,
        amount: amount,
        accountId: _selectedAccountId!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        transactionDate: _date,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final person =
        (widget.loan['person_name'] ?? 'নাম নেই')
            .toString();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 +
              MediaQuery.of(context)
                  .viewInsets
                  .bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                _receivable
                    ? 'ধার ফেরত পেয়েছি'
                    : 'ধার শোধ করেছি',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                person,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .account_balance_wallet_outlined,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'বর্তমান বাকি: '
                        '৳ ${_remaining.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText: 'পরিমাণ',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedAccountId,
                decoration:
                    const InputDecoration(
                  labelText: 'অ্যাকাউন্ট',
                  border: OutlineInputBorder(),
                ),
                items: _accounts.map((account) {
                  final id =
                      account['id'] as int?;

                  final name =
                      (account['name'] ?? '')
                          .toString();

                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccountId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration:
                    const InputDecoration(
                  labelText: 'নোট',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today_outlined,
                ),
                title: const Text('তারিখ'),
                subtitle: Text(
                  '${_date.day.toString().padLeft(2, '0')}/'
                  '${_date.month.toString().padLeft(2, '0')}/'
                  '${_date.year}',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed:
                      _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.check_rounded,
                        ),
                  label: Text(
                    _saving
                        ? 'সেভ হচ্ছে...'
                        : 'সেভ করুন',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
