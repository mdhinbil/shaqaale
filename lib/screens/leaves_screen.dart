import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});
  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  Color _c(String s) => switch (s) {
        'approved' => const Color(0xFF1A7A4F),
        'rejected' => const Color(0xFFC62F16),
        _ => const Color(0xFF8A5A00),
      };
  String _l(String s) => switch (s) {
        'approved' => t('Approved', 'La ansixiyay'),
        'rejected' => t('Rejected', 'La diiday'),
        _ => t('Pending', 'Sugaya'),
      };

  Future<void> _add() async {
    if (store.employees.isEmpty) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LeaveSheet(),
    );
    if (saved == true && mounted) setState(() {});
  }

  void _set(Leave l, String status) {
    l.status = status;
    store.saveLeaves();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = [...store.leaves]..sort((a, b) => b.from.compareTo(a.from));
    return Scaffold(
      appBar: AppBar(title: Text(t('Leave requests', 'Codsiyada fasaxa'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(t('Request', 'Codso')),
      ),
      body: list.isEmpty
          ? Center(
              child: Text(t('No leave requests', 'Codsi fasax ma jiro'),
                  style: const TextStyle(color: Color(0xFF6B7688))))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final l = list[i];
                final emp = store.empById(l.empId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(emp?.name ?? '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: _c(l.status).withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(_l(l.status),
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: _c(l.status))),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                            '${l.type} · ${l.from} → ${l.to} · ${l.days} ${t('days', 'maalmood')}',
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF5C6B82))),
                        if (l.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(l.note,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF8B97A8))),
                          ),
                        if (l.status == 'pending')
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _set(l, 'rejected'),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFC62F16),
                                      side: const BorderSide(
                                          color: Color(0xFFC62F16))),
                                  child: Text(t('Reject', 'Diid')),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _set(l, 'approved'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: kGreen),
                                  child: Text(t('Approve', 'Ansixi')),
                                ),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _LeaveSheet extends StatefulWidget {
  const _LeaveSheet();
  @override
  State<_LeaveSheet> createState() => _LeaveSheetState();
}

class _LeaveSheetState extends State<_LeaveSheet> {
  String _empId = '';
  String _type = 'Annual';
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (store.employees.isNotEmpty) _empId = store.employees.first.id;
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (_empId.isEmpty || _from.text.trim().isEmpty || _to.text.trim().isEmpty) {
      return;
    }
    store.leaves.add(Leave(
      id: 'lv${DateTime.now().millisecondsSinceEpoch}',
      empId: _empId,
      type: _type,
      from: _from.text.trim(),
      to: _to.text.trim(),
      note: _note.text.trim(),
    ));
    store.saveLeaves();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
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
              Text(t('New leave request', 'Codsi fasax cusub'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: kNavy)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _empId.isEmpty ? null : _empId,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: t('Employee', 'Shaqaale')),
                items: [
                  for (final e in store.employees)
                    DropdownMenuItem(value: e.id, child: Text(e.name)),
                ],
                onChanged: (v) => setState(() => _empId = v ?? _empId),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _type,
                isExpanded: true,
                decoration: InputDecoration(labelText: t('Type', 'Nooca')),
                items: const [
                  DropdownMenuItem(value: 'Annual', child: Text('Annual')),
                  DropdownMenuItem(value: 'Sick', child: Text('Sick')),
                  DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _from,
                        decoration: InputDecoration(
                            labelText: t('From (yyyy-mm-dd)', 'Laga (yyyy-mm-dd)')))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: _to,
                        decoration: InputDecoration(
                            labelText: t('To (yyyy-mm-dd)', 'Ilaa (yyyy-mm-dd)')))),
              ]),
              const SizedBox(height: 10),
              TextField(
                  controller: _note,
                  decoration: InputDecoration(labelText: t('Note', 'Qoraal'))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: _save, child: Text(t('Submit', 'Gudbi'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
