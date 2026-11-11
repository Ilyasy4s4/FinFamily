import 'package:flutter/foundation.dart';

import '../services/sentiment_service.dart';

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.authorEmail,
    required this.text,
    required this.createdAt,
    this.rating,
    this.sentiment,
  });

  final String id;
  final String authorEmail;
  final String text;
  final DateTime createdAt;

  /// 1..5, null jika tidak diisi.
  final int? rating;

  /// null jika layanan sentimen gagal (label menyusul).
  final Sentiment? sentiment;
}

/// Ringkasan untuk TIM PENGEMBANG (tidak ditampilkan di aplikasi pengguna).
class FeedbackSummary {
  const FeedbackSummary({
    required this.total,
    required this.positif,
    required this.netral,
    required this.negatif,
    required this.unlabeled,
    required this.averageRating,
  });

  final int total;
  final int positif;
  final int netral;
  final int negatif;
  final int unlabeled;
  final double? averageRating;
}

/// Umpan balik DUMMY (di memori). Nanti diganti API.
class FeedbackRepository extends ChangeNotifier {
  FeedbackRepository._();

  static final FeedbackRepository instance = FeedbackRepository._();

  final List<FeedbackEntry> _items = [];

  List<FeedbackEntry> get all => List.unmodifiable(_items);

  void reset() {
    _items.clear();
    notifyListeners();
  }

  void add(FeedbackEntry entry) {
    _items.add(entry);
    notifyListeners();
  }

  FeedbackSummary summary() {
    var positif = 0, netral = 0, negatif = 0, unlabeled = 0;
    var ratingSum = 0, ratingCount = 0;
    for (final item in _items) {
      switch (item.sentiment?.label) {
        case SentimentLabel.positif:
          positif++;
        case SentimentLabel.netral:
          netral++;
        case SentimentLabel.negatif:
          negatif++;
        case null:
          unlabeled++;
      }
      final rating = item.rating;
      if (rating != null) {
        ratingSum += rating;
        ratingCount++;
      }
    }
    return FeedbackSummary(
      total: _items.length,
      positif: positif,
      netral: netral,
      negatif: negatif,
      unlabeled: unlabeled,
      averageRating: ratingCount == 0 ? null : ratingSum / ratingCount,
    );
  }

  /// Data untuk dianalisis tim pengembang (mis. di Google Colab).
  String exportCsv() {
    String quote(String value) =>
        '"${value.replaceAll('"', '""').replaceAll(RegExp(r'\s*\n\s*'), ' ')}"';
    final lines = ['id,rating,label,score,teks'];
    for (final item in _items) {
      lines.add([
        item.id,
        item.rating?.toString() ?? '',
        item.sentiment?.label.label ?? '',
        item.sentiment?.score.toStringAsFixed(2) ?? '',
        quote(item.text),
      ].join(','));
    }
    return lines.join('\n');
  }
}
