import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

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

  // Settings
  String company = 'My Company';
  String currency = 'USD'; // default display currency for totals
  double fxSos = 580, fxSlsh = 8500; // 1 USD -> local
  String lang = 'en';

  Future<void> init() async {
    _sp = await SharedPreferences.getInstance();
    _readAll();
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

  void _write(String k, Object v) => _sp.setString(k, jsonEncode(v));

  // ── auth ──────────────────────────────────────────────
  bool signIn(String username, String password) {
    for (final a in accounts) {
      if (a.username.toLowerCase() == username.toLowerCase().trim() &&
          a.password == password) {
        user = a;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void signOut() {
    user = null;
    notifyListeners();
  }

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

  void saveSettings() {
    _write(kSettings, {
      'company': company,
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

  /// Attendance status for an employee today, or null if unmarked.
  String? todayStatus(String empId) {
    final d = today();
    for (final a in attendance) {
      if (a.empId == empId && a.date == d) return a.status;
    }
    return null;
  }

  void mark(String empId, String status) {
    final d = today();
    final i = attendance.indexWhere((a) => a.empId == empId && a.date == d);
    if (i >= 0) {
      attendance[i].status = status;
    } else {
      attendance.add(Attendance(
          id: 'at${DateTime.now().microsecondsSinceEpoch}',
          empId: empId,
          date: d,
          status: status));
    }
    saveAttendance();
  }

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
