import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});
  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _generate() {
    final m = store.thisMonth();
    var added = 0;
    for (final e in store.employees.where((e) => e.active)) {
      final exists =
          store.payslips.any((p) => p.empId == e.id && p.month == m);
      if (exists) continue;
      store.payslips.add(Payslip(
        id: 'ps${DateTime.now().microsecondsSinceEpoch}_$added',
        empId: e.id,
        empName: e.name,
        month: m,
        currency: e.currency,
        base: e.salary,
      ));
      added++;
    }
    if (added > 0) store.savePayslips();
    setState(() {});
    _say(added > 0
        ? '${t('Generated', 'La sameeyay')}: $added'
        : t('All already generated', 'Dhammaan horay ayaa loo sameeyay'));
  }

  Future<void> _open(Payslip p) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayslipSheet(slip: p),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final m = store.thisMonth();
    final slips = store.payslips.where((p) => p.month == m).toList()
      ..sort((a, b) => a.empName.toLowerCase().compareTo(b.empName.toLowerCase()));
    final totalUsd = slips.fold(0.0, (a, p) => a + store.toUsd(p.net, p.currency));

    return Scaffold(
      appBar: AppBar(title: Text(t('Payroll', 'Mushahar'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generate,
        icon: const Icon(Icons.playlist_add_check),
        label: Text(t('Generate', 'Samee')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
        children: [
          Card(
            color: kBlue,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t('Month', 'Bisha')} · $m',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(store.money(totalUsd, 'USD'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800)),
                  Text('${slips.length} ${t('payslips', 'warqadaha mushahar')}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (slips.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Center(
                    child: Text(
                        t('No payslips yet — tap Generate.',
                            'Weli warqad mushahar ma jirto — taabo Samee.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6B7688)))),
              ),
            )
          else
            for (final p in slips)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEAF2FF),
                    child: Text(
                        p.empName.isNotEmpty ? p.empName[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: kBlue)),
                  ),
                  title: Text(p.empName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: Text(
                      '${t('Base', 'Aasaas')} ${store.money(p.base, p.currency)}'
                      '${p.earnings > 0 ? ' · +${store.money(p.earnings, p.currency)}' : ''}'
                      '${p.deductions > 0 ? ' · -${store.money(p.deductions, p.currency)}' : ''}'),
                  trailing: Text(store.money(p.net, p.currency),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF1152CC))),
                  onTap: () => _open(p),
                ),
              ),
        ],
      ),
    );
  }
}

class _PayslipSheet extends StatefulWidget {
  final Payslip slip;
  const _PayslipSheet({required this.slip});
  @override
  State<_PayslipSheet> createState() => _PayslipSheetState();
}

class _Row {
  final TextEditingController label;
  final TextEditingController amount;
  bool deduct;
  _Row(String l, double a, this.deduct)
      : label = TextEditingController(text: l),
        amount = TextEditingController(text: a == 0 ? '' : a.toString());
  void dispose() {
    label.dispose();
    amount.dispose();
  }
}

class _PayslipSheetState extends State<_PayslipSheet> {
  final List<_Row> _rows = [];

  @override
  void initState() {
    super.initState();
    for (final it in widget.slip.items) {
      _rows.add(_Row(it.label, it.amount, it.deduct));
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  double _amt(_Row r) => double.tryParse(r.amount.text.trim()) ?? 0;

  void _add(String label, bool deduct) {
    setState(() => _rows.add(_Row(label, 0, deduct)));
  }

  void _save() {
    widget.slip.items
      ..clear()
      ..addAll(_rows
          .where((r) => r.label.text.trim().isNotEmpty || _amt(r) != 0)
          .map((r) => PayItem(
              label: r.label.text.trim(), amount: _amt(r), deduct: r.deduct)));
    store.savePayslips();
    Navigator.pop(context, true);
  }

  void _delete() {
    store.payslips.removeWhere((x) => x.id == widget.slip.id);
    store.savePayslips();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.slip;
    var earn = 0.0, ded = 0.0;
    for (final r in _rows) {
      if (r.deduct) {
        ded += _amt(r);
      } else {
        earn += _amt(r);
      }
    }
    final net = p.base + earn - ded;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFC3CBD6),
                        borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 16),
              Text(p.empName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: kNavy)),
              Text('${t('Payslip', 'Warqad mushahar')} · ${p.month}',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7688))),
              const SizedBox(height: 14),

              // Line items
              for (int i = 0; i < _rows.length; i++) _itemRow(_rows[i]),

              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _preset(t('+ Earning', '+ Dakhli'), false),
                  _preset(t('+ Deduction', '+ Jarid'), true),
                  _chip(t('Overtime', 'Saacado dheeraad'), false),
                  _chip(t('Bonus', 'Abaalmarin'), false),
                  _chip(t('Tax', 'Cashuur'), true),
                  _chip(t('Advance', 'Hormaris'), true),
                ],
              ),

              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE3E8EF)),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _row(t('Base salary', 'Mushahar aasaasi'),
                      store.money(p.base, p.currency)),
                  _row(t('Earnings', 'Dakhliga'),
                      '+ ${store.money(earn, p.currency)}'),
                  _row(t('Deductions', 'Jarid'),
                      '- ${store.money(ded, p.currency)}'),
                  const Divider(height: 18),
                  _row(t('NET PAY', 'LACAGTA GUUD'),
                      store.money(net, p.currency),
                      big: true),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(t('Delete', 'Tirtir')),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        foregroundColor: const Color(0xFFC62F16),
                        side: const BorderSide(color: Color(0xFFC62F16))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                      onPressed: _save, child: Text(t('Save', 'Kaydi'))),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemRow(_Row r) {
    final green = const Color(0xFF1F9D63), red = const Color(0xFFC62F16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => r.deduct = !r.deduct),
            child: Container(
              width: 34,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (r.deduct ? red : green).withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(r.deduct ? Icons.remove : Icons.add,
                  color: r.deduct ? red : green),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: TextField(
              controller: r.label,
              decoration: InputDecoration(
                  isDense: true, hintText: t('Label', 'Sumad')),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: TextField(
              controller: r.amount,
              textAlign: TextAlign.right,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(isDense: true, hintText: '0'),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              r.dispose();
              _rows.remove(r);
            }),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF8B97A8)),
          ),
        ],
      ),
    );
  }

  Widget _preset(String label, bool deduct) => FilledButton.tonal(
        onPressed: () => _add('', deduct),
        style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEAEEF4),
            foregroundColor: kNavy,
            minimumSize: const Size(0, 38)),
        child: Text(label, style: const TextStyle(fontSize: 12.5)),
      );

  Widget _chip(String label, bool deduct) => GestureDetector(
        onTap: () => _add(label, deduct),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD8E0EA)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5C6B82))),
        ),
      );

  Widget _row(String l, String v, {bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: TextStyle(
                    fontSize: big ? 15 : 13,
                    fontWeight: big ? FontWeight.w800 : FontWeight.w600,
                    color: big ? kNavy : const Color(0xFF44536B))),
            Text(v,
                style: TextStyle(
                    fontSize: big ? 18 : 13.5,
                    fontWeight: FontWeight.w800,
                    color: big ? kNavy : const Color(0xFF1152CC))),
          ],
        ),
      );
}
