import '../data/finance_repository.dart';
import '../data/plan_repository.dart';
import '../data/transaction_repository.dart';
import '../models/app_notification.dart';
import '../models/finance_setup.dart';
import '../models/plan.dart';
import '../models/usage_status.dart';
import '../utils/rupiah.dart';
import 'budget_service.dart';

/// Menyusun pengingat dari kondisi keuangan saat ini.
///
/// Tidak menyimpan daftar notifikasi: isinya selalu dihitung ulang supaya
/// angkanya tidak pernah basi. Yang disimpan hanya status "sudah dibaca"
/// di [NotificationRepository].
class NotificationService {
  const NotificationService();

  static const NotificationService instance = NotificationService();

  /// Pengingat untuk sebuah ruang pada bulan tertentu.
  List<AppNotification> forSpace(String space, DateTime month) {
    final finance = FinanceRepository.instance.of(space);
    final budget = BudgetService.of(space, month);
    final extraLimit = budget.extra;
    final limit = budget.limit;
    final used = TransactionRepository.instance.usedLimitInMonth(space, month);
    return build(
      month: month,
      summary: UsageSummary(used: used, limit: limit),
      setup: finance?.setup,
      plans: PlanRepository.instance.all(space),
      extraLimit: extraLimit,
    );
  }

  List<AppNotification> build({
    required DateTime month,
    required UsageSummary summary,
    required FinanceSetup? setup,
    required List<Plan> plans,
    required int extraLimit,
  }) {
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final items = <AppNotification>[];

    if (setup == null) {
      return [
        AppNotification(
          id: 'empty-$key',
          title: 'Lengkapi pengaturan keuangan',
          message:
              'Isi pemasukan dan pengeluaran tetap agar batas belanja dan '
              'saran bisa dihitung.',
          level: AppNotificationLevel.info,
        ),
      ];
    }

    if (setup.sisa < 0) {
      items.add(
        AppNotification(
          id: 'fixed-$key',
          title: 'Pengeluaran tetap melebihi pemasukan',
          message:
              'Total pengeluaran tetap ${formatRupiah(setup.pengeluaranTetap)} '
              'lebih besar ${formatRupiah(-setup.sisa)} dari pemasukan. '
              'Kurangi atau negosiasi tagihan tetap dulu.',
          level: AppNotificationLevel.danger,
        ),
      );
    }

    if (summary.limit > 0) {
      if (summary.ratio >= 1.0) {
        items.add(
          AppNotification(
            id: 'budget-$key-100',
            title: 'Batas belanja sudah terlampaui',
            message:
                'Pengeluaran Sekunder + Tersier ${formatRupiah(summary.used)} '
                'melewati batas ${formatRupiah(summary.limit)}. '
                'Tahan belanja non-primer sampai akhir bulan.',
            level: AppNotificationLevel.danger,
            actionTab: 2,
          ),
        );
      } else if (summary.ratio >= 0.9) {
        items.add(
          AppNotification(
            id: 'budget-$key-90',
            title: 'Batas belanja tinggal ${100 - summary.percent}%',
            message:
                'Pemakaian sudah ${summary.percent}% dari batas. '
                'Sisa ${formatRupiah(summary.limit - summary.used)} untuk '
                'Sekunder dan Tersier bulan ini.',
            level: AppNotificationLevel.danger,
            actionTab: 2,
          ),
        );
      } else if (summary.ratio >= 0.7) {
        items.add(
          AppNotification(
            id: 'budget-$key-70',
            title: 'Pemakaian batas sudah ${summary.percent}%',
            message:
                'Sisa ${formatRupiah(summary.limit - summary.used)}. '
                'Mulai kurangi belanja Sekunder dan Tersier.',
            level: AppNotificationLevel.warning,
            actionTab: 2,
          ),
        );
      }
    }

    if (setup.gaji > 0) {
      final debtRatio = setup.cicilan / setup.gaji;
      if (debtRatio > 0.3) {
        items.add(
          AppNotification(
            id: 'debt-$key',
            title: 'Cicilan cukup berat',
            message:
                'Cicilan ${(debtRatio * 100).round()}% dari pemasukan. '
                'Targetkan total cicilan di bawah 30%.',
            level: AppNotificationLevel.warning,
          ),
        );
      }

      final billRatio = setup.tagihanLain / setup.gaji;
      if (billRatio > 0.15) {
        items.add(
          AppNotification(
            id: 'bill-$key',
            title: 'Tagihan rutin perlu diaudit',
            message:
                'Tagihan rutin ${(billRatio * 100).round()}% dari pemasukan. '
                'Periksa langganan yang bisa ditunda.',
            level: AppNotificationLevel.warning,
          ),
        );
      }
    }

    final beforePlan = setup.sisa + extraLimit;
    final allocation = plans.fold<int>(0, (sum, p) => sum + p.monthlyNeed(month));
    for (final plan in plans.take(3)) {
      final available = beforePlan - (allocation - plan.monthlyNeed(month));
      final assessment = PlanAssessment(plan: plan, sisa: available, now: month);
      if (assessment.sufficient) continue;
      final years = assessment.yearsNeeded;
      items.add(
        AppNotification(
          id: 'plan-${plan.id}',
          title: 'Plan ${plan.name} belum tercapai',
          message:
              'Perlu ${formatRupiah(assessment.needed)} per bulan, '
              'kurang ${formatRupiah(assessment.shortfall)}.'
              '${years == null ? '' : ' Coba perpanjang ke $years tahun.'}',
          level: AppNotificationLevel.warning,
          actionTab: 3,
        ),
      );
    }

    if (extraLimit > 0) {
      items.add(
        AppNotification(
          id: 'income-$key',
          title: 'Batas belanja bertambah',
          message:
              'Pemasukan tambahan menambah ${formatRupiah(extraLimit)} ke '
              'batas belanja bulan ini.',
          level: AppNotificationLevel.info,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        AppNotification(
          id: 'safe-$key',
          title: 'Keuangan bulan ini masih aman',
          message: summary.limit > 0 && summary.used == 0
              ? 'Belum ada pengeluaran Sekunder atau Tersier. '
                    'Batas ${formatRupiah(summary.limit)} masih utuh.'
              : 'Pemakaian batas masih di bawah 70%. '
                    'Pertahankan pola belanja sekarang.',
          level: AppNotificationLevel.info,
          actionTab: 2,
        ),
      );
    }

    return items;
  }
}
