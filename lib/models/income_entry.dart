/// Sumber pemasukan tambahan yang dicatat setelah Pengaturan Awal.
enum IncomeSource { gaji, freelance, bonus, beasiswa, lainnya }

extension IncomeSourceX on IncomeSource {
  String get label => switch (this) {
    IncomeSource.gaji => 'Gaji',
    IncomeSource.freelance => 'Freelance',
    IncomeSource.bonus => 'Bonus',
    IncomeSource.beasiswa => 'Beasiswa',
    IncomeSource.lainnya => 'Lainnya',
  };
}

/// Satu pemasukan yang benar-benar diterima.
///
/// [spendingAllocation] adalah porsi yang boleh menambah batas belanja.
/// Sisanya dianggap surplus/tabungan, supaya pemasukan tidak langsung habis.
class IncomeEntry {
  const IncomeEntry({
    required this.id,
    required this.amount,
    required this.source,
    required this.date,
    this.note = '',
    this.spendingAllocation = 0,
  });

  final String id;
  final int amount;
  final IncomeSource source;
  final DateTime date;
  final String note;
  final int spendingAllocation;
}
