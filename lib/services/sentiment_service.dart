enum SentimentLabel { positif, netral, negatif }

extension SentimentLabelX on SentimentLabel {
  String get label => switch (this) {
        SentimentLabel.positif => 'Positif',
        SentimentLabel.netral => 'Netral',
        SentimentLabel.negatif => 'Negatif',
      };
}

class Sentiment {
  const Sentiment({required this.label, required this.score});

  final SentimentLabel label;

  /// Tingkat keyakinan 0..1.
  final double score;
}

/// TITIK SAMBUNG MODEL SENTIMEN (mata kuliah Pemrograman Sistem Cerdas).
///
/// Layar Umpan Balik hanya memanggil [SentimentService.instance]. Sekarang
/// isinya aturan kata kunci sederhana. Saat model siap, buat class yang
/// memanggil API lalu:
///
///   SentimentService.instance = ApiSentimentService();
///
/// Jika pemanggilan gagal, [analyzeSafely] mengembalikan null: umpan balik
/// tetap tersimpan dan labelnya menyusul.
abstract class SentimentService {
  Future<Sentiment> analyze(String text);

  static SentimentService instance = const RuleBasedSentimentService();
}

class RuleBasedSentimentService implements SentimentService {
  const RuleBasedSentimentService();

  static const _positive = {
    'bagus', 'suka', 'mantap', 'membantu', 'mudah', 'keren', 'puas', 'hebat',
    'cepat', 'praktis', 'rapi', 'berguna', 'bermanfaat', 'senang', 'lancar',
  };
  static const _negative = {
    'jelek', 'lambat', 'lemot', 'error', 'bug', 'buruk', 'susah', 'ribet',
    'gagal', 'kecewa', 'crash', 'lama', 'membingungkan', 'macet', 'rusak',
  };

  @override
  Future<Sentiment> analyze(String text) async {
    final words = text
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((word) => word.isNotEmpty);
    var positive = 0;
    var negative = 0;
    for (final word in words) {
      if (_positive.contains(word)) positive++;
      if (_negative.contains(word)) negative++;
    }
    final diff = positive - negative;
    if (diff == 0) return const Sentiment(label: SentimentLabel.netral, score: 0.5);
    final score = (0.6 + 0.1 * diff.abs()).clamp(0.0, 0.95);
    return Sentiment(
      label: diff > 0 ? SentimentLabel.positif : SentimentLabel.negatif,
      score: score,
    );
  }
}

/// Memanggil layanan; jika error, mengembalikan null.
Future<Sentiment?> analyzeSafely(SentimentService service, String text) async {
  try {
    return await service.analyze(text);
  } catch (_) {
    return null;
  }
}
