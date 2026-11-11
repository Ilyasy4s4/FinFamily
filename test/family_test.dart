import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finfamily/data/auth_repository.dart';
import 'package:finfamily/data/family_repository.dart';
import 'package:finfamily/data/finance_repository.dart';
import 'package:finfamily/data/session.dart';
import 'package:finfamily/data/transaction_repository.dart';
import 'package:finfamily/models/transaction.dart';
import 'package:finfamily/screens/main_shell.dart';

const _ilyas = FamilyRepository.ilyas;
const _siti = FamilyRepository.siti;
const _andi = FamilyRepository.andi;
const _dewi = 'dewi.lestari@example.com';

FamilyRepository get _family => FamilyRepository.instance;

void _register(String name, String email) {
  AuthRepository.instance.register(name: name, email: email, password: 'Keluarga123');
}

Future<void> _open(WidgetTester tester, String email, {String? tab}) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  AuthRepository.instance.login(email, 'Keluarga123');
  await tester.pumpWidget(const MaterialApp(home: MainShell()));
  if (tab != null) {
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }
}

Transaction _tx(String id, int amount, String author, {bool personal = false}) {
  final now = DateTime.now();
  return Transaction(
    id: id,
    name: 'Item $id',
    amount: amount,
    kategori: Kategori.primer,
    date: DateTime(now.year, now.month, now.day),
    authorEmail: author,
    isPersonal: personal,
  );
}

void main() {
  setUp(() {
    AuthRepository.instance.reset();
    FinanceRepository.instance.reset();
    TransactionRepository.instance.reset();
    FamilyRepository.instance.reset();
  });

  group('Kode undangan dan gabung', () {
    test('kode berformat SMART-xxxxx dan berlaku 7 hari (INV_004)', () {
      final invite = _family.createInvite(_ilyas, FamilyRole.pasangan);
      expect(invite.code, startsWith('SMART-'));
      expect(invite.code.length, 11);
      expect(invite.expiresAt.difference(invite.createdAt).inDays, 7);
    });

    test('kode valid: bergabung dengan peran dari kode, hanya sekali pakai', () {
      _register('Dewi', _dewi);
      _family.codeGenerator = () => 'SMART-7K2P9';
      _family.createInvite(_ilyas, FamilyRole.anak);

      expect(_family.join(_dewi, 'smart-7k2p9'), JoinResult.ok);
      expect(_family.roleOf(_dewi), FamilyRole.anak);
      expect(_family.spaceOf(_dewi), _ilyas);
      expect(_family.membersOf(_ilyas), contains(_dewi));

      expect(_family.join(_siti, 'SMART-7K2P9'), JoinResult.invalid); // sudah terpakai
    });

    test('kode salah ditolak (INV_014 langkah 1)', () {
      _register('Dewi', _dewi);
      expect(_family.join(_dewi, 'SMART-00000'), JoinResult.invalid);
      expect(_family.isMember(_dewi), isFalse);
    });

    test('kode lebih dari 7 hari kedaluwarsa (INV_014 langkah 2)', () {
      _register('Dewi', _dewi);
      _family.codeGenerator = () => 'SMART-OLD22';
      _family.createInvite(
        _ilyas,
        FamilyRole.pasangan,
        now: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(_family.join(_dewi, 'SMART-OLD22'), JoinResult.expired);
      expect(_family.isMember(_dewi), isFalse);
    });

    test('akun yang sudah tergabung ditolak (INV_014 langkah 3)', () {
      _register('Dewi', _dewi);
      _family.codeGenerator = () => 'SMART-OTH11';
      _family.createInvite(_dewi, FamilyRole.pasangan); // keluarga lain
      expect(_family.join(_siti, 'SMART-OTH11'), JoinResult.alreadyMember);
    });

    test('hapus anggota: kembali ke ruang pribadi (INV_014 langkah 4-5)', () {
      _family.removeMember(_ilyas, _siti);
      expect(_family.membersOf(_ilyas), [_ilyas, _andi]);
      expect(_family.spaceOf(_siti), _siti);
      expect(_family.roleOf(_siti), FamilyRole.kepala);
    });

    test('ubah peran Anak menjadi Pasangan (ROL_010 langkah 5)', () {
      _family.changeRole(_ilyas, _andi, FamilyRole.pasangan);
      expect(_family.roleOf(_andi), FamilyRole.pasangan);
    });

    test('data pribadi tidak ikut dan kembali utuh (GAB_021)', () {
      _register('Dewi', _dewi);
      final repo = TransactionRepository.instance;
      repo.add(_dewi, _tx('sayur', 50000, _dewi));

      _family.codeGenerator = () => 'SMART-7K2P9';
      _family.createInvite(_ilyas, FamilyRole.anak);
      _family.join(_dewi, 'SMART-7K2P9');

      expect(_family.spaceOf(_dewi), _ilyas); // bekerja di ruang keluarga
      expect(repo.all(_ilyas).any((t) => t.id == 'sayur'), isFalse);

      _family.removeMember(_ilyas, _dewi);
      expect(_family.spaceOf(_dewi), _dewi);
      expect(repo.all(_dewi).map((t) => t.id), ['sayur']);
    });
  });

  group('Tab Keluarga', () {
    testWidgets('mandiri: hanya diri sendiri, undang opsional dan bisa dibatalkan (RUA_019)',
        (tester) async {
      _register('Rina', 'rina@example.com');
      await _open(tester, 'rina@example.com', tab: 'Keluarga');

      expect(find.text('Rina (Kamu)'), findsOneWidget);
      expect(find.text('Kepala Keluarga · akses penuh'), findsOneWidget);

      await tester.tap(find.text('Undang Anggota'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(_family.activeInviteCount('rina@example.com'), 0);
      expect(_family.membersOf('rina@example.com'), ['rina@example.com']);
    });

    testWidgets('Kepala Keluarga membuat kode undangan lalu anggota tampil (INV_004)',
        (tester) async {
      _register('Rina', 'rina@example.com');
      _register('Dewi', _dewi);
      _family.codeGenerator = () => 'SMART-7K2P9';
      await _open(tester, 'rina@example.com', tab: 'Keluarga');

      await tester.tap(find.text('Undang Anggota'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih peran anggota yang akan diundang.'), findsOneWidget);
      await tester.tap(find.text('Anak'));
      await tester.pump();
      await tester.tap(find.text('Buat Kode Undangan'));
      await tester.pumpAndSettle();

      expect(find.text('SMART-7K2P9'), findsOneWidget);
      expect(find.text('Berlaku 7 hari'), findsOneWidget);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      _family.join(_dewi, 'SMART-7K2P9');
      await tester.pumpAndSettle();

      expect(find.text('Dewi'), findsOneWidget);
      expect(find.text('Anak · jatah belum ditetapkan'), findsOneWidget);
    });

    testWidgets('form Gabung Keluarga menampilkan pesan kesalahan (INV_014)',
        (tester) async {
      _register('Dewi', _dewi);
      await _open(tester, _dewi, tab: 'Keluarga');
      expect(find.textContaining('pindah ke ruang keluarga'), findsOneWidget);

      await tester.tap(find.text('Gabung'));
      await tester.pumpAndSettle();
      expect(find.text('Kode undangan wajib diisi'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'SMART-00000');
      await tester.tap(find.text('Gabung'));
      await tester.pumpAndSettle();
      expect(find.text('Kode undangan tidak valid'), findsOneWidget);
    });

    testWidgets('kode kedaluwarsa dan sudah tergabung', (tester) async {
      _register('Dewi', _dewi);
      _family.codeGenerator = () => 'SMART-OLD22';
      _family.createInvite(
        _ilyas,
        FamilyRole.pasangan,
        now: DateTime.now().subtract(const Duration(days: 8)),
      );
      await _open(tester, _dewi, tab: 'Keluarga');

      await tester.enterText(find.byType(TextFormField).first, 'SMART-OLD22');
      await tester.tap(find.text('Gabung'));
      await tester.pumpAndSettle();
      expect(find.text('Kode undangan sudah kedaluwarsa'), findsOneWidget);
      expect(_family.isMember(_dewi), isFalse);
    });

    testWidgets('Pasangan melihat daftar tanpa tombol kelola (ROL_010 langkah 2)',
        (tester) async {
      await _open(tester, _siti, tab: 'Keluarga');

      expect(find.text('Siti Santoso (Kamu)'), findsOneWidget);
      expect(find.text('Undang Anggota'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('bergabung sebagai Anak: menu berubah menjadi tiga (GAB_021)',
        (tester) async {
      _register('Dewi', _dewi);
      _family.codeGenerator = () => 'SMART-7K2P9';
      _family.createInvite(_ilyas, FamilyRole.anak);
      await _open(tester, _dewi, tab: 'Keluarga');

      await tester.enterText(find.byType(TextFormField).first, 'SMART-7K2P9');
      await tester.tap(find.text('Gabung'));
      await tester.pumpAndSettle();

      expect(Session.role, FamilyRole.anak);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations.length, 3);
      expect(find.text('Sisa Jatah Bulan Ini'), findsOneWidget);
      expect(find.text('Jatah belum ditetapkan oleh Kepala Keluarga.'), findsOneWidget);
    });
  });

  group('Kepala Keluarga mengelola anggota', () {
    Future<void> openMenu(WidgetTester tester, int index, String item) async {
      await tester.tap(find.byIcon(Icons.more_vert).at(index));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item));
      await tester.pumpAndSettle();
    }

    testWidgets('daftar anggota dengan peran dan jatah', (tester) async {
      await _open(tester, _ilyas, tab: 'Keluarga');

      expect(find.text('Ilyas (Kamu)'), findsOneWidget);
      expect(find.text('Siti Santoso'), findsOneWidget);
      expect(find.text('Andi Santoso'), findsOneWidget);
      expect(find.text('Pasangan · mencatat transaksi, laporan, dan Plan'), findsOneWidget);
      expect(find.text('Anak · jatah Rp 1.000.000 per bulan'), findsOneWidget);
    });

    testWidgets('atur jatah Anak Rp1.500.000 (ROL_020 langkah 1)', (tester) async {
      await _open(tester, _ilyas, tab: 'Keluarga');
      await openMenu(tester, 1, 'Atur jatah'); // anggota ke-2: Andi

      await tester.enterText(
        find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField)),
        '1500000',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(_family.jatahOf(_andi), 1500000);
      expect(find.text('Anak · jatah Rp 1.500.000 per bulan'), findsOneWidget);
    });

    testWidgets('pantau Anak: jatah dan riwayat tampil (ROL_020 langkah 4)', (tester) async {
      await _open(tester, _ilyas, tab: 'Keluarga');
      await openMenu(tester, 1, 'Pantau');

      expect(find.text('Pantau Andi Santoso'), findsOneWidget);
      expect(find.text('Terpakai Rp 450.000 dari jatah Rp 1.000.000'), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);
      expect(find.text('Boba'), findsOneWidget);
    });

    testWidgets('ubah peran Anak menjadi Pasangan (ROL_010 langkah 5)', (tester) async {
      await _open(tester, _ilyas, tab: 'Keluarga');
      await openMenu(tester, 1, 'Ubah peran');
      await tester.tap(find.text('Pasangan'));
      await tester.pumpAndSettle();

      expect(_family.roleOf(_andi), FamilyRole.pasangan);
    });

    testWidgets('hapus anggota: hilang dari daftar dan kembali ke ruang pribadi (INV_014)',
        (tester) async {
      await _open(tester, _ilyas, tab: 'Keluarga');
      await openMenu(tester, 0, 'Hapus anggota'); // anggota ke-1: Siti
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Siti Santoso'), findsNothing);
      expect(_family.membersOf(_ilyas), [_ilyas, _andi]);
      expect(_family.spaceOf(_siti), _siti);
    });
  });

  group('Tampilan Anak (ROL_010, ROL_020)', () {
    testWidgets('hanya jatah dan transaksi pribadi, tanpa data keluarga', (tester) async {
      await _open(tester, _andi);

      expect(find.text('Halo, Andi!'), findsOneWidget);
      expect(find.text('Sisa Jatah Bulan Ini'), findsOneWidget);
      expect(find.text('Rp 550.000'), findsOneWidget);
      expect(find.text('Terpakai Rp 450.000'), findsOneWidget);
      expect(find.text('Jatah Rp 1.000.000'), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);

      // Penghasilan dan aset keluarga tidak tampil.
      expect(find.text('Sisa Uang Bebas Belanja'), findsNothing);
      expect(find.text('Rp 1.500.000'), findsNothing);
      expect(find.text('Beras dan minyak'), findsNothing);
    });

    testWidgets('menu anggota, Plan, dan Analisis tidak ditampilkan', (tester) async {
      await _open(tester, _andi);

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations.length, 3);
      expect(find.text('Keluarga'), findsNothing);
      expect(find.text('Plan'), findsNothing);
      expect(find.text('Analisis'), findsNothing);
    });

    testWidgets('pengeluaran 80% dari jatah menampilkan peringatan waspada', (tester) async {
      _family.setJatah(_andi, 1500000);
      TransactionRepository.instance.add(_ilyas, _tx('x1', 750000, _andi, personal: true));
      await _open(tester, _andi);

      expect(find.text('Terpakai Rp 1.200.000'), findsOneWidget);
      expect(find.text('Waspada 70%'), findsOneWidget);
      expect(find.textContaining('80% dari jatah'), findsOneWidget);
    });

    testWidgets('transaksi Anak tidak masuk hitungan batas keluarga', (tester) async {
      TransactionRepository.instance.add(_ilyas, _tx('x2', 300000, _andi, personal: true));
      final repo = TransactionRepository.instance;

      expect(repo.usedLimitInMonth(_ilyas, DateTime.now()), 1050000); // tetap
      expect(repo.all(_ilyas).any((t) => t.id == 'x2'), isFalse);
      expect(repo.all(_ilyas, memberEmail: _andi).any((t) => t.id == 'x2'), isTrue);
    });
  });
}
