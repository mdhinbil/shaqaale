import 'package:flutter/material.dart';
import '../main.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const _opts = ['present', 'late', 'leave', 'absent'];
  late String _date; // yyyy-mm-dd being viewed/edited

  @override
  void initState() {
    super.initState();
    _date = store.today();
  }

  String _label(String s) => switch (s) {
        'present' => t('Present', 'Jooga'),
        'late' => t('Late', 'Daahay'),
        'leave' => t('Leave', 'Fasax'),
        _ => t('Absent', 'Maqan'),
      };

  Color _color(String s) => switch (s) {
        'present' => const Color(0xFF1F9D63),
        'late' => const Color(0xFFE0842B),
        'leave' => const Color(0xFF1A6EF5),
        _ => const Color(0xFFD63B3B),
      };

  void _shift(int days) {
    setState(() =>
        _date = store.fmtDate(store.parseDate(_date).add(Duration(days: days))));
  }

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: store.parseDate(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = store.fmtDate(d));
  }

  @override
  Widget build(BuildContext context) {
    final staff = store.employees.where((e) => e.active).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final isToday = _date == store.today();
    final present =
        staff.where((e) => store.statusOn(e.id, _date) == 'present').length;
    final marked = staff.where((e) => store.statusOn(e.id, _date) != null).length;

    return Scaffold(
      appBar: AppBar(title: Text(t('Attendance', 'Xaadiris'))),
      body: staff.isEmpty
          ? Center(
              child: Text(t('Add staff first', 'Marka hore shaqaale ku dar'),
                  style: const TextStyle(color: Color(0xFF6B7688))))
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () => _shift(-1),
                            icon: const Icon(Icons.chevron_left)),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pick,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(
                                      isToday
                                          ? t('Today', 'Maanta')
                                          : t('Date', 'Taariikh'),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF6B7688))),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.calendar_today,
                                      size: 13, color: Color(0xFF8B97A8)),
                                ]),
                                const SizedBox(height: 2),
                                Text(_date,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: kNavy)),
                              ],
                            ),
                          ),
                        ),
                        Text('$present / ${staff.length}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: kGreen)),
                        IconButton(
                            onPressed: () => _shift(1),
                            icon: const Icon(Icons.chevron_right)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                  child: Row(
                    children: [
                      Text(
                          '${t('Marked', 'La calaamadeeyay')}: $marked / ${staff.length}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF8B97A8))),
                      const Spacer(),
                      if (!isToday)
                        TextButton(
                          onPressed: () =>
                              setState(() => _date = store.today()),
                          child: Text(t('Go to today', 'U gudub maanta')),
                        ),
                    ],
                  ),
                ),
                for (final e in staff)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(e.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 14)),
                            ),
                            if (store.statusOn(e.id, _date) != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: _color(store.statusOn(e.id, _date)!)
                                        .withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(_label(store.statusOn(e.id, _date)!),
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color:
                                            _color(store.statusOn(e.id, _date)!))),
                              ),
                          ]),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (final s in _opts)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: _MarkBtn(
                                      label: _label(s),
                                      color: _color(s),
                                      on: store.statusOn(e.id, _date) == s,
                                      onTap: () {
                                        store.markOn(e.id, _date, s);
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MarkBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool on;
  final VoidCallback onTap;
  const _MarkBtn(
      {required this.label,
      required this.color,
      required this.on,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: on ? color : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border:
              Border.all(color: on ? color : const Color(0xFFE3E8EF), width: 1.5),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: on ? Colors.white : const Color(0xFF5C6B82))),
      ),
    );
  }
}
