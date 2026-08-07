import 'package:flutter/material.dart';
import '../main.dart';
import '../photo_util.dart';
import 'messages_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: store.companyLogo.isNotEmpty ? 8 : 16,
        leading: store.companyLogo.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(left: 14),
                child: CircleAvatar(
                    radius: 15,
                    backgroundImage:
                        MemoryImage(base64DecodeSafe(store.companyLogo))),
              )
            : null,
        title: Text(store.company,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final n = store.unreadMessages;
              return IconButton(
                tooltip: t('Messages', 'Fariimaha'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const MessagesScreen())),
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text('$n'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
        children: [
          Text(t('Overview', 'Guudmar').toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: .6,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B7688))),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _Stat(t('Active staff', 'Shaqaale firfircoon'),
                  '${store.activeCount}', kBlue, dark: true),
              _Stat(t('Present today', 'Maanta jooga'), '${store.presentToday}',
                  kGreen, dark: true),
              _Stat(t('Pending leaves', 'Fasax sugaya'),
                  '${store.pendingLeaves}', const Color(0xFFE0842B), dark: true),
              _Stat(t('Payroll (month)', 'Mushahar (bishaan)'),
                  store.money(store.payrollThisMonthUsd(), 'USD'), kCyan,
                  dark: true),
            ],
          ),
          const SizedBox(height: 16),
          Text(t('Recent staff', 'Shaqaalihii dhawaa').toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: .6,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B7688))),
          const SizedBox(height: 8),
          if (store.employees.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Center(
                    child: Text(
                        t('No staff yet — add your first from the Staff tab.',
                            'Weli shaqaale ma jiro — kaga dar tabka Shaqaale.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6B7688)))),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final e in store.employees.take(6))
                    _MiniRow(
                        e.name,
                        [e.position, e.dept]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        e.active),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool dark;
  const _Stat(this.label, this.value, this.color, {this.dark = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? color : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? color : const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : color)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white70 : const Color(0xFF5C6B82))),
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final String name, sub;
  final bool active;
  const _MiniRow(this.name, this.sub, this.active);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F2F6))),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF2FF),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w800, color: kBlue)),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        subtitle: sub.isEmpty ? null : Text(sub),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE3F6EC) : const Color(0xFFEEF1F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
              active ? t('Active', 'Firfircoon') : t('Inactive', 'Joogsan'),
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: active
                      ? const Color(0xFF1A7A4F)
                      : const Color(0xFF6B7688))),
        ),
      ),
    );
  }
}
