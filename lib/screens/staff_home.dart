import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';
import '../photo_util.dart';

/// What a signed-in staff member (not an admin) sees: their own profile, which
/// they can edit, their password, and read-only payslips and attendance.
class StaffHome extends StatefulWidget {
  const StaffHome({super.key});
  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _changePhoto() async {
    final e = store.staffEmp;
    if (e == null) return;
    final r = await choosePhoto(context, hasPhoto: e.photo.isNotEmpty);
    if (r == null) return;
    e.photo = r;
    store.saveEmployees();
    if (mounted) setState(() {});
  }

  Future<void> _editProfile() async {
    final e = store.staffEmp;
    if (e == null) return;
    final name = TextEditingController(text: e.name);
    final phone = TextEditingController(text: e.phone);
    final email = TextEditingController(text: e.email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('Edit my profile', 'Wax ka beddel profile-kayga')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: InputDecoration(labelText: t('Name', 'Magaca'))),
            const SizedBox(height: 10),
            TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t('Phone', 'Telefoon'))),
            const SizedBox(height: 10),
            TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t('Email', 'Iimayl'))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('Cancel', 'Jooji'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t('Save', 'Kaydi'))),
        ],
      ),
    );
    if (ok != true) return;
    final err = store.updateMyProfile(name.text, phone.text, email.text);
    _say(err ?? t('Profile updated', 'Profile-ka waa la cusboonaysiiyay'));
    if (err == null && mounted) setState(() {});
  }

  Future<void> _changePassword() async {
    final cur = TextEditingController();
    final nw = TextEditingController();
    final cf = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('Change password', 'Beddel furaha')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: cur,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: t('Current password', 'Furaha hadda'))),
            const SizedBox(height: 10),
            TextField(
                controller: nw,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: t('New password', 'Furaha cusub'))),
            const SizedBox(height: 10),
            TextField(
                controller: cf,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: t('Confirm new password', 'Xaqiiji furaha cusub'))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('Cancel', 'Jooji'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t('Save', 'Kaydi'))),
        ],
      ),
    );
    if (ok != true) return;
    if (nw.text != cf.text) {
      _say(t('New passwords do not match', 'Furayaasha cusub isma laha'));
      return;
    }
    final err = store.changePassword(cur.text, nw.text);
    _say(err ?? t('Password changed', 'Furaha waa la beddelay'));
  }

  void _viewPayslip(Payslip p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${t('Payslip', 'Warqad mushahar')} · ${p.month}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sum(t('Base salary', 'Mushahar aasaasi'),
                store.money(p.base, p.currency)),
            for (final it in p.items)
              _sum('${it.deduct ? '−' : '+'} ${it.label}',
                  store.money(it.amount, p.currency)),
            const Divider(),
            _sum(t('NET PAY', 'LACAGTA GUUD'), store.money(p.net, p.currency),
                big: true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Done', 'Diyaar'))),
        ],
      ),
    );
  }

  Widget _sum(String l, String v, {bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l,
              style: TextStyle(
                  fontWeight: big ? FontWeight.w800 : FontWeight.w600,
                  fontSize: big ? 15 : 13)),
          Text(v,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: big ? 16 : 13.5,
                  color: const Color(0xFF1152CC))),
        ]),
      );

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(left: 6, top: 16, bottom: 7),
        child: Text(s.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                letterSpacing: .7,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7688))),
      );

  Widget _langBtn(String label, String code) {
    final on = store.lang == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => store.setLang(code)),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: on ? kBlue : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? kBlue : const Color(0xFFD8E0EA)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: on ? Colors.white : const Color(0xFF44536B))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = store.staffEmp;
    final m = store.thisMonth();
    final myPayslips = store.payslips.where((p) => p.empId == store.staffEmpId).toList()
      ..sort((a, b) => b.month.compareTo(a.month));
    var present = 0, absent = 0, leave = 0, lateN = 0;
    for (final a in store.attendance
        .where((a) => a.empId == store.staffEmpId && a.date.startsWith(m))) {
      if (a.status == 'present') {
        present++;
      } else if (a.status == 'late') {
        lateN++;
      } else if (a.status == 'leave') {
        leave++;
      } else {
        absent++;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('My profile', 'Profile-kayga'))),
      body: e == null
          ? Center(child: Text(t('No profile', 'Profile ma jiro')))
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 30),
              children: [
                Card(
                  child: ListTile(
                    leading: GestureDetector(
                      onTap: _changePhoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          photoAvatar(e.photo, e.name),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: kBlue, shape: BoxShape.circle),
                            child: const Icon(Icons.photo_camera,
                                color: Colors.white, size: 10),
                          ),
                        ],
                      ),
                    ),
                    title: Text(e.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text([e.position, e.dept]
                        .where((s) => s.isNotEmpty)
                        .join(' · ')),
                    trailing: const Icon(Icons.edit_outlined, color: kBlue),
                    onTap: _editProfile,
                  ),
                ),
                _label(t('Contact', 'Xiriir')),
                Card(
                  child: Column(children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.phone_outlined, size: 20),
                      title: Text(e.phone.isEmpty ? '—' : e.phone),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.email_outlined, size: 20),
                      title: Text(e.email.isEmpty ? '—' : e.email),
                    ),
                  ]),
                ),
                _label(t('This month', 'Bishaan')),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _att(t('Present', 'Jooga'), present, kGreen),
                        _att(t('Late', 'Daahay'), lateN, const Color(0xFFE0842B)),
                        _att(t('Leave', 'Fasax'), leave, kBlue),
                        _att(t('Absent', 'Maqan'), absent,
                            const Color(0xFFD63B3B)),
                      ],
                    ),
                  ),
                ),
                _label(t('My payslips', 'Warqadahayga mushahar')),
                if (myPayslips.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Center(
                          child: Text(t('No payslips yet', 'Weli warqad ma jirto'),
                              style: const TextStyle(color: Color(0xFF6B7688)))),
                    ),
                  )
                else
                  for (final p in myPayslips)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: kBlue),
                        title: Text(p.month,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        trailing: Text(store.money(p.net, p.currency),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1152CC))),
                        onTap: () => _viewPayslip(p),
                      ),
                    ),
                _label(t('Account', 'Akoonka')),
                Card(
                  child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.password_outlined, color: kBlue),
                      title: Text(t('Change password', 'Beddel furaha')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePassword,
                    ),
                  ]),
                ),
                _label(t('Language', 'Luqadda')),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(children: [
                      _langBtn('English', 'en'),
                      const SizedBox(width: 8),
                      _langBtn('Soomaali', 'so'),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFD63B3B)),
                    title: Text(t('Sign out', 'Ka bax'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD63B3B))),
                    onTap: () => store.signOut(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _att(String label, int n, Color c) => Column(
        children: [
          Text('$n',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: c)),
          Text(label,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7688))),
        ],
      );
}
