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

  bool get isEditing => transactionId != null;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';

  int? _accountId;
  int? _categoryId;
  int? _fromAccountId;
  int? _toAccountId;

  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _categories = [];

  bool _loading = true;
  bool _saving = false;

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final accounts = await MoneyDb.instance.getAccounts();

      final categories = await MoneyDb.instance.getCategories(
        type: _type == 'transfer' ? null : _type,
      );

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _categories = categories;
        _loading = false;
      });

      if (widget.isEditing) {
        await _loadTransaction();
      } else {
        _setDefaultSelections();
      }
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

  Future<void> _loadTransaction() async {
    final id = widget.transactionId;

    if (id == null) return;

    try {
      final transaction = await MoneyDb.instance.getTransaction(id);

      if (transaction == null) {
        if (!mounted) return;

        _showMessage(
          settings.t('noData'),
          isError: true,
        );

        Navigator.pop(context);
        return;
      }

      final type = transaction['type']?.toString() ?? 'expense';

      final amount =
          (transaction['amount'] as num?)?.toDouble() ?? 0;

      final transactionDate =
          DateTime.tryParse(
                transaction['transaction_date']?.toString() ?? '',
              ) ??
              DateTime.now();

      if (!mounted) return;

      setState(() {
        _type = type;

        _amountController.text = amount == amount.toInt()
            ? amount.toInt().toString()
            : amount.toString();

        _noteController.text =
            transaction['note']?.toString() ?? '';

        _accountId = transaction['account_id'] as int?;
        _categoryId = transaction['category_id'] as int?;

        _fromAccountId =
            transaction['from_account_id'] as int?;

        _toAccountId =
            transaction['to_account_id'] as int?;

        _selectedDate = transactionDate;
      });

      final categories = await MoneyDb.instance.getCategories(
        type: type == 'transfer' ? null : type,
      );

      if (!mounted) return;

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _setDefaultSelections() {
    if (_accounts.isNotEmpty) {
      _accountId ??= _accounts.first['id'] as int;
      _fromAccountId ??= _accounts.first['id'] as int;

      if (_accounts.length > 1) {
        _toAccountId ??= _accounts[1]['id'] as int;
      }
    }

    if (_categories.isNotEmpty) {
      _categoryId ??= _categories.first['id'] as int;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _changeType(String type) async {
    if (_saving) return;

    setState(() {
      _type = type;
      _categoryId = null;
    });

    if (type == 'transfer') {
      _fromAccountId ??=
          _accounts.isNotEmpty ? _accounts.first['id'] as int : null;

      if (_accounts.length > 1) {
        _toAccountId ??= _accounts[1]['id'] as int;
      }

      return;
    }

    final categories = await MoneyDb.instance.getCategories(
      type: type,
    );

    if (!mounted) return;

    setState(() {
      _categories = categories;

      if (_categories.isNotEmpty) {
        _categoryId = _categories.first['id'] as int;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.green,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _saveTransaction() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      _showMessage(
        settings.t('enterAmount'),
        isError: true,
      );
      return;
    }

    if (_type == 'transfer') {
      if (_fromAccountId == null || _toAccountId == null) {
        _showMessage(
          settings.t('requiredField'),
          isError: true,
        );
        return;
      }

      if (_fromAccountId == _toAccountId) {
        _showMessage(
          settings.isBangla
              ? 'একই অ্যাকাউন্টে ট্রান্সফার করা যাবে না'
              : 'You cannot transfer to the same account',
          isError: true,
        );
        return;
      }
    } else {
      if (_accountId == null || _categoryId == null) {
        _showMessage(
          settings.t('requiredField'),
          isError: true,
        );
        return;
      }
    }

    setState(() {
      _saving = true;
    });

    try {
      if (widget.isEditing) {
        await MoneyDb.instance.updateTransaction(
          id: widget.transactionId!,
          type: _type,
          amount: amount,
          categoryId: _type == 'transfer' ? null : _categoryId,
          accountId: _type == 'transfer' ? null : _accountId,
          fromAccountId:
              _type == 'transfer' ? _fromAccountId : null,
          toAccountId:
              _type == 'transfer' ? _toAccountId : null,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          transactionDate: _selectedDate,
        );
      } else {
        await MoneyDb.instance.addTransaction(
          type: _type,
          amount: amount,
          categoryId: _type == 'transfer' ? null : _categoryId,
          accountId: _type == 'transfer' ? null : _accountId,
          fromAccountId:
              _type == 'transfer' ? _fromAccountId : null,
          toAccountId:
              _type == 'transfer' ? _toAccountId : null,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          transactionDate: _selectedDate,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _accountName(int id) {
    final account = _accounts.where(
      (item) => item['id'] == id,
    );

    if (account.isEmpty) {
      return '';
    }

    return account.first['name']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? settings.t('editTransaction')
              : settings.t('addTransaction'),
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTypeSelector(),

                    const SizedBox(height: 20),

                    _buildAmountField(),

                    const SizedBox(height: 16),

                    if (_type == 'transfer')
                      _buildTransferFields()
                    else
                      _buildIncomeExpenseFields(),

                    const SizedBox(height: 16),

                    _buildDateField(),

                    const SizedBox(height: 16),

                    _buildNoteField(),

                    const SizedBox(height: 28),

                    _buildSaveButton(isDark),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _typeButton(
              type: 'income',
              label: settings.t('income'),
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Expanded(
            child: _typeButton(
              type: 'expense',
              label: settings.t('expense'),
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Expanded(
            child: _typeButton(
              type: 'transfer',
              label: settings.t('transfer'),
              icon: Icons.swap_horiz_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeButton({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final selected = _type == type;

    return GestureDetector(
      onTap: () => _changeType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.green
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 21,
              color: selected
                  ? Colors.white
                  : AppTheme.gold,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: settings.t('amount'),
        hintText: '0.00',
        prefixIcon: const Icon(
          Icons.payments_outlined,
          color: AppTheme.gold,
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (text.isEmpty) {
          return settings.t('enterAmount');
        }

        final amount = double.tryParse(
          text.replaceAll(',', ''),
        );

        if (amount == null || amount <= 0) {
          return settings.isBangla
              ? 'সঠিক পরিমাণ লিখুন'
              : 'Enter a valid amount';
        }

        return null;
      },
    );
  }

  Widget _buildIncomeExpenseFields() {
    return Column(
      children: [
        _buildAccountDropdown(),

        const SizedBox(height: 16),

        _buildCategoryDropdown(),
      ],
    );
  }

  Widget _buildAccountDropdown() {
    return DropdownButtonFormField<int>(
      value: _accounts.any(
        (item) => item['id'] == _accountId,
      )
          ? _accountId
          : null,
      decoration: InputDecoration(
        labelText: settings.t('accounts'),
        prefixIcon: const Icon(
          Icons.account_balance_wallet_outlined,
          color: AppTheme.gold,
        ),
      ),
      items: _accounts.map((account) {
        final id = account['id'] as int;
        final name = account['name']?.toString() ?? '';

        return DropdownMenuItem<int>(
          value: id,
          child: Text(name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _accountId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return settings.t('requiredField');
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<int>(
      value: _categories.any(
        (item) => item['id'] == _categoryId,
      )
          ? _categoryId
          : null,
      decoration: InputDecoration(
        labelText: settings.t('categories'),
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: AppTheme.gold,
        ),
      ),
      items: _categories.map((category) {
        final id = category['id'] as int;
        final name = category['name']?.toString() ?? '';

        return DropdownMenuItem<int>(
          value: id,
          child: Text(name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _categoryId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return settings.t('requiredField');
        }
        return null;
      },
    );
  }

  Widget _buildTransferFields() {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          value: _accounts.any(
            (item) => item['id'] == _fromAccountId,
          )
              ? _fromAccountId
              : null,
          decoration: InputDecoration(
            labelText: settings.t('fromAccount'),
            prefixIcon: const Icon(
              Icons.arrow_upward_rounded,
              color: AppTheme.gold,
            ),
          ),
          items: _accounts.map((account) {
            final id = account['id'] as int;

            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                account['name']?.toString() ?? '',
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _fromAccountId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return settings.t('requiredField');
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.green.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_downward_rounded,
            color: AppTheme.gold,
          ),
        ),

        const SizedBox(height: 16),

        DropdownButtonFormField<int>(
          value: _accounts.any(
            (item) => item['id'] == _toAccountId,
          )
              ? _toAccountId
              : null,
          decoration: InputDecoration(
            labelText: settings.t('toAccount'),
            prefixIcon: const Icon(
              Icons.arrow_downward_rounded,
              color: AppTheme.gold,
            ),
          ),
          items: _accounts.map((account) {
            final id = account['id'] as int;

            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                account['name']?.toString() ?? '',
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _toAccountId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return settings.t('requiredField');
            }
            return null;
          },
        ),

        if (_fromAccountId != null &&
            _toAccountId != null &&
            _fromAccountId == _toAccountId)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              settings.isBangla
                  ? 'একই অ্যাকাউন্ট নির্বাচন করা হয়েছে'
                  : 'The same account is selected',
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
              ),
            ),
          ),

        if (_fromAccountId != null &&
            _toAccountId != null &&
            _fromAccountId != _toAccountId)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '${_accountName(_fromAccountId!)} → '
              '${_accountName(_toAccountId!)}',
              style: TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: settings.t('date'),
          prefixIcon: const Icon(
            Icons.calendar_month_outlined,
            color: AppTheme.gold,
          ),
        ),
        child: Text(
          _formatDate(_selectedDate),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        labelText: settings.t('note'),
        hintText: settings.isBangla
            ? 'প্রয়োজনে নোট লিখুন'
            : 'Write a note if needed',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 45),
          child: Icon(
            Icons.notes_outlined,
            color: AppTheme.gold,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _saveTransaction,
        icon: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                widget.isEditing
                    ? Icons.check_rounded
                    : Icons.save_rounded,
              ),
        label: Text(
          _saving
              ? settings.t('loading')
              : widget.isEditing
                  ? settings.t('update')
                  : settings.t('save'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
