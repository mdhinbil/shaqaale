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
            color: kNavy,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t('Month', 'Bisha')} · $m',
                      style: const TextStyle(
                          color: Color(0xFFAEB9CC),
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
                          color: Color(0xFFAEB9CC), fontSize: 12.5)),
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
                      '${p.allowances > 0 ? ' · +${store.money(p.allowances, p.currency)}' : ''}'
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

class _PayslipSheetState extends State<_PayslipSheet> {
  late final TextEditingController _allow, _ded;

  @override
  void initState() {
    super.initState();
    _allow = TextEditingController(
        text: widget.slip.allowances == 0 ? '' : widget.slip.allowances.toString());
    _ded = TextEditingController(
        text: widget.slip.deductions == 0 ? '' : widget.slip.deductions.toString());
  }

  @override
  void dispose() {
    _allow.dispose();
    _ded.dispose();
    super.dispose();
  }

  void _save() {
    widget.slip.allowances = double.tryParse(_allow.text.trim()) ?? 0;
    widget.slip.deductions = double.tryParse(_ded.text.trim()) ?? 0;
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
    final net = (double.tryParse(_allow.text.trim()) ?? 0) -
        (double.tryParse(_ded.text.trim()) ?? 0) +
        p.base;
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
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _allow,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                            labelText: t('Allowances', 'Gunno')))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: _ded,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                            labelText: t('Deductions', 'Jarid')))),
              ]),
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
                  _row(t('Allowances', 'Gunno'),
                      '+ ${store.money(double.tryParse(_allow.text.trim()) ?? 0, p.currency)}'),
                  _row(t('Deductions', 'Jarid'),
                      '- ${store.money(double.tryParse(_ded.text.trim()) ?? 0, p.currency)}'),
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
