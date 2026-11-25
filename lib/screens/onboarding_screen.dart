import 'package:flutter/material.dart';
import '../main.dart';

/// First-launch intro: a few swipeable pages explaining what Shaqaale does,
/// with a language switch up top. Shown once per device, before sign-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  final IconData icon;
  final Color color;
  final String title, body;
  const _Page(this.icon, this.color, this.title, this.body);
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _i = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<_Page> get _pages => [
        _Page(
          Icons.groups_rounded,
          kBlue,
          t('Welcome to Shaqaale', 'Ku soo dhawoow Shaqaale'),
          t('All your staff, departments and records in one simple app.',
              'Dhammaan shaqaalahaaga, waaxaha iyo diiwaannada hal app oo fudud.'),
        ),
        _Page(
          Icons.fingerprint_rounded,
          kGreen,
          t('Check in & check out', 'Gal & ka bax shaqada'),
          t('Staff tap Check in when they arrive and Check out when they leave. Late arrivals and hours worked are recorded automatically.',
              'Shaqaaluhu waxay riixaan "Gal" marka ay yimaadaan iyo "Ka bax" marka ay tagaan. Daahitaanka iyo saacadaha la shaqeeyay si toos ah ayaa loo diiwaangeliyaa.'),
        ),
        _Page(
          Icons.account_balance_wallet_rounded,
          const Color(0xFFE0842B),
          t('Payroll & leave', 'Mushahar & fasax'),
          t('Generate payslips in USD, SOS or SLSH and manage leave requests in a few taps.',
              'Samee warqadaha mushaharka USD, SOS ama SLSH, oo maamul codsiyada fasaxa dhawr riixis.'),
        ),
        _Page(
          Icons.cloud_done_rounded,
          kCyan,
          t('Works offline, syncs online', 'Internet la\'aan wuu shaqeeyaa'),
          t('Everything is saved on your device and syncs to the cloud when you are connected.',
              'Wax walba waxay ku kaydsan yihiin qalabkaaga, waxayna cloud-ka la isku xirmaan marka aad internet hesho.'),
        ),
      ];

  void _next() {
    if (_i >= _pages.length - 1) {
      store.finishOnboarding(); // RootGate moves on to the login screen
      return;
    }
    _ctrl.nextPage(
        duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  Widget _lang(String label, String code) {
    final on = store.lang == code;
    return GestureDetector(
      onTap: () => setState(() => store.setLang(code)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: on ? kBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? kBlue : const Color(0xFFD8E0EA)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: on ? Colors.white : const Color(0xFF44536B))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final last = _i == pages.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
              child: Row(children: [
                _lang('EN', 'en'),
                const SizedBox(width: 6),
                _lang('SO', 'so'),
                const Spacer(),
                if (!last)
                  TextButton(
                    onPressed: store.finishOnboarding,
                    child: Text(t('Skip', 'Ka bood'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7688))),
                  ),
              ]),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) {
                  final p = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: p.color.withValues(alpha: .12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon, size: 76, color: p.color),
                        ),
                        const SizedBox(height: 36),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: kNavy)),
                        const SizedBox(height: 14),
                        Text(p.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15.5,
                                height: 1.45,
                                color: Color(0xFF5C6B82))),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _i ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _i ? kBlue : const Color(0xFFD8E0EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(last
                      ? t('Get started', 'Bilow')
                      : t('Next', 'Xiga')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
