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

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String _formatDate(String? value) {
    final date = _parseDate(value);

    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
      return settings.isBangla
          ? 'তারিখ নেই'
          : 'No Date';
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

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate() {
    final groups = <String, List<Map<String, dynamic>>>{};

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

  double _dailyIncome(List<Map<String, dynamic>> items) {
    double total = 0;

    for (final item in items) {
      if (item['type']?.toString() == 'income') {
        total += (item['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    return total;
  }

  double _dailyExpense(List<Map<String, dynamic>> items) {
    double total = 0;

    for (final item in items) {
      if (item['type']?.toString() == 'expense') {
        total += (item['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    return total;
  }

  String _formatAmount(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;

    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
  }

  String _transactionTitle(Map<String, dynamic> item) {
    final type = item['type']?.toString();

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

    return type == 'income'
        ? settings.t('income')
        : settings.t('expense');
  }

  String _transactionSubtitle(
    Map<String, dynamic> item,
  ) {
    final type = item['type']?.toString();

    if (type == 'transfer') {
      final note = item['note']?.toString() ?? '';

      if (note.isNotEmpty) {
        return note;
      }

      return '';
    }

    final account =
        item['account_name']?.toString() ?? '';

    final note = item['note']?.toString() ?? '';

    if (note.isNotEmpty && account.isNotEmpty) {
      return '$account • $note';
    }

    if (account.isNotEmpty) {
      return account;
    }

    return note;
  }

  Color _amountColor(String type) {
    if (type == 'income') {
      return Colors.green.shade600;
    }

    if (type == 'expense') {
      return Colors.red.shade600;
    }

    return AppTheme.gold;
  }

  IconData _transactionIcon(String type) {
    if (type == 'income') {
      return Icons.arrow_downward_rounded;
    }

    if (type == 'expense') {
      return Icons.arrow_upward_rounded;
    }

    return Icons.swap_horiz_rounded;
  }

  String _amountPrefix(String type) {
    if (type == 'income') {
      return '+ ';
    }

    if (type == 'expense') {
      return '- ';
    }

    return '';
  }

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
                    borderRadius: BorderRadius.circular(10),
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

  Widget _buildTransactionCard(
    Map<String, dynamic> item,
  ) {
    final type = item['type']?.toString() ?? 'expense';

    final amount = _formatAmount(item['amount']);

    final color = _amountColor(type);

    final icon = _transactionIcon(type);

    final title = _transactionTitle(item);

    final subtitle = _transactionSubtitle(item);

    final id = item['id'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: InkWell(
        onTap: () => _editTransaction(id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
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
                    '${_amountPrefix(type)}$amount',
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 21,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTransaction(id);
                      } else if (value == 'delete') {
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
                            Text(settings.t('edit')),
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
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              settings.t('delete'),
                              style: TextStyle(
                                color: Colors.red.shade600,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
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
                color: AppTheme.green.withValues(alpha: 0.12),
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
              settings.t('noTransactions'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              settings.isBangla
                  ? 'নতুন আয়, ব্যয় অথবা ট্রান্সফার যোগ করুন'
                  : 'Add a new income, expense or transfer',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _openAddTransaction,
              icon: const Icon(Icons.add_rounded),
              label: Text(settings.t('addTransaction')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) async {
        _searchText = value;
        await _loadTransactions();
      },
      decoration: InputDecoration(
        hintText: settings.t('search'),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppTheme.gold,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () async {
                  _searchController.clear();

                  setState(() {
                    _searchText = '';
                  });

                  await _loadTransactions();
                },
                icon: const Icon(Icons.clear_rounded),
              )
            : null,
      ),
    );
  }

  Widget _buildGroupedTransactions() {
    final groups = _groupTransactionsByDate();

    final children = <Widget>[];

    for (final entry in groups.entries) {
      children.add(
        _buildDateHeader(
          entry.key,
          entry.value,
        ),
      );

      for (final transaction in entry.value) {
        children.add(
          _buildTransactionCard(transaction),
        );
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        100,
      ),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(settings.t('transactions')),
        actions: [
          IconButton(
            tooltip: settings.t('addTransaction'),
            onPressed: _openAddTransaction,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: _buildSearchField(),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
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
                      child: CircularProgressIndicator(),
                    )
                  : _transactions.isEmpty
                      ? _buildEmptyState()
                      : _buildGroupedTransactions(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(settings.t('addTransaction')),
      ),
    );
  }
}
