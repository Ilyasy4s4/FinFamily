import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/session.dart';
import '../data/transaction_repository.dart';
import '../models/transaction.dart';
import '../models/usage_status.dart';
import '../theme/app_colors.dart';
import '../theme/status_style.dart';
import '../utils/date_labels.dart';
import '../utils/rupiah.dart';
import '../widgets/app_background.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/transaction_tile.dart';
import 'history_screen.dart';
import 'login_screen.dart';

/// Beranda untuk peran Anak: hanya jatah dan transaksi pribadi,
/// tanpa penghasilan dan aset keluarga (ROL_010, ROL_020).
///
/// Tampilannya memakai komponen yang sama dengan beranda Kepala/Pasangan
/// ([HomeHeader], [BalanceHeroCard], [QuickActionCard]) supaya konsisten.
class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key, required this.onNavigate});

  /// Pindah tab (1 = Catat, 2 = Analisis, 3 = Umpan Balik).
  final ValueChanged<int> onNavigate;

  void _logout(BuildContext context) {
    AuthRepository.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        TransactionRepository.instance,
        FamilyRepository.instance,
      ]),
      builder: (context, _) => _buildContent(context),
    );
  }

  /// Pesan di kotak peringatan (hanya saat Waspada ke atas).
  String _alertMessage(UsageSummary summary) => switch (summary.status) {
    UsageStatus.aman => '',
    UsageStatus.waspada =>
      'Pengeluaranmu sudah ${summary.percent}% dari jatah. Hati-hati ya.',
    UsageStatus.merah =>
      'Pengeluaranmu sudah ${summary.percent}% dari jatah dan hampir habis.',
    UsageStatus.melebihi => 'Pengeluaranmu sudah melewati jatah bulan ini.',
  };

  /// Tip di dalam hero card: sisa jatah dibagi hari yang tersisa di bulan ini.
  String? _tip(UsageSummary summary, int remaining, DateTime now) {
    if (summary.limit <= 0 || summary.status == UsageStatus.melebihi) {
      return null;
    }
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final perDay = remaining ~/ daysLeft;
    final base =
        'Tersisa ${formatRupiah(remaining)} untuk $daysLeft hari ke depan '
        '(sekitar ${formatRupiah(perDay)} per hari).';
    final advice = switch (summary.status) {
      UsageStatus.aman => 'Pengeluaranmu masih aman.',
      UsageStatus.waspada => 'Mulai kurangi jajan ya.',
      UsageStatus.merah => 'Jatah hampir habis, tahan dulu belanja yang tidak perlu.',
      UsageStatus.melebihi => '',
    };
    return '$base $advice';
  }

  Widget _buildAlert(UsageSummary summary, bool hasJatah) {
    if (!hasJatah) {
      return _AlertBox(
        background: AppColors.softFill,
        foreground: AppColors.ink,
        message: 'Jatah belum ditetapkan oleh Kepala Keluarga.',
      );
    }
    final message = _alertMessage(summary);
    if (message.isEmpty) return const SizedBox.shrink();
    final style = statusStyleFor(summary.status);
    return _AlertBox(
      background: style.background,
      foreground: style.foreground,
      label: summary.status.label,
      message: message,
    );
  }

  Widget _buildContent(BuildContext context) {
    final now = DateTime.now();
    final email = Session.email;
    final space = Session.spaceId;
    final repo = TransactionRepository.instance;
    final jatah = FamilyRepository.instance.jatahOf(email);
    final hasJatah = jatah > 0;
    final used = repo.personalInMonth(space, email, now);
    final summary = UsageSummary(used: used, limit: jatah);
    final remaining = hasJatah ? jatah - used : 0;

    final first = AuthRepository.instance.nameOf(email).trim().split(' ').first;
    final items = repo.all(space, memberEmail: email);

    // Rincian bulan ini: Kebutuhan (Primer) vs Keinginan (Sekunder + Tersier).
    var needs = 0;
    var wants = 0;
    for (final Transaction item in items) {
      if (item.date.year != now.year || item.date.month != now.month) continue;
      if (item.kategori == Kategori.primer) {
        needs += item.amount;
      } else {
        wants += item.amount;
      }
    }

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
                      greeting: 'Halo, $first!',
                      subtitle: 'Kelola uang jatahmu dengan bijak.',
                      roleLabel: FamilyRole.anak.label,
                      initial: first.isEmpty ? 'A' : first[0].toUpperCase(),
                      menuItems: const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'keluar',
                          child: Text('Keluar'),
                        ),
                      ],
                      onMenuSelected: (value) {
                        if (value == 'keluar') _logout(context);
                      },
                    ),
                    const SizedBox(height: 18),
                    BalanceHeroCard(
                      title: 'Sisa Jatah Bulan Ini',
                      remaining: remaining,
                      used: used,
                      limit: jatah,
                      ratio: summary.ratio,
                      monthLabel: monthName(now),
                      statusText: hasJatah ? summary.status.label : null,
                      limitLabel: 'Jatah',
                      infos: [
                        HeroInfo(label: 'Kebutuhan', value: needs),
                        HeroInfo(label: 'Keinginan', value: wants),
                      ],
                      tip: _tip(summary, remaining, now),
                    ),
                    if (!hasJatah || summary.status != UsageStatus.aman) ...[
                      const SizedBox(height: 12),
                      _buildAlert(summary, hasJatah),
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
                              label: 'Catat Pengeluaran',
                              caption: 'Belanja harian',
                              onTap: () => onNavigate(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.bar_chart_rounded,
                              label: 'Analisis',
                              caption: 'Cek uangmu habis ke mana',
                              onTap: () => onNavigate(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Umpan Balik',
                              caption: 'Saran dan ulasan',
                              onTap: () => onNavigate(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Transaksi pribadiku',
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
                              builder: (_) => HistoryScreen(memberEmail: email),
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
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.fieldBorder),
                        ),
                        child: const Text(
                          'Belum ada transaksi. Mulai dengan Catat Pengeluaran.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.body,
                          ),
                        ),
                      )
                    else
                      for (final item in items.take(3)) ...[
                        TransactionTile(
                          transaction: item,
                          dateText: relativeDay(item.date, now),
                        ),
                        const SizedBox(height: 10),
                      ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.softFill,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 22,
                            color: AppColors.accentDeep,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tampilan Anak hanya menampilkan jatah dan transaksi pribadimu. '
                              'Kepala Keluarga dapat memantau jatah dan riwayatmu.',
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kotak peringatan jatah (info jatah belum ada, atau status Waspada ke atas).
class _AlertBox extends StatelessWidget {
  const _AlertBox({
    required this.background,
    required this.foreground,
    required this.message,
    this.label,
  });

  final Color background;
  final Color foreground;
  final String message;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, height: 1.4, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}