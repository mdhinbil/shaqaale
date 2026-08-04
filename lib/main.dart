import 'package:flutter/material.dart';
import 'data/store.dart';
import 'screens/login_screen.dart';
import 'screens/staff_home.dart';
import 'screens/dashboard_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/payroll_screen.dart';
import 'screens/more_screen.dart';

final store = Store();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.init();
  runApp(const ShaqaaleApp());
}

// Brand colours shared across the MareegTech family.
const kNavy = Color(0xFF0A1628);
const kBlue = Color(0xFF1A6EF5);
const kCyan = Color(0xFF00B8D9);
const kGreen = Color(0xFF1F9D63);
const kBg = Color(0xFFF2F5F9);

/// Tiny i18n helper (English / Somali), reading the live language.
String t(String en, String so) => store.lang == 'so' ? so : en;

class ShaqaaleApp extends StatelessWidget {
  const ShaqaaleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shaqaale',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kBlue, primary: kBlue),
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kNavy,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
              fontSize: 19, fontWeight: FontWeight.w800, color: kNavy),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE3E8EF)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});
  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  @override
  void initState() {
    super.initState();
    store.addListener(_onChange);
  }

  @override
  void dispose() {
    store.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (store.user == null) return const LoginScreen();
    if (store.isStaff) return const StaffHome(); // limited self-service view
    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    store.addListener(_onChange);
  }

  @override
  void dispose() {
    store.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const EmployeesScreen(),
      const AttendanceScreen(),
      const PayrollScreen(),
      const MoreScreen(),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: screens[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        height: 66,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: t('Home', 'Guriga')),
          NavigationDestination(
            icon: const Icon(Icons.people_alt_outlined),
            selectedIcon: const Icon(Icons.people_alt),
            label: t('Staff', 'Shaqaale')),
          NavigationDestination(
            icon: const Icon(Icons.event_available_outlined),
            selectedIcon: const Icon(Icons.event_available),
            label: t('Attendance', 'Xaadiris')),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            selectedIcon: const Icon(Icons.payments),
            label: t('Payroll', 'Mushahar')),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            selectedIcon: const Icon(Icons.more_horiz),
            label: t('More', 'Dheeraad')),
        ],
      ),
    );
  }
}
