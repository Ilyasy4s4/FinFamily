import 'package:flutter/foundation.dart';

import '../models/plan.dart';

/// Data Plan DUMMY (di memori), satu daftar per akun. Nanti diganti API.
class PlanRepository extends ChangeNotifier {
  PlanRepository._() {
    reset();
  }

  static final PlanRepository instance = PlanRepository._();

  final Map<String, List<Plan>> _byEmail = {};

  static DateTime _monthsAgo(int months) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - months, 1);
  }

  /// Membuat [count] setoran bulanan berturut-turut (dummy).
  static List<PlanDeposit> _deposits(String prefix, int count, int amount) {
    return [
      for (var i = 0; i < count; i++)
        PlanDeposit(
          id: '$prefix-$i',
          amount: amount,
          date: _monthsAgo(count - i),
          note: 'Setoran bulanan',
        ),
    ];
  }

  /// Mengosongkan data lalu mengisi tiga rencana contoh untuk akun Ilyas.
  /// Kebutuhan bulanan ketiganya Rp350.000 + Rp400.000 + Rp250.000 = Rp1.000.000,
  /// sehingga sisa uang Rp2.500.000 menjadi batas belanja Rp1.500.000.
  void reset() {
    _byEmail
      ..clear()
      ..['ilyas@gmail.com'] = [
        // Perlu Rp350.000 per bulan (sisa Rp28 jt dalam 80 bulan). Tertinggal dari jadwal.
        Plan(
          id: 'p1',
          goal: PlanGoal.pendidikan,
          name: 'Kuliah Anak',
          targetAmount: 38000000,
          years: 10,
          startDate: _monthsAgo(40),
          deposits: _deposits('p1', 40, 250000), // 10 jt
        ),
        // Perlu Rp400.000 per bulan (sisa Rp7,2 jt dalam 18 bulan). On Track.
        Plan(
          id: 'p2',
          goal: PlanGoal.darurat,
          name: 'Dana Darurat',
          targetAmount: 18000000,
          years: 2,
          startDate: _monthsAgo(6),
          deposits: _deposits('p2', 6, 1800000), // 10,8 jt
        ),
        // Perlu Rp250.000 per bulan (sisa Rp1,5 jt dalam 6 bulan). On Track.
        Plan(
          id: 'p3',
          goal: PlanGoal.liburan,
          name: 'Liburan Keluarga',
          targetAmount: 9000000,
          years: 1,
          startDate: _monthsAgo(6),
          deposits: _deposits('p3', 6, 1250000), // 7,5 jt
        ),
      ];
    notifyListeners();
  }

  /// Urut berdasarkan tenggat terdekat.
  List<Plan> all(String email) {
    final list = [...?_byEmail[email]];
    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  }

  Plan? byId(String email, String id) {
    for (final p in _byEmail[email] ?? const <Plan>[]) {
      if (p.id == id) return p;
    }
    return null;
  }

  void add(String email, Plan plan) {
    _byEmail.putIfAbsent(email, () => []).add(plan);
    notifyListeners();
  }

  void addDeposit(String email, String planId, PlanDeposit deposit) {
    _replace(email, planId, (p) => p.copyWith(deposits: [...p.deposits, deposit]));
  }

  void removeDeposit(String email, String planId, String depositId) {
    _replace(
      email,
      planId,
      (p) => p.copyWith(
        deposits: p.deposits.where((d) => d.id != depositId).toList(),
      ),
    );
  }

  void _replace(String email, String planId, Plan Function(Plan) change) {
    final list = _byEmail[email];
    if (list == null) return;
    final i = list.indexWhere((p) => p.id == planId);
    if (i < 0) return;
    list[i] = change(list[i]);
    notifyListeners();
  }
}