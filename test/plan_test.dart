import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finfamily/data/auth_repository.dart';
import 'package:finfamily/data/finance_repository.dart';
import 'package:finfamily/data/plan_repository.dart';
import 'package:finfamily/data/transaction_repository.dart';
import 'package:finfamily/models/finance_setup.dart';
import 'package:finfamily/models/plan.dart';
import 'package:finfamily/screens/main_shell.dart';

const _rina = 'rina@example.com';

Plan _plan(int target, int years) => Plan(
      id: 'x',
      goal: PlanGoal.pendidikan,
      name: 'Uji',
      targetAmount: target,
      years: years,
    );

/// Akun dengan sisa uang bulanan Rp1.500.000 dan belum punya rencana.
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

Finder _field(int index) => find.byType(TextFormField).at(index);

Future<void> _openPlan(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: MainShell()));
  await tester.tap(find.text('Plan'));
  await tester.pumpAndSettle();
}

Future<void> _openForm(WidgetTester tester) async {
  await tester.tap(find.text('Tambah Rencana'));
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, {String name = 'Dana Kuliah Anak', required String target, required String years}) async {
  await tester.enterText(_field(0), name);
  await tester.enterText(_field(1), target);
  await tester.enterText(_field(2), years);
  await tester.pump();
}

void main() {
  setUp(() {
    AuthRepository.instance.reset();
    FinanceRepository.instance.reset();
    TransactionRepository.instance.reset();
    PlanRepository.instance.reset();
  });

  group('Hitungan Plan', () {
    test('tabungan per bulan sesuai test case', () {
      expect(_plan(150000000, 15).monthlySaving, 833333); // PLN_009
      expect(_plan(150000000, 5).monthlySaving, 2500000); // PLN_018 langkah 1
      expect(_plan(150000000, 10).monthlySaving, 1250000); // PLN_018 langkah 5
      expect(_plan(300000000, 15).monthlySaving, 1666667); // contoh desain
    });

    test('mencukupi atau tidak terhadap sisa uang Rp1.500.000', () {
      const sisa = 1500000;
      expect(PlanAssessment(plan: _plan(150000000, 15), sisa: sisa).sufficient, isTrue);
      expect(PlanAssessment(plan: _plan(150000000, 10), sisa: sisa).sufficient, isTrue);

      final tight = PlanAssessment(plan: _plan(150000000, 5), sisa: sisa);
      expect(tight.sufficient, isFalse);
      expect(tight.shortfall, 1000000);
      expect(tight.yearsNeeded, 9); // 9 tahun = Rp1.388.889 per bulan

      final house = PlanAssessment(plan: _plan(300000000, 15), sisa: sisa);
      expect(house.shortfall, 166667);
      expect(house.yearsNeeded, 17);
    });

    test('tanpa sisa uang tidak ada saran lama waktu', () {
      expect(PlanAssessment(plan: _plan(150000000, 5), sisa: 0).yearsNeeded, isNull);
    });
  });

  group('Layar Plan', () {
    testWidgets('akun Ilyas melihat rencana contoh yang belum cukup', (tester) async {
      AuthRepository.instance.login('ilyas@example.com', 'Keluarga123');
      await _openPlan(tester);

      expect(find.text('Tambah Rencana'), findsOneWidget);
      expect(find.text('Rumah Pertama'), findsOneWidget);
      expect(find.text('Belum cukup'), findsOneWidget);
      expect(find.text('Target Rp 300.000.000 · Rp 1.666.667 per bulan'), findsOneWidget);
    });

    testWidgets('PLN_009: pilihan tujuan, simpan, tampil di daftar, detail mencukupi',
        (tester) async {
      _prepareRina();
      await _openPlan(tester);
      expect(find.textContaining('Belum ada rencana'), findsOneWidget);

      await _openForm(tester);
      for (final goal in ['Dana pendidikan', 'Pembelian rumah', 'Dana pensiun', 'Lainnya']) {
        expect(find.text(goal), findsOneWidget, reason: goal);
      }

      await _fill(tester, target: '150000000', years: '15');
      expect(find.text('Rp 833.333'), findsOneWidget);
      expect(find.text('Rencana layak'), findsOneWidget);

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Rencana tersimpan.'), findsOneWidget);
      expect(find.text('Dana Kuliah Anak'), findsOneWidget);
      expect(find.text('Target Rp 150.000.000 · Rp 833.333 per bulan'), findsOneWidget);

      await tester.tap(find.text('Dana Kuliah Anak'));
      await tester.pumpAndSettle();
      expect(find.text('Detail rencana'), findsOneWidget);
      expect(find.textContaining('mencukupi untuk menabung Rp 833.333'), findsOneWidget);
      expect(find.textContaining('tidak mencukupi'), findsNothing);
      expect(find.text('Rp 1.500.000'), findsWidgets);
    });

    testWidgets('PLN_018: 5 tahun tidak mencukupi, ada saran, 10 tahun mencukupi',
        (tester) async {
      _prepareRina();
      await _openPlan(tester);
      await _openForm(tester);

      await _fill(tester, name: 'Kuliah Cepat', target: '150000000', years: '5');
      expect(find.text('Rp 2.500.000'), findsOneWidget);
      expect(find.text('Belum cukup'), findsOneWidget);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kuliah Cepat'));
      await tester.pumpAndSettle();
      expect(find.textContaining('tidak mencukupi'), findsWidgets);
      expect(find.textContaining('Sekunder atau Tersier'), findsOneWidget);
      expect(find.textContaining('perpanjang waktu menjadi 9 tahun'), findsOneWidget);
    });

    testWidgets('PLN_018: target waktu 0 ditolak, 10 tahun diterima', (tester) async {
      _prepareRina();
      await _openPlan(tester);
      await _openForm(tester);

      await _fill(tester, target: '150000000', years: '0');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Target waktu tidak valid'), findsOneWidget);
      expect(PlanRepository.instance.all(_rina), isEmpty);

      await tester.enterText(_field(2), '10');
      await tester.pump();
      expect(find.text('Rp 1.250.000'), findsOneWidget);
      expect(find.text('Rencana layak'), findsOneWidget);

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(PlanRepository.instance.all(_rina).length, 1);
    });

    testWidgets('isian kosong ditolak', (tester) async {
      _prepareRina();
      await _openPlan(tester);
      await _openForm(tester);

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Nama rencana wajib diisi'), findsOneWidget);
      expect(find.text('Target dana wajib diisi'), findsOneWidget);
      expect(find.text('Target waktu wajib diisi'), findsOneWidget);
      expect(PlanRepository.instance.all(_rina), isEmpty);
    });
  });
}
