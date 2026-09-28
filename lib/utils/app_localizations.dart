import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('bn'),
    Locale('en'),
  ];

  static AppLocalizations of(BuildContext context) {
    final result = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

    if (result == null) {
      throw FlutterError(
        'AppLocalizations could not be found in the widget tree.',
      );
    }

    return result;
  }

  bool get isBangla => locale.languageCode == 'bn';

  String get appName => isBangla ? 'আমার হিসাব' : 'Amar Hisab';

  String get appTagline =>
      isBangla ? 'সহজে আপনার হিসাব রাখুন' : 'Manage your money easily';

  // =========================
  // Main Menu
  // =========================

  String get moneyManager =>
      isBangla ? 'মানি ম্যানেজার' : 'Money Manager';

  String get transactions =>
      isBangla ? 'লেনদেন' : 'Transactions';

  String get accounts =>
      isBangla ? 'অ্যাকাউন্ট' : 'Accounts';

  String get categories =>
      isBangla ? 'খাত' : 'Categories';

  String get statistics =>
      isBangla ? 'পরিসংখ্যান' : 'Statistics';

  String get report =>
      isBangla ? 'রিপোর্ট' : 'Report';

  String get settings =>
      isBangla ? 'সেটিংস' : 'Settings';

  String get about =>
      isBangla ? 'অ্যাপ সম্পর্কে' : 'About';

  // =========================
  // Transaction
  // =========================

  String get addTransaction =>
      isBangla ? 'লেনদেন যোগ করুন' : 'Add Transaction';

  String get editTransaction =>
      isBangla ? 'লেনদেন সম্পাদনা' : 'Edit Transaction';

  String get income =>
      isBangla ? 'আয়' : 'Income';

  String get expense =>
      isBangla ? 'ব্যয়' : 'Expense';

  String get transfer =>
      isBangla ? 'ট্রান্সফার' : 'Transfer';

  String get amount =>
      isBangla ? 'পরিমাণ' : 'Amount';

  String get date =>
      isBangla ? 'তারিখ' : 'Date';

  String get time =>
      isBangla ? 'সময়' : 'Time';

  String get note =>
      isBangla ? 'নোট' : 'Note';

  String get description =>
      isBangla ? 'বিবরণ' : 'Description';

  String get save =>
      isBangla ? 'সংরক্ষণ করুন' : 'Save';

  String get update =>
      isBangla ? 'আপডেট করুন' : 'Update';

  String get cancel =>
      isBangla ? 'বাতিল' : 'Cancel';

  String get delete =>
      isBangla ? 'মুছে ফেলুন' : 'Delete';

  String get edit =>
      isBangla ? 'সম্পাদনা' : 'Edit';

  String get search =>
      isBangla ? 'অনুসন্ধান' : 'Search';

  String get noTransactions =>
      isBangla ? 'কোনো লেনদেন পাওয়া যায়নি' : 'No transactions found';

  // =========================
  // Accounts
  // =========================

  String get addAccount =>
      isBangla ? 'অ্যাকাউন্ট যোগ করুন' : 'Add Account';

  String get accountName =>
      isBangla ? 'অ্যাকাউন্টের নাম' : 'Account Name';

  String get cash =>
      isBangla ? 'ক্যাশ' : 'Cash';

  String get bkash =>
      isBangla ? 'বিকাশ' : 'Bkash';

  String get nagad =>
      isBangla ? 'নগদ' : 'Nagad';

  String get bankAccount =>
      isBangla ? 'ব্যাংক অ্যাকাউন্ট' : 'Bank Account';

  String get card =>
      isBangla ? 'কার্ড' : 'Card';

  String get balance =>
      isBangla ? 'ব্যালেন্স' : 'Balance';

  String get totalBalance =>
      isBangla ? 'মোট ব্যালেন্স' : 'Total Balance';

  // =========================
  // Categories
  // =========================

  String get addCategory =>
      isBangla ? 'নতুন খাত যোগ করুন' : 'Add New Category';

  String get categoryName =>
      isBangla ? 'খাতের নাম' : 'Category Name';

  String get incomeCategories =>
      isBangla ? 'আয়ের খাত' : 'Income Categories';

  String get expenseCategories =>
      isBangla ? 'ব্যয়ের খাত' : 'Expense Categories';

  String get noCategories =>
      isBangla ? 'কোনো খাত নেই' : 'No categories found';

  String get categoryAdded =>
      isBangla ? 'খাত সফলভাবে যোগ হয়েছে' : 'Category added successfully';

  String get categoryDeleted =>
      isBangla ? 'খাত মুছে ফেলা হয়েছে' : 'Category deleted';

  // =========================
  // Statistics
  // =========================

  String get incomeTotal =>
      isBangla ? 'মোট আয়' : 'Total Income';

  String get expenseTotal =>
      isBangla ? 'মোট ব্যয়' : 'Total Expense';

  String get surplus =>
      isBangla ? 'উদ্বৃত্ত' : 'Surplus';

  String get deficit =>
      isBangla ? 'ঘাটতি' : 'Deficit';

  String get daily =>
      isBangla ? 'দৈনিক' : 'Daily';

  String get weekly =>
      isBangla ? 'সাপ্তাহিক' : 'Weekly';

  String get monthly =>
      isBangla ? 'মাসিক' : 'Monthly';

  String get yearly =>
      isBangla ? 'বার্ষিক' : 'Yearly';

  String get today =>
      isBangla ? 'আজ' : 'Today';

  String get thisWeek =>
      isBangla ? 'এই সপ্তাহ' : 'This Week';

  String get thisMonth =>
      isBangla ? 'এই মাস' : 'This Month';

  String get thisYear =>
      isBangla ? 'এই বছর' : 'This Year';

  // =========================
  // Transfer
  // =========================

  String get fromAccount =>
      isBangla ? 'যে অ্যাকাউন্ট থেকে' : 'From Account';

  String get toAccount =>
      isBangla ? 'যে অ্যাকাউন্টে' : 'To Account';

  String get transferAmount =>
      isBangla ? 'ট্রান্সফারের পরিমাণ' : 'Transfer Amount';

  // =========================
  // Report
  // =========================

  String get generateReport =>
      isBangla ? 'রিপোর্ট তৈরি করুন' : 'Generate Report';

  String get monthlyReport =>
      isBangla ? 'মাসিক রিপোর্ট' : 'Monthly Report';

  String get incomeReport =>
      isBangla ? 'আয়ের রিপোর্ট' : 'Income Report';

  String get expenseReport =>
      isBangla ? 'ব্যয়ের রিপোর্ট' : 'Expense Report';

  String get downloadPdf =>
      isBangla ? 'PDF ডাউনলোড করুন' : 'Download PDF';

  String get downloadJpg =>
      isBangla ? 'JPG ডাউনলোড করুন' : 'Download JPG';

  String get reportSaved =>
      isBangla ? 'রিপোর্ট সংরক্ষণ করা হয়েছে' : 'Report saved';

  // =========================
  // Settings
  // =========================

  String get language =>
      isBangla ? 'ভাষা' : 'Language';

  String get bangla =>
      isBangla ? 'বাংলা' : 'Bangla';

  String get english =>
      isBangla ? 'ইংরেজি' : 'English';

  String get theme =>
      isBangla ? 'থিম' : 'Theme';

  String get darkTheme =>
      isBangla ? 'ডার্ক থিম' : 'Dark Theme';

  String get lightTheme =>
      isBangla ? 'লাইট থিম' : 'Light Theme';

  // =========================
  // About
  // =========================

  String get aboutApp =>
      isBangla ? 'আমার হিসাব সম্পর্কে' : 'About Amar Hisab';

  String get appDescription => isBangla
      ? 'আমার হিসাব একটি সহজ ও ব্যবহারবান্ধব ব্যক্তিগত মানি ম্যানেজমেন্ট অ্যাপ। এর মাধ্যমে আপনার দৈনন্দিন আয়, ব্যয়, লেনদেন, অ্যাকাউন্ট ও আর্থিক হিসাব সহজে সংরক্ষণ ও পরিচালনা করতে পারবেন।'
      : 'Amar Hisab is a simple and user-friendly personal money management app. You can easily record and manage your daily income, expenses, transactions, accounts and financial records.';

  String get features =>
      isBangla ? 'অ্যাপের ফিচারসমূহ' : 'App Features';

  String get developerInfo =>
      isBangla ? 'ডেভেলপার সম্পর্কে' : 'Developer Information';

  String get developedBy =>
      isBangla ? 'ডেভেলপ করেছেন' : 'Developed by';

  String get contact =>
      isBangla ? 'যোগাযোগ' : 'Contact';

  // =========================
  // Common
  // =========================

  String get yes =>
      isBangla ? 'হ্যাঁ' : 'Yes';

  String get no =>
      isBangla ? 'না' : 'No';

  String get close =>
      isBangla ? 'বন্ধ করুন' : 'Close';

  String get confirm =>
      isBangla ? 'নিশ্চিত করুন' : 'Confirm';

  String get warning =>
      isBangla ? 'সতর্কতা' : 'Warning';

  String get success =>
      isBangla ? 'সফল' : 'Success';

  String get error =>
      isBangla ? 'ত্রুটি' : 'Error';

  String get loading =>
      isBangla ? 'লোড হচ্ছে...' : 'Loading...';

  String get noData =>
      isBangla ? 'কোনো তথ্য পাওয়া যায়নি' : 'No data found';

  String get deleteConfirmation => isBangla
      ? 'আপনি কি এই তথ্যটি মুছে ফেলতে চান?'
      : 'Do you want to delete this information?';

  String get enterAmount =>
      isBangla ? 'পরিমাণ লিখুন' : 'Enter amount';

  String get enterName =>
      isBangla ? 'নাম লিখুন' : 'Enter name';

  String get requiredField =>
      isBangla ? 'এই তথ্যটি প্রয়োজনীয়' : 'This field is required';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['bn', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) {
    return false;
  }
}
