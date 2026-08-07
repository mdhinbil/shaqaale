import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Shaqaale — cloud sync over Firebase REST, mirroring the other MareegTech
/// apps so it works from any origin with no SDK.
///
///   auth  → identitytoolkit.googleapis.com   (email + password)
///   data  → firestore.googleapis.com/v1      (Bearer idToken)
///
/// One document per storage key, under the signed-in user:
///   shaqaale/{uid}/keys/{hr_employees | hr_payslips | …}
/// Newest-timestamp-wins on pull — one HR office edits at a time.

// Public web API key + project id (shared MareegTech Firebase project). Safe to
// ship: access is Firebase Auth + Firestore rules scoped to the signed-in uid.
const _apiKey = 'AIzaSyCEZxp9W7_h2Nu1qs_wiQdrbXARVb5yvg8';
const _projectId = 'isguul-togdheer';
const _root = 'shaqaale';

/// The MareegTech super-admin. Signs in through the normal login and gets the
/// Companies approval console instead of the HR app.
const kMasterEmail = 'admin@mareegtech.com';

const cloudKeys = [
  'hr_employees', 'hr_attendance', 'hr_leaves', 'hr_payslips',
  'hr_departments', 'hr_settings', 'hr_accounts', 'hr_messages',
];

class SyncInfo {
  final bool has;
  final int employees, payslips;
  const SyncInfo({this.has = false, this.employees = 0, this.payslips = 0});
}

/// A company row in the approval registry.
class Workspace {
  final String uid, email, name;
  final bool approved;
  final int createdAt;
  const Workspace({
    required this.uid,
    this.email = '',
    this.name = '',
    this.approved = false,
    this.createdAt = 0,
  });
}

class Cloud extends ChangeNotifier {
  SharedPreferences? _sp;

  String email = '';
  String uid = '';
  String _idToken = '';
  String _refreshToken = '';
  int _tokenAt = 0;
  bool on = false;
  bool busy = false;
  int lastSync = 0;
  String lastError = '';
  String status = 'off'; // off | sync | ok | err

  // Cached approval state, persisted so an offline device still gates correctly.
  bool wsRegistered = false;
  bool wsApproved = false;
  String wsName = '';

  bool get master =>
      on && email.trim().toLowerCase() == kMasterEmail.trim().toLowerCase();

  /// The HR app is blocked while a company is registered but not yet approved.
  bool get appBlocked => on && !master && wsRegistered && !wsApproved;

  final Map<String, bool> _pending = {};
  Timer? _timer;

  void _paint(String s) {
    status = s;
    notifyListeners();
  }

  Future<void> load() async {
    _sp ??= await SharedPreferences.getInstance();
    try {
      final raw = _sp!.getString('hr_cloud');
      if (raw != null && raw.isNotEmpty) {
        final s = Map<String, dynamic>.from(jsonDecode(raw));
        email = (s['email'] ?? '').toString();
        uid = (s['uid'] ?? '').toString();
        _refreshToken = (s['refreshToken'] ?? '').toString();
        lastSync = (s['lastSync'] as num?)?.toInt() ?? 0;
        wsRegistered = s['wsRegistered'] == true;
        wsApproved = s['wsApproved'] == true;
        wsName = (s['wsName'] ?? '').toString();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    _sp ??= await SharedPreferences.getInstance();
    await _sp!.setString(
        'hr_cloud',
        jsonEncode({
          'email': email,
          'uid': uid,
          'refreshToken': _refreshToken,
          'lastSync': lastSync,
          'wsRegistered': wsRegistered,
          'wsApproved': wsApproved,
          'wsName': wsName,
        }));
  }

  // ── auth ──────────────────────────────────────────────────────────────────
  Uri _authUrl(String m) => Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:$m?key=$_apiKey');

  Future<Map<String, dynamic>> _auth(String m, String em, String pw) async {
    final r = await http.post(_authUrl(m),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': em, 'password': pw, 'returnSecureToken': true}));
    final j = Map<String, dynamic>.from(jsonDecode(r.body));
    if (r.statusCode >= 400) {
      throw CloudError((j['error']?['message'] ?? 'AUTH_FAILED').toString());
    }
    return j;
  }

  Future<void> _applySession(Map<String, dynamic> j) async {
    _idToken = (j['idToken'] ?? '').toString();
    _refreshToken = (j['refreshToken'] ?? '').toString();
    uid = (j['localId'] ?? '').toString();
    _tokenAt = DateTime.now().millisecondsSinceEpoch;
    on = true;
    await _save();
  }

  Future<String> _freshToken() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_idToken.isNotEmpty && (now - _tokenAt) < 50 * 60 * 1000) return _idToken;
    if (_refreshToken.isEmpty) throw CloudError('NO_SESSION');
    final r = await http.post(
        Uri.parse('https://securetoken.googleapis.com/v1/token?key=$_apiKey'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
            'grant_type=refresh_token&refresh_token=${Uri.encodeComponent(_refreshToken)}');
    final j = Map<String, dynamic>.from(jsonDecode(r.body));
    if (j['id_token'] == null) throw CloudError('REFRESH_FAILED');
    _idToken = j['id_token'].toString();
    _refreshToken = (j['refresh_token'] ?? _refreshToken).toString();
    _tokenAt = DateTime.now().millisecondsSinceEpoch;
    await _save();
    return _idToken;
  }

  // ── firestore per-key docs ──────────────────────────────────────────────────
  Uri _docUrl(String key) => Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$_root/$uid/keys/$key');

  Future<bool> _putKey(String key, String token) async {
    _sp ??= await SharedPreferences.getInstance();
    final raw = _sp!.getString(key);
    if (raw == null) return false;
    final body = jsonEncode({
      'fields': {
        'v': {'stringValue': raw},
        'ts': {'integerValue': DateTime.now().millisecondsSinceEpoch.toString()},
      }
    });
    final r = await http.patch(_docUrl(key),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body);
    if (r.statusCode >= 400) throw CloudError(_httpErr(r));
    return true;
  }

  Future<Map<String, dynamic>?> _getKey(String key, String token) async {
    final r =
        await http.get(_docUrl(key), headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode == 404) return null;
    if (r.statusCode >= 400) throw CloudError(_httpErr(r));
    final doc = Map<String, dynamic>.from(jsonDecode(r.body));
    final f = doc['fields'];
    if (f == null || f['v'] == null) return null;
    return {
      'v': f['v']['stringValue'],
      'ts': int.tryParse((f['ts']?['integerValue'] ?? '0').toString()) ?? 0,
    };
  }

  String _httpErr(http.Response r) {
    try {
      final j = Map<String, dynamic>.from(jsonDecode(r.body));
      return (j['error']?['message'] ?? 'HTTP ${r.statusCode}').toString();
    } catch (_) {
      return 'HTTP ${r.statusCode}';
    }
  }

  // ── push / pull ─────────────────────────────────────────────────────────────
  void queue(String key) {
    if (!on || !cloudKeys.contains(key)) return;
    _pending[key] = true;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), flush);
  }

  Future<void> flush() async {
    if (!on || busy) return;
    final keys = _pending.keys.toList();
    if (keys.isEmpty) return;
    _pending.clear();
    busy = true;
    _paint('sync');
    try {
      final token = await _freshToken();
      for (final k in keys) {
        await _putKey(k, token);
      }
      lastSync = DateTime.now().millisecondsSinceEpoch;
      lastError = '';
      await _save();
      busy = false;
      _paint('ok');
    } catch (e) {
      for (final k in keys) {
        _pending[k] = true;
      }
      lastError = errText(e);
      busy = false;
      _paint('err');
    }
  }

  Future<int> pull({bool force = false}) async {
    if (!on) return 0;
    _sp ??= await SharedPreferences.getInstance();
    busy = true;
    _paint('sync');
    var applied = 0;
    try {
      final token = await _freshToken();
      for (final k in cloudKeys) {
        final remote = await _getKey(k, token);
        if (remote == null) continue;
        final localTs = _sp!.getInt('hr_ts_$k') ?? 0;
        final rts = (remote['ts'] as int?) ?? 0;
        if (!force && rts <= localTs) continue;
        if (_sp!.getString(k) == remote['v']) continue;
        await _sp!.setString(k, remote['v'].toString());
        await _sp!.setInt('hr_ts_$k', rts);
        applied++;
      }
      lastSync = DateTime.now().millisecondsSinceEpoch;
      lastError = '';
      await _save();
      busy = false;
      _paint('ok');
      return applied;
    } catch (e) {
      lastError = errText(e);
      busy = false;
      _paint('err');
      return 0;
    }
  }

  Future<void> pushAll() async {
    if (!on) return;
    for (final k in cloudKeys) {
      _pending[k] = true;
    }
    await flush();
  }

  /// What is already in the cloud for this account? Never inferred from
  /// timestamps — a fresh install has newer stamps than a PC that uploaded
  /// yesterday, which would push the empty device over real data.
  Future<SyncInfo> remoteInfo() async {
    final token = await _freshToken();
    var has = false;
    var emp = 0, pay = 0;
    for (final k in cloudKeys) {
      final r = await _getKey(k, token);
      if (r == null || r['v'] == null) continue;
      var n = 0;
      try {
        final a = jsonDecode(r['v'].toString());
        n = a is List ? a.length : 0;
      } catch (_) {}
      if (k == 'hr_employees') emp = n;
      if (k == 'hr_payslips') pay = n;
      if (n > 0) has = true;
    }
    return SyncInfo(has: has, employees: emp, payslips: pay);
  }

  Future<SyncInfo> localInfo() async {
    _sp ??= await SharedPreferences.getInstance();
    int n(String k) {
      try {
        final a = jsonDecode(_sp!.getString(k) ?? '[]');
        return a is List ? a.length : 0;
      } catch (_) {
        return 0;
      }
    }

    return SyncInfo(employees: n('hr_employees'), payslips: n('hr_payslips'));
  }

  Future<SyncInfo> signIn(String em, String pw, {bool isNew = false}) async {
    final j = await _auth(isNew ? 'signUp' : 'signInWithPassword', em, pw);
    email = em;
    await _applySession(j);
    _paint('ok');
    return remoteInfo();
  }

  Future<void> signOut() async {
    on = false;
    _idToken = '';
    _refreshToken = '';
    uid = '';
    email = '';
    wsRegistered = false;
    wsApproved = false;
    wsName = '';
    _pending.clear();
    await _save();
    _paint('off');
  }

  // ── company approval registry ──────────────────────────────────────────────
  //  shaqaale_workspaces/{uid}: { email, name, approved, createdAt }.
  //  A company reads/writes only its OWN doc; the master lists all and flips
  //  `approved`. Holds NO HR data — that stays private to each uid.
  Uri _wsUrl([String? u]) => Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/shaqaale_workspaces/${u ?? uid}');

  Future<void> registerWorkspace(String name) async {
    final token = await _freshToken();
    final body = jsonEncode({
      'fields': {
        'email': {'stringValue': email},
        'name': {'stringValue': name},
        'approved': {'booleanValue': false},
        'createdAt': {
          'integerValue': DateTime.now().millisecondsSinceEpoch.toString()
        },
      }
    });
    final r = await http.patch(_wsUrl(),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body);
    if (r.statusCode >= 400) throw CloudError(_httpErr(r));
  }

  Future<Workspace?> workspaceStatus() async {
    final token = await _freshToken();
    final r = await http.get(_wsUrl(), headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode == 404) return null;
    if (r.statusCode >= 400) throw CloudError(_httpErr(r));
    final doc = Map<String, dynamic>.from(jsonDecode(r.body));
    final f = doc['fields'] ?? {};
    return Workspace(
      uid: uid,
      email: (f['email']?['stringValue'] ?? '').toString(),
      name: (f['name']?['stringValue'] ?? '').toString(),
      approved: f['approved']?['booleanValue'] == true,
    );
  }

  /// Refresh cached approval state (company accounts only). Keeps last-known
  /// values on failure so an offline device still gates correctly.
  Future<void> refreshWorkspace() async {
    if (!on || master) return;
    try {
      final ws = await workspaceStatus();
      wsRegistered = ws != null;
      wsApproved = ws?.approved ?? false;
      wsName = ws?.name ?? '';
      await _save();
      notifyListeners();
    } catch (_) {}
  }

  /// Master: list every company.
  Future<List<Workspace>> listWorkspaces() async {
    final token = await _freshToken();
    final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/shaqaale_workspaces?pageSize=300');
    final r = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode >= 400) throw CloudError(_httpErr(r));
    final j = Map<String, dynamic>.from(jsonDecode(r.body));
    final docs = (j['documents'] as List?) ?? [];
    return docs.map((d) {
      final doc = Map<String, dynamic>.from(d);
      final f = doc['fields'] ?? {};
      final nm = (doc['name'] ?? '').toString();
      return Workspace(
        uid: nm.substring(nm.lastIndexOf('/') + 1),
        email: (f['email']?['stringValue'] ?? '').toString(),
        name: (f['name']?['stringValue'] ?? '').toString(),
        approved: f['approved']?['booleanValue'] == true,
        createdAt:
            int.tryParse((f['createdAt']?['integerValue'] ?? '0').toString()) ??
                0,
      );
    }).toList();
  }

  /// Master: approve (or revoke) a company — patches only `approved`.
  Future<void> approveWorkspace(String u, bool approved) async {
    final token = await _freshToken();
    final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/shaqaale_workspaces/$u?updateMask.fieldPaths=approved');
    final r = await http.patch(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'fields': {
            'approved': {'booleanValue': approved}
          }
        }));
    if (r.statusCode >= 400) throw CloudError(_httpErr(r));
  }

  Future<int> boot() async {
    await load();
    if (_refreshToken.isEmpty) {
      _paint('off');
      return 0;
    }
    on = true;
    _paint('sync');
    try {
      await _freshToken();
      final n = await pull(force: false);
      await refreshWorkspace();
      return n;
    } catch (e) {
      lastError = errText(e);
      _paint('err');
      return 0;
    }
  }

  static String errText(Object e) {
    final code = e is CloudError ? e.code : e.toString();
    const m = {
      'EMAIL_NOT_FOUND': 'No account with that email',
      'INVALID_PASSWORD': 'Wrong password',
      'INVALID_LOGIN_CREDENTIALS': 'Wrong email or password',
      'EMAIL_EXISTS': 'That email already has an account',
      'WEAK_PASSWORD': 'Password must be at least 6 characters',
      'INVALID_EMAIL': "That email address isn't valid",
      'OPERATION_NOT_ALLOWED': 'Email sign-in is not enabled',
      'NO_SESSION': 'Sign in first',
      'TOO_MANY_ATTEMPTS_TRY_LATER': 'Too many attempts — try later',
    };
    for (final k in m.keys) {
      if (code.contains(k)) return m[k]!;
    }
    if (code.contains('SocketException') ||
        code.contains('Failed host lookup') ||
        code.contains('ClientException')) {
      return 'No internet connection';
    }
    return code;
  }
}

class CloudError implements Exception {
  final String code;
  CloudError(this.code);
  @override
  String toString() => code;
}

/// The one cloud client, shared by the store (sync) and the UI (status).
final cloud = Cloud();
