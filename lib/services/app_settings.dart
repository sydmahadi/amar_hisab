import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  SharedPreferences? _prefs;

  bool _darkMode = true;
  String _language = 'bn';

  bool get darkMode => _darkMode;

  String get language => _language;

  bool get isBangla => _language == 'bn';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    _darkMode = _prefs?.getBool('dark_mode') ?? true;
    _language = _prefs?.getString('language') ?? 'bn';
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;

    await _prefs?.setBool('dark_mode', value);

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!_darkMode);
  }

  Future<void> setLanguage(String language) async {
    if (language != 'bn' && language != 'en') {
      return;
    }

    _language = language;

    await _prefs?.setString('language', language);

    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    if (_language == 'bn') {
      await setLanguage('en');
    } else {
      await setLanguage('bn');
    }
  }

  String t(String key) {
    final translations = <String, Map<String, String>>{
      'appName': {
        'bn': 'আমার হিসাব',
        'en': 'Amar Hisab',
      },

      'appTagline': {
        'bn': 'সহজে আপনার হিসাব রাখুন',
        'en': 'Manage your money easily',
      },

      'moneyManager': {
        'bn': 'মানি ম্যানেজার',
        'en': 'Money Manager',
      },

      'transactions': {
        'bn': 'লেনদেন',
        'en': 'Transactions',
      },

      'accounts': {
        'bn': 'অ্যাকাউন্ট',
        'en': 'Accounts',
      },

      'categories': {
        'bn': 'খাত',
        'en': 'Categories',
      },

      'statistics': {
        'bn': 'পরিসংখ্যান',
        'en': 'Statistics',
      },

      'report': {
        'bn': 'রিপোর্ট',
        'en': 'Report',
      },

      'settings': {
        'bn': 'সেটিংস',
        'en': 'Settings',
      },

      'about': {
        'bn': 'অ্যাপ সম্পর্কে',
        'en': 'About',
      },

      'addTransaction': {
        'bn': 'লেনদেন যোগ করুন',
        'en': 'Add Transaction',
      },

      'editTransaction': {
        'bn': 'লেনদেন সম্পাদনা',
        'en': 'Edit Transaction',
      },

      'income': {
        'bn': 'আয়',
        'en': 'Income',
      },

      'expense': {
        'bn': 'ব্যয়',
        'en': 'Expense',
      },

      'transfer': {
        'bn': 'ট্রান্সফার',
        'en': 'Transfer',
      },

      'amount': {
        'bn': 'পরিমাণ',
        'en': 'Amount',
      },

      'date': {
        'bn': 'তারিখ',
        'en': 'Date',
      },

      'time': {
        'bn': 'সময়',
        'en': 'Time',
      },

      'note': {
        'bn': 'নোট',
        'en': 'Note',
      },

      'description': {
        'bn': 'বিবরণ',
        'en': 'Description',
      },

      'save': {
        'bn': 'সংরক্ষণ করুন',
        'en': 'Save',
      },

      'update': {
        'bn': 'আপডেট করুন',
        'en': 'Update',
      },

      'cancel': {
        'bn': 'বাতিল',
        'en': 'Cancel',
      },

      'delete': {
        'bn': 'মুছে ফেলুন',
        'en': 'Delete',
      },

      'edit': {
        'bn': 'সম্পাদনা',
        'en': 'Edit',
      },

      'search': {
        'bn': 'অনুসন্ধান',
        'en': 'Search',
      },

      'noTransactions': {
        'bn': 'কোনো লেনদেন পাওয়া যায়নি',
        'en': 'No transactions found',
      },

      'addAccount': {
        'bn': 'অ্যাকাউন্ট যোগ করুন',
        'en': 'Add Account',
      },

      'accountName': {
        'bn': 'অ্যাকাউন্টের নাম',
        'en': 'Account Name',
      },

      'cash': {
        'bn': 'ক্যাশ',
        'en': 'Cash',
      },

      'bkash': {
        'bn': 'বিকাশ',
        'en': 'Bkash',
      },

      'nagad': {
        'bn': 'নগদ',
        'en': 'Nagad',
      },

      'bankAccount': {
        'bn': 'ব্যাংক অ্যাকাউন্ট',
        'en': 'Bank Account',
      },

      'card': {
        'bn': 'কার্ড',
        'en': 'Card',
      },

      'balance': {
        'bn': 'ব্যালেন্স',
        'en': 'Balance',
      },

      'totalBalance': {
        'bn': 'মোট ব্যালেন্স',
        'en': 'Total Balance',
      },

      'addCategory': {
        'bn': 'নতুন খাত যোগ করুন',
        'en': 'Add New Category',
      },

      'categoryName': {
        'bn': 'খাতের নাম',
        'en': 'Category Name',
      },

      'incomeCategories': {
        'bn': 'আয়ের খাত',
        'en': 'Income Categories',
      },

      'expenseCategories': {
        'bn': 'ব্যয়ের খাত',
        'en': 'Expense Categories',
      },

      'noCategories': {
        'bn': 'কোনো খাত নেই',
        'en': 'No categories found',
      },

      'categoryAdded': {
        'bn': 'খাত সফলভাবে যোগ হয়েছে',
        'en': 'Category added successfully',
      },

      'categoryDeleted': {
        'bn': 'খাত মুছে ফেলা হয়েছে',
        'en': 'Category deleted',
      },

      'incomeTotal': {
        'bn': 'মোট আয়',
        'en': 'Total Income',
      },

      'expenseTotal': {
        'bn': 'মোট ব্যয়',
        'en': 'Total Expense',
      },

      'surplus': {
        'bn': 'উদ্বৃত্ত',
        'en': 'Surplus',
      },

      'deficit': {
        'bn': 'ঘাটতি',
        'en': 'Deficit',
      },

      'daily': {
        'bn': 'দৈনিক',
        'en': 'Daily',
      },

      'weekly': {
        'bn': 'সাপ্তাহিক',
        'en': 'Weekly',
      },

      'monthly': {
        'bn': 'মাসিক',
        'en': 'Monthly',
      },

      'yearly': {
        'bn': 'বার্ষিক',
        'en': 'Yearly',
      },

      'today': {
        'bn': 'আজ',
        'en': 'Today',
      },

      'thisWeek': {
        'bn': 'এই সপ্তাহ',
        'en': 'This Week',
      },

      'thisMonth': {
        'bn': 'এই মাস',
        'en': 'This Month',
      },

      'thisYear': {
        'bn': 'এই বছর',
        'en': 'This Year',
      },

      'fromAccount': {
        'bn': 'যে অ্যাকাউন্ট থেকে',
        'en': 'From Account',
      },

      'toAccount': {
        'bn': 'যে অ্যাকাউন্টে',
        'en': 'To Account',
      },

      'transferAmount': {
        'bn': 'ট্রান্সফারের পরিমাণ',
        'en': 'Transfer Amount',
      },

      'generateReport': {
        'bn': 'রিপোর্ট তৈরি করুন',
        'en': 'Generate Report',
      },

      'monthlyReport': {
        'bn': 'মাসিক রিপোর্ট',
        'en': 'Monthly Report',
      },

      'incomeReport': {
        'bn': 'আয়ের রিপোর্ট',
        'en': 'Income Report',
      },

      'expenseReport': {
        'bn': 'ব্যয়ের রিপোর্ট',
        'en': 'Expense Report',
      },

      'downloadPdf': {
        'bn': 'PDF ডাউনলোড করুন',
        'en': 'Download PDF',
      },

      'downloadJpg': {
        'bn': 'JPG ডাউনলোড করুন',
        'en': 'Download JPG',
      },

      'reportSaved': {
        'bn': 'রিপোর্ট সংরক্ষণ করা হয়েছে',
        'en': 'Report saved',
      },

      'language': {
        'bn': 'ভাষা',
        'en': 'Language',
      },

      'bangla': {
        'bn': 'বাংলা',
        'en': 'Bangla',
      },

      'english': {
        'bn': 'ইংরেজি',
        'en': 'English',
      },

      'theme': {
        'bn': 'থিম',
        'en': 'Theme',
      },

      'darkTheme': {
        'bn': 'ডার্ক থিম',
        'en': 'Dark Theme',
      },

      'lightTheme': {
        'bn': 'লাইট থিম',
        'en': 'Light Theme',
      },

      'aboutApp': {
        'bn': 'আমার হিসাব সম্পর্কে',
        'en': 'About Amar Hisab',
      },

      'appDescription': {
        'bn':
            'আমার হিসাব একটি সহজ ও ব্যবহারবান্ধব ব্যক্তিগত মানি ম্যানেজমেন্ট অ্যাপ। এর মাধ্যমে আপনার দৈনন্দিন আয়, ব্যয়, লেনদেন, অ্যাকাউন্ট ও আর্থিক হিসাব সহজে সংরক্ষণ ও পরিচালনা করতে পারবেন।',
        'en':
            'Amar Hisab is a simple and user-friendly personal money management app. You can easily record and manage your daily income, expenses, transactions, accounts and financial records.',
      },

      'features': {
        'bn': 'অ্যাপের ফিচারসমূহ',
        'en': 'App Features',
      },

      'developerInfo': {
        'bn': 'ডেভেলপার সম্পর্কে',
        'en': 'Developer Information',
      },

      'developedBy': {
        'bn': 'ডেভেলপ করেছেন',
        'en': 'Developed by',
      },

      'contact': {
        'bn': 'যোগাযোগ',
        'en': 'Contact',
      },

      'yes': {
        'bn': 'হ্যাঁ',
        'en': 'Yes',
      },

      'no': {
        'bn': 'না',
        'en': 'No',
      },

      'close': {
        'bn': 'বন্ধ করুন',
        'en': 'Close',
      },

      'confirm': {
        'bn': 'নিশ্চিত করুন',
        'en': 'Confirm',
      },

      'warning': {
        'bn': 'সতর্কতা',
        'en': 'Warning',
      },

      'success': {
        'bn': 'সফল',
        'en': 'Success',
      },

      'error': {
        'bn': 'ত্রুটি',
        'en': 'Error',
      },

      'loading': {
        'bn': 'লোড হচ্ছে...',
        'en': 'Loading...',
      },

      'noData': {
        'bn': 'কোনো তথ্য পাওয়া যায়নি',
        'en': 'No data found',
      },

      'deleteConfirmation': {
        'bn': 'আপনি কি এই তথ্যটি মুছে ফেলতে চান?',
        'en': 'Do you want to delete this information?',
      },

      'enterAmount': {
        'bn': 'পরিমাণ লিখুন',
        'en': 'Enter amount',
      },

      'enterName': {
        'bn': 'নাম লিখুন',
        'en': 'Enter name',
      },

      'requiredField': {
        'bn': 'এই তথ্যটি প্রয়োজনীয়',
        'en': 'This field is required',
      },
    };

    return translations[key]?[_language] ?? key;
  }
}

এটাই এখন তোমার ৪ নম্বর ফাইল।

এটা বসানোর পর আর কোনো "app_localizations.dart" লাগবে না। তোমার "main.dart" যেহেতু "AppSettings.instance.t()" ব্যবহার করছে, এই structure-এর সাথেই সরাসরি কাজ করবে।

এটা বসিয়ে "হয়েছে" বলো। তারপর ৫ নম্বর "money_db.dart" দেব।
