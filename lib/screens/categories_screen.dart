import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/money_db.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];

  bool _loading = true;

  AppSettings get settings => AppSettings.instance;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final income = await MoneyDb.instance.getCategories(
        type: 'income',
      );

      final expense = await MoneyDb.instance.getCategories(
        type: 'expense',
      );

      if (!mounted) return;

      setState(() {
        _incomeCategories = income;
        _expenseCategories = expense;
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

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();

    String type = _tabController.index == 0 ? 'income' : 'expense';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(settings.t('addCategory')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: settings.t('categoryName'),
                      hintText: settings.t('enterName'),
                      prefixIcon: const Icon(
                        Icons.category_outlined,
                        color: AppTheme.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(
                      labelText: settings.isBangla
                          ? 'খাতের ধরন'
                          : 'Category Type',
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'income',
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 19,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(settings.t('income')),
                          ],
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'expense',
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 19,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(settings.t('expense')),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        type = value;
                      });
                    },
                  ),
                ],
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
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            settings.t('enterName'),
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await MoneyDb.instance.addCategory(
                        name: name,
                        type: type,
                        icon: type == 'income' ? 0xe850 : 0xe145,
                        color: type == 'income'
                            ? 0xFF176B45
                            : 0xFFE57373,
                      );

                      if (!context.mounted) return;

                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      if (!context.mounted) return;

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

    if (result == true) {
      await _loadCategories();

      if (!mounted) return;

      _showMessage(
        settings.t('categoryAdded'),
      );
    }
  }

  Future<void> _showEditCategoryDialog(
    Map<String, dynamic> category,
  ) async {
    final id = category['id'] as int;

    final nameController = TextEditingController(
      text: category['name']?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(settings.t('edit')),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: settings.t('categoryName'),
              prefixIcon: const Icon(
                Icons.category_outlined,
                color: AppTheme.gold,
              ),
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
                final name = nameController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        settings.t('enterName'),
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await MoneyDb.instance.updateCategory(
                    id,
                    name: name,
                  );

                  if (!context.mounted) return;

                  Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (!context.mounted) return;

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
              },
              child: Text(settings.t('update')),
            ),
          ],
        );
      },
    );

    nameController.dispose();

    if (result == true) {
      await _loadCategories();

      if (!mounted) return;

      _showMessage(
        settings.isBangla ? 'খাত আপডেট হয়েছে' : 'Category updated',
      );
    }
  }

  Future<void> _deleteCategory(
    Map<String, dynamic> category,
  ) async {
    final id = category['id'] as int;

    if ((category['is_default'] ?? 0) == 1) {
      _showMessage(
        settings.isBangla
            ? 'ডিফল্ট খাত মুছে ফেলা যাবে না'
            : 'Default categories cannot be deleted',
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
                ? 'আপনি কি এই খাতটি মুছে ফেলতে চান?'
                : 'Do you want to delete this category?',
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
      await MoneyDb.instance.deleteCategory(id);

      await _loadCategories();

      if (!mounted) return;

      _showMessage(
        settings.t('categoryDeleted'),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  IconData _iconForCategory(
    dynamic rawIcon,
    String type,
  ) {
    if (rawIcon is int) {
      return IconData(rawIcon, fontFamily: 'MaterialIcons');
    }

    final iconStr = rawIcon?.toString();
    final parsedInt = int.tryParse(iconStr ?? '');
    if (parsedInt != null) {
      return IconData(parsedInt, fontFamily: 'MaterialIcons');
    }

    switch (iconStr) {
      case 'payments':
        return Icons.payments_outlined;
      case 'business_center':
        return Icons.business_center_outlined;
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'medical_services':
        return Icons.medical_services_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'family_restroom':
        return Icons.family_restroom_outlined;
      default:
        return type == 'income'
            ? Icons.add_circle_outline
            : Icons.category_outlined;
    }
  }

  Color _colorForCategory(
    Map<String, dynamic> category,
  ) {
    final value = category['color'];

    if (value is int) {
      return Color(value);
    }

    if (value is num) {
      return Color(value.toInt());
    }

    return category['type'] == 'income'
        ? AppTheme.green
        : Colors.red.shade400;
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
  ) {
    final type = category['type']?.toString() ?? 'expense';
    final name = category['name']?.toString() ?? '';
    final color = _colorForCategory(category);
    final isDefault = (category['is_default'] ?? 0) == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 3,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _iconForCategory(
              category['icon'],
              type,
            ),
            color: color,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isDefault
              ? settings.isBangla
                  ? 'ডিফল্ট খাত'
                  : 'Default category'
              : settings.isBangla
                  ? 'নিজস্ব খাত'
                  : 'Custom category',
          style: TextStyle(
            fontSize: 11,
            color: isDefault
                ? AppTheme.gold
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditCategoryDialog(category);
            } else if (value == 'delete') {
              _deleteCategory(category);
            }
          },
          itemBuilder: (context) {
            return [
              PopupMenuItem<String>(
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
                PopupMenuItem<String>(
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
            ];
          },
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    List<Map<String, dynamic>> categories,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 58,
              color: AppTheme.gold.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            Text(
              settings.t('noCategories'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              settings.isBangla
                  ? 'নিচের + বাটনে নতুন খাত যোগ করুন'
                  : 'Tap the + button to add a category',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          100,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryCard(
            categories[index],
          );
        },
      ),
    );
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
          backgroundColor: isError ? Colors.red.shade700 : AppTheme.green,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          settings.t('categories'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          indicatorWeight: 3,
          labelColor: AppTheme.gold,
          unselectedLabelColor:
              Theme.of(context).textTheme.bodyMedium?.color,
          tabs: [
            Tab(
              icon: const Icon(
                Icons.arrow_downward_rounded,
              ),
              text: settings.t('incomeCategories'),
            ),
            Tab(
              icon: const Icon(
                Icons.arrow_upward_rounded,
              ),
              text: settings.t('expenseCategories'),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(
                  _incomeCategories,
                ),
                _buildCategoryList(
                  _expenseCategories,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          settings.t('addCategory'),
        ),
      ),
    );
  }
}
