import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/finance_repository.dart';
import '../data/income_repository.dart';
import '../data/notification_repository.dart';
import '../data/plan_repository.dart';
import '../data/session.dart';
import '../data/transaction_repository.dart';
import '../models/plan.dart';
import '../models/usage_status.dart';
import '../services/budget_service.dart';
import '../services/financial_classifier.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_labels.dart';
import '../utils/rupiah.dart';
import '../widgets/app_background.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/financial_insight_card.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/transaction_tile.dart';
import 'feedback_screen.dart';
import 'history_screen.dart';
import 'income_screen.dart';
import 'login_screen.dart';
import 'notification_screen.dart';
import 'setup_screen.dart';

/// Beranda Kepala Keluarga dan Pasangan: sisa uang bebas belanja, status
/// pemakaian batas, aksi cepat, pengingat, transaksi terbaru, dan target Plan.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Pindah tab pada MainShell (1 Transaksi, 2 Analisis, 3 Plan).
  final ValueChanged<int> onNavigate;

  bool get _isKepala => Session.role == FamilyRole.kepala;

  void _logout(BuildContext context) {
    AuthRepository.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const SetupScreen(editMode: true),
      ),
    );
  }

  void _openFeedback(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FeedbackScreen(showBack: true),
      ),
    );
  }

  void _onMenu(BuildContext context, String value) {
    switch (value) {
      case 'pengaturan':
        _openSettings(context);
      case 'umpan_balik':
        _openFeedback(context);
      case 'keluar':
        _logout(context);
    }
  }

  Future<void> _openIncome(BuildContext context) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const IncomeScreen()));
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Pemasukan tersimpan. Batas belanja diperbarui.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        TransactionRepository.instance,
        IncomeRepository.instance,
        FinanceRepository.instance,
        PlanRepository.instance,
        NotificationRepository.instance,
        FamilyRepository.instance,
      ]),
      builder: (context, _) => _buildContent(context),
    );
  }

  /// Tip di hero card: sisa batas dibagi hari yang tersisa di bulan ini.
  String? _tip({
    required UsageSummary summary,
    required BudgetSnapshot budget,
    required int remaining,
    required DateTime now,
  }) {
    if (budget.overAllocated) {
      return 'Alokasi Plan melebihi uang bulanan, jadi batas belanja jadi Rp 0. Atur ulang Plan.';
    }
    if (summary.limit <= 0) {
      return _isKepala
          ? 'Batas belanja belum ada. Lengkapi Pengaturan Keuangan dulu.'
          : 'Batas belanja belum ada. Minta Kepala Keluarga melengkapi Pengaturan Keuangan.';
    }
    if (summary.status == UsageStatus.melebihi) {
      return 'Pengeluaran sudah melewati batas bulan ini. Tahan dulu belanja Sekunder dan Tersier.';
    }
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final perDay = remaining ~/ daysLeft;
    final base =
        'Tersisa ${formatRupiah(remaining)} untuk $daysLeft hari ke depan '
        '(sekitar ${formatRupiah(perDay)} per hari).';
    final advice = switch (summary.status) {
      UsageStatus.aman => 'Pengeluaran masih terkendali.',
      UsageStatus.waspada => 'Disarankan rem jajan santai ya!',
      UsageStatus.merah => 'Batas hampir habis, rem belanja Sekunder dan Tersier.',
      UsageStatus.melebihi => '',
    };
    return '$base $advice';
  }

  Widget _buildContent(BuildContext context) {
    final now = DateTime.now();
    final space = Session.spaceId;
    final finance = FinanceRepository.instance.of(space);
    final repo = TransactionRepository.instance;
    final transactions = repo.all(space);
    final budget = BudgetService.of(space);
    final summary = UsageSummary(
      used: repo.usedLimitInMonth(space, now),
      limit: budget.limit,
    );
    final remaining = budget.limit - summary.used;
    final insight = finance == null
        ? null
        : FinancialClassifier.instance.assess(finance.setup);
    final notifications = NotificationService.instance.forSpace(space, now);
    final unread = NotificationRepository.instance.unreadCount(
      space,
      notifications,
    );

    final first = (AuthRepository.instance.currentUser?.name ?? '')
        .trim()
        .split(' ')
        .first;
    final owner = AuthRepository.instance.nameOf(space).trim().split(' ').first;

    final openPlans = [
      for (final p in PlanRepository.instance.all(space))
        if (p.saved < p.targetAmount) p,
    ]..sort((a, b) => a.deadline.compareTo(b.deadline));
    final target = openPlans.isEmpty ? null : openPlans.first;

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: AppBackground()),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeHeader(
                      greeting: 'Halo, ${first.isEmpty ? 'Keluarga' : first}!',
                      subtitle: owner.isEmpty
                          ? 'Kelola keuangan bersama'
                          : 'Keluarga $owner',
                      roleLabel: Session.role.label,
                      initial: first.isEmpty ? 'K' : first[0].toUpperCase(),
                      unread: unread,
                      onNotifications: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              NotificationScreen(onNavigate: onNavigate),
                        ),
                      ),
                      menuItems: <PopupMenuEntry<String>>[
                        if (_isKepala)
                          const PopupMenuItem<String>(
                            value: 'pengaturan',
                            child: Text('Pengaturan Keuangan'),
                          ),
                        const PopupMenuItem<String>(
                          value: 'umpan_balik',
                          child: Text('Umpan Balik'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'keluar',
                          child: Text('Keluar'),
                        ),
                      ],
                      onMenuSelected: (value) => _onMenu(context, value),
                    ),
                    const SizedBox(height: 18),
                    BalanceHeroCard(
                      title: 'Sisa Uang Bebas Belanja',
                      remaining: remaining,
                      used: summary.used,
                      limit: budget.limit,
                      ratio: summary.ratio,
                      monthLabel: monthName(now),
                      statusText: summary.status.label,
                      infos: [
                        HeroInfo(
                          label: 'Pemasukan tambahan',
                          value: budget.extra,
                        ),
                        HeroInfo(
                          label: 'Alokasi Plan',
                          value: budget.planAllocation,
                        ),
                      ],
                      tip: _tip(
                        summary: summary,
                        budget: budget,
                        remaining: remaining,
                        now: now,
                      ),
                    ),
                    if (finance == null) ...[
                      const SizedBox(height: 12),
                      _buildSetupCta(context),
                    ],
                    const SizedBox(height: 22),
                    const Text(
                      'Aksi Cepat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.add_rounded,
                              label: 'Catat Transaksi',
                              caption: 'Pengeluaran',
                              onTap: () => onNavigate(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.bar_chart_rounded,
                              label: 'Hasil & Analisis',
                              caption: 'Kesehatan kas',
                              onTap: () => onNavigate(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.calendar_month_outlined,
                              label: 'Plan Masa Depan',
                              caption: 'Tabungan impian',
                              onTap: () => onNavigate(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildIncomeButton(context),
                    if (insight != null && insight.hasData) ...[
                      const SizedBox(height: 14),
                      FinancialInsightCard(insight: insight),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Transaksi terbaru',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const HistoryScreen(),
                            ),
                          ),
                          child: const Text(
                            'Lihat semua',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (transactions.isEmpty)
                      _buildEmpty()
                    else
                      for (final item in transactions.take(3)) ...[
                        TransactionTile(
                          transaction: item,
                          dateText: _dateWithAuthor(item.date, item.authorEmail, now),
                        ),
                        const SizedBox(height: 10),
                      ],
                    if (target != null) ...[
                      const SizedBox(height: 14),
                      _buildTargetCard(target),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// "Hari ini · Ilyas": tanggal relatif + nama pencatat (jika tercatat).
  String _dateWithAuthor(DateTime date, String authorEmail, DateTime now) {
    final day = relativeDay(date, now);
    if (authorEmail.isEmpty) return day;
    final name = AuthRepository.instance.nameOf(authorEmail).trim().split(' ').first;
    return name.isEmpty ? day : '$day · $name';
  }

  Widget _buildSetupCta(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengaturan keuangan belum diisi.',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isKepala
                ? 'Isi gaji, kebutuhan, dan cicilan supaya batas belanja bisa dihitung.'
                : 'Minta Kepala Keluarga mengisi pengaturan keuangan agar batas belanja bisa dihitung.',
            style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.body),
          ),
          if (_isKepala) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _openSettings(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentDeep,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.primary, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Lengkapi Pengaturan'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomeButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _openIncome(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.accentDeep,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.fieldBorder, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      icon: const Icon(Icons.add_card_rounded, size: 20),
      label: const Text('Ada Pemasukan Tambahan?'),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: const Text(
        'Belum ada transaksi. Mulai dengan Catat Transaksi.',
        style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.body),
      ),
    );
  }

  /// Rencana dengan tenggat terdekat yang belum tercapai.
  Widget _buildTargetCard(Plan plan) {
    final percent = (plan.progress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: AppColors.accentDeep,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target terdekat: ${plan.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: plan.progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatRupiah(plan.saved)} dari ${formatRupiah(plan.targetAmount)} ($percent%)',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.body),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => onNavigate(3),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDeep,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Detail'),
          ),
        ],
      ),
    );
  }
}