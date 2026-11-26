import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../data/cloud.dart';
import '../models/models.dart';
import '../photo_util.dart';

/// Entrance check-in kiosk. A tablet/phone left at the company door: staff tap
/// their name, type their PIN, then Check in on arrival / Check out on leaving.
/// No HR screens are reachable from here; the lock button + exit PIN leaves.
class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});
  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  Timer? _clock, _sync;
  String _q = '';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
    // Pick up new staff / PIN changes made on the HR device.
    _sync = Timer.periodic(const Duration(minutes: 2), (_) => _pull());
    _pull();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _sync?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _pull() async {
    if (!cloud.on) return;
    try {
      final n = await cloud.pull().timeout(const Duration(seconds: 8));
      if (n > 0) store.reload();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  String _clockText() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _exit() async {
    final pin = await _askPin(t('Exit kiosk', 'Ka bax qalabka albaabka'),
        t('Enter the exit PIN', 'Geli PIN-ka ka bixitaanka'));
    if (pin == null) return;
    if (!store.stopKiosk(pin)) {
      _toast(t('Wrong PIN', 'PIN khalad ah'), error: true);
    }
  }

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: error ? const Color(0xFFD63B3B) : null,
        content: Text(m)));
  }

  Future<String?> _askPin(String title, String sub) => showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (_) => _PinDialog(title: title, subtitle: sub),
      );

  Future<void> _tapStaff(Employee e) async {
    if (e.pin.isEmpty) {
      _toast(
          t('No check-in PIN set for ${e.name}. Ask HR to add one.',
              '${e.name} PIN looma samayn. HR ka codso.'),
          error: true);
      return;
    }
    final pin = await _askPin(e.name, t('Enter your PIN', 'Geli PIN-kaaga'));
    if (pin == null) return;
    if (pin != e.pin) {
      _toast(t('Wrong PIN', 'PIN khalad ah'), error: true);
      return;
    }
    // Get the latest attendance first so we don't overwrite HR's edits.
    await _pull();
    if (!mounted) return;
    final a = store.attOn(e.id, store.today());
    if (a != null && a.checkedOut) {
      _result(e, t('Already checked out today', 'Maanta horey ayaad u baxday'),
          '${a.checkIn} → ${a.checkOut} · ${fmtMinutes(a.workedMinutes)}',
          kBlue, Icons.info_outline_rounded);
      return;
    }
    if (a == null || !a.checkedIn) {
      store.checkIn(e.id);
      final n = store.attOn(e.id, store.today())!;
      final isLate = n.status == 'late';
      _result(
          e,
          '${t('Welcome', 'Ku soo dhawoow')}, ${e.name.split(' ').first}',
          '${t('Checked in at', 'Waxaad gashay')} ${n.checkIn}'
              '${isLate ? ' · ${t('Late', 'Daahay')}' : ''}',
          isLate ? const Color(0xFFE0842B) : kGreen,
          Icons.login_rounded);
    } else {
      store.checkOut(e.id);
      final n = store.attOn(e.id, store.today())!;
      _result(
          e,
          '${t('Goodbye', 'Nabad gelyo')}, ${e.name.split(' ').first}',
          '${t('Checked out at', 'Waxaad baxday')} ${n.checkOut} · '
              '${fmtMinutes(n.workedMinutes)}',
          const Color(0xFFE0842B),
          Icons.logout_rounded);
    }
    _search.clear();
    setState(() => _q = '');
  }

  void _result(Employee e, String title, String sub, Color c, IconData ic) {
    var open = true;
    final nav = Navigator.of(context);
    // Close by itself so the next person can use the kiosk.
    Timer(const Duration(seconds: 3), () {
      if (open) nav.pop();
    });
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.bottomRight, children: [
              photoAvatar(e.photo, e.name, radius: 42),
              CircleAvatar(
                  radius: 15,
                  backgroundColor: c,
                  child: Icon(ic, color: Colors.white, size: 17)),
            ]),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800, color: kNavy)),
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: c)),
          ]),
        );
      },
    ).then((_) => open = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final staff = store.employees
        .where((e) => e.active && (q.isEmpty || e.name.toLowerCase().contains(q)))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final inNow = store.checkedInNow;
    final width = MediaQuery.of(context).size.width;
    final cols = width > 900 ? 6 : width > 600 ? 4 : 3;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          Container(
            color: kNavy,
            padding: const EdgeInsets.fromLTRB(18, 14, 6, 16),
            child: Row(children: [
              if (store.companyLogo.isNotEmpty) ...[
                CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        MemoryImage(base64DecodeSafe(store.companyLogo))),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    Text(
                        '${store.today()} · ${t('Inside now', 'Hadda gudaha')}: $inNow',
                        style: const TextStyle(
                            color: Color(0xFFAFC2DE), fontSize: 12.5)),
                  ],
                ),
              ),
              Text(_clockText(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800)),
              IconButton(
                tooltip: t('Exit kiosk', 'Ka bax'),
                onPressed: _exit,
                icon: const Icon(Icons.lock_outline, color: Color(0xFF6F84A6)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Column(children: [
              Text(t('Tap your name to check in or out',
                      'Riix magacaaga si aad u gasho ama u baxdo'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: kNavy)),
              const SizedBox(height: 10),
              TextField(
                controller: _search,
                onChanged: (v) => setState(() => _q = v.trim()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: t('Search name', 'Raadi magac'),
                  isDense: true,
                ),
              ),
            ]),
          ),
          Expanded(
            child: staff.isEmpty
                ? Center(
                    child: Text(t('No staff found', 'Shaqaale lama helin'),
                        style: const TextStyle(color: Color(0xFF6B7688))))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: .82,
                    ),
                    itemCount: staff.length,
                    itemBuilder: (_, i) {
                      final e = staff[i];
                      final a = store.attOn(e.id, store.today());
                      final inside = a != null && a.checkedIn && !a.checkedOut;
                      final done = a != null && a.checkedOut;
                      final inTime = a?.checkIn ?? '';
                      final dot = inside
                          ? kGreen
                          : done
                              ? const Color(0xFF8B97A8)
                              : null;
                      return Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _tapStaff(e),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      photoAvatar(e.photo, e.name, radius: 30),
                                      if (dot != null)
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                              color: dot,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 2.5)),
                                        ),
                                    ]),
                                const SizedBox(height: 8),
                                Text(e.name,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: kNavy)),
                                const SizedBox(height: 2),
                                Text(
                                    inside
                                        ? '${t('In', 'Gudaha')} $inTime'
                                        : done
                                            ? t('Left', 'Baxay')
                                            : ' ',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: dot ?? const Color(0xFF8B97A8))),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

/// Big numeric PIN pad in a dialog. Returns the typed PIN, or null on cancel.
class _PinDialog extends StatefulWidget {
  final String title, subtitle;
  const _PinDialog({required this.title, required this.subtitle});
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String _pin = '';

  void _key(String k) {
    setState(() {
      if (k == '<') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 6) {
        _pin += k;
      }
    });
  }

  Widget _btn(String k) {
    final isOk = k == 'ok', isDel = k == '<';
    return Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: 70,
        height: 58,
        child: isOk
            ? FilledButton(
                style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero, backgroundColor: kGreen),
                onPressed:
                    _pin.length >= 4 ? () => Navigator.pop(context, _pin) : null,
                child: const Icon(Icons.check_rounded, size: 28),
              )
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => _key(k),
                child: isDel
                    ? const Icon(Icons.backspace_outlined)
                    : Text(k,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kNavy)),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, textAlign: TextAlign.center),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.subtitle,
            style: const TextStyle(color: Color(0xFF6B7688))),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 6; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? kBlue : const Color(0xFFE3E8EF),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['<', '0', 'ok'],
        ])
          Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (final k in row) _btn(k)]),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Cancel', 'Jooji'))),
      ],
    );
  }
}
