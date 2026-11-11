/// Kelas kondisi keuangan dari model klasifikasi.
///
/// Kelas ini sengaja tidak ditampilkan sebagai label di UI. Hasil klasifikasi
/// hanya dipakai untuk memilih rekomendasi yang relevan.
enum FinancialCondition { aman, cukup, kritis, overleveraged }

/// Hasil olahan data awal menjadi saran yang bisa dibaca pengguna.
class FinancialInsight {
  const FinancialInsight({
    required this.condition,
    required this.headline,
    required this.summary,
    required this.actions,
    required this.income,
    required this.fixedCost,
    required this.remaining,
  });

  final FinancialCondition condition;
  final String headline;
  final String summary;
  final List<String> actions;
  final int income;
  final int fixedCost;
  final int remaining;

  bool get hasData => income > 0 || fixedCost > 0;
}
