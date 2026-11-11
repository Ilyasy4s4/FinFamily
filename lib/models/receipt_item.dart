import 'transaction.dart';

/// Satu barang hasil bacaan struk (bisa diedit sebelum disimpan).
class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.price,
    required this.kategori,
  });

  final String name;
  final int price;
  final Kategori kategori;
}
