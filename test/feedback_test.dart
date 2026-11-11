import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finfamily/data/auth_repository.dart';
import 'package:finfamily/data/family_repository.dart';
import 'package:finfamily/data/feedback_repository.dart';
import 'package:finfamily/data/finance_repository.dart';
import 'package:finfamily/data/transaction_repository.dart';
import 'package:finfamily/screens/main_shell.dart';
import 'package:finfamily/services/sentiment_service.dart';

const _ilyas = FamilyRepository.ilyas;
const _andi = FamilyRepository.andi;

class _FailingSentiment implements SentimentService {
  @override
  Future<Sentiment> analyze(String text) => throw Exception('layanan gagal');
}

FeedbackRepository get _repo => FeedbackRepository.instance;

Future<void> _openAs(WidgetTester tester, String email) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  AuthRepository.instance.login(email, 'Keluarga123');
  await tester.pumpWidget(const MaterialApp(home: MainShell()));
}

/// Anak membuka tab Umpan Balik (menu bawah).
Future<void> _openChildFeedback(WidgetTester tester) async {
  await _openAs(tester, _andi);
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text('Umpan Balik')),
  );
  await tester.pumpAndSettle();
}

Future<void> _write(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextFormField).first, text);
  await tester.pump();
}

Future<void> _send(WidgetTester tester) async {
  await tester.tap(find.text('Kirim Umpan Balik'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AuthRepository.instance.reset();
    FinanceRepository.instance.reset();
    TransactionRepository.instance.reset();
    FamilyRepository.instance.reset();
    FeedbackRepository.instance.reset();
    SentimentService.instance = const RuleBasedSentimentService();
  });

  group('Layanan sentimen', () {
    Future<Sentiment> analyze(String text) =>
        const RuleBasedSentimentService().analyze(text);

    test('positif, negatif, dan netral', () async {
      final positive = await analyze('Aplikasinya bagus dan membantu');
      expect(positive.label, SentimentLabel.positif);
      expect(positive.score, closeTo(0.8, 0.001));

      expect((await analyze('Aplikasinya lambat dan sering error')).label, SentimentLabel.negatif);
      expect((await analyze('Saya mencatat pengeluaran hari ini')).label, SentimentLabel.netral);
    });

    test('kalimat campuran tidak error dan tetap berlabel', () async {
      final result = await analyze('Bagus tapi lambat');
      expect(result.label, SentimentLabel.netral);
    });

    test('analyzeSafely mengembalikan null jika layanan gagal', () async {
      expect(await analyzeSafely(_FailingSentiment(), 'apa saja'), isNull);
    });
  });

  group('Ringkasan untuk tim pengembang', () {
    test('menghitung label dan rata-rata rating', () {
      final now = DateTime.now();
      _repo.add(FeedbackEntry(
        id: '1', authorEmail: _ilyas, text: 'bagus', createdAt: now, rating: 5,
        sentiment: const Sentiment(label: SentimentLabel.positif, score: 0.8),
      ));
      _repo.add(FeedbackEntry(
        id: '2', authorEmail: _andi, text: 'lambat', createdAt: now, rating: 2,
        sentiment: const Sentiment(label: SentimentLabel.negatif, score: 0.7),
      ));
      _repo.add(FeedbackEntry(id: '3', authorEmail: _ilyas, text: 'biasa', createdAt: now));

      final summary = _repo.summary();
      expect(summary.total, 3);
      expect(summary.positif, 1);
      expect(summary.negatif, 1);
      expect(summary.netral, 0);
      expect(summary.unlabeled, 1);
      expect(summary.averageRating, 3.5);
    });

    test('ekspor CSV memakai tanda kutip dan satu baris per umpan balik', () {
      _repo.add(FeedbackEntry(
        id: '1',
        authorEmail: _ilyas,
        text: 'Aplikasi "oke", bagus\nbanget',
        createdAt: DateTime.now(),
        rating: 4,
        sentiment: const Sentiment(label: SentimentLabel.positif, score: 0.8),
      ));
      final lines = _repo.exportCsv().split('\n');
      expect(lines.first, 'id,rating,label,score,teks');
      expect(lines.length, 2);
      expect(lines[1], '1,4,Positif,0.80,"Aplikasi ""oke"", bagus banget"');
    });
  });

  group('Layar Umpan Balik', () {
    testWidgets('Anak mengirim umpan balik positif dengan rating', (tester) async {
      await _openChildFeedback(tester);

      expect(find.text('Saran atau ulasan'), findsOneWidget);
      expect(find.text('0 / 500'), findsOneWidget);

      await _write(tester, 'Aplikasinya bagus dan membantu');
      await tester.tap(find.byTooltip('Beri 4 bintang'));
      await tester.pump();
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));

      await _send(tester);

      expect(find.textContaining('Terima kasih'), findsOneWidget);
      expect(_repo.all.length, 1);
      final entry = _repo.all.first;
      expect(entry.authorEmail, _andi);
      expect(entry.rating, 4);
      expect(entry.sentiment?.label, SentimentLabel.positif);

      // Label hanya untuk tim pengembang, tidak ditampilkan kepada pengguna.
      expect(find.text('Positif'), findsNothing);
      expect(find.text('0 / 500'), findsOneWidget); // form kembali kosong
    });

    testWidgets('umpan balik negatif tersimpan tanpa rating', (tester) async {
      await _openChildFeedback(tester);
      await _write(tester, 'Scan struk lambat dan sering error');
      await _send(tester);

      expect(_repo.all.first.sentiment?.label, SentimentLabel.negatif);
      expect(_repo.all.first.rating, isNull);
    });

    testWidgets('teks kosong ditolak', (tester) async {
      await _openChildFeedback(tester);
      await _send(tester);

      expect(find.text('Umpan balik tidak boleh kosong'), findsOneWidget);
      expect(_repo.all, isEmpty);
    });

    testWidgets('teks lebih dari 500 karakter ditolak', (tester) async {
      await _openChildFeedback(tester);
      await _write(tester, 'a' * 501);
      expect(find.text('501 / 500'), findsOneWidget);

      await _send(tester);
      expect(find.text('Umpan balik maksimal 500 karakter'), findsOneWidget);
      expect(_repo.all, isEmpty);
    });

    testWidgets('menekan bintang yang sama lagi menghapus rating', (tester) async {
      await _openChildFeedback(tester);
      await tester.tap(find.byTooltip('Beri 3 bintang'));
      await tester.pump();
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));

      await tester.tap(find.byTooltip('Beri 3 bintang'));
      await tester.pump();
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('layanan sentimen gagal: tetap tersimpan tanpa label', (tester) async {
      SentimentService.instance = _FailingSentiment();
      await _openChildFeedback(tester);
      await _write(tester, 'Aplikasinya bagus');
      await _send(tester);

      expect(find.textContaining('Terima kasih'), findsOneWidget);
      expect(_repo.all.length, 1);
      expect(_repo.all.first.sentiment, isNull);
      expect(_repo.summary().unlabeled, 1);
    });

    testWidgets('Kepala Keluarga membuka dari Beranda dan bisa kembali', (tester) async {
      await _openAs(tester, _ilyas);
      await tester.tap(find.text('Umpan Balik'));
      await tester.pumpAndSettle();

      expect(find.text('Kirim Umpan Balik'), findsOneWidget);
      await _write(tester, 'Mudah dipakai');
      await _send(tester);
      expect(_repo.all.first.authorEmail, _ilyas);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Halo, Ilyas!'), findsOneWidget);
    });

    testWidgets('Kepala Keluarga membuka dari tab Keluarga', (tester) async {
      await _openAs(tester, _ilyas);
      await tester.tap(find.text('Keluarga'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim Umpan Balik'));
      await tester.pumpAndSettle();

      expect(find.text('Saran atau ulasan'), findsOneWidget);
    });
  });
}
