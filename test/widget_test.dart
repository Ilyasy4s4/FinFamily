import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finfamily/data/auth_repository.dart';
import 'package:finfamily/data/finance_repository.dart';
import 'package:finfamily/main.dart';

void _phoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Finder _field(int index) => find.byType(TextFormField).at(index);

void main() {
  setUp(() {
    AuthRepository.instance.reset();
    FinanceRepository.instance.reset();
  });

  group('Login', () {
    testWidgets('menampilkan elemen utama', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(const FinFamilyApp());

      expect(find.text('Selamat datang kembali'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
    });

    testWidgets('password bisa ditampilkan dan disembunyikan', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(const FinFamilyApp());

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('form kosong menampilkan pesan wajib diisi', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(const FinFamilyApp());

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });

    testWidgets('email format salah ditolak', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(const FinFamilyApp());

      await tester.enterText(_field(0), 'ilyas.santoso@');
      await tester.enterText(_field(1), 'Keluarga123');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid'), findsOneWidget);
    });

    testWidgets('akun salah menampilkan Email atau password salah', (
      tester,
    ) async {
      _phoneScreen(tester);
      await tester.pumpWidget(const FinFamilyApp());

      await tester.enterText(_field(0), 'ilyas@example.com');
      await tester.enterText(_field(1), 'Salah12345');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Email atau password salah'), findsOneWidget);
    });

    testWidgets('akun lama masuk ke Beranda', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(const FinFamilyApp());

      await tester.enterText(_field(0), 'ilyas@example.com');
      await tester.enterText(_field(1), 'Keluarga123');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Halo, Ilyas!'), findsOneWidget);
    });
  });

  group('Registrasi', () {
    Future<void> openRegister(WidgetTester tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(const FinFamilyApp());
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
    }

    testWidgets('tombol Daftar membuka halaman Buat akun', (tester) async {
      await openRegister(tester);

      expect(find.text('Buat akun'), findsOneWidget);
      expect(find.text('Konfirmasi password'), findsOneWidget);
      expect(
        find.textContaining('Kepala Keluarga', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('data tidak valid ditolak (REG_011)', (tester) async {
      await openRegister(tester);

      await tester.enterText(_field(0), 'Ilyas');
      await tester.enterText(_field(1), 'ilyas.santoso@');
      await tester.enterText(_field(2), 'abc12');
      await tester.enterText(_field(3), 'abc13');
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid'), findsOneWidget);
      expect(find.text('Password minimal 8 karakter'), findsOneWidget);
      expect(find.text('Konfirmasi password tidak sama'), findsOneWidget);
    });

    testWidgets('email yang sudah terdaftar ditolak', (tester) async {
      await openRegister(tester);

      await tester.enterText(_field(0), 'Ilyas');
      await tester.enterText(_field(1), 'ilyas@example.com');
      await tester.enterText(_field(2), 'Keluarga123');
      await tester.enterText(_field(3), 'Keluarga123');
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Email sudah terdaftar'), findsOneWidget);
    });

    testWidgets(
      'registrasi berhasil kembali ke Login lalu ke Pengaturan Awal',
      (tester) async {
        await openRegister(tester);

        await tester.enterText(_field(0), 'Sari Dewi');
        await tester.enterText(_field(1), 'sari.dewi@example.com');
        await tester.enterText(_field(2), 'Keluarga123');
        await tester.enterText(_field(3), 'Keluarga123');
        await tester.tap(find.text('Daftar'));
        await tester.pumpAndSettle();

        // Kembali ke Login dengan email terisi.
        expect(find.text('Selamat datang kembali'), findsOneWidget);
        expect(
          find.text('Registrasi berhasil. Silakan masuk.'),
          findsOneWidget,
        );
        expect(find.text('sari.dewi@example.com'), findsOneWidget);

        await tester.enterText(_field(1), 'Keluarga123');
        await tester.tap(find.text('Masuk'));
        await tester.pumpAndSettle();

        // Akun baru diarahkan ke Pengaturan Awal.
        expect(find.text('Pengaturan Awal'), findsOneWidget);
      },
    );
  });
}
