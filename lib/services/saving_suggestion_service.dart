import '../models/finance_setup.dart';
import '../models/financial_insight.dart';
import '../models/plan.dart';
import '../models/usage_status.dart';
import '../utils/rupiah.dart';
import 'budget_service.dart';
import 'financial_classifier.dart';

enum SavingAdviceKind { danaDarurat, tujuanLain, sisaBulan, fokusKebutuhan }

/// Isian awal untuk form Tambah Rencana yang datang dari saran.
class PlanPrefill {
  const PlanPrefill({
    required this.goal,
    required this.name,
    required this.targetAmount,
    required this.years,
  });

  final PlanGoal goal;
  final String name;
  final int targetAmount;
  final int years;
}

class SavingAdvice {
  const SavingAdvice({
    required this.kind,
    required this.title,
    required this.message,
    this.amount = 0,
    this.actionLabel,
    this.prefill,
    this.depositPlanId,
  });

  final SavingAdviceKind kind;
  final String title;
  final String message;

  /// Nominal yang disarankan per bulan (atau sekali setor untuk [sisaBulan]).
  final int amount;

  /// null = hanya informasi, tanpa tombol.
  final String? actionLabel;

  /// Diisi jika tombol membuka form Tambah Rencana.
  final PlanPrefill? prefill;

  /// Diisi jika tombol membuka form Setor untuk rencana ini.
  final String? depositPlanId;
}

/// Saran menabung dari aplikasi. Menabung tidak ditanya di Pengaturan Awal;
/// saran baru muncul kalau kebutuhan terpenuhi dan ada uang lebih.
///
/// Urutan: (1) kondisi ketat -> fokus kebutuhan, (2) akhir bulan dan batas
/// belanja masih longgar -> setor sisanya ke Plan, (3) ada uang yang belum
/// dialokasikan -> dana darurat dulu, lalu tujuan lain.
abstract final class SavingSuggestionService {
  static const int _step = 50000;

  static int _floorStep(int value) => value ~/ _step * _step;

  static int _daysLeftInMonth(DateTime now) =>
      DateTime(now.year, now.month + 1, 0).day - now.day;

  static SavingAdvice? advise({
    required FinanceSetup? setup,
    required BudgetSnapshot budget,
    required List<Plan> plans,
    required UsageSummary usage,
    required DateTime now,
  }) {
    if (setup == null || setup.sisa <= 0) return null;

    final condition = FinancialClassifier.instance.assess(setup).condition;
    if (condition == FinancialCondition.kritis ||
        condition == FinancialCondition.overleveraged) {
      return const SavingAdvice(
        kind: SavingAdviceKind.fokusKebutuhan,
        title: 'Fokus kebutuhan dulu',
        message:
            'Keuangan bulan ini masih ketat. Penuhi kebutuhan pokok lebih '
            'dulu. Saran menabung muncul saat ada uang lebih.',
      );
    }

    final active = plans.where((p) => p.remaining > 0).toList();

    // Akhir bulan dan batas belanja masih longgar: setor sebagian sisanya.
    if (_daysLeftInMonth(now) <= 7 &&
        active.isNotEmpty &&
        budget.limit > 0 &&
        usage.status == UsageStatus.aman) {
      final leftover = budget.limit - usage.used;
      final amount = _floorStep(leftover ~/ 2);
      if (amount >= _step) {
        final target = active.firstWhere(
          (p) => p.status(now) == PlanStatus.butuhAkselerasi,
          orElse: () => active.first,
        );
        return SavingAdvice(
          kind: SavingAdviceKind.sisaBulan,
          title: 'Batas belanja masih longgar',
          message:
              'Batas belanja bulan ini tersisa ${formatRupiah(leftover)}. '
              'Setorkan sekitar ${formatRupiah(amount)} ke ${target.name} '
              'supaya lebih cepat tercapai.',
          amount: amount,
          actionLabel: 'Setor sekarang',
          depositPlanId: target.id,
        );
      }
    }

    // Ada uang bulanan yang belum dialokasikan ke Plan mana pun.
    final free = budget.unallocated;
    if (free < _step) return null;

    final share = condition == FinancialCondition.aman ? 0.5 : 0.3;
    var amount = _floorStep((free * share).floor());
    if (amount < _step) amount = _step;

    final hasEmergency = plans.any((p) => p.goal == PlanGoal.darurat);
    if (!hasEmergency && setup.pengeluaranTetap > 0) {
      final months = setup.tanggungan > 0 ? 6 : 3;
      final raw = months * setup.pengeluaranTetap;
      final target = (raw + 99999) ~/ 100000 * 100000;
      final perYear = amount * 12;
      final years = ((target + perYear - 1) ~/ perYear).clamp(1, 50);
      return SavingAdvice(
        kind: SavingAdviceKind.danaDarurat,
        title: 'Mulai dari dana darurat',
        message:
            'Kamu punya ${formatRupiah(free)} yang belum dialokasikan. '
            'Dana darurat sebaiknya $months bulan biaya tetap '
            '(${formatRupiah(target)}). Menyisihkan sekitar '
            '${formatRupiah(amount)} per bulan, targetnya tercapai '
            'dalam ±$years tahun.',
        amount: amount,
        actionLabel: 'Buat dana darurat',
        prefill: PlanPrefill(
          goal: PlanGoal.darurat,
          name: 'Dana Darurat',
          targetAmount: target,
          years: years,
        ),
      );
    }

    return SavingAdvice(
      kind: SavingAdviceKind.tujuanLain,
      title: 'Ada uang yang bisa ditabung',
      message:
          'Kamu punya ${formatRupiah(free)} yang belum dialokasikan. '
          'Menyisihkan sekitar ${formatRupiah(amount)} per bulan bisa untuk '
          'tujuan lain seperti pendidikan, rumah, atau liburan.',
      amount: amount,
      actionLabel: 'Buat rencana',
    );
  }
}
