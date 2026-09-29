import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/money_db.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local database before the app starts.
  await MoneyDb.instance.init();

  // Initialize app settings.
  await AppSettings.instance.init();

  runApp(const AmarHisabApp());
}

class AmarHisabApp extends StatefulWidget {
  const AmarHisabApp({super.key});

  @override
  State<AmarHisabApp> createState() => _AmarHisabAppState();
}

class _AmarHisabAppState extends State<AmarHisabApp> {
  @override
  void initState() {
    super.initState();

    AppSettings.instance.addListener(_settingsChanged);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_settingsChanged);
    super.dispose();
  }

  void _settingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: settings.t('appName'),

      theme: AppTheme.light(),

      darkTheme: AppTheme.dark(),

      themeMode: settings.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,

      home: const HomeScreen(),
    );
  }
}
