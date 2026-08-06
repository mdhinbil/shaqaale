import 'package:flutter/material.dart';
import '../main.dart';
import '../data/cloud.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  final _company = TextEditingController();
  bool _err = false, _hide = true, _busy = false, _isNew = false;
  String _errMsg = '';

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final u = _u.text.trim();
    final p = _p.text;
    // 1) Local admin / staff account (skip when creating a new cloud company).
    if (!_isNew && store.signIn(u, p)) return;
    // 2) Cloud company account (email) — sign in or create, then open the app.
    if (u.contains('@')) {
      setState(() {
        _busy = true;
        _err = false;
        _errMsg = '';
      });
      try {
        final remote = await cloud.signIn(u, p, isNew: _isNew);
        // The master account manages approvals; no company data / gating.
        if (cloud.master) {
          store.openCloudAdmin(u);
          return; // RootGate shows the Companies console
        }
        if (_isNew) {
          final name = _company.text.trim();
          await store.startNewCompany(name); // clean slate for the new company
          await cloud.registerWorkspace(name.isEmpty ? u : name); // pending approval
        } else if (remote.has) {
          await store.adoptCloudData(); // existing company: pull its cloud data
        } else {
          await store.uploadLocalData(); // existing account, no cloud data yet
        }
        await cloud.refreshWorkspace();
        store.openCloudAdmin(u);
        return; // RootGate → app, or the pending screen if not yet approved
      } catch (e) {
        // Auth succeeded but reading data failed (e.g. Firestore rules not set
        // up yet): let the admin in anyway — sync retries from Settings.
        if (cloud.on) {
          store.openCloudAdmin(u);
          return;
        }
        if (mounted) {
          setState(() {
            _busy = false;
            _err = true;
            _errMsg = Cloud.errText(e);
          });
        }
        return;
      }
    }
    setState(() {
      _err = true;
      _errMsg = '';
    });
  }

  Widget _lang(String label, String code) {
    final on = store.lang == code;
    return GestureDetector(
      onTap: () => setState(() => store.setLang(code)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: on ? kBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: on ? Colors.white : const Color(0xFF6B7688))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kNavy, Color(0xFF1A4DC4)]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                            color: kBlue, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.people_alt,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text('Shaqaale',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kNavy)),
                      Text(t('HR & Payroll', 'Shaqaale & Mushahar'),
                          style: const TextStyle(
                              fontSize: 12.5, color: Color(0xFF6B7688))),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEEF1F5),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          _lang('English', 'en'),
                          _lang('Soomaali', 'so'),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      if (_err)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFEAEA),
                              border: Border.all(color: const Color(0xFFFFB3B3)),
                              borderRadius: BorderRadius.circular(9)),
                          child: Text(
                              _errMsg.isNotEmpty
                                  ? _errMsg
                                  : t('Wrong username or password',
                                      'Magaca ama furaha waa khalad'),
                              style: const TextStyle(
                                  color: Color(0xFFBF2600), fontSize: 12.5)),
                        ),
                      if (_isNew) ...[
                        TextField(
                          controller: _company,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                              labelText: t('Company name', 'Magaca shirkadda'),
                              prefixIcon: const Icon(Icons.business_outlined)),
                        ),
                        const SizedBox(height: 11),
                      ],
                      TextField(
                        controller: _u,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                            labelText: _isNew
                                ? t('Company email', 'Iimaylka shirkadda')
                                : t('Username', 'Magaca isticmaale'),
                            prefixIcon: const Icon(Icons.person_outline)),
                      ),
                      const SizedBox(height: 11),
                      TextField(
                        controller: _p,
                        obscureText: _hide,
                        onSubmitted: (_) => _go(),
                        decoration: InputDecoration(
                          labelText: t('Password', 'Furaha'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              icon: Icon(_hide
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() => _hide = !_hide)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                            t('Create a company account', 'Samee akoon shirkad'),
                            style: const TextStyle(fontSize: 13)),
                        value: _isNew,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() {
                                  _isNew = v;
                                  _err = false;
                                  _errMsg = '';
                                }),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                            onPressed: _busy ? null : _go,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(_isNew
                                    ? t('Create account', 'Samee akoon')
                                    : t('Sign in', 'Gal'))),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
