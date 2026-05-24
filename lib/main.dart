import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/activity_store.dart';
import 'theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/dictation/dictation_screen.dart';
import 'screens/notes/notes_screen.dart';
import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await initializeDateFormatting('fr_FR', null);
  await ActivityStore.instance.load();
  runApp(const KairosApp());
}

class KairosApp extends StatelessWidget {
  const KairosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      theme: KairosTheme.light,
      home: const KairosShell(),
    );
  }
}

class KairosShell extends StatefulWidget {
  const KairosShell({super.key});

  @override
  State<KairosShell> createState() => _KairosShellState();
}

class _KairosShellState extends State<KairosShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    DictationScreen(),
    NotesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9F9FF), Color(0xFFE7EEFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: KairosBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
