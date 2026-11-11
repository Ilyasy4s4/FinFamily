enum PlanGoal { pendidikan, rumah, pensiun, darurat, liburan, lainnya }

extension PlanGoalX on PlanGoal {
  String get label => switch (this) {
        PlanGoal.pendidikan => 'Dana pendidikan',
        PlanGoal.rumah => 'Pembelian rumah',
        PlanGoal.pensiun => 'Dana pensiun',
        PlanGoal.darurat => 'Dana darurat',
        PlanGoal.liburan => 'Liburan',
        PlanGoal.lainnya => 'Lainnya',
      };
}

/// Status kemajuan rencana (progres aktual dibanding progres ideal menurut waktu).
enum PlanStatus { tercapai, hampirTercapai, onTrack, butuhAkselerasi }

extension PlanStatusX on PlanStatus {
  String get label => switch (this) {
        PlanStatus.tercapai => 'Tercapai',
        PlanStatus.hampirTercapai => 'Hampir Tercapai',
        PlanStatus.onTrack => 'On Track',
        PlanStatus.butuhAkselerasi => 'Butuh Akselerasi',
      };
}

/// Satu catatan setoran ke sebuah rencana.
class PlanDeposit {
  const PlanDeposit({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final String id;
  final int amount;
  final DateTime date;
  final String note;
}

/// Rencana keuangan jangka panjang.
class Plan {
  const Plan({
    required this.id,
    required this.goal,
    required this.name,
    required this.targetAmount,
    required this.years,
    required this.startDate,
    this.deposits = const [],
  });

  final String id;
  final PlanGoal goal;
  final String name;
  final int targetAmount;
  final int years;
  final DateTime startDate;
  final List<PlanDeposit> deposits;

  Plan copyWith({List<PlanDeposit>? deposits}) => Plan(
        id: id,
        goal: goal,
        name: name,
        targetAmount: targetAmount,
        years: years,
        startDate: startDate,
        deposits: deposits ?? this.deposits,
      );

  /// Tabungan per bulan = target dana / (tahun x 12), dibulatkan ke rupiah terdekat.
  /// Contoh: 150.000.000 dalam 15 tahun = Rp833.333 (PLN_009).
  int get monthlySaving {
    final months = years * 12;
    return (targetAmount * 2 + months) ~/ (months * 2);
  }

  /// Uang yang perlu disisihkan per bulan mulai [now]: sisa target dibagi sisa
  /// bulan sampai tenggat (dibulatkan ke rupiah terdekat). 0 jika sudah tercapai.
  /// Makin banyak setoran, makin kecil angkanya.
  int monthlyNeed(DateTime now) {
    if (remaining <= 0) return 0;
    final left = monthsLeft(now);
    final months = left < 1 ? 1 : left;
    return (remaining * 2 + months) ~/ (months * 2);
  }

  /// Total uang yang sudah terkumpul.
  int get saved => deposits.fold(0, (sum, d) => sum + d.amount);

  /// 0.0 sampai 1.0.
  double get progress =>
      targetAmount <= 0 ? 0 : (saved / targetAmount).clamp(0.0, 1.0);

  /// Sisa dana yang masih harus dikumpulkan.
  int get remaining => saved >= targetAmount ? 0 : targetAmount - saved;

  /// Tenggat (bulan dan tahun).
  DateTime get deadline => DateTime(startDate.year + years, startDate.month);

  /// Sisa bulan sampai tenggat (minimal 0).
  int monthsLeft(DateTime now) {
    final m = (deadline.year - now.year) * 12 + (deadline.month - now.month);
    return m < 0 ? 0 : m;
  }

  PlanStatus status(DateTime now) {
    if (saved >= targetAmount) return PlanStatus.tercapai;
    if (progress >= 0.9) return PlanStatus.hampirTercapai;
    final total = years * 12;
    final elapsed = (total - monthsLeft(now)).clamp(0, total);
    final ideal = elapsed / total;
    return progress >= ideal * 0.9
        ? PlanStatus.onTrack
        : PlanStatus.butuhAkselerasi;
  }
}

/// Perbandingan sebuah rencana dengan sisa uang bulanan.
class PlanAssessment {
  PlanAssessment({required this.plan, required this.sisa, DateTime? now})
      : now = now ?? DateTime.now();

  final Plan plan;

  /// Uang bulanan yang tersedia untuk rencana ini, yaitu sisa uang dikurangi
  /// alokasi rencana lain (lihat BudgetService.availableForPlan).
  final int sisa;

  final DateTime now;

  /// Uang yang perlu disisihkan per bulan untuk rencana ini.
  int get needed => plan.monthlyNeed(now);

  bool get sufficient => needed <= sisa;

  /// Kekurangan per bulan (0 jika mencukupi).
  int get shortfall => sufficient ? 0 : needed - sisa;

  /// Lama waktu minimal dari sekarang (tahun, dibulatkan ke atas) agar uang
  /// yang tersedia mencukupi sisa target. null jika tidak ada uang tersedia.
  int? get yearsNeeded {
    if (sisa <= 0) return null;
    final perYear = sisa * 12;
    return (plan.remaining + perYear - 1) ~/ perYear;
  }
}