import 'package:flutter/material.dart';
import '../main.dart';
import '../data/cloud.dart';

/// Shown instead of the HR app while a company is registered but not yet
/// approved by MareegTech.
class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});
  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  bool _busy = false;

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      await cloud.refreshWorkspace();
      if (mounted && !cloud.wsApproved) {
        _say(t('Still pending — check back soon',
            'Weli sugaya — dib u eeg mar dhow'));
      }
    } catch (e) {
      _say(Cloud.errText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _switch() async {
    store.signOut();
    await cloud.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kNavy, Color(0xFF1A4DC4)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E5),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.hourglass_top,
                            color: Color(0xFFE0842B), size: 34),
                      ),
                      const SizedBox(height: 16),
                      Text(t('Waiting for approval', 'Sugaya ansixinta'),
                          style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: kNavy)),
                      const SizedBox(height: 8),
                      Text(
                        cloud.wsName.isNotEmpty
                            ? t(
                                '“${cloud.wsName}” has been submitted. MareegTech '
                                    'will approve it shortly. You can use the app '
                                    'once it is approved.',
                                '“${cloud.wsName}” waa la gudbiyay. MareegTech '
                                    'ayaa dhawaan ansixin doona. Waad isticmaali '
                                    'kartaa marka la ansixiyo.')
                            : t(
                                'Your company has been submitted. MareegTech '
                                    'will approve it shortly.',
                                'Shirkaddaada waa la gudbiyay. MareegTech ayaa '
                                    'dhawaan ansixin doona.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13.5, color: Color(0xFF5C6B82), height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Text(cloud.email,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7688))),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _check,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.refresh),
                          label: Text(t('Check again', 'Dib u hubi')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : _switch,
                        child: Text(t('Sign out', 'Ka bax')),
                      ),
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
