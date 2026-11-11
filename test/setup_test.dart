import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finfamily/data/auth_repository.dart';
import 'package:finfamily/data/finance_repository.dart';
import 'package:finfamily/screens/setup_screen.dart';
import 'package:finfamily/services/recommendation_service.dart';
import 'package:finfamily/models/finance_setup.dart';

Finder _field(int index) => find.byType(TextFormField).at(index);

Future<void> _openSetup(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  AuthRepository.instance.register(
    name: 'Sari Dewi',
    email: 'sari.dewi@example.com',
    password: 'Keluarga123',
  );
  AuthRepository.instance.login('sari.dewi@example.com', 'Keluarga123');
  await tester.pumpWidget(const MaterialApp(home: SetupScreen()));
}

Future<void> _fillValid(WidgetTester tester) async {
  await tester.enterText(_field(0), '8000000');
  await tester.enterText(_field(1), '4000000');
  await tester.enterText(_field(2), '1500000');
  await tester.enterText(_field(3), '1000000');
  await tester.pump();
}

class _FailingService implements RecommendationService {
  @override
  Future<Recommendation> recommend(FinanceSetup setup) =>
      throw Exception('layanan gagal');
}

void main() {
  setUp(() {
    AuthRepository.instance.reset();
    FinanceRepository.instance.reset();
    RecommendationService.instance = const DefaultRecommendationService();
  });

  testWidgets('form tampil tanpa meminta membuat keluarga (SET_003)', (
    tester,
  ) async {
    await _openSetup(tester);

    expect(find.text('Atur keuangan bulananmu'), findsOneWidget);
    expect(find.text('Gaji per bulan'), findsOneWidget);
    expect(find.text('Tabungan per bulan'), findsOneWidget);
    expect(find.textContaining('Undang'), findsNothing);
    expect(find.textContaining('keluarga baru'), findsNothing);
  });

  testWidgets('nominal tampil format rupiah dan sisa dihitung otomatis', (
    tester,
  ) async {
    await _openSetup(tester);
    await _fillValid(tester);

    expect(find.text('8.000.000'), findsOneWidget);
    expect(find.text('Rp 1.500.000'), findsOneWidget);
    expect(find.text('Sekunder'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('simpan: notifikasi muncul lalu ke Beranda', (tester) async {
    await _openSetup(tester);
    await _fillValid(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Sari!'), findsOneWidget);
    expect(find.textContaining('Data keuangan tersimpan'), findsOneWidget);
    expect(AuthRepository.instance.currentUser?.setupDone, isTrue);
    expect(
      FinanceRepository.instance.of('sari.dewi@example.com')?.setup.sisa,
      1500000,
    );
  });

  testWidgets('gaji kosong ditolak (SET_013 langkah 1)', (tester) async {
    await _openSetup(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Gaji wajib diisi'), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);
  });

  testWidgets('huruf pada gaji ditolak (SET_013 langkah 2)', (tester) async {
    await _openSetup(tester);

    await tester.enterText(_field(0), 'abc');
    await tester.pump();

    final editable = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(editable.controller.text, '');
  });

  testWidgets('gaji negatif ditolak (SET_013 langkah 3)', (tester) async {
    await _openSetup(tester);

    await tester.enterText(_field(0), '-500000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Gaji harus lebih dari 0'), findsOneWidget);
  });

  testWidgets(
    'cicilan melebihi gaji memunculkan peringatan (SET_013 langkah 4)',
    (tester) async {
      await _openSetup(tester);

      await tester.enterText(_field(0), '8000000');
      await tester.enterText(_field(2), '9000000');
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('melebihi pemasukan'), findsWidgets);
      expect(find.text('Perbaiki'), findsOneWidget);
      expect(find.text('Tetap simpan'), findsOneWidget);
    },
  );

  testWidgets('jika layanan rekomendasi gagal, pembagian bawaan dipakai', (
    tester,
  ) async {
    RecommendationService.instance = _FailingService();
    await _openSetup(tester);
    await _fillValid(tester);

    expect(find.text('75%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('mode sunting: isian terisi data lama dan bisa diperbarui', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    AuthRepository.instance.login('ilyas@example.com', 'Keluarga123');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => const SetupScreen(editMode: true),
                ),
              ),
              child: const Text('buka pengaturan'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka pengaturan'));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan Keuangan'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(find.text('8.000.000'), findsOneWidget);

    await tester.enterText(_field(0), '10000000');
    await tester.pump();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(
      FinanceRepository.instance.of('ilyas@example.com')?.setup.gaji,
      10000000,
    );
    expect(find.text('buka pengaturan'), findsOneWidget);
  });
}
