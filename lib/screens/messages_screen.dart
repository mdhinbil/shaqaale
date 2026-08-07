import 'package:flutter/material.dart';
import '../main.dart';
import '../models/models.dart';

/// The company message board: admin announcements and staff messages, shown as
/// a simple chat. Everyone in the company shares one thread.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _c = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    store.markMessagesSeen();
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
  }

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  void _send() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    store.sendMessage(t);
    _c.clear();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
  }

  String _time(DateTime d) {
    final now = DateTime.now();
    final sameDay =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final hm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return sameDay ? hm : '${d.day}/${d.month} $hm';
  }

  @override
  Widget build(BuildContext context) {
    final msgs = [...store.messages]..sort((a, b) => a.ts.compareTo(b.ts));
    return Scaffold(
      appBar: AppBar(title: Text(t('Messages', 'Fariimaha'))),
      body: Column(
        children: [
          Expanded(
            child: msgs.isEmpty
                ? Center(
                    child: Text(
                        t('No messages yet', 'Weli fariin ma jirto'),
                        style: const TextStyle(color: Color(0xFF6B7688))))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) => _bubble(msgs[i]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE3E8EF))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: store.isStaff
                            ? t('Message…', 'Fariin…')
                            : t('Write an announcement…', 'Qor ogeysiis…'),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(backgroundColor: kBlue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(Message m) {
    final mine = store.isMine(m);
    final admin = m.isAdmin;
    final bg = mine
        ? kBlue
        : (admin ? const Color(0xFFEAF2FF) : const Color(0xFFEFF2F6));
    final fg = mine ? Colors.white : kNavy;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 3),
            bottomRight: Radius.circular(mine ? 3 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(
                  admin
                      ? '${m.senderName} · ${t('Admin', 'Maamul')}'
                      : m.senderName,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: admin ? kBlue : const Color(0xFF5C6B82))),
            Text(m.text,
                style: TextStyle(fontSize: 14, height: 1.3, color: fg)),
            const SizedBox(height: 2),
            Text(_time(m.when),
                style: TextStyle(
                    fontSize: 10,
                    color: mine ? Colors.white70 : const Color(0xFF8B97A8))),
          ],
        ),
      ),
    );
  }
}
