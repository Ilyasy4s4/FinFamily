import '../data/finance_repository.dart';
import '../data/income_repository.dart';
import '../data/plan_repository.dart';

/// Ringkasan uang bulanan satu ruang pada satu bulan.
///
/// Rumusnya satu-satunya di aplikasi:
///   sisa awal (Pengaturan Awal) + porsi pemasukan tambahan
///   - alokasi Plan = batas belanja Sekunder + Tersier.
class BudgetSnapshot {
  const BudgetSnapshot({
    required this.baseSisa,
    required this.extra,
    required this.planAllocation,
  });

  /// Sisa uang dari Pengaturan Awal (gaji - kebutuhan - cicilan - tagihan).
  final int baseSisa;

  /// Porsi pemasukan tambahan yang boleh menambah batas belanja bulan ini.
  final int extra;

  /// Total uang yang disisihkan untuk semua Plan aktif per bulan.
  final int planAllocation;

  /// Uang bulanan sebelum dikurangi Plan.
  int get beforePlan => baseSisa + extra;

  /// Uang yang belum dialokasikan (bisa negatif jika Plan berlebih).
  int get unallocated => beforePlan - planAllocation;

  bool get overAllocated => unallocated < 0;

  /// Batas belanja Sekunder + Tersier (tidak pernah di bawah 0).
  int get limit => unallocated < 0 ? 0 : unallocated;
}

abstract final class BudgetService {
  static BudgetSnapshot of(String space, [DateTime? month]) {
    final m = month ?? DateTime.now();
    final base = FinanceRepository.instance.of(space)?.setup.sisa ?? 0;
    final extra = IncomeRepository.instance.spendingAllocationInMonth(space, m);
    final allocation = PlanRepository.instance
        .all(space)
        .fold<int>(0, (sum, plan) => sum + plan.monthlyNeed(m));
    return BudgetSnapshot(
      baseSisa: base,
      extra: extra,
      planAllocation: allocation,
    );
  }

  /// Uang yang tersedia untuk satu rencana: uang bulanan dikurangi alokasi
  /// rencana LAIN. Untuk rencana baru (belum disimpan) kosongkan [planId].
  static int availableForPlan(
    String space, {
    String? planId,
    DateTime? month,
  }) {
    final m = month ?? DateTime.now();
    final snapshot = of(space, m);
    final own = planId == null
        ? 0
        : (PlanRepository.instance.byId(space, planId)?.monthlyNeed(m) ?? 0);
    return snapshot.beforePlan - (snapshot.planAllocation - own);
  }
}
