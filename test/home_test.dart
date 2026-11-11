import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finfamily/data/auth_repository.dart';
import 'package:finfamily/data/finance_repository.dart';
import 'package:finfamily/data/transaction_repository.dart';
import 'package:finfamily/main.dart';
import 'package:finfamily/models/usage_status.dart';

Future<void> _loginAs(
  WidgetTester tester,
  String email,
  String password,
) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const FinFamilyApp());
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.text('Masuk'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AuthRepository.instance.reset();
    FinanceRepository.instance.reset();
    TransactionRepository.instance.reset();
  });

  group('Status pemakaian batas', () {
    test('ambang 70, 90, 100 persen', () {
      expect(usageStatusFor(0.69), UsageStatus.aman);
      expect(usageStatusFor(0.70), UsageStatus.waspada);
      expect(usageStatusFor(0.89), UsageStatus.waspada);
      expect(usageStatusFor(0.90), UsageStatus.merah);
      expect(usageStatusFor(0.99), UsageStatus.merah);
      expect(usageStatusFor(1.00), UsageStatus.melebihi);
      expect(usageStatusFor(1.08), UsageStatus.melebihi);
    });

    test('batas nol dengan pengeluaran dianggap melebihi', () {
      expect(const UsageSummary(used: 1000, limit: 0).status, UsageStatus.melebihi);
      expect(const UsageSummary(used: 0, limit: 0).status, UsageStatus.aman);
    });
  });

  group('Beranda', () {
    testWidgets('akun lama menampilkan sisa uang, status, dan transaksi',
        (tester) async {
      await _loginAs(tester, 'ilyas@example.com', 'Keluarga123');

      expect(find.text('Halo, Ilyas!'), findsOneWidget);
      expect(find.text('Rp 1.500.000'), findsOneWidget);
      expect(find.text('Rp 1.050.000 dari Rp 1.500.000'), findsOneWidget);
      expect(find.text('Waspada 70%'), findsOneWidget);
      expect(find.text('Beras dan minyak'), findsOneWidget);
      expect(find.text('Kopi kafe'), findsOneWidget);
      expect(find.text('Token listrik'), findsOneWidget);
      expect(find.text('Belanja bulanan'), findsNothing); // hanya 3 terbaru
      expect(find.text('−Rp 185.000'), findsOneWidget);
    });

    testWidgets('akun baru setelah Pengaturan Awal: belum ada transaksi',
        (tester) async {
      AuthRepository.instance.register(
        name: 'Sari Dewi',
        email: 'sari.dewi@example.com',
        password: 'Keluarga123',
      );
      await _loginAs(tester, 'sari.dewi@example.com', 'Keluarga123');

      await tester.enterText(find.byType(TextFormField).at(0), '8000000');
      await tester.enterText(find.byType(TextFormField).at(1), '4000000');
      await tester.enterText(find.byType(TextFormField).at(2), '1500000');
      await tester.enterText(find.byType(TextFormField).at(3), '1000000');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Halo, Sari!'), findsOneWidget);
      expect(find.text('Rp 1.500.000'), findsOneWidget);
      expect(find.text('Rp 0 dari Rp 1.500.000'), findsOneWidget);
      expect(find.text('Aman'), findsOneWidget);
      expect(find.textContaining('Belum ada transaksi'), findsOneWidget);
    });

    testWidgets('menu cepat memindahkan tab navigasi bawah', (tester) async {
      await _loginAs(tester, 'ilyas@example.com', 'Keluarga123');

      int selected() =>
          tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

      expect(selected(), 0);
      await tester.tap(find.text('Hasil & Analisis'));
      await tester.pumpAndSettle();
      expect(selected(), 2);

      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan Masa Depan'));
      await tester.pumpAndSettle();
      expect(selected(), 3);
    });

    testWidgets('tombol Keluar kembali ke Login', (tester) async {
      await _loginAs(tester, 'ilyas@example.com', 'Keluarga123');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(find.text('Selamat datang kembali'), findsOneWidget);
      expect(AuthRepository.instance.currentUser, isNull);
    });
  });
}
