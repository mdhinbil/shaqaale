import 'package:flutter/material.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _err = false, _hide = true;

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  void _go() {
    if (!store.signIn(_u.text, _p.text)) setState(() => _err = true);
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
                              t('Wrong username or password',
                                  'Magaca ama furaha waa khalad'),
                              style: const TextStyle(
                                  color: Color(0xFFBF2600), fontSize: 12.5)),
                        ),
                      TextField(
                        controller: _u,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                            labelText: t('Username', 'Magaca isticmaale'),
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                            onPressed: _go, child: Text(t('Sign in', 'Gal'))),
                      ),
                      const SizedBox(height: 12),
                      Text(t('Default:  admin / admin123',
                          'Default:  admin / admin123'),
                          style: const TextStyle(
                              fontSize: 11.5, color: Color(0xFF98A2B3))),
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
