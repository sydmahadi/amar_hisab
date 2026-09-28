import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  AppSettings get settings => AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(settings.t('settings')),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              40,
            ),
            children: [
              _sectionTitle(
                context,
                settings.t('language'),
                Icons.language_rounded,
              ),
              const SizedBox(height: 10),

              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'bn',
                      groupValue: settings.language,
                      onChanged: (value) {
                        if (value != null) {
                          settings.setLanguage(value);
                        }
                      },
                      title: Text(
                        settings.t('bangla'),
                      ),
                      secondary: const Icon(
                        Icons.translate_rounded,
                      ),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      value: 'en',
                      groupValue: settings.language,
                      onChanged: (value) {
                        if (value != null) {
                          settings.setLanguage(value);
                        }
                      },
                      title: Text(
                        settings.t('english'),
                      ),
                      secondary: const Icon(
                        Icons.language_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _sectionTitle(
                context,
                settings.t('theme'),
                Icons.palette_outlined,
              ),
              const SizedBox(height: 10),

              Card(
                child: SwitchListTile(
                  value: settings.darkMode,
                  onChanged: (value) {
                    settings.setDarkMode(value);
                  },
                  title: Text(
                    settings.darkMode
                        ? settings.t('darkTheme')
                        : settings.t('lightTheme'),
                  ),
                  subtitle: Text(
                    settings.darkMode
                        ? 'Dark'
                        : 'Light',
                  ),
                  secondary: Icon(
                    settings.darkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: AppTheme.gold,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _sectionTitle(
                context,
                settings.t('about'),
                Icons.info_outline_rounded,
              ),
              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          AppTheme.green.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.green,
                    ),
                  ),
                  title: Text(
                    settings.t('aboutApp'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    settings.isBangla
                        ? 'অ্যাপ, ফিচার ও ডেভেলপার সম্পর্কে জানুন'
                        : 'Learn about the app, features and developer',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AboutScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: Column(
                  children: [
                    Text(
                      'আমার হিসাব',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Sayeed Mahadi',
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
      },
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.gold,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
