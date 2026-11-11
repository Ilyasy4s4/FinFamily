import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finfamily/data/auth_repository.dart';
import 'package:finfamily/data/finance_repository.dart';
import 'package:finfamily/data/transaction_repository.dart';
import 'package:finfamily/models/finance_setup.dart';
import 'package:finfamily/models/transaction.dart';
import 'package:finfamily/models/usage_status.dart';
import 'package:finfamily/screens/main_shell.dart';
import 'package:finfamily/utils/percent.dart';

const _rina = 'rina@example.com';

/// Akun dengan batas Sekunder + Tersier Rp1.500.000 dan tanpa transaksi.
void _prepareRina() {
  AuthRepository.instance.register(name: 'Rina', email: _rina, password: 'Keluarga123');
  AuthRepository.instance.login(_rina, 'Keluarga123');
  FinanceRepository.instance.save(
    email: _rina,
    setup: const FinanceSetup(
      gaji: 8000000,
      kebutuhan: 4000000,
      cicilan: 1500000,
      tabungan: 1000000,
    ),
    sekunderPercent: 70,
  );
}

void _add(String id, int amount, Kategori kategori, {DateTime? date}) {
  final now = DateTime.now();
  TransactionRepository.instance.add(
    _rina,
    Transaction(
      id: id,
      name: 'Item $id',
      amount: amount,
      kategori: kategori,
      date: date ?? DateTime(now.year, now.month, now.day),
    ),
  );
}

Future<void> _openAnalisis(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: MainShell()));
  await tester.tap(find.text('Analisis'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AuthRepository.instance.reset();
    FinanceRepository.instance.reset();
    TransactionRepository.instance.reset();
  });

  group('Persen per kategori', () {
    test('jumlah selalu tepat 100,0% (ANL_007)', () {
      final shares = sharesInTenths([2000000, 900000, 450000]);
      expect(shares.fold<int>(0, (a, b) => a + b), 1000);
      expect(shares, [597, 269, 134]);
    });

    test('contoh dari desain: 69,6% / 18,8% / 11,6%', () {
      expect(sharesInTenths([2400000, 650000, 400000]), [696, 188, 116]);
    });

    test('tanpa pengeluaran semuanya 0', () {
      expect(sharesInTenths([0, 0, 0]), [0, 0, 0]);
      expect(formatTenths(696), '69,6%');
    });
  });

  group('Ambang status (ANL_017)', () {
    UsageStatus at(int used) => UsageSummary(used: used, limit: 1500000).status;

    test('tepat di 70%, 90%, dan 100% batas Rp1.500.000', () {
      expect(at(1000000), UsageStatus.aman); // sekitar 67%
      expect(at(1049999), UsageStatus.aman);
      expect(at(1050000), UsageStatus.waspada); // tepat 70%
      expect(at(1349999), UsageStatus.waspada);
      expect(at(1350000), UsageStatus.merah); // tepat 90%
      expect(at(1499999), UsageStatus.merah);
      expect(at(1500000), UsageStatus.melebihi); // tepat 100%
      expect(at(1620000), UsageStatus.melebihi);
    });
  });

  group('Layar Hasil & Analisis', () {
    testWidgets('akun Ilyas: angka sama dengan desain', (tester) async {
      AuthRepository.instance.login('ilyas@example.com', 'Keluarga123');
      await _openAnalisis(tester);

      expect(find.text('3.450.000'), findsOneWidget);
      expect(find.text('69,6%'), findsOneWidget);
      expect(find.text('18,8%'), findsOneWidget);
      expect(find.text('11,6%'), findsOneWidget);
      expect(find.text('Rp 2.400.000'), findsOneWidget);
      expect(find.text('Rp 650.000'), findsOneWidget);
      expect(find.text('Rp 400.000'), findsOneWidget);
      expect(find.text('Waspada 70%'), findsOneWidget);
      expect(find.text('Rp 1.050.000 terpakai'), findsOneWidget);
      expect(find.text('Batas Rp 1.500.000'), findsOneWidget);
      expect(find.text('Rp 2.400.000 dari Rp 4.000.000'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('ANL_007: Sekunder + Tersier Rp1.350.000 = 90% bertanda merah, lalu ikut berubah',
        (tester) async {
      _prepareRina();
      _add('p1', 2000000, Kategori.primer);
      _add('s1', 900000, Kategori.sekunder);
      _add('t1', 450000, Kategori.tersier);
      await _openAnalisis(tester);

      expect(find.text('59,7%'), findsOneWidget);
      expect(find.text('26,9%'), findsOneWidget);
      expect(find.text('13,4%'), findsOneWidget);
      expect(find.text('Rp 1.350.000 terpakai'), findsOneWidget);
      expect(find.text('Merah 90%'), findsOneWidget);

      _add('p2', 150000, Kategori.primer); // transaksi baru
      await tester.pump();
      expect(find.text('Rp 2.150.000'), findsOneWidget);
      expect(find.text('3.500.000'), findsOneWidget);
    });

    testWidgets('ANL_017: status berubah 67% -> 70% -> 90% -> 100% -> kembali aman',
        (tester) async {
      _prepareRina();
      _add('a1', 1000000, Kategori.sekunder);
      await _openAnalisis(tester);
      expect(find.text('Aman'), findsOneWidget);

      _add('a2', 50000, Kategori.tersier);
      await tester.pump();
      expect(find.text('Waspada 70%'), findsOneWidget);

      _add('a3', 300000, Kategori.sekunder);
      await tester.pump();
      expect(find.text('Merah 90%'), findsOneWidget);

      _add('a4', 150000, Kategori.sekunder);
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Melebihi batas pengeluaran'), findsOneWidget);
      expect(find.textContaining('berhati-hati'), findsWidgets);

      for (final id in ['a4', 'a3', 'a2']) {
        TransactionRepository.instance.remove(_rina, id);
      }
      await tester.pump();
      expect(find.text('Aman'), findsOneWidget);
      expect(find.text('Melebihi batas pengeluaran'), findsNothing);
    });

    testWidgets('melebihi batas menampilkan selisih dan persen', (tester) async {
      _prepareRina();
      _add('m1', 1620000, Kategori.sekunder);
      await _openAnalisis(tester);

      expect(find.text('108%'), findsOneWidget);
      expect(find.textContaining('melewati batas Rp 120.000'), findsOneWidget);
    });

    testWidgets('hanya transaksi bulan berjalan yang dihitung', (tester) async {
      _prepareRina();
      final now = DateTime.now();
      _add('b1', 500000, Kategori.sekunder);
      _add('old', 999000, Kategori.sekunder, date: DateTime(now.year, now.month - 1, 15));
      await _openAnalisis(tester);

      expect(find.text('Rp 500.000 terpakai'), findsOneWidget);
      expect(find.text('500.000'), findsOneWidget); // total di tengah donat
    });

    testWidgets('tautan ke Plan memindahkan tab', (tester) async {
      AuthRepository.instance.login('ilyas@example.com', 'Keluarga123');
      await _openAnalisis(tester);

      await tester.tap(find.text('Cek apakah Plan masa depanmu masih aman'));
      await tester.pumpAndSettle();
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 3);
    });
  });
}
