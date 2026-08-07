import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'cloud.dart';

/// Everything Shaqaale knows, held in memory and mirrored to disk. Keys are
/// prefixed `hr_` so they don't collide with other MareegTech apps on a shared
/// device, and the JSON shape is cloud-sync friendly for later.
class Store extends ChangeNotifier {
  static const kEmployees = 'hr_employees';
  static const kAttendance = 'hr_attendance';
  static const kLeaves = 'hr_leaves';
  static const kPayslips = 'hr_payslips';
  static const kAccounts = 'hr_accounts';
  static const kDepts = 'hr_departments';
  static const kSettings = 'hr_settings';

  late SharedPreferences _sp;

  List<Employee> employees = [];
  List<Attendance> attendance = [];
  List<Leave> leaves = [];
  List<Payslip> payslips = [];
  List<Account> accounts = [];
  List<String> departments = [];

  Account? user;
  String staffEmpId = ''; // set when a staff member (not an admin) is signed in

  // Settings
  String company = 'My Company';
  String companyLogo = ''; // base64 company logo, or ''
  String adminPhoto = ''; // base64 admin profile picture, or ''
  String currency = 'USD'; // default display currency for totals
  double fxSos = 580, fxSlsh = 8500; // 1 USD -> local
  String lang = 'en';

  Future<void> init() async {
    _sp = await SharedPreferences.getInstance();
    _readAll();
    // Restore a saved cloud session and pull before seeding defaults, so a
    // device that persisted its session doesn't recreate defaults over real data.
    try {
      final applied = await cloud.boot();
      if (applied > 0) _readAll();
    } catch (_) {}
    if (accounts.isEmpty) {
      accounts = [
        Account(id: 'a1', name: 'Admin', username: 'admin', password: 'admin123', role: 'admin'),
      ];
      _write(kAccounts, accounts.map((e) => e.toJson()).toList());
    }
    if (departments.isEmpty) {
      departments = ['Management', 'Finance', 'Operations', 'Sales', 'Support'];
      _write(kDepts, departments);
    }
    notifyListeners();
  }

  void _readAll() {
    employees = _list(kEmployees).map((e) => Employee.fromJson(e)).toList();
    attendance = _list(kAttendance).map((e) => Attendance.fromJson(e)).toList();
    leaves = _list(kLeaves).map((e) => Leave.fromJson(e)).toList();
    payslips = _list(kPayslips).map((e) => Payslip.fromJson(e)).toList();
    accounts = _list(kAccounts).map((e) => Account.fromJson(e)).toList();
    departments = _strings(kDepts);
    final s = _map(kSettings);
    company = (s['company'] ?? 'My Company').toString();
    companyLogo = (s['companyLogo'] ?? '').toString();
    adminPhoto = (s['adminPhoto'] ?? '').toString();
    currency = (s['currency'] ?? 'USD').toString();
    fxSos = (s['fxSos'] as num?)?.toDouble() ?? 580;
    fxSlsh = (s['fxSlsh'] as num?)?.toDouble() ?? 8500;
    lang = _sp.getString('hr_lang') == 'so' ? 'so' : 'en';
  }

  List<Map<String, dynamic>> _list(String k) {
    try {
      final raw = _sp.getString(k);
      if (raw == null || raw.isEmpty) return [];
      final v = jsonDecode(raw);
      if (v is! List) return [];
      return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  List<String> _strings(String k) {
    try {
      final raw = _sp.getString(k);
      if (raw == null || raw.isEmpty) return [];
      final v = jsonDecode(raw);
      return v is List ? v.map((e) => e.toString()).toList() : [];
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _map(String k) {
    try {
      final raw = _sp.getString(k);
      if (raw == null || raw.isEmpty) return {};
      final v = jsonDecode(raw);
      return v is Map ? Map<String, dynamic>.from(v) : {};
    } catch (_) {
      return {};
    }
  }

  void _write(String k, Object v) {
    _sp.setString(k, jsonEncode(v));
    _sp.setInt('hr_ts_$k', DateTime.now().millisecondsSinceEpoch);
    cloud.queue(k); // debounced push; no-op when not signed in
  }

  /// Re-read everything from disk (after a cloud pull changed it underneath us).
  void reload() {
    _readAll();
    notifyListeners();
  }

  /// Replace this device's data with the cloud's for this account.
  Future<void> adoptCloudData() async {
    for (final k in cloudKeys) {
      await _sp.remove(k);
      await _sp.remove('hr_ts_$k');
    }
    await cloud.pull(force: true);
    _readAll();
    _ensureDefaults();
    notifyListeners();
  }

  Future<void> uploadLocalData() async => cloud.pushAll();

  /// A brand-new company account starts empty — clear any records left on this
  /// device (e.g. from testing), keep default departments, then seed the cloud.
  Future<void> startNewCompany(String companyName) async {
    employees = [];
    attendance = [];
    leaves = [];
    payslips = [];
    company = companyName.trim().isEmpty ? 'My Company' : companyName.trim();
    saveEmployees();
    saveAttendance();
    saveLeaves();
    savePayslips();
    saveSettings();
    await cloud.pushAll();
  }

  void _ensureDefaults() {
    if (accounts.isEmpty) {
      accounts = [
        Account(id: 'a1', name: 'Admin', username: 'admin', password: 'admin123', role: 'admin'),
      ];
      saveAccounts();
    }
    if (departments.isEmpty) {
      departments = ['Management', 'Finance', 'Operations', 'Sales', 'Support'];
      saveDepartments();
    }
  }

  // ── auth ──────────────────────────────────────────────
  bool signIn(String username, String password) {
    final u = username.toLowerCase().trim();
    for (final a in accounts) {
      if (a.username.toLowerCase() == u && a.password == password) {
        user = a;
        staffEmpId = '';
        notifyListeners();
        return true;
      }
    }
    // Staff self-service login: an active employee with matching credentials.
    for (final e in employees) {
      if (e.active &&
          e.username.isNotEmpty &&
          e.username.toLowerCase() == u &&
          e.password == password) {
        user = Account(
            id: 'emp_${e.id}',
            name: e.name,
            username: e.username,
            password: e.password,
            role: 'staff');
        staffEmpId = e.id;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  bool get isStaff => user?.role == 'staff';
  Employee? get staffEmp => empById(staffEmpId);

  /// Open an admin session after signing in with the cloud account (front-door
  /// cloud login). The synthetic user just lets the app open; data comes from
  /// the cloud pull the caller runs.
  void openCloudAdmin(String email) {
    user = Account(
      id: 'cloud_admin',
      name: email.contains('@') ? email.split('@').first : email,
      username: email,
      password: '',
      role: 'admin',
    );
    staffEmpId = '';
    _ensureDefaults();
    notifyListeners();
  }

  void signOut() {
    user = null;
    staffEmpId = '';
    notifyListeners();
  }

  /// Change the signed-in account's password. Returns null on success, or a
  /// human-readable reason it failed.
  String? changePassword(String current, String next) {
    final u = user;
    if (u == null) return 'Not signed in';
    final wrong = t2('Current password is wrong', 'Furaha hadda waa khalad');
    final short =
        t2('New password is too short', 'Furaha cusub aad buu u gaaban yahay');
    // Staff change the password on their own employee record.
    if (isStaff) {
      final e = staffEmp;
      if (e == null) return 'No profile';
      if (e.password != current) return wrong;
      if (next.trim().length < 4) return short;
      e.password = next.trim();
      u.password = next.trim();
      saveEmployees();
      return null;
    }
    if (u.password != current) return wrong;
    if (next.trim().length < 4) return short;
    u.password = next.trim();
    final i = accounts.indexWhere((a) => a.id == u.id);
    if (i >= 0) accounts[i].password = next.trim();
    saveAccounts();
    return null;
  }

  /// A staff member edits their own contact details.
  String? updateMyProfile(String name, String phone, String email) {
    final e = staffEmp;
    if (e == null) return 'No profile';
    if (name.trim().isNotEmpty) e.name = name.trim();
    e.phone = phone.trim();
    e.email = email.trim();
    user?.name = e.name;
    saveEmployees();
    return null;
  }

  /// Update the signed-in account's display name and login username. Returns
  /// null on success, or a human-readable reason it failed.
  String? updateProfile(String name, String username) {
    final u = user;
    if (u == null) return 'Not signed in';
    final un = username.trim();
    if (un.isEmpty) {
      return t2('Username cannot be empty', 'Magaca isticmaale ma madhnaan karo');
    }
    if (accounts.any(
        (a) => a.id != u.id && a.username.toLowerCase() == un.toLowerCase())) {
      return t2('That username is taken', 'Magacaas horey ayaa loo qaatay');
    }
    u.name = name.trim().isEmpty ? u.name : name.trim();
    u.username = un;
    final i = accounts.indexWhere((a) => a.id == u.id);
    if (i >= 0) {
      accounts[i].name = u.name;
      accounts[i].username = un;
    }
    saveAccounts();
    return null;
  }

  // Local i18n helper (store can't import main.dart's t() without a cycle).
  String t2(String en, String so) => lang == 'so' ? so : en;

  void setLang(String l) {
    lang = l == 'so' ? 'so' : 'en';
    _sp.setString('hr_lang', lang);
    notifyListeners();
  }

  // ── saves ─────────────────────────────────────────────
  void saveEmployees() {
    _write(kEmployees, employees.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  void saveAttendance() {
    _write(kAttendance, attendance.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  void saveLeaves() {
    _write(kLeaves, leaves.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  void savePayslips() {
    _write(kPayslips, payslips.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  void saveDepartments() {
    _write(kDepts, departments);
    notifyListeners();
  }

  void saveAccounts() {
    _write(kAccounts, accounts.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  void saveSettings() {
    _write(kSettings, {
      'company': company,
      'companyLogo': companyLogo,
      'adminPhoto': adminPhoto,
      'currency': currency,
      'fxSos': fxSos,
      'fxSlsh': fxSlsh,
    });
    notifyListeners();
  }

  // ── helpers ───────────────────────────────────────────
  Employee? empById(String id) {
    for (final e in employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  String today() {
    final n = DateTime.now();
    return '${n.year}-${_2(n.month)}-${_2(n.day)}';
  }

  String thisMonth() {
    final n = DateTime.now();
    return '${n.year}-${_2(n.month)}';
  }

  String _2(int n) => n.toString().padLeft(2, '0');

  /// Attendance status for an employee on a given day (yyyy-mm-dd), or null.
  String? statusOn(String empId, String date) {
    for (final a in attendance) {
      if (a.empId == empId && a.date == date) return a.status;
    }
    return null;
  }

  void markOn(String empId, String date, String status) {
    final i = attendance.indexWhere((a) => a.empId == empId && a.date == date);
    if (i >= 0) {
      attendance[i].status = status;
    } else {
      attendance.add(Attendance(
          id: 'at${DateTime.now().microsecondsSinceEpoch}',
          empId: empId,
          date: date,
          status: status));
    }
    saveAttendance();
  }

  String? todayStatus(String empId) => statusOn(empId, today());
  void mark(String empId, String status) => markOn(empId, today(), status);

  String fmtDate(DateTime n) => '${n.year}-${_2(n.month)}-${_2(n.day)}';
  DateTime parseDate(String s) => DateTime.tryParse(s) ?? DateTime.now();

  /// Format an amount held in [cur] into a readable string in that currency.
  String money(double amount, [String? cur]) {
    switch (cur ?? currency) {
      case 'SOS':
        return 'Sh ${amount.round()}';
      case 'SLSH':
        return 'SlSh ${amount.round()}';
      default:
        return '\$${amount.toStringAsFixed(2)}';
    }
  }

  /// Convert an amount from its currency to USD (for cross-employee totals).
  double toUsd(double amount, String cur) {
    switch (cur) {
      case 'SOS':
        return amount / fxSos;
      case 'SLSH':
        return amount / fxSlsh;
      default:
        return amount;
    }
  }

  // Dashboard figures
  int get activeCount => employees.where((e) => e.active).length;
  int get presentToday {
    final d = today();
    return attendance.where((a) => a.date == d && a.status == 'present').length;
  }

  int get onLeaveToday {
    final d = today();
    return attendance.where((a) => a.date == d && a.status == 'leave').length;
  }

  int get pendingLeaves => leaves.where((l) => l.status == 'pending').length;

  /// Total monthly payroll (net of generated payslips this month) in USD.
  double payrollThisMonthUsd() {
    final m = thisMonth();
    var t = 0.0;
    for (final p in payslips.where((p) => p.month == m)) {
      t += toUsd(p.net, p.currency);
    }
    return t;
  }
}
