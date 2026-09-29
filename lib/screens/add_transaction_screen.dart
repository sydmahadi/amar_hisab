
import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final int? transactionId;

  const AddTransactionScreen({
    super.key,
    this.transactionId,
  });

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _personController = TextEditingController();

  AppSettings get settings => AppSettings.instance;

  String _type = 'expense';

  int? _selectedAccountId;
  int? _fromAccountId;
  int? _toAccountId;
  int? _selectedCategoryId;
  int? _selectedLoanId;

  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _loans = [];

  bool _loading = true;
  bool _saving = false;

  bool get _isTransfer => _type == 'transfer';

  bool get _isLoanGiven => _type == 'loan_given';

  bool get _isLoanTaken => _type == 'loan_taken';

  bool get _isLoanReceived => _type == 'loan_received';

  bool get _isLoanPaid => _type == 'loan_paid';

  bool get _isNewLoan => _isLoanGiven || _isLoanTaken;

  bool get _isLoanRepayment =>
      _isLoanReceived || _isLoanPaid;

  bool get _isLoanTransaction =>
      _isNewLoan || _isLoanRepayment;

  bool get _isEdit => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _personController.dispose();
    super.dispose();
  }

  String _text(String bn, String en) =>
      settings.isBangla ? bn : en;

  String _formatAmount(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;

    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
  }

  Future<void> _loadInitialData() async {
    try {
      final accounts = await MoneyDb.instance.getAccounts();
      final loans = await MoneyDb.instance.getLoans();

      Map<String, dynamic>? existing;

      if (_isEdit) {
        final transactions =
            await MoneyDb.instance.getTransactions();

        for (final transaction in transactions) {
          if (transaction['id'] == widget.transactionId) {
            existing = transaction;
            break;
          }
        }
      }

      String initialType = 'expense';

      if (existing != null) {
        initialType = existing['type']?.toString() ?? 'expense';

        _amountController.text =
            (existing['amount'] as num?)?.toString() ?? '';

        _noteController.text =
            existing['note']?.toString() ?? '';

        _personController.text =
            existing['loan_person_name']?.toString() ?? '';

        final date = DateTime.tryParse(
          existing['transaction_date']?.toString() ?? '',
        );

        if (date != null) {
          _selectedDate = date;
        }

        _selectedAccountId =
            (existing['account_id'] as num?)?.toInt();

        _fromAccountId =
            (existing['from_account_id'] as num?)?.toInt();

        _toAccountId =
            (existing['to_account_id'] as num?)?.toInt();

        _selectedCategoryId =
            (existing['category_id'] as num?)?.toInt();

        _selectedLoanId =
            (existing['loan_id'] as num?)?.toInt();
      }

      final categories =
          initialType == 'income' || initialType == 'expense'
              ? await MoneyDb.instance.getCategories(
                  type: initialType,
                )
              : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _type = initialType;
        _accounts = accounts;
        _categories = categories;
        _loans = loans;

        if (_selectedAccountId == null && accounts.isNotEmpty) {
          _selectedAccountId =
              (accounts.first['id'] as num?)?.toInt();
        }

        if (_fromAccountId == null && accounts.isNotEmpty) {
          _fromAccountId =
              (accounts.first['id'] as num?)?.toInt();
        }

        if (_toAccountId == null && accounts.length > 1) {
          _toAccountId =
              (accounts[1]['id'] as num?)?.toInt();
        }

        if (_selectedCategoryId == null &&
            categories.isNotEmpty) {
          _selectedCategoryId =
              (categories.first['id'] as num?)?.toInt();
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage(_errorText(e), isError: true);
    }
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _onTypeChanged(String newType) async {
    if (_saving || _type == newType) return;

    setState(() {
      _type = newType;
      _selectedCategoryId = null;
      _selectedLoanId = null;
      _loading = true;
    });

    try {
      final categories =
          newType == 'income' || newType == 'expense'
              ? await MoneyDb.instance.getCategories(
                  type: newType,
                )
              : <Map<String, dynamic>>[];

      final loans = await MoneyDb.instance.getLoans();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _loans = loans;

        if (categories.isNotEmpty) {
          _selectedCategoryId =
              (categories.first['id'] as num?)?.toInt();
        }

        if (_isLoanRepayment) {
          final desiredType =
              _isLoanReceived ? 'receivable' : 'payable';

          final available = loans.where(
            (loan) =>
                loan['type']?.toString() == desiredType &&
                ((loan['remaining'] as num?)?.toDouble() ?? 0) > 0,
          );

          _selectedLoanId = available.isEmpty
              ? null
              : (available.first['id'] as num?)?.toInt();
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage(_errorText(e), isError: true);
    }
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_text('নতুন খাত যোগ করুন', 'Add Category')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: _text('খাতের নাম', 'Category Name'),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_text('বাতিল', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              }
            },
            child: Text(_text('যোগ করুন', 'Add')),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    try {
      final existing = await MoneyDb.instance.getCategories(
        type: _type,
      );

      if (existing.any(
        (item) =>
            item['name'].toString().trim().toLowerCase() ==
            name.trim().toLowerCase(),
      )) {
        _showMessage(
          _text('এই খাতটি আগে থেকেই আছে', 'Category already exists'),
          isError: true,
        );
        return;
      }

      final id = await MoneyDb.instance.addCategory(
        name: name.trim(),
        type: _type,
        icon: Icons.category_outlined.codePoint,
        color: AppTheme.green.toARGB32(),
      );

      final categories = await MoneyDb.instance.getCategories(
        type: _type,
      );

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _selectedCategoryId = id;
      });

      _showMessage(_text('খাত যোগ হয়েছে', 'Category added'));
    } catch (e) {
      _showMessage(_errorText(e), isError: true);
    }
  }

  List<Map<String, dynamic>> get _repaymentLoans {
    final desiredType =
        _isLoanReceived ? 'receivable' : 'payable';

    return _loans.where((loan) {
      final remaining =
          (loan['remaining'] as num?)?.toDouble() ?? 0;

      return loan['type']?.toString() == desiredType &&
          remaining > 0;
    }).toList();
  }

  Future<void> _refreshLoans() async {
    final loans = await MoneyDb.instance.getLoans();

    if (!mounted) return;

    setState(() {
      _loans = loans;

      if (_isLoanRepayment &&
          !_repaymentLoans.any(
            (loan) =>
                (loan['id'] as num?)?.toInt() ==
                _selectedLoanId,
          )) {
        _selectedLoanId = _repaymentLoans.isEmpty
            ? null
            : (_repaymentLoans.first['id'] as num?)?.toInt();
      }
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  String _dateText() {
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final month =
        _selectedDate.month.toString().padLeft(2, '0');

    return '$day/$month/${_selectedDate.year}';
  }

  String _accountName(Map<String, dynamic> account) {
    final name = account['name']?.toString() ?? '';

    switch (name.toLowerCase()) {
      case 'cash':
        return _text('ক্যাশ', 'Cash');
      case 'bkash':
        return _text('বিকাশ', 'Bkash');
      case 'nagad':
        return _text('নগদ', 'Nagad');
      case 'bank account':
        return _text('ব্যাংক অ্যাকাউন্ট', 'Bank Account');
      case 'card':
        return _text('কার্ড', 'Card');
      default:
        return name;
    }
  }

  String _typeName(String type) {
    switch (type) {
      case 'income':
        return _text('আয়', 'Income');
      case 'expense':
        return _text('ব্যয়', 'Expense');
      case 'transfer':
        return _text('ট্রান্সফার', 'Transfer');
      case 'loan_given':
        return _text('ধার দিয়েছি', 'Loan Given');
      case 'loan_taken':
        return _text('ধার নিয়েছি', 'Loan Taken');
      case 'loan_received':
        return _text('ধার ফেরত পেয়েছি', 'Loan Received');
      case 'loan_paid':
        return _text('ধার শোধ করেছি', 'Loan Repaid');
      default:
        return type;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'income':
        return const Color(0xFF2E9D68);
      case 'transfer':
        return const Color(0xFF3F7FD6);
      case 'loan_given':
      case 'loan_received':
        return const Color(0xFFB99550);
      case 'loan_taken':
      case 'loan_paid':
        return const Color(0xFF8E72C7);
      default:
        return const Color(0xFFD9534F);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.south_west_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'loan_given':
        return Icons.call_made_rounded;
      case 'loan_taken':
        return Icons.call_received_rounded;
      case 'loan_received':
        return Icons.payments_outlined;
      case 'loan_paid':
        return Icons.price_check_rounded;
      default:
        return Icons.north_east_rounded;
    }
  }

  Widget _buildTypeSelector() {
    const types = [
      'expense',
      'income',
      'transfer',
      'loan_given',
      'loan_taken',
      'loan_received',
      'loan_paid',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text('লেনদেনের ধরন', 'Transaction Type'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            final selected = _type == type;
            final color = _typeColor(type);

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _saving ? null : () => _onTypeChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.14)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? color
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _typeIcon(type),
                      size: 19,
                      color: color,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _typeName(type),
                      style: TextStyle(
                        color: selected
                            ? color
                            : Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    final color = _typeColor(_type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('টাকার পরিমাণ', 'Amount'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              prefixText: '৳ ',
              hintText: '0.00',
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (value) {
              final amount = double.tryParse(
                (value ?? '').trim(),
              );

              if (amount == null || amount <= 0) {
                return _text(
                  'সঠিক টাকার পরিমাণ লিখুন',
                  'Enter a valid amount',
                );
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDropdown() {
    if (_accounts.isEmpty) {
      return _emptyMessage(
        _text('কোনো অ্যাকাউন্ট নেই', 'No accounts available'),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _accounts.any(
        (a) => (a['id'] as num?)?.toInt() == _selectedAccountId,
      )
          ? _selectedAccountId
          : null,
      decoration: InputDecoration(
        labelText: _text('অ্যাকাউন্ট', 'Account'),
        prefixIcon: const Icon(
          Icons.account_balance_wallet_outlined,
        ),
      ),
      items: _accounts.map((account) {
        final id = (account['id'] as num).toInt();

        return DropdownMenuItem<int>(
          value: id,
          child: Text(_accountName(account)),
        );
      }).toList(),
      onChanged: _saving
          ? null
          : (value) {
              setState(() => _selectedAccountId = value);
            },
    );
  }

  Widget _buildTransferAccounts() {
    if (_accounts.length < 2) {
      return _emptyMessage(
        _text(
          'ট্রান্সফারের জন্য অন্তত দুটি অ্যাকাউন্ট দরকার',
          'Transfer requires at least two accounts',
        ),
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<int>(
          initialValue: _accounts.any(
            (a) => (a['id'] as num?)?.toInt() == _fromAccountId,
          )
              ? _fromAccountId
              : null,
          decoration: InputDecoration(
            labelText: _text('যে অ্যাকাউন্ট থেকে', 'From Account'),
            prefixIcon: const Icon(Icons.call_made_rounded),
          ),
          items: _accounts.map((account) {
            final id = (account['id'] as num).toInt();

            return DropdownMenuItem<int>(
              value: id,
              child: Text(_accountName(account)),
            );
          }).toList(),
          onChanged: _saving
              ? null
              : (value) {
                  setState(() {
                    _fromAccountId = value;

                    if (_fromAccountId == _toAccountId) {
                      _toAccountId = _accounts
                          .map((a) => (a['id'] as num).toInt())
                          .firstWhere((id) => id != value);
                    }
                  });
                },
        ),
        const SizedBox(height: 12),
        const Icon(
          Icons.south_rounded,
          color: AppTheme.gold,
          size: 26,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _accounts.any(
            (a) => (a['id'] as num?)?.toInt() == _toAccountId,
          )
              ? _toAccountId
              : null,
          decoration: InputDecoration(
            labelText: _text('যে অ্যাকাউন্টে', 'To Account'),
            prefixIcon: const Icon(Icons.call_received_rounded),
          ),
          items: _accounts
              .where(
                (account) =>
                    (account['id'] as num).toInt() !=
                    _fromAccountId,
              )
              .map((account) {
            final id = (account['id'] as num).toInt();

            return DropdownMenuItem<int>(
              value: id,
              child: Text(_accountName(account)),
            );
          }).toList(),
          onChanged: _saving
              ? null
              : (value) {
                  setState(() => _toAccountId = value);
                },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _categories.any(
              (c) =>
                  (c['id'] as num?)?.toInt() ==
                  _selectedCategoryId,
            )
                ? _selectedCategoryId
                : null,
            decoration: InputDecoration(
              labelText: _text('খাত', 'Category'),
              prefixIcon: const Icon(
                Icons.category_outlined,
              ),
            ),
            items: _categories.map((category) {
              final id = (category['id'] as num).toInt();

              return DropdownMenuItem<int>(
                value: id,
                child: Text(
                  category['name']?.toString() ?? '',
                ),
              );
            }).toList(),
            onChanged: _saving
                ? null
                : (value) {
                    setState(
                      () => _selectedCategoryId = value,
                    );
                  },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: _text('নতুন খাত যোগ করুন', 'Add Category'),
          onPressed: _saving ? null : _addCategory,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }

  Widget _buildPersonField() {
    return TextFormField(
      controller: _personController,
      readOnly: _isEdit,
      decoration: InputDecoration(
        labelText: _text('ব্যক্তির নাম', 'Person Name'),
        hintText: _text(
          'যেমন: রহিম',
          'Example: Rahim',
        ),
        prefixIcon: const Icon(Icons.person_outline_rounded),
      ),
      validator: (value) {
        if (_isNewLoan && (value ?? '').trim().isEmpty) {
          return _text(
            'ব্যক্তির নাম লিখুন',
            'Enter the person name',
          );
        }

        return null;
      },
    );
  }

  Widget _buildLoanDropdown() {
    if (_repaymentLoans.isEmpty) {
      return _emptyMessage(
        _isLoanReceived
            ? _text(
                'ফেরত পাওয়ার মতো কোনো ধার নেই',
                'No receivable loans available',
              )
            : _text(
                'শোধ করার মতো কোনো ধার নেই',
                'No payable loans available',
              ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _repaymentLoans.any(
        (loan) =>
            (loan['id'] as num?)?.toInt() == _selectedLoanId,
      )
          ? _selectedLoanId
          : null,
      decoration: InputDecoration(
        labelText: _text('ধার নির্বাচন করুন', 'Select Loan'),
        prefixIcon: const Icon(Icons.people_alt_outlined),
      ),
      items: _repaymentLoans.map((loan) {
        final id = (loan['id'] as num).toInt();
        final remaining =
            (loan['remaining'] as num?)?.toDouble() ?? 0;

        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            '${loan['person_name']} • ৳${_formatAmount(remaining)}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _saving
          ? null
          : (value) {
              setState(() => _selectedLoanId = value);
            },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _saving ? null : _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _text('তারিখ', 'Date'),
          prefixIcon: const Icon(
            Icons.calendar_month_rounded,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: Text(_dateText())),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: _text('নোট / বিবরণ', 'Note / Description'),
        hintText: _text(
          'প্রয়োজনে বিস্তারিত লিখুন',
          'Add details if needed',
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 36),
          child: Icon(Icons.note_alt_outlined),
        ),
      ),
    );
  }

  Widget _emptyMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message),
    );
  }

  Future<void> _saveTransaction() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    final amount =
        double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      _showMessage(
        _text('সঠিক পরিমাণ লিখুন', 'Enter a valid amount'),
        isError: true,
      );
      return;
    }

    if (_accounts.isEmpty) {
      _showMessage(
        _text('কোনো অ্যাকাউন্ট নেই', 'No accounts available'),
        isError: true,
      );
      return;
    }

    if (_isTransfer) {
      if (_fromAccountId == null || _toAccountId == null) {
        _showMessage(
          _text('দুটি অ্যাকাউন্ট নির্বাচন করুন', 'Select both accounts'),
          isError: true,
        );
        return;
      }

      if (_fromAccountId == _toAccountId) {
        _showMessage(
          _text(
            'দুটি আলাদা অ্যাকাউন্ট নির্বাচন করুন',
            'Choose two different accounts',
          ),
          isError: true,
        );
        return;
      }
    } else if (_selectedAccountId == null) {
      _showMessage(
        _text('অ্যাকাউন্ট নির্বাচন করুন', 'Select an account'),
        isError: true,
      );
      return;
    }

    if ((_type == 'income' || _type == 'expense') &&
        _selectedCategoryId == null) {
      _showMessage(
        _text('একটি খাত নির্বাচন করুন', 'Select a category'),
        isError: true,
      );
      return;
    }

    if (_isLoanRepayment) {
      if (_selectedLoanId == null ||
          !_repaymentLoans.any(
            (loan) =>
                (loan['id'] as num?)?.toInt() ==
                _selectedLoanId,
          )) {
        _showMessage(
          _text(
            'একটি সক্রিয় ধার নির্বাচন করুন',
            'Select an active loan',
          ),
          isError: true,
        );
        return;
      }

      final loan = _repaymentLoans.firstWhere(
        (item) =>
            (item['id'] as num).toInt() ==
            _selectedLoanId,
      );

      final remaining =
          (loan['remaining'] as num?)?.toDouble() ?? 0;

      if (amount > remaining) {
        _showMessage(
          _text(
            'পরিমাণ বাকি ধার থেকে বেশি হতে পারবে না',
            'Amount cannot exceed the remaining loan',
          ),
          isError: true,
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final note = _noteController.text.trim();

      if (_isEdit) {
        await MoneyDb.instance.updateTransaction(
          widget.transactionId!,
          type: _type,
          amount: amount,
          categoryId: _selectedCategoryId,
          accountId: _isTransfer ? null : _selectedAccountId,
          fromAccountId: _isTransfer ? _fromAccountId : null,
          toAccountId: _isTransfer ? _toAccountId : null,
          loanId: _isLoanTransaction ? _selectedLoanId : null,
          note: note,
          transactionDate: _selectedDate,
        );
      } else if (_isNewLoan) {
        await MoneyDb.instance.createLoan(
          personName: _personController.text.trim(),
          type: _isLoanGiven ? 'receivable' : 'payable',
          amount: amount,
          accountId: _selectedAccountId!,
          note: note,
          transactionDate: _selectedDate,
        );
      } else if (_isLoanRepayment) {
        await MoneyDb.instance.addLoanRepayment(
          loanId: _selectedLoanId!,
          amount: amount,
          accountId: _selectedAccountId!,
          note: note,
          transactionDate: _selectedDate,
        );
      } else {
        await MoneyDb.instance.addTransaction(
          type: _type,
          amount: amount,
          categoryId: _selectedCategoryId,
          accountId: _isTransfer ? null : _selectedAccountId,
          fromAccountId: _isTransfer ? _fromAccountId : null,
          toAccountId: _isTransfer ? _toAccountId : null,
          note: note,
          transactionDate: _selectedDate,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(_errorText(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? _text('লেনদেন সম্পাদনা', 'Edit Transaction')
              : _text('নতুন লেনদেন', 'New Transaction'),
      ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    30,
                  ),
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 20),
                    _buildAmountField(),
                    const SizedBox(height: 16),

                    if (_isNewLoan) ...[
                      _buildPersonField(),
                      const SizedBox(height: 14),
                    ],

                    if (_isLoanRepayment) ...[
                      _buildLoanDropdown(),
                      const SizedBox(height: 14),
                    ],

                    if (_isTransfer) ...[
                      _buildTransferAccounts(),
                    ] else ...[
                      _buildAccountDropdown(),
                    ],

                    if (_type == 'income' ||
                        _type == 'expense') ...[
                      const SizedBox(height: 14),
                      _buildCategoryDropdown(),
                    ],

                    if (_isLoanTransaction) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.gold,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isLoanGiven
                                    ? _text(
                                        'এই টাকা আপনার পাওনা হিসেবে থাকবে।',
                                        'This amount will be recorded as money owed to you.',
                                      )
                                    : _isLoanTaken
                                        ? _text(
                                            'এই টাকা আপনার পরিশোধযোগ্য ধার হিসেবে থাকবে।',
                                            'This amount will be recorded as money you owe.',
                                          )
                                        : _isLoanReceived
                                            ? _text(
                                                'নির্বাচিত ব্যক্তি থেকে ফেরত পাওয়া টাকা যোগ হবে।',
                                                'The repayment received will reduce the outstanding loan.',
                                              )
                                            : _text(
                                                'নির্বাচিত ধার পরিশোধের হিসাব আপডেট হবে।',
                                                'The selected loan balance will be reduced.',
                                              ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    _buildDateField(),
                    const SizedBox(height: 14),
                    _buildNoteField(),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveTransaction,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isEdit
                                    ? Icons.check_rounded
                                    : Icons.save_rounded,
                              ),
                        label: Text(
                          _saving
                              ? _text('সংরক্ষণ হচ্ছে...', 'Saving...')
                              : _isEdit
                                  ? _text('আপডেট করুন', 'Update')
                                  : _text(
                                      'লেনদেন সংরক্ষণ করুন',
                                      'Save Transaction',
                                    ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
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
