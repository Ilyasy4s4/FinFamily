import 'package:flutter/foundation.dart';

import '../models/finance_setup.dart';

class SavedFinance {
  const SavedFinance({required this.setup, required this.sekunderPercent});

  final FinanceSetup setup;

  /// Persen sisa uang untuk Sekunder; Tersier = 100 - nilai ini.
  final int sekunderPercent;
}

/// Data keuangan DUMMY (di memori), satu per ruang. Nanti diganti API.
/// Reaktif supaya Beranda, Analisis, dan Plan ikut berubah setelah
/// pengaturan keuangan disunting.
class FinanceRepository extends ChangeNotifier {
  FinanceRepository._() {
    reset();
  }

  static final FinanceRepository instance = FinanceRepository._();

  final Map<String, SavedFinance> _byEmail = {};

  /// Mengosongkan data lalu mengisi data akun lama (Ilyas) dari Excel.
  void reset() {
    _byEmail
      ..clear()
      ..['ilyas@gmail.com'] = const SavedFinance(
        setup: FinanceSetup(
          gaji: 8000000,
          kebutuhan: 4000000,
          cicilan: 1500000,
        ),
        sekunderPercent: 70,
      );
    notifyListeners();
  }

  void save({
    required String email,
    required FinanceSetup setup,
    required int sekunderPercent,
  }) {
    _byEmail[email] = SavedFinance(
      setup: setup,
      sekunderPercent: sekunderPercent,
    );
    notifyListeners();
  }

  SavedFinance? of(String email) => _byEmail[email];
}
