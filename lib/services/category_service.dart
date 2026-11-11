import '../models/transaction.dart';

/// TITIK SAMBUNG MODEL KLASIFIKASI BARANG (mata kuliah Machine Learning).
///
/// Layar hanya memanggil [CategoryService.instance]. Sekarang isinya aturan
/// kata kunci sederhana. Saat model siap, buat class yang memanggil API lalu:
///
///   CategoryService.instance = ApiCategoryService();
///
/// Jika pemanggilan gagal, [classifySafely] memakai Sekunder sebagai cadangan.
abstract class CategoryService {
  Future<Kategori> classify(String itemName);

  static CategoryService instance = const RuleBasedCategoryService();
}

class RuleBasedCategoryService implements CategoryService {
  const RuleBasedCategoryService();

  static const _tersier = {
    'cincin', 'emas', 'perhiasan', 'kalung', 'gelang', 'anting', 'berlian',
    'parfum', 'branded', 'liburan', 'villa',
  };
  static const _sekunder = {
    'kopi', 'es', 'jajan', 'boba', 'snack', 'keripik', 'cemilan', 'camilan',
    'hiburan', 'bioskop', 'streaming', 'langganan', 'gadget', 'hobi', 'kafe',
    'cafe', 'restoran', 'game', 'coklat', 'cokelat', 'soda', 'permen',
  };
  static const _primer = {
    'beras', 'sayur', 'bayam', 'cabe', 'cabai', 'bawang', 'telur', 'minyak',
    'gula', 'garam', 'daging', 'ayam', 'ikan', 'tahu', 'tempe', 'susu',
    'listrik', 'token', 'air', 'gas', 'transportasi', 'bensin', 'sekolah',
    'spp', 'buku', 'obat', 'sabun', 'sembako', 'sayuran', 'pulsa',
  };

  @override
  Future<Kategori> classify(String itemName) async {
    final words = itemName
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((word) => word.isNotEmpty)
        .toSet();
    if (words.any(_tersier.contains)) return Kategori.tersier;
    if (words.any(_sekunder.contains)) return Kategori.sekunder;
    if (words.any(_primer.contains)) return Kategori.primer;
    return Kategori.sekunder; // barang tidak dikenal
  }
}

/// Memanggil layanan; jika error, memakai Sekunder.
Future<Kategori> classifySafely(CategoryService service, String itemName) async {
  try {
    return await service.classify(itemName);
  } catch (_) {
    return Kategori.sekunder;
  }
}
