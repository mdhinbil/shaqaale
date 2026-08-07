import 'package:flutter/material.dart';
import '../main.dart';
import '../photo_util.dart';
import 'cloud_section.dart';
import 'leaves_screen.dart';
import 'reports_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});
  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  late final TextEditingController _company, _sos, _slsh;

  @override
  void initState() {
    super.initState();
    _company = TextEditingController(text: store.company);
    _sos = TextEditingController(text: store.fxSos.toString());
    _slsh = TextEditingController(text: store.fxSlsh.toString());
  }

  @override
  void dispose() {
    _company.dispose();
    _sos.dispose();
    _slsh.dispose();
    super.dispose();
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _changeAdminPhoto() async {
    final r = await choosePhoto(context, hasPhoto: store.adminPhoto.isNotEmpty);
    if (r == null) return;
    store.adminPhoto = r;
    store.saveSettings();
    if (mounted) setState(() {});
  }

  Future<void> _changeLogo() async {
    final r = await choosePhoto(context, hasPhoto: store.companyLogo.isNotEmpty);
    if (r == null) return;
    store.companyLogo = r;
    store.saveSettings();
    if (mounted) setState(() {});
  }

  void _saveSettings() {
    store.company = _company.text.trim().isEmpty ? 'My Company' : _company.text.trim();
    store.fxSos = double.tryParse(_sos.text.trim()) ?? store.fxSos;
    store.fxSlsh = double.tryParse(_slsh.text.trim()) ?? store.fxSlsh;
    store.saveSettings();
    _say(t('Saved', 'La kaydiyay'));
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(text: store.user?.name ?? '');
    final un = TextEditingController(text: store.user?.username ?? '');
    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('Edit profile', 'Wax ka beddel profile')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: InputDecoration(labelText: t('Name', 'Magaca'))),
            const SizedBox(height: 10),
            TextField(
                controller: un,
                decoration: InputDecoration(
                    labelText: t('Username', 'Magaca isticmaale'))),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context, 'password'),
                icon: const Icon(Icons.password_outlined, size: 18),
                label: Text(t('Change password', 'Beddel furaha')),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text(t('Cancel', 'Jooji'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: Text(t('Save', 'Kaydi'))),
        ],
      ),
    );
    if (action == 'password') {
      if (mounted) await _changePassword();
      return;
    }
    if (action != 'save') return;
    final err = store.updateProfile(name.text, un.text);
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

  Future<void> _manageDepartments() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeptSheet(),
    );
    if (mounted) setState(() {});
  }

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
    return Scaffold(
      appBar: AppBar(title: Text(t('More', 'Dheeraad'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 30),
        children: [
          Card(
            child: ListTile(
              leading: GestureDetector(
                onTap: _changeAdminPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    photoAvatar(store.adminPhoto, store.user?.name ?? 'Admin'),
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
              title: Text(store.user?.name ?? 'Admin',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                  '@${store.user?.username ?? 'admin'} · ${store.user?.role ?? 'admin'}'),
              trailing: const Icon(Icons.edit_outlined, color: kBlue),
              onTap: _editProfile,
            ),
          ),
          _label(t('Cloud sync', 'Isku xirka cloud')),
          const CloudSection(),
          _label(t('Language', 'Luqadda')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                _langBtn('English', 'en'),
                const SizedBox(width: 8),
                _langBtn('Somali', 'so'),
              ]),
            ),
          ),
          _label(t('Reports', 'Warbixinno')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: kBlue),
              title: Text(t('Reports & export', 'Warbixinno & soo saarid')),
              subtitle: Text(t('Payroll, attendance, staff list',
                  'Mushahar, xaadiris, liiska shaqaalaha')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsScreen())),
            ),
          ),
          _label(t('Leave', 'Fasax')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.beach_access_outlined, color: kBlue),
              title: Text(t('Leave requests', 'Codsiyada fasaxa')),
              subtitle: Text(
                  '${store.pendingLeaves} ${t('pending', 'sugaya')}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeavesScreen())),
            ),
          ),
          _label(t('Departments', 'Waaxaha')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.apartment_outlined, color: kBlue),
              title: Text(t('Manage departments', 'Maamul waaxaha')),
              subtitle: Text('${store.departments.length}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _manageDepartments,
            ),
          ),
          _label(t('Company & currency', 'Shirkadda & lacagta')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: _changeLogo,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(12),
                              image: store.companyLogo.isNotEmpty
                                  ? DecorationImage(
                                      image: MemoryImage(
                                          base64DecodeSafe(store.companyLogo)),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: store.companyLogo.isEmpty
                                ? const Icon(Icons.business, color: kBlue)
                                : null,
                          ),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(t('Company logo', 'Astaanta shirkadda'),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5C6B82))),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _company,
                      decoration: InputDecoration(
                          labelText: t('Company name', 'Magaca shirkadda'))),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _sos,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                labelText: 'USD → SOS'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                            controller: _slsh,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                labelText: 'USD → SLSH'))),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: _saveSettings,
                        child: Text(t('Save', 'Kaydi'))),
                  ),
                ],
              ),
            ),
          ),
          _label(t('Account', 'Akoonka')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.password_outlined, color: kBlue),
              title: Text(t('Change password', 'Beddel furaha')),
              subtitle: Text(store.user?.username ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFD63B3B)),
              title: Text(t('Sign out', 'Ka bax'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFFD63B3B))),
              onTap: () => store.signOut(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Shaqaale 1.0 · MareegTech Solutions',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF98A2B3))),
          ),
        ],
      ),
    );
  }
}

class _DeptSheet extends StatefulWidget {
  const _DeptSheet();
  @override
  State<_DeptSheet> createState() => _DeptSheetState();
}

class _DeptSheetState extends State<_DeptSheet> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _add() {
    final n = _c.text.trim();
    if (n.isEmpty || store.departments.contains(n)) return;
    store.departments.add(n);
    store.saveDepartments();
    _c.clear();
    setState(() {});
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
              Text(t('Departments', 'Waaxaha'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: kNavy)),
              const SizedBox(height: 12),
              for (final d in store.departments)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(d),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFC62F16)),
                      onPressed: () {
                        store.departments.remove(d);
                        store.saveDepartments();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _c,
                        decoration: InputDecoration(
                            labelText: t('New department', 'Waax cusub')))),
                const SizedBox(width: 10),
                FilledButton(onPressed: _add, child: Text(t('Add', 'Ku dar'))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
