import '../models/finance_setup.dart';
import '../models/financial_insight.dart';
import 'financial_classifier.dart';

enum RecommendationSource { defaultRule, model }

/// Porsi sisa uang untuk Sekunder. Semakin ketat kondisi keuangan, semakin
/// kecil porsi Tersier supaya belanja keinginan tidak mengganggu kebutuhan.
///
/// Nilai ini TIDAK menampilkan kelas kondisi ke pengguna. Kelas hanya dipakai
/// untuk menentukan pembagian dan teks saran.
int sekunderShareFor(FinancialCondition condition) => switch (condition) {
  FinancialCondition.aman => 70,
  FinancialCondition.cukup => 75,
  FinancialCondition.kritis => 85,
  FinancialCondition.overleveraged => 90,
};

/// Hasil rekomendasi: berapa persen sisa uang untuk Sekunder (sisanya Tersier),
/// plus saran yang dihasilkan dari klasifikasi kondisi keuangan.
class Recommendation {
  const Recommendation({
    required this.sekunderPercent,
    required this.source,
    this.insight,
  });

  final int sekunderPercent;
  final RecommendationSource source;
  final FinancialInsight? insight;

  int get tersierPercent => 100 - sekunderPercent;
}

/// TITIK SAMBUNG MODEL (mata kuliah Machine Learning).
///
/// Layar Pengaturan Awal hanya memanggil [RecommendationService.instance].
/// Sekarang isinya aturan bawaan yang menyesuaikan pembagian dengan kondisi
/// keuangan. Kalau model sudah siap, buat class baru yang memanggil API
/// (NestJS -> layanan model), lalu ganti satu baris:
///
///   RecommendationService.instance = ApiRecommendationService();
///
/// Layar tidak perlu diubah. Jika panggilan gagal, [recommendSafely]
/// otomatis memakai pembagian bawaan agar aplikasi tetap jalan.
abstract class RecommendationService {
  Future<Recommendation> recommend(FinanceSetup setup);

  static RecommendationService instance = const DefaultRecommendationService();
}

/// Pembagian bawaan yang mengikuti kondisi keuangan:
/// aman 70/30, cukup 75/25, kritis 85/15, overleveraged 90/10.
/// Saran detail diambil dari [FinancialClassifier].
class DefaultRecommendationService implements RecommendationService {
  const DefaultRecommendationService();

  @override
  Future<Recommendation> recommend(FinanceSetup setup) async {
    final insight = FinancialClassifier.instance.assess(setup);
    return Recommendation(
      sekunderPercent: sekunderShareFor(insight.condition),
      source: RecommendationSource.defaultRule,
      insight: insight,
    );
  }
}

/// Memanggil layanan; jika error, kembali ke pembagian bawaan.
Future<Recommendation> recommendSafely(
  RecommendationService service,
  FinanceSetup setup,
) async {
  try {
    return await service.recommend(setup);
  } catch (_) {
    return const DefaultRecommendationService().recommend(setup);
  }
}
