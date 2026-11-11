/// Membagi [values] menjadi persen dalam satuan sepersepuluh (1000 = 100,0%).
/// Memakai metode sisa terbesar sehingga jumlahnya selalu tepat 100,0% (ANL_007).
List<int> sharesInTenths(List<int> values) {
  final total = values.fold<int>(0, (sum, v) => sum + v);
  if (total <= 0) return List<int>.filled(values.length, 0);

  final shares = [for (final v in values) v * 1000 ~/ total];
  final remainders = [for (final v in values) (v * 1000) % total];
  var left = 1000 - shares.fold<int>(0, (sum, v) => sum + v);

  final order = List<int>.generate(values.length, (i) => i)
    ..sort((a, b) => remainders[b].compareTo(remainders[a]));
  for (var i = 0; left > 0 && i < order.length; i++, left--) {
    shares[order[i]]++;
  }
  return shares;
}

/// 696 -> "69,6%"
String formatTenths(int tenths) => '${tenths ~/ 10},${tenths % 10}%';
