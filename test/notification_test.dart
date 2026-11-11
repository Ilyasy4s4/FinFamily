import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finfamily/data/auth_repository.dart';
import 'package:finfamily/data/finance_repository.dart';
import 'package:finfamily/data/notification_repository.dart';
import 'package:finfamily/data/plan_repository.dart';
import 'package:finfamily/data/transaction_repository.dart';
import 'package:finfamily/models/app_notification.dart';
import 'package:finfamily/models/finance_setup.dart';
import 'package:finfamily/models/plan.dart';
import 'package:finfamily/models/usage_status.dart';
import 'package:finfamily/screens/notification_screen.dart';
import 'package:finfamily/services/notification_service.dart';

const _service = NotificationService();
final _month = DateTime(2026, 11, 1);
const _setup = FinanceSetup(
  gaji: 8000000,
  kebutuhan: 4000000,
  cicilan: 1500000,
  tabungan: 1000000,
);

void main() {
  setUp(() => NotificationRepository.instance.reset());

  test('pemakaian 90 persen memunculkan pengingat bahaya', () {
    final items = _service.build(
      month: _month,
      summary: const UsageSummary(used: 1350000, limit: 1500000),
      setup: _setup,
      plans: const [],
      extraLimit: 0,
    );

    final item = items.firstWhere((n) => n.id == 'budget-2026-11-90');
    expect(item.level, AppNotificationLevel.danger);
    expect(item.actionTab, 2);
  });

  test('pemakaian di bawah 70 persen tidak memunculkan peringatan batas', () {
    final items = _service.build(
      month: _month,
      summary: const UsageSummary(used: 300000, limit: 1500000),
      setup: _setup,
      plans: const [],
      extraLimit: 0,
    );

    expect(items.any((n) => n.id.startsWith('budget-')), isFalse);
    expect(items.first.id, 'safe-2026-11');
  });

  test('plan yang belum cukup memberi saran perpanjang waktu', () {
    const plan = Plan(
      id: 'p1',
      goal: PlanGoal.rumah,
      name: 'Rumah Pertama',
      targetAmount: 300000000,
      years: 15,
    );

    final items = _service.build(
      month: _month,
      summary: const UsageSummary(used: 0, limit: 1500000),
      setup: _setup,
      plans: const [plan],
      extraLimit: 0,
    );

    final item = items.firstWhere((n) => n.id == 'plan-p1');
    expect(item.level, AppNotificationLevel.warning);
    expect(item.message, contains('perpanjang'));
    expect(item.actionTab, 3);
  });

  test('status sudah dibaca disimpan per ruang', () {
    final repo = NotificationRepository.instance;

    expect(repo.isRead('a@example.com', 'x'), isFalse);
    repo.markRead('a@example.com', 'x');
    expect(repo.isRead('a@example.com', 'x'), isTrue);
    expect(repo.isRead('b@example.com', 'x'), isFalse);

    final items = [
      const AppNotification(
        id: 'x',
        title: 'Satu',
        message: 'Pesan',
        level: AppNotificationLevel.info,
      ),
      const AppNotification(
        id: 'y',
        title: 'Dua',
        message: 'Pesan',
        level: AppNotificationLevel.info,
      ),
    ];
    expect(repo.unreadCount('a@example.com', items), 1);
    repo.markAllRead('a@example.com', items.map((item) => item.id));
    expect(repo.unreadCount('a@example.com', items), 0);
  });

  testWidgets('layar notifikasi menampilkan pengingat dan bisa ditandai', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    AuthRepository.instance.reset();
    FinanceRepository.instance.reset();
    TransactionRepository.instance.reset();
    PlanRepository.instance.reset();
    AuthRepository.instance.login('ilyas@example.com', 'Keluarga123');

    await tester.pumpWidget(const MaterialApp(home: NotificationScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Plan Rumah Pertama belum tercapai'), findsOneWidget);

    await tester.tap(find.text('Tandai semua dibaca'));
    await tester.pumpAndSettle();

    expect(find.text('Semua pengingat sudah dibaca.'), findsOneWidget);
  });
}
