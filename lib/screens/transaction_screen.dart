import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];

  bool _loading = true;
  String _filter = 'all';
  String _searchText = '';

  final TextEditingController _searchController =
      TextEditingController();

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // LOAD
  // ------------------------------------------------------------

  Future<void> _loadTransactions() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      List<Map<String, dynamic>> data;

      if (_searchText.trim().isNotEmpty) {
        data = await MoneyDb.instance.searchTransactions(
          _searchText.trim(),
        );
      } else {
        data = await MoneyDb.instance.getTransactions(
          type: _filter == 'all' ? null : _filter,
        );
      }

      if (!mounted) return;

      setState(() {
        _transactions = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );

    if (result == true) {
      await _loadTransactions();
    }
  }

  Future<void> _editTransaction(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          transactionId: id,
        ),
      ),
    );

    if (result == true) {
      await _loadTransactions();
    }
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<void> _deleteTransaction(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(settings.t('confirm')),
          content: Text(settings.t('deleteConfirmation')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(settings.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: Text(settings.t('delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await MoneyDb.instance.deleteTransaction(id);

      await _loadTransactions();

      if (!mounted) return;

      _showMessage(
        settings.isBangla
            ? 'লেনদেন মুছে ফেলা হয়েছে'
            : 'Transaction deleted',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
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
          backgroundColor:
              isError ? Colors.red.shade700 : AppTheme.green,
        ),
      );
  }

  // ------------------------------------------------------------
  // DATE
  // ------------------------------------------------------------

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String _dateKey(Map<String, dynamic> item) {
    final date = _parseDate(
      item['transaction_date']?.toString(),
    );

    if (date == null) {
      return 'unknown';
    }

    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _dateHeader(String key) {
    if (key == 'unknown') {
      return settings.isBangla ? 'তারিখ নেই' : 'No Date';
    }

    final parts = key.split('-');

    if (parts.length != 3) {
      return key;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) {
      return key;
    }

    if (month < 1 || month > 12) {
      return key;
    }

    final date = DateTime(year, month, day);
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final yesterday = today.subtract(
      const Duration(days: 1),
    );

    final onlyDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (onlyDate == today) {
      return settings.isBangla ? 'আজ' : 'Today';
    }

    if (onlyDate == yesterday) {
      return settings.isBangla ? 'গতকাল' : 'Yesterday';
    }

    const bnMonths = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
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

    const enMonths = [
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

    final monthName = settings.isBangla
        ? bnMonths[month - 1]
        : enMonths[month - 1];

    if (settings.isBangla) {
      return '$day $monthName, $year';
    }

    return '$monthName $day, $year';
  }

  Map<String, List<Map<String, dynamic>>>
      _groupTransactionsByDate() {
    final groups =
        <String, List<Map<String, dynamic>>>{};

    for (final item in _transactions) {
      final key = _dateKey(item);

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(item);
    }

    final entries = groups.entries.toList();

    entries.sort((a, b) {
      if (a.key == 'unknown') return 1;
      if (b.key == 'unknown') return -1;

      return b.key.compareTo(a.key);
    });

    return Map.fromEntries(entries);
  }

  // ------------------------------------------------------------
  // AMOUNT
  // ------------------------------------------------------------

  double _amount(Map<String, dynamic> item) {
    return (item['amount'] as num?)?.toDouble() ?? 0;
  }

  String _formatAmount(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;

    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
  }

  double _dailyIncome(
    List<Map<String, dynamic>> items,
  ) {
    double total = 0;

    for (final item in items) {
      if (item['type']?.toString() == 'income') {
        total += _amount(item);
      }
    }

    return total;
  }

  double _dailyExpense(
    List<Map<String, dynamic>> items,
  ) {
    double total = 0;

    for (final item in items) {
      if (item['type']?.toString() == 'expense') {
        total += _amount(item);
      }
    }

    return total;
  }

  // ------------------------------------------------------------
  // TYPE HELPERS
  // ------------------------------------------------------------

  bool _isLoanType(String type) {
    return type == 'loan_given' ||
        type == 'loan_taken' ||
        type == 'loan_received' ||
        type == 'loan_paid';
  }

  String _loanTypeTitle(String type) {
    switch (type) {
      case 'loan_given':
        return settings.isBangla
            ? 'ধার দিয়েছি'
            : 'Loan Given';

      case 'loan_taken':
        return settings.isBangla
            ? 'ধার নিয়েছি'
            : 'Loan Taken';

      case 'loan_received':
        return settings.isBangla
            ? 'ধার ফেরত পেয়েছি'
            : 'Loan Received';

      case 'loan_paid':
        return settings.isBangla
            ? 'ধার শোধ করেছি'
            : 'Loan Paid';

      default:
        return settings.isBangla
            ? 'ধার'
            : 'Loan';
    }
  }

  Color _amountColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green.shade600;

      case 'expense':
        return Colors.red.shade600;

      case 'loan_given':
        return Colors.orange.shade700;

      case 'loan_taken':
        return Colors.blue.shade600;

      case 'loan_received':
        return Colors.green.shade700;

      case 'loan_paid':
        return Colors.red.shade700;

      case 'transfer':
        return AppTheme.gold;

      default:
        return AppTheme.gold;
    }
  }

  IconData _transactionIcon(String type) {
    switch (type) {
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
        return Icons.assignment_return_rounded;

      case 'loan_paid':
        return Icons.payments_outlined;

      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _amountPrefix(String type) {
    switch (type) {
      case 'income':
      case 'loan_received':
        return '+ ';

      case 'expense':
      case 'loan_given':
      case 'loan_paid':
        return '- ';

      default:
        return '';
    }
  }

  // ------------------------------------------------------------
  // LOAN PERSON
  // ------------------------------------------------------------

  String _personName(Map<String, dynamic> item) {
    final possibleKeys = [
      'person_name',
      'loan_person_name',
      'person',
      'borrower_name',
      'lender_name',
    ];

    for (final key in possibleKeys) {
      final value = item[key]?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  String _loanSubtitle(
    Map<String, dynamic> item,
  ) {
    final person = _personName(item);

    final account =
        item['account_name']?.toString().trim() ?? '';

    final note =
        item['note']?.toString().trim() ?? '';

    final parts = <String>[];

    if (person.isNotEmpty) {
      parts.add(person);
    }

    if (account.isNotEmpty) {
      parts.add(account);
    }

    if (note.isNotEmpty) {
      parts.add(note);
    }

    return parts.join(' • ');
  }

  // ------------------------------------------------------------
  // TITLE
  // ------------------------------------------------------------

  String _transactionTitle(
    Map<String, dynamic> item,
  ) {
    final type = item['type']?.toString() ?? '';

    if (_isLoanType(type)) {
      final person = _personName(item);

      final loanTitle = _loanTypeTitle(type);

      if (person.isNotEmpty) {
        return '$loanTitle • $person';
      }

      return loanTitle;
    }

    if (type == 'transfer') {
      final from =
          item['from_account_name']?.toString() ?? '';

      final to =
          item['to_account_name']?.toString() ?? '';

      if (from.isNotEmpty && to.isNotEmpty) {
        return '$from → $to';
      }

      return settings.t('transfer');
    }

    final category =
        item['category_name']?.toString() ?? '';

    if (category.isNotEmpty) {
      return category;
    }

    if (type == 'income') {
      return settings.t('income');
    }

    if (type == 'expense') {
      return settings.t('expense');
    }

    return settings.isBangla
        ? 'লেনদেন'
        : 'Transaction';
  }

  // ------------------------------------------------------------
  // SUBTITLE
  // ------------------------------------------------------------

  String _transactionSubtitle(
    Map<String, dynamic> item,
  ) {
    final type = item['type']?.toString() ?? '';

    if (_isLoanType(type)) {
      return _loanSubtitle(item);
    }

    if (type == 'transfer') {
      final note =
          item['note']?.toString().trim() ?? '';

      return note;
    }

    final account =
        item['account_name']?.toString().trim() ?? '';

    final note =
        item['note']?.toString().trim() ?? '';

    if (note.isNotEmpty && account.isNotEmpty) {
      return '$account • $note';
    }

    if (account.isNotEmpty) {
      return account;
    }

    return note;
  }

  // ------------------------------------------------------------
  // FILTER
  // ------------------------------------------------------------

  Widget _buildFilter() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterButton(
            value: 'all',
            label: settings.t('transactions'),
          ),
          const SizedBox(width: 8),

          _filterButton(
            value: 'income',
            label: settings.t('income'),
          ),
          const SizedBox(width: 8),

          _filterButton(
            value: 'expense',
            label: settings.t('expense'),
          ),
          const SizedBox(width: 8),

          _filterButton(
            value: 'transfer',
            label: settings.t('transfer'),
          ),
          const SizedBox(width: 8),

          _filterButton(
            value: 'loan_given',
            label: settings.isBangla
                ? 'ধার দিয়েছি'
                : 'Given',
          ),
          const SizedBox(width: 8),

          _filterButton(
            value: 'loan_taken',
            label: settings.isBangla
                ? 'ধার নিয়েছি'
                : 'Taken',
          ),
          const SizedBox(width: 8),

          _filterButton(
            value: 'loan_received',
            label: settings.isBangla
                ? 'ফেরত পেয়েছি'
                : 'Received',
          ),
          const SizedBox(width: 8),

          _filterButton(
            value: 'loan_paid',
            label: settings.isBangla
                ? 'ধার শোধ'
                : 'Paid',
          ),
        ],
      ),
    );
  }

  Widget _filterButton({
    required String value,
    required String label,
  }) {
    final selected = _filter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) async {
        setState(() {
          _filter = value;
        });

        await _loadTransactions();
      },
      selectedColor: AppTheme.green,
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color,
        fontWeight:
            selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE HEADER
  // ------------------------------------------------------------

  Widget _buildDateHeader(
    String dateKey,
    List<Map<String, dynamic>> items,
  ) {
    final income = _dailyIncome(items);
    final expense = _dailyExpense(items);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        2,
        18,
        2,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateHeader(dateKey),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${items.length} ${settings.isBangla ? 'টি লেনদেন' : 'transactions'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (income > 0 || expense > 0)
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                if (income > 0)
                  Text(
                    '+ ${_formatAmount(income)}',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (expense > 0)
                  Text(
                    '- ${_formatAmount(expense)}',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TRANSACTION CARD
  // ------------------------------------------------------------

  Widget _buildTransactionCard(
    Map<String, dynamic> item,
  ) {
    final type =
        item['type']?.toString() ?? 'expense';

    final amount = _formatAmount(
      item['amount'],
    );

    final color = _amountColor(type);

    final icon = _transactionIcon(type);

    final title = _transactionTitle(item);

    final subtitle =
        _transactionSubtitle(item);

    final rawId = item['id'];

    final id = rawId is int
        ? rawId
        : int.tryParse(rawId.toString()) ?? 0;

    final isLoan = _isLoanType(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: InkWell(
        onTap: id > 0
            ? () => _editTransaction(id)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              // ICON
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // TITLE + SUBTITLE
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                        ),
                      ),
                    ],

                    if (isLoan) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration:
                            BoxDecoration(
                          color: color.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            6,
                          ),
                        ),
                        child: Text(
                          _loanTypeTitle(type),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // AMOUNT + MENU
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_amountPrefix(type)}$amount',
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 21,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTransaction(id);
                      } else if (value ==
                          'delete') {
                        _deleteTransaction(id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              settings.t('edit'),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color:
                                  Colors.red.shade600,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              settings.t('delete'),
                              style: TextStyle(
                                color:
                                    Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    final isFiltered =
        _filter != 'all' ||
        _searchText.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(
                  alpha: 0.12,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 45,
                color: AppTheme.gold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isFiltered
                  ? (settings.isBangla
                      ? 'কোনো লেনদেন পাওয়া যায়নি'
                      : 'No transactions found')
                  : settings.t('noTransactions'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isFiltered
                  ? (settings.isBangla
                      ? 'অন্য ফিল্টার বা সার্চ ব্যবহার করুন'
                      : 'Try another filter or search')
                  : (settings.isBangla
                      ? 'নতুন আয়, ব্যয়, ট্রান্সফার অথবা ধার যোগ করুন'
                      : 'Add a new income, expense, transfer or loan'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color,
              ),
            ),

            const SizedBox(height: 20),

            if (!isFiltered)
              ElevatedButton.icon(
                onPressed:
                    _openAddTransaction,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label: Text(
                  settings.t(
                    'addTransaction',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) async {
        _searchText = value;

        await _loadTransactions();

        if (mounted) {
          setState(() {});
        }
      },
      decoration: InputDecoration(
        hintText: settings.t('search'),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppTheme.gold,
        ),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () async {
                      _searchController.clear();

                      setState(() {
                        _searchText = '';
                      });

                      await _loadTransactions();
                    },
                    icon: const Icon(
                      Icons.clear_rounded,
                    ),
                  )
                : null,
      ),
    );
  }

  // ------------------------------------------------------------
  // GROUPED LIST
  // ------------------------------------------------------------

  Widget _buildGroupedTransactions() {
    final groups =
        _groupTransactionsByDate();

    final children = <Widget>[];

    for (final entry in groups.entries) {
      children.add(
        _buildDateHeader(
          entry.key,
          entry.value,
        ),
      );

      for (final transaction
          in entry.value) {
        children.add(
          _buildTransactionCard(
            transaction,
          ),
        );
      }
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        100,
      ),
      children: children,
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          settings.t('transactions'),
        ),
        actions: [
          IconButton(
            tooltip:
                settings.t('addTransaction'),
            onPressed:
                _openAddTransaction,
            icon: const Icon(
              Icons.add_rounded,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: _buildSearchField(),
          ),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              10,
            ),
            child: _buildFilter(),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : _transactions.isEmpty
                      ? _buildEmptyState()
                      : _buildGroupedTransactions(),
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _openAddTransaction,
        backgroundColor:
            AppTheme.green,
        foregroundColor:
            Colors.white,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: Text(
          settings.t(
            'addTransaction',
          ),
        ),
      ),
    );
  }
}
