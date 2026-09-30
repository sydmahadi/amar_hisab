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
  String _dateFilter = 'all';

  DateTime? _selectedDate;
  DateTime? _selectedMonth;

  double _receivable = 0;
  double _payable = 0;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOAD
  // =========================================================

  Future<void> _loadLoans() async {
    setState(() {
      _loading = true;
    });

    try {
      final totals = await _db.getLoanTotals();

      final loans = await _db.getLoans(
        type: _typeFilter == 'all'
            ? null
            : _typeFilter,
        activeOnly: false,
      );

      final search = _searchController.text
          .trim()
          .toLowerCase();

      final filtered = <Map<String, dynamic>>[];

      for (final loan in loans) {
        final person =
            (loan['person_name'] ?? '')
                .toString()
                .toLowerCase();

        final note =
            (loan['note'] ?? '')
                .toString()
                .toLowerCase();

        if (search.isNotEmpty &&
            !person.contains(search) &&
            !note.contains(search)) {
          continue;
        }

        final remaining =
            _toDouble(loan['remaining']);

        if (_statusFilter == 'active' &&
            remaining <= 0) {
          continue;
        }

        if (_statusFilter == 'completed' &&
            remaining > 0) {
          continue;
        }

        final loanId =
            (loan['id'] as num?)?.toInt();

        if (loanId == null) {
          continue;
        }

        final transactions =
            await _db.getLoanTransactions(loanId);

        if (!_matchesDateFilter(
          transactions,
        )) {
          continue;
        }

        filtered.add(loan);
      }

      if (!mounted) return;

      setState(() {
        _loans = filtered;
        _receivable =
            totals['receivable'] ?? 0;
        _payable =
            totals['payable'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'লোড করতে সমস্যা হয়েছে: $e',
        isError: true,
      );
    }
  }

  // =========================================================
  // DATE FILTER
  // =========================================================

  bool _matchesDateFilter(
    List<Map<String, dynamic>> transactions,
  ) {
    if (_dateFilter == 'all') {
      return true;
    }

    if (_dateFilter == 'date' &&
        _selectedDate != null) {
      for (final transaction in transactions) {
        final date = _parseDate(
          transaction['transaction_date'],
        );

        if (date == null) continue;

        if (date.year == _selectedDate!.year &&
            date.month == _selectedDate!.month &&
            date.day == _selectedDate!.day) {
          return true;
        }
      }

      return false;
    }

    if (_dateFilter == 'month' &&
        _selectedMonth != null) {
      for (final transaction in transactions) {
        final date = _parseDate(
          transaction['transaction_date'],
        );

        if (date == null) continue;

        if (date.year == _selectedMonth!.year &&
            date.month == _selectedMonth!.month) {
          return true;
        }
      }

      return false;
    }

    return true;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _money(double value) {
    return '৳ ${value.toStringAsFixed(2)}';
  }

  String _dateText(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return '-';
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

  // =========================================================
  // FILTER LABEL
  // =========================================================

  String _filterLabel() {
    if (_dateFilter == 'date' &&
        _selectedDate != null) {
      return '${_selectedDate!.day.toString().padLeft(2, '0')}/'
          '${_selectedDate!.month.toString().padLeft(2, '0')}/'
          '${_selectedDate!.year}';
    }

    if (_dateFilter == 'month' &&
        _selectedMonth != null) {
      return '${_monthName(_selectedMonth!.month)} '
          '${_selectedMonth!.year}';
    }

    return 'সব তারিখ';
  }

  String _typeLabel() {
    switch (_typeFilter) {
      case 'receivable':
        return 'আমার পাওনা';
      case 'payable':
        return 'আমার দেনা';
      default:
        return 'সব লোন';
    }
  }

  String _statusLabel() {
    switch (_statusFilter) {
      case 'active':
        return 'চলমান';
      case 'completed':
        return 'পরিশোধ সম্পন্ন';
      default:
        return 'সব অবস্থা';
    }
  }

  // =========================================================
  // FILTER MENU
  // =========================================================

  Future<void> _showFilterMenu() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor:
          Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),

                _filterOption(
                  icon: Icons.all_inclusive_rounded,
                  title: 'সব লোন',
                  selected:
                      _typeFilter == 'all',
                  onTap: () {
                    setState(() {
                      _typeFilter = 'all';
                    });

                    Navigator.pop(context);
                    _loadLoans();
                  },
                ),

                _filterOption(
                  icon: Icons.arrow_downward_rounded,
                  title: 'আমার পাওনা',
                  selected:
                      _typeFilter == 'receivable',
                  onTap: () {
                    setState(() {
                      _typeFilter = 'receivable';
                    });

                    Navigator.pop(context);
                    _loadLoans();
                  },
                ),

                _filterOption(
                  icon: Icons.arrow_upward_rounded,
                  title: 'আমার দেনা',
                  selected:
                      _typeFilter == 'payable',
                  onTap: () {
                    setState(() {
                      _typeFilter = 'payable';
                    });

                    Navigator.pop(context);
                    _loadLoans();
                  },
                ),

                const Divider(),

                _filterOption(
                  icon: Icons.pending_actions_rounded,
                  title: 'শুধু চলমান',
                  selected:
                      _statusFilter == 'active',
                  onTap: () {
                    setState(() {
                      _statusFilter = 'active';
                    });

                    Navigator.pop(context);
                    _loadLoans();
                  },
                ),

                _filterOption(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'পরিশোধ সম্পন্ন',
                  selected:
                      _statusFilter == 'completed',
                  onTap: () {
                    setState(() {
                      _statusFilter = 'completed';
                    });

                    Navigator.pop(context);
                    _loadLoans();
                  },
                ),

                const Divider(),

                _filterOption(
                  icon: Icons.calendar_today_rounded,
                  title: 'নির্দিষ্ট তারিখ',
                  selected:
                      _dateFilter == 'date',
                  onTap: () {
                    Navigator.pop(context);
                    _pickDate();
                  },
                ),

                _filterOption(
                  icon: Icons.calendar_month_rounded,
                  title: 'নির্দিষ্ট মাস',
                  selected:
                      _dateFilter == 'month',
                  onTap: () {
                    Navigator.pop(context);
                    _pickMonth();
                  },
                ),

                _filterOption(
                  icon: Icons.clear_rounded,
                  title: 'ফিল্টার পরিষ্কার',
                  selected: false,
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      _typeFilter = 'all';
                      _statusFilter = 'all';
                      _dateFilter = 'all';
                      _selectedDate = null;
                      _selectedMonth = null;
                    });

                    _loadLoans();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterOption({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: selected
            ? AppTheme.gold
            : theme.colorScheme.onSurface
                .withValues(alpha: 0.75),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? Icon(
              Icons.check_circle_rounded,
              color: AppTheme.gold,
            )
          : null,
      onTap: onTap,
    );
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _dateFilter = 'date';
      _selectedDate = picked;
      _selectedMonth = null;
    });

    _loadLoans();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        int selectedYear =
            _selectedMonth?.year ?? now.year;
        int selectedMonth =
            _selectedMonth?.month ?? now.month;

        return StatefulBuilder(
          builder: (
            context,
            setStateDialog,
          ) {
            return AlertDialog(
              title: const Text(
                'মাস নির্বাচন করুন',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
                    decoration:
                        const InputDecoration(
                      labelText: 'মাস',
                    ),
                    items: List.generate(
                      12,
                      (index) {
                        final month = index + 1;

                        return DropdownMenuItem(
                          value: month,
                          child: Text(
                            _monthName(month),
                          ),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setStateDialog(() {
                        selectedMonth = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    decoration:
                        const InputDecoration(
                      labelText: 'বছর',
                    ),
                    items: List.generate(
                      101,
                      (index) {
                        final year =
                            2000 + index;

                        return DropdownMenuItem(
                          value: year,
                          child: Text(
                            '$year',
                          ),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setStateDialog(() {
                        selectedYear = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('বাতিল'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DateTime(
                        selectedYear,
                        selectedMonth,
                      ),
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

    if (picked == null) return;

    setState(() {
      _dateFilter = 'month';
      _selectedMonth = picked;
      _selectedDate = null;
    });

    _loadLoans();
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void _onSearchChanged(String value) {
    _loadLoans();
  }

  // =========================================================
  // LOAN DETAILS
  // =========================================================

  Future<void> _showLoanDetails(
    Map<String, dynamic> loan,
  ) async {
    final loanId =
        (loan['id'] as num?)?.toInt();

    if (loanId == null) return;

    final transactions =
        await _db.getLoanTransactions(loanId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.94,
            builder: (
              context,
              scrollController,
            ) {
              return _buildLoanDetailsSheet(
                loan,
                transactions,
                scrollController,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoanDetailsSheet(
    Map<String, dynamic> loan,
    List<Map<String, dynamic>> transactions,
    ScrollController scrollController,
  ) {
    final theme = Theme.of(context);

    final type =
        loan['type']?.toString() ??
            'receivable';

    final person =
        loan['person_name']?.toString() ??
            '';

    final principal =
        _toDouble(loan['principal']);

    final remaining =
        _toDouble(loan['remaining']);

    final repaid =
        principal - remaining;

    final isReceivable =
        type == 'receivable';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20,
      ),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(
                  alpha: 0.35,
                ),
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor:
                    AppTheme.gold.withValues(
                  alpha: 0.15,
                ),
                child: Icon(
                  isReceivable
                      ? Icons
                          .arrow_downward_rounded
                      : Icons
                          .arrow_upward_rounded,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      person,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isReceivable
                          ? 'আমার পাওনা'
                          : 'আমার দেনা',
                      style: TextStyle(
                        color: theme
                            .colorScheme
                            .onSurface
                            .withValues(
                              alpha: 0.65,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  title: 'মূল টাকা',
                  amount: principal,
                  icon: Icons
                      .account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryBox(
                  title: 'পরিশোধ',
                  amount: repaid < 0
                      ? 0
                      : repaid,
                  icon: Icons
                      .check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryBox(
                  title: 'বাকি',
                  amount: remaining,
                  icon: Icons
                      .pending_actions_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (transactions.isNotEmpty) ...[
            const Text(
              'লেনদেনসমূহ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (transactions.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'কোনো লেনদেন পাওয়া যায়নি',
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurface
                        .withValues(
                          alpha: 0.6,
                        ),
                  ),
                ),
              ),
            )
          else
            ...transactions.map(
              (transaction) {
                return _buildLoanTransactionTile(
                  transaction,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _summaryBox({
    required String title,
    required double amount,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.gold.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: AppTheme.gold,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(amount),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanTransactionTile(
    Map<String, dynamic> transaction,
  ) {
    final type =
        transaction['type']?.toString() ??
            '';

    final amount =
        _toDouble(transaction['amount']);

    final isPositive =
        type == 'loan_given' ||
        type == 'loan_paid';

    String title;

    if (type == 'loan_given') {
      title = 'ধার দিয়েছি';
    } else if (type == 'loan_taken') {
      title = 'ধার নিয়েছি';
    } else if (type == 'loan_received') {
      title = 'ধার ফেরত পেয়েছি';
    } else if (type == 'loan_paid') {
      title = 'ধার শোধ করেছি';
    } else {
      title = 'লোন';
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor:
              (isPositive
                      ? Colors.green
                      : Colors.red)
                  .withValues(alpha: 0.12),
          child: Icon(
            isPositive
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 20,
            color: isPositive
                ? Colors.green
                : Colors.red,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${_dateText(transaction['transaction_date'])}'
          '${(transaction['note'] ?? '').toString().trim().isEmpty ? '' : ' • ${transaction['note']}'}',
        ),
        trailing: Text(
          _money(amount),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isPositive
                ? Colors.green
                : Colors.red,
          ),
        ),
        onTap: () {
          _editTransaction(
            transaction,
          );
        },
      ),
    );
  }

  // =========================================================
  // EDIT
  // =========================================================

  Future<void> _editTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final id =
        (transaction['id'] as num?)?.toInt();

    if (id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          transactionId: id,
        ),
      ),
    );

    _loadLoans();
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> _deleteTransaction(
    int id,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'লেনদেন মুছে ফেলবেন?',
          ),
          content: const Text(
            'এই লোন লেনদেনটি মুছে ফেলা হবে। '
            'এই কাজটি পরে আর ফিরিয়ে নেওয়া যাবে না।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('মুছে ফেলুন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _db.deleteTransaction(id);

      if (!mounted) return;

      _showMessage(
        'লেনদেন মুছে ফেলা হয়েছে',
      );

      _loadLoans();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  // =========================================================
  // LOAN CARD
  // =========================================================

  Widget _buildLoanCard(
    Map<String, dynamic> loan,
  ) {
    final theme = Theme.of(context);

    final type =
        loan['type']?.toString() ??
            'receivable';

    final person =
        loan['person_name']?.toString() ??
            '';

    final principal =
        _toDouble(loan['principal']);

    final remaining =
        _toDouble(loan['remaining']);

    final completed =
        remaining <= 0;

    final isReceivable =
        type == 'receivable';

    final loanId =
        (loan['id'] as num?)?.toInt();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color: (isReceivable
                  ? Colors.green
                  : Colors.red)
              .withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          _showLoanDetails(loan);
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          (isReceivable
                                  ? Colors.green
                                  : Colors.red)
                              .withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      isReceivable
                          ? Icons
                              .arrow_downward_rounded
                          : Icons
                              .arrow_upward_rounded,
                      color: isReceivable
                          ? Colors.green
                          : Colors.red,
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
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isReceivable
                              ? 'আমার পাওনা'
                              : 'আমার দেনা',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme
                                .colorScheme
                                .onSurface
                                .withValues(
                                  alpha: 0.62,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit' &&
                          loanId != null) {
                        _openLoanEdit(
                          loan,
                        );
                      }

                      if (value == 'delete') {
                        _deleteLoan(
                          loan,
                        );
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
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
                                Icons
                                    .delete_outline_rounded,
                              ),
                              SizedBox(width: 10),
                              Text('ডিলিট'),
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
                    child: _loanAmountInfo(
                      'মূল',
                      principal,
                    ),
                  ),
                  Expanded(
                    child: _loanAmountInfo(
                      'বাকি',
                      remaining,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment:
                          Alignment.centerRight,
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: completed
                              ? Colors.green
                                  .withValues(
                                  alpha: 0.10,
                                )
                              : AppTheme.gold
                                  .withValues(
                                  alpha: 0.10,
                                ),
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: Text(
                          completed
                              ? 'সম্পন্ন'
                              : 'চলমান',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                            color: completed
                                ? Colors.green
                                : AppTheme.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loanAmountInfo(
    String title,
    double amount,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _money(amount),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EDIT LOAN
  // =========================================================

  Future<void> _openLoanEdit(
    Map<String, dynamic> loan,
  ) async {
    final loanId =
        (loan['id'] as num?)?.toInt();

    if (loanId == null) return;

    final transactions =
        await _db.getLoanTransactions(loanId);

    if (transactions.isEmpty) return;

    final original = transactions.firstWhere(
      (transaction) {
        final type =
            transaction['type']?.toString();

        return type == 'loan_given' ||
            type == 'loan_taken';
      },
      orElse: () => transactions.first,
    );

    final transactionId =
        (original['id'] as num?)?.toInt();

    if (transactionId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          transactionId: transactionId,
        ),
      ),
    );

    _loadLoans();
  }

  // =========================================================
  // DELETE LOAN
  // =========================================================

  Future<void> _deleteLoan(
    Map<String, dynamic> loan,
  ) async {
    final loanId =
        (loan['id'] as num?)?.toInt();

    if (loanId == null) return;

    final transactions =
        await _db.getLoanTransactions(loanId);

    final original = transactions.where(
      (transaction) {
        final type =
            transaction['type']?.toString();

        return type == 'loan_given' ||
            type == 'loan_taken';
      },
    );

    if (original.isEmpty) return;

    final originalId =
        (original.first['id'] as num?)?.toInt();

    if (originalId == null) return;

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'লোন মুছে ফেলবেন?',
          ),
          content: Text(
            '${loan['person_name']} এর লোনটি মুছে ফেলা হবে।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('মুছে ফেলুন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _db.deleteTransaction(
        originalId,
      );

      if (!mounted) return;

      _showMessage(
        'লোন মুছে ফেলা হয়েছে',
      );

      _loadLoans();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }

  // =========================================================
  // FILTER BAR
  // =========================================================

  Widget _buildFilterBar() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_typeLabel()} • '
              '${_statusLabel()} • '
              '${_filterLabel()}',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius:
                BorderRadius.circular(10),
            onTap: _showFilterMenu,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AppTheme.gold
                    .withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 17,
                    color: AppTheme.gold,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'ফিল্টার',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                      color: AppTheme.gold,
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

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: _topSummaryCard(
              title: 'আমার পাওনা',
              amount: _receivable,
              icon:
                  Icons.arrow_downward_rounded,
              iconColor: Colors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _topSummaryCard(
              title: 'আমার দেনা',
              amount: _payable,
              icon:
                  Icons.arrow_upward_rounded,
              iconColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withValues(alpha: 0.14),
            iconColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: iconColor.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    _money(amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'দেনা-পাওনা',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'রিফ্রেশ',
            onPressed: _loadLoans,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddTransactionScreen(),
            ),
          );

          _loadLoans();
        },
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'নতুন লেনদেন',
        ),
      ),
      body: Column(
        children: [
          _buildSummary(),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              4,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText:
                    'ব্যক্তির নাম বা নোট খুঁজুন...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon:
                    _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController
                                  .clear();
                              setState(() {});
                              _loadLoans();
                            },
                            icon: const Icon(
                              Icons.clear_rounded,
                            ),
                          ),
                isDense: true,
                filled: true,
                fillColor:
                    theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          _buildFilterBar(),

          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadLoans,
                    child: _loans.isEmpty
                        ? ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(
                                height: 100,
                              ),
                              Icon(
                                Icons
                                    .account_balance_wallet_outlined,
                                size: 58,
                                color: theme
                                    .colorScheme
                                    .onSurface
                                    .withValues(
                                      alpha: 0.25,
                                    ),
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              Center(
                                child: Text(
                                  'কোনো দেনা-পাওনা পাওয়া যায়নি',
                                  style: TextStyle(
                                    color: theme
                                        .colorScheme
                                        .onSurface
                                        .withValues(
                                          alpha: 0.6,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              16,
                              4,
                              16,
                              100,
                            ),
                            itemCount:
                                _loans.length,
                            itemBuilder:
                                (context, index) {
                              return _buildLoanCard(
                                _loans[index],
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
