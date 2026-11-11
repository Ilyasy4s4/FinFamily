import 'package:flutter/foundation.dart';

import '../models/income_entry.dart';

/// Data pemasukan tambahan DUMMY (di memori), satu daftar per ruang.
/// Dipakai untuk skenario pemasukan tidak tetap seperti freelance.
class IncomeRepository extends ChangeNotifier {
  IncomeRepository._();

  static final IncomeRepository instance = IncomeRepository._();

  final Map<String, List<IncomeEntry>> _bySpace = {};

  void reset() {
    _bySpace.clear();
    notifyListeners();
  }

  /// Pemasukan terbaru di atas. Tanggal sama: yang terakhir dicatat di atas.
  List<IncomeEntry> all(String space) {
    final source = [...?_bySpace[space]];
    final entries = source.asMap().entries.toList();
    entries.sort((a, b) {
      final byDate = b.value.date.compareTo(a.value.date);
      return byDate != 0 ? byDate : b.key.compareTo(a.key);
    });
    return [for (final entry in entries) entry.value];
  }

  void add(String space, IncomeEntry entry) {
    _bySpace.putIfAbsent(space, () => []).add(entry);
    notifyListeners();
  }

  int totalInMonth(String space, DateTime month) {
    var sum = 0;
    for (final entry in _bySpace[space] ?? const <IncomeEntry>[]) {
      if (entry.date.year == month.year && entry.date.month == month.month) {
        sum += entry.amount;
      }
    }
    return sum;
  }

  /// Porsi pemasukan tambahan yang boleh menambah batas belanja bulan ini.
  int spendingAllocationInMonth(String space, DateTime month) {
    var sum = 0;
    for (final entry in _bySpace[space] ?? const <IncomeEntry>[]) {
      if (entry.date.year == month.year && entry.date.month == month.month) {
        sum += entry.spendingAllocation;
      }
    }
    return sum;
  }
}
