import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

/// Reports you can read on screen and copy out (into WhatsApp, email, a note).
/// Text/clipboard keeps it dependency-free and works fully offline.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _tab = 0; // 0 payroll, 1 attendance, 2 staff

  static const _w = 32;
  String _pad(int n) => n > 0 ? ' ' * n : '';
  String _line(String a, String b) =>
      a + _pad((_w - a.length - b.length).clamp(1, _w)) + b;
  String _clip(String s, int n) => s.length > n ? s.substring(0, n) : s;

  String _payroll() {
    final m = store.thisMonth();
    final slips = store.payslips.where((p) => p.month == m).toList()
      ..sort((a, b) => a.empName.toLowerCase().compareTo(b.empName.toLowerCase()));
    final b = StringBuffer();
    b.writeln(store.company.toUpperCase());
    b.writeln('${t('PAYROLL', 'MUSHAHAR')} · $m');
    b.writeln('=' * _w);
    if (slips.isEmpty) {
      b.writeln(t('No payslips this month.', 'Bishaan warqad ma jirto.'));
    }
    final byCur = <String, double>{};
    for (final p in slips) {
      b.writeln(_line(_clip(p.empName, 20), store.money(p.net, p.currency)));
      byCur[p.currency] = (byCur[p.currency] ?? 0) + p.net;
    }
    if (slips.isNotEmpty) {
      b.writeln('-' * _w);
      byCur.forEach((cur, tot) => b.writeln(_line(cur, store.money(tot, cur))));
      final usd = slips.fold(0.0, (a, p) => a + store.toUsd(p.net, p.currency));
      b.writeln('=' * _w);
      b.writeln(_line('${t('TOTAL', 'WADARTA')} (USD)', store.money(usd, 'USD')));
      b.writeln('${slips.length} ${t('staff', 'shaqaale')}');
    }
    return b.toString();
  }

  String _attendance() {
    final m = store.thisMonth();
    final staff = store.employees.where((e) => e.active).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final b = StringBuffer();
    b.writeln(store.company.toUpperCase());
    b.writeln('${t('ATTENDANCE', 'XAADIRIS')} · $m');
    b.writeln('=' * _w);
    b.writeln(_line(t('Name', 'Magaca'), 'P  L  Lv A'));
    b.writeln('-' * _w);
    for (final e in staff) {
      var p = 0, l = 0, lv = 0, ab = 0;
      for (final a in store.attendance
          .where((a) => a.empId == e.id && a.date.startsWith(m))) {
        if (a.status == 'present') {
          p++;
        } else if (a.status == 'late') {
          l++;
        } else if (a.status == 'leave') {
          lv++;
        } else {
          ab++;
        }
      }
      final counts =
          '${_p2(p)} ${_p2(l)} ${_p2(lv)} ${_p2(ab)}';
      b.writeln(_line(_clip(e.name, 20), counts));
    }
    if (staff.isEmpty) b.writeln(t('No staff.', 'Shaqaale ma jiro.'));
    b.writeln('=' * _w);
    b.writeln('P=${t('Present', 'Jooga')} L=${t('Late', 'Daahay')} '
        'Lv=${t('Leave', 'Fasax')} A=${t('Absent', 'Maqan')}');
    return b.toString();
  }

  String _p2(int n) => n.toString().padLeft(2);

  String _staff() {
    final list = [...store.employees]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final b = StringBuffer();
    b.writeln(store.company.toUpperCase());
    b.writeln('${t('STAFF LIST', 'LIISKA SHAQAALAHA')} · ${list.length}');
    b.writeln('=' * _w);
    for (final e in list) {
      b.writeln(e.name);
      final sub = [e.position, e.dept].where((s) => s.isNotEmpty).join(' · ');
      if (sub.isNotEmpty) b.writeln('  $sub');
      b.writeln(_line('  ${store.money(e.salary, e.currency)}',
          e.active ? t('active', 'firfircoon') : t('inactive', 'joogsan')));
    }
    if (list.isEmpty) b.writeln(t('No staff.', 'Shaqaale ma jiro.'));
    return b.toString();
  }

  String get _report => switch (_tab) {
        1 => _attendance(),
        2 => _staff(),
        _ => _payroll(),
      };

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: Text(t('Reports', 'Warbixinno'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                _seg(0, t('Payroll', 'Mushahar')),
                const SizedBox(width: 8),
                _seg(1, t('Attendance', 'Xaadiris')),
                const SizedBox(width: 8),
                _seg(2, t('Staff', 'Shaqaale')),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 90),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFC9D3E3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(report,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12.5, height: 1.5)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: report));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t('Report copied', 'Warbixinta waa la koobiyeeyay'))));
        },
        icon: const Icon(Icons.copy_all),
        label: Text(t('Copy', 'Koobi')),
      ),
    );
  }

  Widget _seg(int i, String label) {
    final on = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: on ? kBlue : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? kBlue : const Color(0xFFD8E0EA), width: 2),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: on ? Colors.white : const Color(0xFF5C6B82))),
        ),
      ),
    );
  }
}
