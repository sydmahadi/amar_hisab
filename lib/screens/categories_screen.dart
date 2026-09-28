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

  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];

  bool _loading = true;

  AppSettings get settings => AppSettings.instance;

  final List<IconData> _availableIcons = const [
    Icons.shopping_bag,
    Icons.fastfood,
    Icons.home,
    Icons.directions_bus,
    Icons.medical_services,
    Icons.movie,
    Icons.school,
    Icons.receipt_long,
    Icons.card_giftcard,
    Icons.work,
    Icons.attach_money,
    Icons.trending_up,
    Icons.business_center,
    Icons.laptop,
    Icons.store,
    Icons.savings,
    Icons.account_balance,
    Icons.sports_esports,
    Icons.flight,
    Icons.pets,
  ];

  final List<Color> _availableColors = const [
    AppTheme.green,
    AppTheme.gold,
    Colors.red,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final expense = await MoneyDb.instance.getCategories(type: 'expense');
      final income = await MoneyDb.instance.getCategories(type: 'income');

      if (!mounted) return;

      setState(() {
        _expenseCategories = expense;
        _incomeCategories = income;
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

  void _showMessage(String message, {bool isError = false}) {
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

  IconData _iconFromData(dynamic iconData) {
    int codePoint = Icons.category.codePoint;

    if (iconData is int) {
      codePoint = iconData;
    } else if (iconData is num) {
      codePoint = iconData.toInt();
    } else if (iconData is String) {
      final parsed = int.tryParse(iconData);
      if (parsed != null) {
        codePoint = parsed;
      }
    }

    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }

  Color _colorFromData(dynamic colorData) {
    if (colorData is int) {
      return Color(colorData);
    }

    if (colorData is num) {
      return Color(colorData.toInt());
    }

    if (colorData is String) {
      final parsed = int.tryParse(colorData);
      if (parsed != null) {
        return Color(parsed);
      }
    }

    return AppTheme.green;
  }

  Future<void> _addOrEditCategory({
    required String type,
    Map<String, dynamic>? category,
  }) async {
    final nameController = TextEditingController(
      text: category?['name']?.toString() ?? '',
    );

    IconData selectedIcon = category != null
        ? _iconFromData(category['icon'])
        : _availableIcons.first;

    Color selectedColor = category != null
        ? _colorFromData(category['color'])
        : _availableColors.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category == null
                          ? (type == 'expense'
                              ? (settings.isBangla
                                  ? 'নতুন খরচের খাত'
                                  : 'New Expense Category')
                              : (settings.isBangla
                                  ? 'নতুন আয়ের খাত'
                                  : 'New Income Category'))
                          : (settings.isBangla
                              ? 'খাত এডিট করুন'
                              : 'Edit Category'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: settings.t('categoryName'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      settings.isBangla ? 'আইকন বেছে নিন' : 'Select Icon',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 55,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableIcons.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final icon = _availableIcons[index];
                          final isSelected =
                              selectedIcon.codePoint == icon.codePoint;

                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedIcon = icon;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedColor.withValues(alpha: 0.2)
                                    : theme.cardColor,
                                border: Border.all(
                                  color: isSelected
                                      ? selectedColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected
                                    ? selectedColor
                                    : theme.iconTheme.color,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      settings.isBangla ? 'কালার বেছে নিন' : 'Select Color',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 45,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableColors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final color = _availableColors[index];
                          final isSelected =
                              selectedColor.toARGB32() == color.toARGB32();

                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedColor = color;
                              });
                            },
                            customBorder: const CircleBorder(),
                            child: CircleAvatar(
                              backgroundColor: color,
                              radius: 20,
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          try {
                            if (category == null) {
                              await MoneyDb.instance.addCategory(
                                name: name,
                                type: type,
                                icon: selectedIcon.codePoint,
                                color: selectedColor.toARGB32(),
                              );
                            } else {
                              await MoneyDb.instance.updateCategory(
                                id: category['id'] as int,
                                name: name,
                                type: type,
                                icon: selectedIcon.codePoint,
                                color: selectedColor.toARGB32(),
                              );
                            }

                            if (!mounted) return;
                            Navigator.pop(context);
                            _loadCategories();
                          } catch (e) {
                            _showMessage(
                              e.toString().replaceFirst('Exception: ', ''),
                              isError: true,
                            );
                          }
                        },
                        child: Text(
                          category == null
                              ? settings.t('add')
                              : settings.t('update'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settings.isBangla ? 'খাত মুছুন' : 'Delete Category'),
        content: Text(
          settings.isBangla
              ? 'আপনি কি নিশ্চিত যে এই খাতটি মুছে ফেলতে চান?'
              : 'Are you sure you want to delete this category?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(settings.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(settings.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await MoneyDb.instance.deleteCategory(category['id'] as int);
        _loadCategories();
      } catch (e) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  Widget _buildCategoryList(
      List<Map<String, dynamic>> categories, String type) {
    if (categories.isEmpty) {
      return Center(
        child: Text(settings.t('noData')),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final item = categories[index];
        final name = item['name']?.toString() ?? '';
        final icon = _iconFromData(item['icon']);
        final color = _colorFromData(item['color']);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _addOrEditCategory(
                    type: type,
                    category: item,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  onPressed: () => _deleteCategory(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(settings.t('categories')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          tabs: [
            Tab(text: settings.t('expense')),
            Tab(text: settings.t('income')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(_expenseCategories, 'expense'),
                _buildCategoryList(_incomeCategories, 'income'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.green,
        onPressed: () {
          final currentType =
              _tabController.index == 0 ? 'expense' : 'income';
          _addOrEditCategory(type: currentType);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
