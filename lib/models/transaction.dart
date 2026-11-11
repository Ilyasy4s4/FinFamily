enum Kategori { primer, sekunder, tersier }

extension KategoriX on Kategori {
  String get label => switch (this) {
        Kategori.primer => 'Primer',
        Kategori.sekunder => 'Sekunder',
        Kategori.tersier => 'Tersier',
      };
}

class Transaction {
  const Transaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.kategori,
    required this.date,
    this.note = '',
    this.authorEmail = '',
    this.isPersonal = false,
  });

  final String id;
  final String name;
  final int amount;
  final Kategori kategori;
  final DateTime date;
  final String note;

  /// Akun yang mencatat transaksi.
  final String authorEmail;

  /// true = transaksi pribadi Anak (dihitung dari jatah, bukan dari batas keluarga).
  final bool isPersonal;
}
