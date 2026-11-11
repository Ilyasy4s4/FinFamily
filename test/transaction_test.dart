import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finfamily/data/auth_repository.dart';
import 'package:finfamily/data/finance_repository.dart';
import 'package:finfamily/data/transaction_repository.dart';
import 'package:finfamily/models/transaction.dart';
import 'package:finfamily/screens/history_screen.dart';
import 'package:finfamily/screens/main_shell.dart';
import 'package:finfamily/services/category_service.dart';
import 'package:finfamily/widgets/transaction_tile.dart';

const _ilyas = 'ilyas@example.com';

Finder _field(int index) => find.byType(TextFormField).at(index);

Future<void> _openTransaksi(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  AuthRepository.instance.login(_ilyas, 'Keluarga123');
  await tester.pumpWidget(const MaterialApp(home: MainShell()));
  await tester.tap(find.text('Transaksi'));
  await tester.pumpAndSettle();
}

List<Transaction> _items() => TransactionRepository.instance.all(_ilyas);

void main() {
  setUp(() {
    AuthRepository.instance.reset();
    FinanceRepository.instance.reset();
    TransactionRepository.instance.reset();
    CategoryService.instance = const RuleBasedCategoryService();
  });

  group('Klasifikasi kategori (KTG_008)', () {
    Future<Kategori> classify(String name) =>
        const RuleBasedCategoryService().classify(name);

    test('contoh dari test case', () async {
      expect(await classify('Token listrik'), Kategori.primer);
      expect(await classify('Es kopi susu'), Kategori.sekunder);
      expect(await classify('Cincin emas'), Kategori.tersier);
      expect(await classify('Sayur bayam'), Kategori.primer);
      expect(await classify('cabe'), Kategori.primer);
    });

    test('barang tidak dikenal masuk Sekunder', () async {
      expect(await classify('xyz'), Kategori.sekunder);
    });
  });

  group('Input manual', () {
    testWidgets('menampilkan pilihan manual dan scan struk (TRX_005)',
        (tester) async {
      await _openTransaksi(tester);

      expect(find.text('Input Manual'), findsOneWidget);
      expect(find.text('Scan Struk'), findsOneWidget);
      expect(find.text('Nama barang'), findsOneWidget);
      expect(find.text('Harga'), findsOneWidget);
      expect(find.text('Tanggal'), findsOneWidget);
      expect(find.text('Catatan'), findsOneWidget);
    });

    testWidgets('kategori diusulkan otomatis, simpan, lalu tampil di riwayat',
        (tester) async {
      await _openTransaksi(tester);

      await tester.enterText(_field(0), 'Sayur bayam');
      await tester.enterText(_field(1), '50000');
      await tester.enterText(_field(3), 'Belanja sayur di pasar');
      await tester.pumpAndSettle();
      expect(find.textContaining('masuk Primer'), findsOneWidget);

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Transaksi tersimpan.'), findsOneWidget);
      expect(_items().any((t) => t.name == 'Sayur bayam' && t.amount == 50000), isTrue);

      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();
      final history = find.byType(HistoryScreen);
      expect(find.descendant(of: history, matching: find.text('Sayur bayam')), findsOneWidget);
      expect(find.descendant(of: history, matching: find.text('−Rp 50.000')), findsOneWidget);
    });

    testWidgets('tiap contoh barang mendapat kategori yang benar (KTG_008)',
        (tester) async {
      await _openTransaksi(tester);

      for (final row in const [
        ('Token listrik', 'masuk Primer'),
        ('Es kopi susu', 'masuk Sekunder'),
        ('Cincin emas', 'masuk Tersier'),
      ]) {
        await tester.enterText(_field(0), row.$1);
        await tester.pumpAndSettle();
        expect(find.textContaining(row.$2), findsOneWidget, reason: row.$1);
      }
    });

    testWidgets('harga kosong dan negatif ditolak (TRX_015)', (tester) async {
      await _openTransaksi(tester);
      final before = _items().length;

      await tester.enterText(_field(0), 'cabe');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Harga wajib diisi'), findsOneWidget);
      expect(_items().length, before);

      await tester.enterText(_field(1), '-5000');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Harga harus lebih dari 0'), findsOneWidget);
      expect(_items().length, before);
    });

    testWidgets('kategori bisa diubah, tersimpan sesuai ubahan, lalu bisa dihapus',
        (tester) async {
      await _openTransaksi(tester);
      final totalBefore = TransactionRepository.instance.totalAll(_ilyas);

      await tester.enterText(_field(0), 'cabe');
      await tester.enterText(_field(1), '10000');
      await tester.pumpAndSettle();
      expect(find.textContaining('masuk Primer'), findsOneWidget);

      await tester.tap(find.text('Sekunder'));
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(
        _items().any((t) => t.name == 'cabe' && t.kategori == Kategori.sekunder),
        isTrue,
      );

      // Hapus dari riwayat (TRX_015 langkah 5).
      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();
      final tile = find.widgetWithText(TransactionTile, 'cabe');
      expect(tile, findsOneWidget);
      await tester.tap(
        find.descendant(of: tile, matching: find.byIcon(Icons.delete_outline)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(_items().any((t) => t.name == 'cabe'), isFalse);
      expect(TransactionRepository.instance.totalAll(_ilyas), totalBefore);
    });
  });

  group('Scan struk', () {
    testWidgets('struk terbaca: konfirmasi lalu simpan satu kali (TRX_006, TRX_016)',
        (tester) async {
      await _openTransaksi(tester);
      final before = _items().length;
      final totalBefore = TransactionRepository.instance.totalAll(_ilyas);

      await tester.tap(find.text('Scan Struk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ambil Foto Struk'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Struk'), findsOneWidget);
      expect(find.text('Struk terbaca. 4 barang ditemukan.'), findsOneWidget);
      expect(find.text('Rp 125.000'), findsOneWidget);

      // Tekan Simpan dua kali dengan cepat: hanya satu kali tersimpan.
      await tester.tap(find.text('Simpan'));
      await tester.tap(find.text('Simpan'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(_items().length, before + 4);
      expect(TransactionRepository.instance.totalAll(_ilyas), totalBefore + 125000);
      expect(find.textContaining('Total Rp 125.000'), findsOneWidget);
    });

    testWidgets('barang pada struk bisa diedit sebelum disimpan', (tester) async {
      await _openTransaksi(tester);

      await tester.tap(find.text('Scan Struk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ambil Foto Struk'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keripik kentang'));
      await tester.pumpAndSettle();
      expect(find.text('Edit barang'), findsOneWidget);

      await tester.tap(find.text('Primer').last);
      await tester.pump();
      await tester.tap(find.text('Simpan perubahan'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Struk'), findsOneWidget);
    });

    testWidgets('struk buram: muncul pesan dan pilihan input manual (TRX_016)',
        (tester) async {
      await _openTransaksi(tester);

      await tester.tap(find.text('Scan Struk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coba struk buram (contoh)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Struk tidak terbaca'), findsOneWidget);
      expect(find.text('Foto Ulang'), findsOneWidget);

      await tester.tap(find.text('Pakai Input Manual'));
      await tester.pumpAndSettle();
      expect(find.text('Nama barang'), findsOneWidget);
    });
  });
}
