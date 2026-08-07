import 'package:flutter/material.dart';
import 'data/store.dart';
import 'data/cloud.dart';
import 'screens/login_screen.dart';
import 'screens/staff_home.dart';
import 'screens/pending_screen.dart';
import 'screens/companies_admin_screen.dart';
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
        // Bigger, more legible bottom-nav labels and icons (esp. on tablets).
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE4EEFF), // soft brand-blue pill
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                fontSize: 13.5,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: states.contains(WidgetState.selected)
                    ? kBlue
                    : const Color(0xFF6B7688),
              )),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                size: 27,
                color: states.contains(WidgetState.selected)
                    ? kBlue
                    : const Color(0xFF6B7688),
              )),
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
    cloud.addListener(_onChange); // approval state drives which screen shows
  }

  @override
  void dispose() {
    store.removeListener(_onChange);
    cloud.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (store.user == null) return const LoginScreen();
    // MareegTech master account manages approvals instead of running HR.
    if (cloud.master) return const CompaniesAdminScreen(isHome: true);
    // Staff self-service (local employee login) is never cloud-gated.
    if (store.isStaff) return const StaffHome();
    // A company registered but not yet approved can't use the app.
    if (cloud.appBlocked) return const PendingScreen();
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
        height: 72,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: t('Home', 'Guriga')),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: t('Staff', 'Shaqaale')),
          NavigationDestination(
            icon: const Icon(Icons.fact_check_outlined),
            selectedIcon: const Icon(Icons.fact_check_rounded),
            label: t('Attendance', 'Xaadiris')),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: t('Payroll', 'Mushahar')),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: t('More', 'Dheeraad')),
        ],
      ),
    );
  }
}
