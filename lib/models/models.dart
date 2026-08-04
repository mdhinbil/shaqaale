// Shaqaale data shapes. Kept loosely typed and JSON-round-trippable so they
// store cleanly in shared_preferences and later sync to the cloud unchanged.

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse((v ?? '').toString()) ?? 0;
}

class Employee {
  String id, name, phone, email, dept, position, currency, status, hired, gender, note;
  double salary; // base monthly salary, in `currency`

  Employee({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.dept = '',
    this.position = '',
    this.currency = 'USD',
    this.status = 'active', // active | inactive
    this.hired = '',
    this.gender = '',
    this.note = '',
    this.salary = 0,
  });

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        dept: (j['dept'] ?? '').toString(),
        position: (j['position'] ?? '').toString(),
        currency: (j['currency'] ?? 'USD').toString(),
        status: (j['status'] ?? 'active').toString(),
        hired: (j['hired'] ?? '').toString(),
        gender: (j['gender'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
        salary: _num(j['salary']),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'phone': phone, 'email': email, 'dept': dept,
        'position': position, 'currency': currency, 'status': status,
        'hired': hired, 'gender': gender, 'note': note, 'salary': salary,
      };

  bool get active => status == 'active';
}

/// One attendance mark for an employee on a day (yyyy-mm-dd).
class Attendance {
  String id, empId, date, status; // present | absent | late | leave
  Attendance({
    required this.id,
    required this.empId,
    required this.date,
    this.status = 'present',
  });

  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        id: (j['id'] ?? '').toString(),
        empId: (j['empId'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        status: (j['status'] ?? 'present').toString(),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'empId': empId, 'date': date, 'status': status};
}

/// A leave request. from/to are yyyy-mm-dd.
class Leave {
  String id, empId, type, from, to, status, note; // status: pending|approved|rejected
  Leave({
    required this.id,
    required this.empId,
    this.type = 'Annual',
    this.from = '',
    this.to = '',
    this.status = 'pending',
    this.note = '',
  });

  factory Leave.fromJson(Map<String, dynamic> j) => Leave(
        id: (j['id'] ?? '').toString(),
        empId: (j['empId'] ?? '').toString(),
        type: (j['type'] ?? 'Annual').toString(),
        from: (j['from'] ?? '').toString(),
        to: (j['to'] ?? '').toString(),
        status: (j['status'] ?? 'pending').toString(),
        note: (j['note'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'empId': empId, 'type': type, 'from': from, 'to': to,
        'status': status, 'note': note,
      };

  int get days {
    final a = DateTime.tryParse(from), b = DateTime.tryParse(to);
    if (a == null || b == null) return 0;
    return b.difference(a).inDays + 1;
  }
}

/// A generated payslip for an employee for a month (yyyy-mm).
class Payslip {
  String id, empId, empName, month, currency;
  double base, allowances, deductions;

  Payslip({
    required this.id,
    required this.empId,
    required this.empName,
    required this.month,
    this.currency = 'USD',
    this.base = 0,
    this.allowances = 0,
    this.deductions = 0,
  });

  factory Payslip.fromJson(Map<String, dynamic> j) => Payslip(
        id: (j['id'] ?? '').toString(),
        empId: (j['empId'] ?? '').toString(),
        empName: (j['empName'] ?? '').toString(),
        month: (j['month'] ?? '').toString(),
        currency: (j['currency'] ?? 'USD').toString(),
        base: _num(j['base']),
        allowances: _num(j['allowances']),
        deductions: _num(j['deductions']),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'empId': empId, 'empName': empName, 'month': month,
        'currency': currency, 'base': base, 'allowances': allowances,
        'deductions': deductions,
      };

  double get net => base + allowances - deductions;
}

class Account {
  String id, name, username, password, role; // role: admin | hr
  Account({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.role = 'hr',
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        username: (j['username'] ?? '').toString(),
        password: (j['password'] ?? '').toString(),
        role: (j['role'] ?? 'hr').toString(),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'username': username, 'password': password, 'role': role};
}
