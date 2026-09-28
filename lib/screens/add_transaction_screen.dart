import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';
  int? _selectedAccountId;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final accounts = await MoneyDb.instance.getAccounts();
    final categories = await MoneyDb.instance.getCategories(type: _type);

    if (!mounted) return;

    setState(() {
      _accounts = accounts;
      _categories = categories;

      if (_accounts.isNotEmpty) {
        _selectedAccountId = _accounts.first['id'] as int?;
      }
      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.first['id'] as int?;
      }

      _loading = false;
    });
  }

  Future<void> _onTypeChanged(String newType) async {
    setState(() {
      _type = newType;
      _loading = true;
    });

    final categories = await MoneyDb.instance.getCategories(type: newType);

    if (!mounted) return;

    setState(() {
      _categories = categories;
      _selectedCategoryId =
          _categories.isNotEmpty ? _categories.first['id'] as int? : null;
      _loading = false;
    });
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    try {
      await MoneyDb.instance.addTransaction(
        type: _type,
        amount: amount,
        accountId: _selectedAccountId,
        categoryId: _selectedCategoryId,
        note: _noteController.text.trim(),
        transactionDate: _selectedDate,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(settings.isBangla ? 'লেনদেন যোগ করুন' : 'Add Transaction'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Expense')),
                      ButtonSegment(value: 'income', label: Text('Income')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (set) {
                      _onTypeChanged(set.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: settings.t('amount'),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_accounts.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedAccountId,
                      decoration: InputDecoration(
                        labelText: settings.t('account'),
                      ),
                      items: _accounts.map((acc) {
                        return DropdownMenuItem<int>(
                          value: acc['id'] as int,
                          child: Text(acc['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAccountId = val;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  if (_categories.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: settings.t('category'),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat['id'] as int,
                          child: Text(cat['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: settings.t('note'),
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(settings.t('save')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
