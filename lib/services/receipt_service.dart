import '../models/receipt_item.dart';
import 'category_service.dart';

/// Struk tidak bisa dibaca (buram, gelap, dll).
class ReceiptUnreadable implements Exception {
  const ReceiptUnreadable();
}

/// TITIK SAMBUNG KAMERA + OCR (mata kuliah Citra Digital).
///
/// Sekarang [DummyReceiptService] mengembalikan contoh struk minimarket.
/// Saat OCR siap: buat class yang mengambil foto, mengirim ke layanan OCR,
/// lalu `ReceiptService.instance = ApiReceiptService();`.
abstract class ReceiptService {
  /// Melempar [ReceiptUnreadable] jika struk tidak terbaca.
  Future<List<ReceiptItem>> scan();

  static ReceiptService instance = const DummyReceiptService();
}

class DummyReceiptService implements ReceiptService {
  const DummyReceiptService({this.blurry = false});

  /// true = simulasi foto buram (untuk menunjukkan pesan gagal).
  final bool blurry;

  static const _rows = [
    ('Beras 5 kg', 68000),
    ('Telur 1 kg', 30000),
    ('Keripik kentang', 15000),
    ('Es krim', 12000),
  ];

  @override
  Future<List<ReceiptItem>> scan() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (blurry) throw const ReceiptUnreadable();
    final items = <ReceiptItem>[];
    for (final row in _rows) {
      final kategori = await classifySafely(CategoryService.instance, row.$1);
      items.add(ReceiptItem(name: row.$1, price: row.$2, kategori: kategori));
    }
    return items; // Primer 98.000 + Sekunder 27.000 = 125.000
  }
}

/// Menjumlahkan harga barang.
int receiptTotal(List<ReceiptItem> items) =>
    items.fold(0, (sum, item) => sum + item.price);
