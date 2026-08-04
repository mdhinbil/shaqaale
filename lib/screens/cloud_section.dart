import 'package:flutter/material.dart';
import '../main.dart';
import '../data/cloud.dart';

/// Cloud sync card for the More screen. Same Firebase backend model as the other
/// MareegTech apps: sign in, choose which side's data to keep, then it auto-syncs.
class CloudSection extends StatefulWidget {
  const CloudSection({super.key});
  @override
  State<CloudSection> createState() => _CloudSectionState();
}

class _CloudSectionState extends State<CloudSection> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    cloud.addListener(_onCloud);
  }

  @override
  void dispose() {
    cloud.removeListener(_onCloud);
    super.dispose();
  }

  void _onCloud() {
    if (mounted) setState(() {});
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _link() async {
    final creds = await _askCredentials();
    if (creds == null) return;
    setState(() => _busy = true);
    try {
      final remote = await cloud.signIn(creds.$1, creds.$2, isNew: creds.$3);
      final local = await cloud.localInfo();
      if (remote.has && local.employees > 0) {
        if (!mounted) return;
        final keep = await _askDirection(local, remote);
        if (keep == 'cloud') {
          await store.adoptCloudData();
          _say(t('Using cloud data', 'La isticmaalayo xogta cloud-ka'));
        } else if (keep == 'local') {
          await store.uploadLocalData();
          _say(t('This device uploaded', 'Qalabkan waa la geliyay'));
        }
      } else if (remote.has) {
        await store.adoptCloudData();
        _say(t('Cloud data restored', 'Xogta cloud-ka waa la soo celiyay'));
      } else {
        await store.uploadLocalData();
        _say(t('Data uploaded to cloud', 'Xogta waa la geliyay cloud-ka'));
      }
    } catch (e) {
      _say(Cloud.errText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    try {
      await cloud.pull(force: false);
      await cloud.pushAll();
      store.reload();
      _say(t('Synced', 'La isku waafajiyay'));
    } catch (e) {
      _say(Cloud.errText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    await cloud.signOut();
    if (mounted) setState(() {});
  }

  Future<(String, String, bool)?> _askCredentials() {
    final e = TextEditingController();
    final p = TextEditingController();
    var isNew = false;
    return showDialog<(String, String, bool)>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(isNew
              ? t('Create cloud account', 'Samee akoon cloud')
              : t('Link to cloud', 'Ku xir cloud-ka')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: e,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t('Email', 'Iimayl')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: p,
                obscureText: true,
                decoration: InputDecoration(labelText: t('Password', 'Furaha')),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(t('Create a new account', 'Samee akoon cusub')),
                value: isNew,
                onChanged: (v) => setD(() => isNew = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t('Cancel', 'Jooji'))),
            FilledButton(
              onPressed: () {
                if (e.text.trim().isEmpty || p.text.isEmpty) return;
                Navigator.pop(ctx, (e.text.trim(), p.text, isNew));
              },
              child: Text(isNew ? t('Create', 'Samee') : t('Sign in', 'Gal')),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askDirection(SyncInfo local, SyncInfo remote) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('Which data to keep?', 'Xogtee la hayaa?')),
        content: Text(t(
            'Cloud has ${remote.employees} staff, ${remote.payslips} payslips.\n'
                'This device has ${local.employees} staff, ${local.payslips} payslips.\n'
                'Pick one — the other is replaced.',
            'Cloud-ku wuxuu leeyahay ${remote.employees} shaqaale, ${remote.payslips} warqad.\n'
                'Qalabkanna wuxuu leeyahay ${local.employees} shaqaale, ${local.payslips} warqad.\n'
                'Mid dooro — kan kale waa la beddelayaa.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('Cancel', 'Jooji'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'local'),
              child: Text(t('Keep this device', 'Hay qalabkan'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, 'cloud'),
              child: Text(t('Use cloud', 'Isticmaal cloud'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!cloud.on) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_outlined, color: kBlue),
          title: Text(t('Link to cloud', 'Ku xir cloud-ka')),
          subtitle: Text(t('Back up and sync across devices',
              'Kaydi oo isku xir aaladaha')),
          onTap: _busy ? null : _link,
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: kGreen,
                child: Icon(Icons.cloud_done, color: Colors.white)),
            title: Text(cloud.email,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(cloud.lastError.isNotEmpty
                ? cloud.lastError
                : (cloud.status == 'ok'
                    ? t('Up to date', 'Waa la cusbooneysiiyay')
                    : t('Connected', 'Ku xiran'))),
          ),
          const Divider(height: 1),
          ListTile(
            leading: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync, color: kBlue),
            title: Text(t('Sync now', 'Hadda isku waafaji')),
            onTap: _busy ? null : _syncNow,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFD63B3B)),
            title: Text(t('Sign out of cloud', 'Ka bax cloud-ka')),
            onTap: _busy ? null : _unlink,
          ),
        ],
      ),
    );
  }
}
