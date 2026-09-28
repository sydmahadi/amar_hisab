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
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';

  int? _selectedAccountId;
  int? _selectedCategoryId;

  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _categories = [];

  bool _loading = true;
  bool _saving = false;

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadInitialData() async {
    try {
      final accounts =
          await MoneyDb.instance.getAccounts();

      Map<String, dynamic>? existingTx;

      if (widget.transactionId != null) {
        final allTxs =
            await MoneyDb.instance.getTransactions();

        final matches = allTxs.where(
          (t) => t['id'] == widget.transactionId,
        );

        if (matches.isNotEmpty) {
          existingTx = matches.first;
        }
      }

      if (existingTx != null) {
        _type =
            existingTx['type']?.toString() ?? 'expense';

        _amountController.text =
            (existingTx['amount'] as num?)
                    ?.toString() ??
                '';

        _noteController.text =
            existingTx['note']?.toString() ?? '';

        if (existingTx['transaction_date'] != null) {
          _selectedDate =
              DateTime.tryParse(
                    existingTx['transaction_date']
                        .toString(),
                  ) ??
                  DateTime.now();
        }
      }

      final categories =
          _type == 'transfer'
              ? <Map<String, dynamic>>[]
              : await MoneyDb.instance.getCategories(
                  type: _type,
                );

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _categories = categories;

        if (existingTx != null) {
          _selectedAccountId =
              existingTx['account_id'] as int?;

          _selectedCategoryId =
              existingTx['category_id'] as int?;
        } else {
          if (_accounts.isNotEmpty) {
            _selectedAccountId =
                _accounts.first['id'] as int?;
          }

          if (_categories.isNotEmpty) {
            _selectedCategoryId =
                _categories.first['id'] as int?;
          }
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  // ============================================================
  // TYPE CHANGE
  // ============================================================

  Future<void> _onTypeChanged(
    String newType,
  ) async {
    if (_type == newType) return;

    setState(() {
      _type = newType;
      _selectedCategoryId = null;
      _loading = true;
    });

    try {
      final categories =
          newType == 'transfer'
              ? <Map<String, dynamic>>[]
              : await MoneyDb.instance.getCategories(
                  type: newType,
                );

      if (!mounted) return;

      setState(() {
        _categories = categories;

        if (_categories.isNotEmpty) {
          _selectedCategoryId =
              _categories.first['id'] as int?;
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  // ============================================================
  // ADD CATEGORY
  // ============================================================

  Future<void> _addNewCategory() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            settings.isBangla
                ? 'নতুন খাত যোগ করুন'
                : 'Add New Category',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction:
                TextInputAction.done,
            decoration: InputDecoration(
              labelText: settings.isBangla
                  ? 'খাতের নাম'
                  : 'Category Name',
              hintText: settings.isBangla
                  ? 'যেমন: খাবার, বেতন, যাতায়াত'
                  : 'Example: Food, Salary, Transport',
              prefixIcon: const Icon(
                Icons.category_outlined,
              ),
            ),
            onSubmitted: (_) {
              final value =
                  controller.text.trim();

              if (value.isNotEmpty) {
                Navigator.pop(
                  dialogContext,
                  value,
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: Text(
                settings.isBangla
                    ? 'বাতিল'
                    : 'Cancel',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(
                    dialogContext,
                    value,
                  );
                }
              },
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: Text(
                settings.isBangla
                    ? 'যোগ করুন'
                    : 'Add',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      final existing =
          await MoneyDb.instance.getCategories(
        type: _type,
      );

      final alreadyExists = existing.any(
        (category) =>
            category['name']
                .toString()
                .trim()
                .toLowerCase() ==
            name.trim().toLowerCase(),
      );

      if (alreadyExists) {
        if (!mounted) return;

        _showMessage(
          settings.isBangla
              ? 'এই নামে খাত আগে থেকেই আছে'
              : 'A category with this name already exists',
          isError: true,
        );

        return;
      }

      final categoryId =
          await MoneyDb.instance.addCategory(
        name: name.trim(),
        type: _type,
        icon: _type == 'income'
            ? Icons.payments_outlined.codePoint
            : Icons.category_outlined.codePoint,
        color: _type == 'income'
            ? AppTheme.green.toARGB32()
            : Colors.red.shade600.toARGB32(),
      );

      final categories =
          await MoneyDb.instance.getCategories(
        type: _type,
      );

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _selectedCategoryId = categoryId;
      });

      _showMessage(
        settings.isBangla
            ? 'নতুন খাত যোগ হয়েছে'
            : 'New category added',
      );
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

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveTransaction() async {
    if (_saving) return;

    final amountText =
        _amountController.text.trim();

    if (amountText.isEmpty) {
      _showMessage(
        settings.isBangla
            ? 'টাকার পরিমাণ লিখুন'
            : 'Enter an amount',
        isError: true,
      );
      return;
    }

    final amount =
        double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showMessage(
        settings.isBangla
            ? 'সঠিক টাকার পরিমাণ দিন'
            : 'Enter a valid amount',
        isError: true,
      );
      return;
    }

    if (_selectedAccountId == null) {
      _showMessage(
        settings.isBangla
            ? 'একটি অ্যাকাউন্ট নির্বাচন করুন'
            : 'Select an account',
        isError: true,
      );
      return;
    }

    if (_type != 'transfer' &&
        _selectedCategoryId == null) {
      _showMessage(
        settings.isBangla
            ? 'একটি খাত নির্বাচন করুন'
            : 'Select a category',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (widget.transactionId != null) {
        await MoneyDb.instance.updateTransaction(
          widget.transactionId!,
          type: _type,
          amount: amount,
          accountId: _selectedAccountId,
          categoryId: _selectedCategoryId,
          note: _noteController.text.trim(),
          transactionDate: _selectedDate,
        );
      } else {
        await MoneyDb.instance.addTransaction(
          type: _type,
          amount: amount,
          accountId: _selectedAccountId,
          categoryId: _selectedCategoryId,
          note: _noteController.text.trim(),
          transactionDate: _selectedDate,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _selectDate() async {
    final selected =
        await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(
                  primary: AppTheme.green,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _selectedDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate() {
    final d = _selectedDate.day
        .toString()
        .padLeft(2, '0');

    final m = _selectedDate.month
        .toString()
        .padLeft(2, '0');

    final y = _selectedDate.year
        .toString();

    return '$d/$m/$y';
  }

  String _accountName(
    Map<String, dynamic> account,
  ) {
    final name =
        account['name']?.toString() ?? '';

    switch (name.toLowerCase()) {
      case 'cash':
        return settings.isBangla
            ? 'ক্যাশ'
            : 'Cash';

      case 'bkash':
        return settings.isBangla
            ? 'বিকাশ'
            : 'Bkash';

      case 'nagad':
        return settings.isBangla
            ? 'নগদ'
            : 'Nagad';

      case 'bank account':
        return settings.isBangla
            ? 'ব্যাংক অ্যাকাউন্ট'
            : 'Bank Account';

      case 'card':
        return settings.isBangla
            ? 'কার্ড'
            : 'Card';

      default:
        return name;
    }
  }

  IconData _accountIcon(
    String type,
  ) {
    switch (type) {
      case 'cash':
        return Icons.payments_rounded;

      case 'bkash':
        return Icons.phone_android_rounded;

      case 'nagad':
        return Icons.account_balance_wallet_rounded;

      case 'bank':
        return Icons.account_balance_rounded;

      case 'card':
        return Icons.credit_card_rounded;

      default:
        return Icons.wallet_rounded;
    }
  }

  Color _typeColor(
    String type,
  ) {
    switch (type) {
      case 'income':
        return const Color(0xFF2E9D68);

      case 'transfer':
        return const Color(0xFF3F7FD6);

      default:
        return const Color(0xFFD9534F);
    }
  }

  IconData _typeIcon(
    String type,
  ) {
    switch (type) {
      case 'income':
        return Icons.south_west_rounded;

      case 'transfer':
        return Icons.swap_horiz_rounded;

      default:
        return Icons.north_east_rounded;
    }
  }

  String _typeTitle(
    String type,
  ) {
    switch (type) {
      case 'income':
        return settings.isBangla
            ? 'আয়'
            : 'Income';

      case 'transfer':
        return settings.isBangla
            ? 'ট্রান্সফার'
            : 'Transfer';

      default:
        return settings.isBangla
            ? 'ব্যয়'
            : 'Expense';
    }
  }

  String _typeSubtitle(
    String type,
  ) {
    switch (type) {
      case 'income':
        return settings.isBangla
            ? 'টাকা এসেছে'
            : 'Money received';

      case 'transfer':
        return settings.isBangla
            ? 'এক অ্যাকাউন্ট থেকে অন্যটিতে'
            : 'Between accounts';

      default:
        return settings.isBangla
            ? 'টাকা খরচ হয়েছে'
            : 'Money spent';
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
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.red.shade700
              : AppTheme.green,
        ),
      );
  }

  // ============================================================
  // TRANSACTION TYPE SELECTOR
  // ============================================================

  Widget _buildTypeSelector() {
    final types = [
      'expense',
      'income',
      'transfer',
    ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          settings.isBangla
              ? 'লেনদেনের ধরন'
              : 'Transaction Type',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: types.map((type) {
            final selected =
                _type == type;

            final color =
                _typeColor(type);

            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(
                  right: type == 'transfer'
                      ? 0
                      : 8,
                ),
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(
                    17,
                  ),
                  onTap: _saving
                      ? null
                      : () =>
                          _onTypeChanged(
                            type,
                          ),
                  child: AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 220,
                    ),
                    curve:
                        Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 13,
                    ),
                    decoration:
                        BoxDecoration(
                      color: selected
                          ? color.withValues(
                              alpha: 0.13,
                            )
                          : Theme.of(context)
                              .cardColor,
                      borderRadius:
                          BorderRadius.circular(
                        17,
                      ),
                      border: Border.all(
                        color: selected
                            ? color
                            : Theme.of(context)
                                .dividerColor,
                        width:
                            selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration:
                              const Duration(
                            milliseconds: 220,
                          ),
                          width: 43,
                          height: 43,
                          decoration:
                              BoxDecoration(
                            color: selected
                                ? color
                                : color.withValues(
                                    alpha: 0.08,
                                  ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _typeIcon(type),
                            color: selected
                                ? Colors.white
                                : color,
                            size: 21,
                          ),
                        ),
                        const SizedBox(
                          height: 7,
                        ),
                        Text(
                          _typeTitle(type),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? color
                                : Theme.of(
                                    context,
                                  )
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          _typeSubtitle(type),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodySmall
                                ?.color,
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        AnimatedOpacity(
                          duration:
                              const Duration(
                            milliseconds: 180,
                          ),
                          opacity:
                              selected ? 1 : 0,
                          child: Icon(
                            Icons
                                .check_circle_rounded,
                            color: color,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================
  // AMOUNT
  // ============================================================

  Widget _buildAmountField() {
    final color = _typeColor(_type);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        15,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(20),
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
            settings.isBangla
                ? 'টাকার পরিমাণ'
                : 'Amount',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color,
            ),
          ),
          const SizedBox(height: 3),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            decoration:
                const InputDecoration(
              border: InputBorder.none,
              filled: false,
              hintText: '0.00',
              contentPadding:
                  EdgeInsets.zero,
              prefixText: '৳ ',
              prefixStyle: TextStyle(
                fontSize: 25,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

  Widget _buildAccountSelector() {
    if (_accounts.isEmpty) {
      return _emptySelector(
        icon: Icons.wallet_outlined,
        title: settings.isBangla
            ? 'কোনো অ্যাকাউন্ট নেই'
            : 'No accounts found',
      );
    }

    return _sectionCard(
      child: DropdownButtonFormField<int>(
        initialValue: _selectedAccountId,
        decoration: InputDecoration(
          labelText: settings.isBangla
              ? 'অ্যাকাউন্ট'
              : 'Account',
          prefixIcon: const Icon(
            Icons.account_balance_wallet_outlined,
          ),
        ),
        items: _accounts.map((account) {
          return DropdownMenuItem<int>(
            value: account['id'] as int,
            child: Row(
              children: [
                Icon(
                  _accountIcon(
                    account['type']
                            ?.toString() ??
                        '',
                  ),
                  size: 19,
                ),
                const SizedBox(width: 9),
                Text(
                  _accountName(account),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: _saving
            ? null
            : (value) {
                setState(() {
                  _selectedAccountId =
                      value;
                });
              },
      ),
    );
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Widget _buildCategorySelector() {
    if (_type == 'transfer') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF3F7FD6)
              .withValues(alpha: 0.08),
          borderRadius:
              BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0xFF3F7FD6)
                .withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF3F7FD6),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                settings.isBangla
                    ? 'ট্রান্সফারের জন্য খাত প্রয়োজন নেই'
                    : 'Category is not required for transfer',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _sectionCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue:
                      _selectedCategoryId,
                  decoration:
                      InputDecoration(
                    labelText:
                        settings.isBangla
                            ? 'খাত'
                            : 'Category',
                    prefixIcon:
                        const Icon(
                      Icons
                          .category_outlined,
                    ),
                  ),
                  items: _categories
                      .map((category) {
                    return DropdownMenuItem<
                        int>(
                      value:
                          category['id']
                              as int,
                      child: Text(
                        category['name']
                            .toString(),
                      ),
                    );
                  }).toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCategoryId =
                                value;
                          });
                        },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 50,
                height: 50,
                decoration:
                    BoxDecoration(
                  color: AppTheme.green
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: IconButton(
                  tooltip:
                      settings.isBangla
                          ? 'নতুন খাত যোগ করুন'
                          : 'Add category',
                  onPressed: _saving
                      ? null
                      : _addNewCategory,
                  icon: const Icon(
                    Icons.add_rounded,
                    color:
                        AppTheme.green,
                  ),
                ),
              ),
            ],
          ),

          if (_categories.isEmpty) ...[
            const SizedBox(height: 9),
            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                settings.isBangla
                    ? 'এই ধরনের কোনো খাত নেই। + চাপ দিয়ে নতুন খাত যোগ করুন।'
                    : 'No category found. Tap + to add one.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  )
                      .textTheme
                      .bodySmall
                      ?.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DATE & NOTE
  // ============================================================

  Widget _buildDateSelector() {
    return InkWell(
      borderRadius:
          BorderRadius.circular(17),
      onTap: _saving
          ? null
          : _selectDate,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              BorderRadius.circular(17),
          border: Border.all(
            color:
                Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(
                color: AppTheme.gold
                    .withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppTheme.gold,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.isBangla
                        ? 'তারিখ'
                        : 'Date',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(),
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      textInputAction:
          TextInputAction.newline,
      decoration: InputDecoration(
        labelText: settings.isBangla
            ? 'নোট'
            : 'Note',
        hintText: settings.isBangla
            ? 'প্রয়োজনে বিস্তারিত লিখুন'
            : 'Add a note if needed',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(
            bottom: 36,
          ),
          child: Icon(
            Icons.note_alt_outlined,
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(19),
      ),
      child: child,
    );
  }

  Widget _emptySelector({
    required IconData icon,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.gold,
          ),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isEdit =
        widget.transactionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? (settings.isBangla
                  ? 'লেনদেন আপডেট করুন'
                  : 'Edit Transaction')
              : (settings.isBangla
                  ? 'নতুন লেনদেন'
                  : 'New Transaction'),
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),

                    const SizedBox(height: 18),

                    _buildAmountField(),

                    const SizedBox(height: 15),

                    _buildAccountSelector(),

                    const SizedBox(height: 12),

                    _buildCategorySelector(),

                    const SizedBox(height: 12),

                    _buildDateSelector(),

                    const SizedBox(height: 12),

                    _buildNoteField(),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _saving
                            ? null
                            : _saveTransaction,
                        icon: _saving
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : Icon(
                                isEdit
                                    ? Icons
                                        .check_rounded
                                    : Icons
                                        .save_rounded,
                              ),
                        label: Text(
                          _saving
                              ? (settings.isBangla
                                  ? 'সংরক্ষণ হচ্ছে...'
                                  : 'Saving...')
                              : isEdit
                                  ? (settings.isBangla
                                      ? 'আপডেট করুন'
                                      : 'Update Transaction')
                                  : (settings.isBangla
                                      ? 'লেনদেন সংরক্ষণ করুন'
                                      : 'Save Transaction'),
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
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
