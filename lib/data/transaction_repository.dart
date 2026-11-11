import 'package:flutter/foundation.dart';

import '../models/transaction.dart';

/// Data transaksi DUMMY (di memori), satu daftar per akun. Nanti diganti API.
/// Berupa ChangeNotifier supaya Beranda dan Riwayat ikut berubah saat data berubah.
class TransactionRepository extends ChangeNotifier {
  TransactionRepository._() {
    reset();
  }

  static final TransactionRepository instance = TransactionRepository._();

  final Map<String, List<Transaction>> _byEmail = {};

  /// Mengosongkan data lalu mengisi transaksi contoh untuk akun Ilyas.
  /// Total: Primer 2.400.000, Sekunder 650.000, Tersier 400.000
  /// (Sekunder + Tersier = 1.050.000 = 70% dari batas 1.500.000).
  void reset({DateTime? now}) {
    final base = now ?? DateTime.now();
    // Semua data contoh jatuh di bulan berjalan agar angka "bulan ini" selalu sama.
    Transaction t(
      String id,
      String name,
      int amount,
      Kategori k,
      int ago, {
      String by = 'ilyas@gmail.com',
    }) =>
        Transaction(
          id: id,
          name: name,
          amount: amount,
          kategori: k,
          date: DateTime(base.year, base.month, base.day > ago ? base.day - ago : 1),
          authorEmail: by,
        );
    Transaction p(String id, String name, int amount, Kategori k, int ago) =>
        Transaction(
          id: id,
          name: name,
          amount: amount,
          kategori: k,
          date: DateTime(base.year, base.month, base.day > ago ? base.day - ago : 1),
          authorEmail: 'gusti@gmail.com',
          isPersonal: true,
        );
    // Urutan dari yang terlama ke terbaru (tanggal sama: yang di belakang tampil di atas).
    _byEmail
      ..clear()
      ..['ilyas@gmail.com'] = [
        // Transaksi pribadi Anak (Andi): terpakai Rp450.000 dari jatah.
        p('a4', 'Transport kampus', 312000, Kategori.primer, 3),
        p('a3', 'Buku kuliah', 85000, Kategori.primer, 2),
        p('a2', 'Boba', 28000, Kategori.sekunder, 1),
        p('a1', 'Makan siang', 25000, Kategori.primer, 0),
        t('t10', 'Bensin', 400000, Kategori.primer, 9),
        t('t9', 'Jajan anak', 198000, Kategori.sekunder, 8, by: 'siti.santoso@example.com'),
        t('t8', 'Parfum', 400000, Kategori.tersier, 7, by: 'siti.santoso@example.com'),
        t('t7', 'Transportasi', 515000, Kategori.primer, 6),
        t('t6', 'Langganan streaming', 54000, Kategori.sekunder, 5, by: 'siti.santoso@example.com'),
        t('t5', 'Makan di luar', 350000, Kategori.sekunder, 4),
        t('t4', 'Belanja bulanan', 1100000, Kategori.primer, 3, by: 'siti.santoso@example.com'),
        t('t3', 'Token listrik', 200000, Kategori.primer, 2, by: 'siti.santoso@example.com'),
        t('t2', 'Kopi kafe', 48000, Kategori.sekunder, 1),
        t('t1', 'Beras dan minyak', 185000, Kategori.primer, 0, by: 'siti.santoso@example.com'),
      ];
    notifyListeners();
  }

  /// Transaksi ruang, terbaru di atas (tanggal sama: yang dicatat belakangan di atas).
  /// Tanpa [memberEmail]: transaksi keluarga (tanpa transaksi pribadi Anak).
  /// Dengan [memberEmail]: hanya transaksi pribadi anggota itu.
  List<Transaction> all(String email, {String? memberEmail}) {
    final source = (_byEmail[email] ?? const <Transaction>[])
        .where((t) => memberEmail == null
            ? !t.isPersonal
            : t.isPersonal && t.authorEmail == memberEmail)
        .toList();
    final entries = source.asMap().entries.toList();
    entries.sort((a, b) {
      final byDate = b.value.date.compareTo(a.value.date);
      return byDate != 0 ? byDate : b.key.compareTo(a.key);
    });
    return [for (final entry in entries) entry.value];
  }

  void add(String email, Transaction transaction) {
    _byEmail.putIfAbsent(email, () => []).add(transaction);
    notifyListeners();
  }

  void remove(String email, String id) {
    _byEmail[email]?.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  int total(String email, Kategori kategori) {
    var sum = 0;
    for (final item in _byEmail[email] ?? const <Transaction>[]) {
      if (!item.isPersonal && item.kategori == kategori) sum += item.amount;
    }
    return sum;
  }

  /// Total semua pengeluaran akun.
  int totalAll(String email) {
    var sum = 0;
    for (final item in _byEmail[email] ?? const <Transaction>[]) {
      if (!item.isPersonal) sum += item.amount;
    }
    return sum;
  }

  /// Pemakaian batas = Sekunder + Tersier.
  int usedLimit(String email) =>
      total(email, Kategori.sekunder) + total(email, Kategori.tersier);

  bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  /// Total satu kategori pada bulan tertentu.
  int totalInMonth(String email, Kategori kategori, DateTime month) {
    var sum = 0;
    for (final item in _byEmail[email] ?? const <Transaction>[]) {
      if (!item.isPersonal && item.kategori == kategori && _sameMonth(item.date, month)) {
        sum += item.amount;
      }
    }
    return sum;
  }

  /// Pemakaian batas (Sekunder + Tersier) pada bulan tertentu.
  int usedLimitInMonth(String email, DateTime month) =>
      totalInMonth(email, Kategori.sekunder, month) +
      totalInMonth(email, Kategori.tersier, month);

  /// Pengeluaran keluarga bulan tertentu per pencatat, dipecah per kategori.
  /// Transaksi pribadi Anak tidak ikut. Kunci '' = pencatat tidak diketahui.
  Map<String, Map<Kategori, int>> byAuthorInMonth(String email, DateTime month) {
    final result = <String, Map<Kategori, int>>{};
    for (final item in _byEmail[email] ?? const <Transaction>[]) {
      if (item.isPersonal || !_sameMonth(item.date, month)) continue;
      final perKategori = result.putIfAbsent(
        item.authorEmail,
        () => {for (final k in Kategori.values) k: 0},
      );
      perKategori[item.kategori] = perKategori[item.kategori]! + item.amount;
    }
    return result;
  }

  /// Pengeluaran pribadi seorang Anak pada bulan tertentu (dihitung dari jatah).
  int personalInMonth(String email, String member, DateTime month) {
    var sum = 0;
    for (final item in _byEmail[email] ?? const <Transaction>[]) {
      if (item.isPersonal && item.authorEmail == member && _sameMonth(item.date, month)) {
        sum += item.amount;
      }
    }
    return sum;
  }
}