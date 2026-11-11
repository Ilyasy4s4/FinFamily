/// Status pemakaian batas pengeluaran Sekunder + Tersier.
/// Aman < 70%, Waspada >= 70%, Merah >= 90%, Melebihi >= 100% (test case ANL_017).
enum UsageStatus { aman, waspada, merah, melebihi }

UsageStatus usageStatusFor(double ratio) {
  if (ratio >= 1.0) return UsageStatus.melebihi;
  if (ratio >= 0.9) return UsageStatus.merah;
  if (ratio >= 0.7) return UsageStatus.waspada;
  return UsageStatus.aman;
}

extension UsageStatusX on UsageStatus {
  String get label => switch (this) {
        UsageStatus.aman => 'Aman',
        UsageStatus.waspada => 'Waspada 70%',
        UsageStatus.merah => 'Merah 90%',
        UsageStatus.melebihi => 'Melebihi 100%',
      };
}

class UsageSummary {
  const UsageSummary({required this.used, required this.limit});

  /// Total pengeluaran Sekunder + Tersier.
  final int used;

  /// Batas = sisa uang bebas belanja.
  final int limit;

  double get ratio => limit <= 0 ? (used > 0 ? 1.0 : 0.0) : used / limit;
  int get percent => (ratio * 100).round();
  /// Memakai bilangan bulat agar ambang tepat di 70%, 90%, dan 100%.
  UsageStatus get status {
    if (limit <= 0) return used > 0 ? UsageStatus.melebihi : UsageStatus.aman;
    if (used >= limit) return UsageStatus.melebihi;
    if (used * 10 >= limit * 9) return UsageStatus.merah;
    if (used * 10 >= limit * 7) return UsageStatus.waspada;
    return UsageStatus.aman;
  }
}
