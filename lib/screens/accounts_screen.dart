import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Map<String, dynamic>> _accounts = [];
  bool _loading = true;

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final accounts = await MoneyDb.instance.getAccounts();

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
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

  Future<void> _showAddAccountDialog() async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    String selectedType = 'cash';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(settings.t('addAccount')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: settings.t('accountName'),
                        hintText: settings.t('enterName'),
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: settings.isBangla
                            ? 'অ্যাকাউন্টের ধরন'
                            : 'Account Type',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text(settings.t('cash')),
                        ),
                        DropdownMenuItem(
                          value: 'bkash',
                          child: Text(settings.t('bkash')),
                        ),
                        DropdownMenuItem(
                          value: 'nagad',
                          child: Text(settings.t('nagad')),
                        ),
                        DropdownMenuItem(
                          value: 'bank',
                          child: Text(settings.t('bankAccount')),
                        ),
                        DropdownMenuItem(
                          value: 'card',
                          child: Text(settings.t('card')),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(
                            settings.isBangla
                                ? 'অন্যান্য'
                                : 'Other',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: balanceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: settings.t('balance'),
                        hintText: '0.00',
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: Text(settings.t('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name =
                        nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context)
                        .showSnackBar(
                          SnackBar(
                            content: Text(
                              settings.t('enterName'),
                            ),
                          ),
                        );
                      return;
                    }

                    final balance = double.tryParse(
                          balanceController.text
                              .trim()
                              .replaceAll(',', ''),
                        ) ??
                        0;

                    try {
                      await MoneyDb.instance.addAccount(
                        name: name,
                        type: selectedType,
                        balance: balance,
                        icon: _iconNameForType(
                          selectedType,
                        ),
                        color: _colorForType(
                          selectedType,
                        ),
                      );

                      if (!context.mounted) return;

                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context)
                        .showSnackBar(
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
                  },
                  child: Text(settings.t('save')),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    balanceController.dispose();

    if (result == true) {
      await _loadAccounts();

      if (!mounted) return;

      _showMessage(
        settings.isBangla
            ? 'অ্যাকাউন্ট সফলভাবে যোগ হয়েছে'
            : 'Account added successfully',
      );
    }
  }

  Future<void> _showEditAccountDialog(
    Map<String, dynamic> account,
  ) async {
    final id = account['id'] as int;

    final nameController = TextEditingController(
      text: account['name']?.toString() ?? '',
    );

    final balanceController = TextEditingController(
      text: _formatNumber(account['balance']),
    );

    String selectedType =
        account['type']?.toString() ?? 'other';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(settings.t('edit')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: settings.t('accountName'),
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _validAccountType(
                        selectedType,
                      ),
                      decoration: InputDecoration(
                        labelText: settings.isBangla
                            ? 'অ্যাকাউন্টের ধরন'
                            : 'Account Type',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text(settings.t('cash')),
                        ),
                        DropdownMenuItem(
                          value: 'bkash',
                          child: Text(settings.t('bkash')),
                        ),
                        DropdownMenuItem(
                          value: 'nagad',
                          child: Text(settings.t('nagad')),
                        ),
                        DropdownMenuItem(
                          value: 'bank',
                          child: Text(settings.t('bankAccount')),
                        ),
                        DropdownMenuItem(
                          value: 'card',
                          child: Text(settings.t('card')),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(
                            settings.isBangla
                                ? 'অন্যান্য'
                                : 'Other',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: balanceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: settings.t('balance'),
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),

                    if ((account['is_default'] ?? 0) == 1)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 12),
                        child: Text(
                          settings.isBangla
                              ? 'এটি ডিফল্ট অ্যাকাউন্ট'
                              : 'This is a default account',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.gold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: Text(settings.t('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name =
                        nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            settings.t('enterName'),
                          ),
                        ),
                      );
                      return;
                    }

                    final balance = double.tryParse(
                          balanceController.text
                              .trim()
                              .replaceAll(',', ''),
                        ) ??
                        0;

                    try {
                      await MoneyDb.instance.updateAccount(
                        id: id,
                        name: name,
                        type: selectedType,
                        balance:
                            (account['is_default'] ?? 0) == 1
                                ? null
                                : balance,
                        icon: _iconNameForType(
                          selectedType,
                        ),
                        color: _colorForType(
                          selectedType,
                        ),
                      );

                      if (!context.mounted) return;

                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
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
                  },
                  child: Text(settings.t('update')),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    balanceController.dispose();

    if (result == true) {
      await _loadAccounts();

      if (!mounted) return;

      _showMessage(
        settings.isBangla
            ? 'অ্যাকাউন্ট আপডেট হয়েছে'
            : 'Account updated',
      );
    }
  }

  Future<void> _deleteAccount(
    Map<String, dynamic> account,
  ) async {
    final id = account['id'] as int;

    if ((account['is_default'] ?? 0) == 1) {
      _showMessage(
        settings.isBangla
            ? 'ডিফল্ট অ্যাকাউন্ট মুছে ফেলা যাবে না'
            : 'Default accounts cannot be deleted',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(settings.t('confirm')),
          content: Text(
            settings.isBangla
                ? 'আপনি কি এই অ্যাকাউন্টটি মুছে ফেলতে চান?'
                : 'Do you want to delete this account?',
          ),
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
      await MoneyDb.instance.deleteAccount(id);

      await _loadAccounts();

      if (!mounted) return;

      _showMessage(
        settings.isBangla
            ? 'অ্যাকাউন্ট মুছে ফেলা হয়েছে'
            : 'Account deleted',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  String _validAccountType(String type) {
    const types = [
      'cash',
      'bkash',
      'nagad',
      'bank',
      'card',
      'other',
    ];

    if (types.contains(type)) {
      return type;
    }

    return 'other';
  }

  String _iconNameForType(String type) {
    switch (type) {
      case 'cash':
        return 'account_balance_wallet';

      case 'bkash':
      case 'nagad':
        return 'phone_android';

      case 'bank':
        return 'account_balance';

      case 'card':
        return 'credit_card';

      default:
        return 'wallet';
    }
  }

  int _colorForType(String type) {
    switch (type) {
      case 'bkash':
        return 0xFFE2136E;

      case 'nagad':
        return 0xFFF7941D;

      case 'bank':
        return 0xFF246B4A;

      case 'card':
        return 0xFFC9A45C;

      case 'cash':
        return 0xFF176B45;

      default:
        return 0xFF607D8B;
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'cash':
        return Icons.account_balance_wallet_outlined;

      case 'bkash':
      case 'nagad':
        return Icons.phone_android_rounded;

      case 'bank':
        return Icons.account_balance_outlined;

      case 'card':
        return Icons.credit_card_outlined;

      default:
        return Icons.wallet_outlined;
    }
  }

  Color _colorFromValue(dynamic value) {
    if (value is int) {
      return Color(value);
    }

    if (value is num) {
      return Color(value.toInt());
    }

    return AppTheme.green;
  }

  String _formatNumber(dynamic value) {
    final number =
        (value as num?)?.toDouble() ?? 0;

    if (number == number.toInt()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(2);
  }

  String _displayType(String? type) {
    switch (type) {
      case 'cash':
        return settings.t('cash');

      case 'bkash':
        return settings.t('bkash');

      case 'nagad':
        return settings.t('nagad');

      case 'bank':
        return settings.t('bankAccount');

      case 'card':
        return settings.t('card');

      default:
        return settings.isBangla
            ? 'অন্যান্য'
            : 'Other';
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

  Widget _buildAccountCard(
    Map<String, dynamic> account,
  ) {
    final name =
        account['name']?.toString() ?? '';

    final type =
        account['type']?.toString() ?? 'other';

    final balance =
        (account['balance'] as num?)?.toDouble() ?? 0;

    final color =
        _colorFromValue(account['color']);

    final isDefault =
        (account['is_default'] ?? 0) == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Icon(
                _iconForType(type),
                color: color,
                size: 27,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _displayType(type),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ),

                  if (isDefault)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 5,
                      ),
                      child: Text(
                        settings.isBangla
                            ? 'ডিফল্ট'
                            : 'Default',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.gold,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber(balance),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: balance < 0
                        ? Colors.red.shade600
                        : AppTheme.green,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  settings.t('balance'),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 5),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditAccountDialog(account);
                } else if (value == 'delete') {
                  _deleteAccount(account);
                }
              },
              itemBuilder: (context) {
                return [
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
                  if (!isDefault)
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
                              color:
                                  Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _accounts.fold<double>(
      0,
      (sum, account) =>
          sum +
          ((account['balance'] as num?)
                  ?.toDouble() ??
              0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.t('accounts')),
        actions: [
          IconButton(
            onPressed: _showAddAccountDialog,
            icon: const Icon(Icons.add_rounded),
            tooltip: settings.t('addAccount'),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadAccounts,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  90,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.darkGreen,
                          AppTheme.green,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.green
                              .withOpacity(0.20),
                          blurRadius: 18,
                          offset:
                              const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration:
                              BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons
                                .account_balance_wallet_rounded,
                            color: AppTheme.gold,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                settings.t(
                                  'totalBalance',
                                ),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                _formatNumber(
                                  totalBalance,
                                ),
                                style:
                                    const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          settings.t('accounts'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${_accounts.length}',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  ..._accounts.map(
                    _buildAccountCard,
                  ),
                ],
              ),
            ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: _showAddAccountDialog,
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
