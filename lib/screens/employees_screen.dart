import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _q = '';

  List<Employee> get _list {
    final q = _q.toLowerCase();
    final all = [...store.employees]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (q.isEmpty) return all;
    return all
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.position.toLowerCase().contains(q) ||
            e.dept.toLowerCase().contains(q) ||
            e.phone.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _edit([Employee? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeSheet(existing: existing),
    );
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _list;
    return Scaffold(
      appBar: AppBar(title: Text(t('Staff', 'Shaqaale'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.person_add_alt),
        label: Text(t('Add', 'Ku dar')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: t('Search staff…', 'Raadi shaqaale…'),
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                        _q.isEmpty
                            ? t('No staff yet', 'Weli shaqaale ma jiro')
                            : t('No match', 'Waxba lama helin'),
                        style: const TextStyle(color: Color(0xFF6B7688))))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final e = items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEAF2FF),
                            child: Text(
                                e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, color: kBlue)),
                          ),
                          title: Text(e.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14)),
                          subtitle: Text([e.position, e.dept]
                              .where((s) => s.isNotEmpty)
                              .join(' · ')),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(store.money(e.salary, e.currency),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: Color(0xFF1152CC))),
                              Text(
                                  e.active
                                      ? t('Active', 'Firfircoon')
                                      : t('Inactive', 'Joogsan'),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: e.active
                                          ? const Color(0xFF1A7A4F)
                                          : const Color(0xFF8B97A8))),
                            ],
                          ),
                          onTap: () => _edit(e),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeSheet extends StatefulWidget {
  final Employee? existing;
  const _EmployeeSheet({this.existing});
  @override
  State<_EmployeeSheet> createState() => _EmployeeSheetState();
}

class _EmployeeSheetState extends State<_EmployeeSheet> {
  late final TextEditingController _n, _pos, _phone, _email, _sal, _hired, _note;
  late final TextEditingController _un, _pw;
  late String _dept, _currency, _status;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _n = TextEditingController(text: e?.name ?? '');
    _pos = TextEditingController(text: e?.position ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _sal = TextEditingController(text: e == null ? '' : e.salary.toString());
    _hired = TextEditingController(text: e?.hired ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _un = TextEditingController(text: e?.username ?? '');
    _pw = TextEditingController(text: e?.password ?? '');
    _dept = e?.dept.isNotEmpty == true ? e!.dept : (store.departments.isNotEmpty ? store.departments.first : '');
    _currency = e?.currency ?? 'USD';
    _status = e?.status ?? 'active';
  }

  @override
  void dispose() {
    for (final c in [_n, _pos, _phone, _email, _sal, _hired, _note, _un, _pw]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final name = _n.text.trim();
    if (name.isEmpty) return;
    final salary = double.tryParse(_sal.text.trim()) ?? 0;
    final e = widget.existing;
    if (e != null) {
      e.name = name;
      e.position = _pos.text.trim();
      e.phone = _phone.text.trim();
      e.email = _email.text.trim();
      e.dept = _dept;
      e.currency = _currency;
      e.status = _status;
      e.salary = salary;
      e.hired = _hired.text.trim();
      e.note = _note.text.trim();
      e.username = _un.text.trim();
      e.password = _pw.text;
    } else {
      store.employees.add(Employee(
        id: 'e${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        position: _pos.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        dept: _dept,
        currency: _currency,
        status: _status,
        salary: salary,
        hired: _hired.text.trim(),
        note: _note.text.trim(),
        username: _un.text.trim(),
        password: _pw.text,
      ));
    }
    store.saveEmployees();
    Navigator.pop(context, true);
  }

  void _delete() {
    final e = widget.existing;
    if (e == null) return;
    store.employees.removeWhere((x) => x.id == e.id);
    store.saveEmployees();
    Navigator.pop(context, true);
  }

  Widget _seg(String label, List<(String, String)> opts, String val,
      void Function(String) on) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7688))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in opts)
              GestureDetector(
                onTap: () => setState(() => on(o.$1)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: val == o.$1 ? kBlue : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: val == o.$1 ? kBlue : const Color(0xFFE3E8EF),
                        width: 2),
                  ),
                  child: Text(o.$2,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: val == o.$1 ? Colors.white : const Color(0xFF5C6B82))),
                ),
              ),
          ],
        ),
      ],
    );
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
              Text(
                  widget.existing == null
                      ? t('Add staff', 'Ku dar shaqaale')
                      : t('Edit staff', 'Wax ka beddel shaqaale'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: kNavy)),
              const SizedBox(height: 14),
              TextField(
                  controller: _n,
                  decoration:
                      InputDecoration(labelText: t('Full name', 'Magaca oo dhan'))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _pos,
                        decoration: InputDecoration(
                            labelText: t('Position', 'Jagada')))),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: store.departments.contains(_dept)
                        ? _dept
                        : (store.departments.isNotEmpty
                            ? store.departments.first
                            : null),
                    isExpanded: true,
                    decoration:
                        InputDecoration(labelText: t('Department', 'Waaxda')),
                    items: [
                      for (final d in store.departments)
                        DropdownMenuItem(value: d, child: Text(d)),
                    ],
                    onChanged: (v) => setState(() => _dept = v ?? _dept),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                            labelText: t('Phone', 'Telefoon')))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            InputDecoration(labelText: t('Email', 'Iimayl')))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _sal,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                            labelText: t('Salary', 'Mushahar')))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: _hired,
                        decoration: InputDecoration(
                            labelText: t('Hired (yyyy-mm-dd)', 'La qoray')))),
              ]),
              const SizedBox(height: 14),
              _seg(t('Currency', 'Lacagta'), const [
                ('USD', 'USD'),
                ('SOS', 'SOS'),
                ('SLSH', 'SLSH'),
              ], _currency, (v) => _currency = v),
              const SizedBox(height: 14),
              _seg(t('Status', 'Xaaladda'), [
                ('active', t('Active', 'Firfircoon')),
                ('inactive', t('Inactive', 'Joogsan')),
              ], _status, (v) => _status = v),
              const SizedBox(height: 12),
              TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: t('Note', 'Qoraal'))),
              const SizedBox(height: 16),
              Text(t('Staff login (optional)', 'Gelitaanka shaqaalaha (ikhtiyaari)'),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7688))),
              const SizedBox(height: 2),
              Text(
                  t('Give the staff member a username & password to sign in and edit their own profile.',
                      'Sii shaqaalaha magac & furaha si uu u galo oo u beddelo profile-kiisa.'),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF98A2B3))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _un,
                        decoration: InputDecoration(
                            labelText: t('Username', 'Magaca isticmaale')))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: _pw,
                        decoration: InputDecoration(
                            labelText: t('Password', 'Furaha')))),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                if (widget.existing != null)
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
                if (widget.existing != null) const SizedBox(width: 10),
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
}
