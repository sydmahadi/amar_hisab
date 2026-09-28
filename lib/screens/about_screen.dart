import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  AppSettings get settings => AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    final isBangla = settings.isBangla;

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.t('aboutApp')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          40,
        ),
        children: [
          _buildHeader(context),

          const SizedBox(height: 20),

          _buildSection(
            context,
            icon: Icons.info_outline_rounded,
            title: settings.t('appDescription'),
            child: Text(
              isBangla
                  ? 'আমার হিসাব একটি সহজ, সুন্দর ও ব্যবহারবান্ধব ব্যক্তিগত মানি ম্যানেজমেন্ট অ্যাপ। এই অ্যাপের মাধ্যমে দৈনন্দিন আয়, ব্যয়, লেনদেন, অ্যাকাউন্ট এবং বিভিন্ন খাতের হিসাব সহজে সংরক্ষণ ও পরিচালনা করা যায়।'
                  : 'Amar Hisab is a simple, clean and user-friendly personal money management app. It helps you record and manage daily income, expenses, transactions, accounts and categories easily.',
              style: const TextStyle(
                height: 1.7,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 16),

          _buildSection(
            context,
            icon: Icons.auto_awesome_rounded,
            title: settings.t('features'),
            child: Column(
              children: [
                _featureItem(
                  context,
                  Icons.add_card_rounded,
                  isBangla
                      ? 'আয়, ব্যয় ও ট্রান্সফার'
                      : 'Income, Expense & Transfer',
                ),
                _featureItem(
                  context,
                  Icons.account_balance_wallet_rounded,
                  isBangla
                      ? 'একাধিক অ্যাকাউন্ট'
                      : 'Multiple Accounts',
                ),
                _featureItem(
                  context,
                  Icons.category_rounded,
                  isBangla
                      ? 'নিজের মতো খাত যোগ ও পরিচালনা'
                      : 'Add and manage custom categories',
                ),
                _featureItem(
                  context,
                  Icons.edit_note_rounded,
                  isBangla
                      ? 'লেনদেন সম্পাদনা ও মুছে ফেলা'
                      : 'Edit and delete transactions',
                ),
                _featureItem(
                  context,
                  Icons.bar_chart_rounded,
                  isBangla
                      ? 'আয় ও ব্যয়ের পরিসংখ্যান'
                      : 'Income and expense statistics',
                ),
                _featureItem(
                  context,
                  Icons.calendar_month_rounded,
                  isBangla
                      ? 'দৈনিক, সাপ্তাহিক, মাসিক ও বার্ষিক হিসাব'
                      : 'Daily, weekly, monthly and yearly records',
                ),
                _featureItem(
                  context,
                  Icons.assessment_rounded,
                  isBangla
                      ? 'মাসিক রিপোর্ট'
                      : 'Monthly reports',
                ),
                _featureItem(
                  context,
                  Icons.picture_as_pdf_rounded,
                  isBangla
                      ? 'রিপোর্ট PDF/JPG হিসেবে সংরক্ষণ'
                      : 'Save reports as PDF/JPG',
                ),
                _featureItem(
                  context,
                  Icons.dark_mode_rounded,
                  isBangla
                      ? 'ডার্ক ও লাইট থিম'
                      : 'Dark and light theme',
                ),
                _featureItem(
                  context,
                  Icons.language_rounded,
                  isBangla
                      ? 'বাংলা ও ইংরেজি ভাষা'
                      : 'Bangla and English language',
                ),
                _featureItem(
                  context,
                  Icons.storage_rounded,
                  isBangla
                      ? 'ডিভাইসে লোকাল ডেটা সংরক্ষণ'
                      : 'Local data storage on the device',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSection(
            context,
            icon: Icons.person_outline_rounded,
            title: settings.t('developerInfo'),
            child: Column(
              children: [
                _infoRow(
                  context,
                  Icons.person_rounded,
                  settings.t('developedBy'),
                  'Sayeed Mahadi',
                ),
                const SizedBox(height: 14),
                _infoRow(
                  context,
                  Icons.email_rounded,
                  settings.t('contact'),
                  'mahadisayeed@gmail.com',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Column(
              children: [
                const Text(
                  'আমার হিসাব',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isBangla
                      ? 'সহজে আপনার হিসাব রাখুন'
                      : 'Manage your money easily',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.darkGreen,
            AppTheme.green,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 40,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'আমার হিসাব',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            settings.isBangla
                ? 'সহজে আপনার হিসাব রাখুন'
                : 'Manage your money easily',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.green,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _featureItem(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.gold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: AppTheme.gold,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
