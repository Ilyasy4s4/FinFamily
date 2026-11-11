import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../data/session.dart';
import '../data/transaction_repository.dart';
import '../models/transaction.dart';
import '../models/usage_status.dart';
import '../theme/app_colors.dart';
import '../theme/status_style.dart';
import '../utils/date_labels.dart';
import '../utils/percent.dart';
import '../utils/rupiah.dart';
import '../widgets/app_background.dart';
import '../widgets/donut_chart.dart';

const _primerColor = Color(0xFFC2410C);
const _sekunderColor = Color(0xFFF97316);
const _tersierColor = Color(0xFFFDBA74);

/// Aturan "boros": porsi Keinginan (Sekunder + Tersier) terhadap total
/// pengeluaran pribadi bulan ini. Ubah angkanya di sini kalau berubah.
const _wantsHigh = 0.5; // >= 50%  -> terlalu besar
const _wantsMid = 0.3; // >= 30%  -> perlu dijaga

/// Analisis untuk Anak: uangnya habis ke mana bulan ini.
/// Hanya memakai transaksi pribadi Anak (bukan data keluarga).
class ChildAnalysisScreen extends StatelessWidget {
  const ChildAnalysisScreen({super.key});

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

  Widget _buildContent(BuildContext context) {
    final now = DateTime.now();
    final email = Session.email;
    final jatah = FamilyRepository.instance.jatahOf(email);

    final items = [
      for (final t in TransactionRepository.instance.all(
        Session.spaceId,
        memberEmail: email,
      ))
        if (t.date.year == now.year && t.date.month == now.month) t,
    ];

    var primer = 0;
    var sekunder = 0;
    var tersier = 0;
    for (final t in items) {
      switch (t.kategori) {
        case Kategori.primer:
          primer += t.amount;
        case Kategori.sekunder:
          sekunder += t.amount;
        case Kategori.tersier:
          tersier += t.amount;
      }
    }
    final total = primer + sekunder + tersier;
    final wants = sekunder + tersier;

    final top = ([...items]..sort((a, b) => b.amount.compareTo(a.amount)))
        .take(3)
        .toList();

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final weekCount = (daysInMonth + 6) ~/ 7;
    final weekly = List<int>.filled(weekCount, 0);
    for (final t in items) {
      final index = ((t.date.day - 1) ~/ 7).clamp(0, weekCount - 1);
      weekly[index] += t.amount;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: AppBackground()),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Analisis Jatahku',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uangmu habis ke mana di ${monthName(now)}.',
                      style: const TextStyle(fontSize: 15, color: AppColors.body),
                    ),
                    const SizedBox(height: 18),
                    _buildJatahCard(total, jatah),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      _card(
                        child: const Text(
                          'Belum ada pengeluaran bulan ini. Catat pengeluaranmu dulu, nanti analisisnya muncul di sini.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.body,
                          ),
                        ),
                      )
                    else ...[
                      _buildInsight(total, wants),
                      const SizedBox(height: 14),
                      _buildDonutCard(primer, sekunder, tersier, total),
                      const SizedBox(height: 22),
                      const Text(
                        'Paling banyak habis di',
                        style: _sectionStyle,
                      ),
                      const SizedBox(height: 10),
                      _buildTopCard(top),
                      const SizedBox(height: 22),
                      const Text('Pola per minggu', style: _sectionStyle),
                      const SizedBox(height: 10),
                      _buildWeeklyCard(weekly, (now.day - 1) ~/ 7),
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

  static const _sectionStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: child,
    );
  }

  Widget _buildJatahCard(int used, int jatah) {
    if (jatah <= 0) {
      return _card(
        child: const Text(
          'Jatah belum ditetapkan oleh Kepala Keluarga.',
          style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.body),
        ),
      );
    }
    final summary = UsageSummary(used: used, limit: jatah);
    final style = statusStyleFor(summary.status);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pemakaian jatah',
                  style: TextStyle(fontSize: 14, color: AppColors.body),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  summary.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: style.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: summary.ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.softFill,
              valueColor: AlwaysStoppedAnimation<Color>(style.bar),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Terpakai ${formatRupiah(used)} dari jatah ${formatRupiah(jatah)} (${summary.percent}%)',
            style: const TextStyle(fontSize: 13.5, color: AppColors.body),
          ),
        ],
      ),
    );
  }

  Widget _buildInsight(int total, int wants) {
    final share = total <= 0 ? 0.0 : wants / total;
    final pct = (share * 100).round();
    final (UsageStatus level, IconData icon, String text) = share >= _wantsHigh
        ? (
            UsageStatus.merah,
            Icons.warning_amber_rounded,
            'Lebih dari separuh pengeluaranmu ($pct%) habis untuk keinginan. Coba tahan jajan dan pilih yang benar-benar perlu.',
          )
        : share >= _wantsMid
        ? (
            UsageStatus.waspada,
            Icons.info_outline_rounded,
            'Keinginanmu $pct% dari total pengeluaran. Masih wajar, tapi jaga supaya tidak makin naik.',
          )
        : (
            UsageStatus.aman,
            Icons.thumb_up_alt_outlined,
            'Bagus! Sebagian besar uangmu dipakai untuk kebutuhan. Keinginanmu hanya $pct%.',
          );
    final style = statusStyleFor(level);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: style.foreground, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: style.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutCard(int primer, int sekunder, int tersier, int total) {
    final shares = sharesInTenths([primer, sekunder, tersier]);
    return _card(
      child: Column(
        children: [
          DonutChart(
            values: [primer, sekunder, tersier],
            colors: const [_primerColor, _sekunderColor, _tersierColor],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 13, color: AppColors.body),
                ),
                Text(
                  formatNumber(total),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _LegendRow(
            color: _primerColor,
            name: 'Kebutuhan (Primer)',
            amount: primer,
            tenths: shares[0],
          ),
          const SizedBox(height: 12),
          _LegendRow(
            color: _sekunderColor,
            name: 'Keinginan (Sekunder)',
            amount: sekunder,
            tenths: shares[1],
          ),
          const SizedBox(height: 12),
          _LegendRow(
            color: _tersierColor,
            name: 'Keinginan (Tersier)',
            amount: tersier,
            tenths: shares[2],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard(List<Transaction> top) {
    final maxAmount = top.isEmpty ? 1 : top.first.amount;
    return _card(
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _TopRow(rank: i + 1, item: top[i], maxAmount: maxAmount),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(List<int> weekly, int currentWeek) {
    final maxValue = weekly.fold<int>(0, (m, v) => v > m ? v : m);
    final maxIndex = maxValue == 0 ? -1 : weekly.indexOf(maxValue);
    const barArea = 96.0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: barArea + 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < weekly.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          weekly[i] == 0 ? '' : _short(weekly[i]),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: maxValue == 0
                              ? 6
                              : 6 + (barArea - 6) * weekly[i] / maxValue,
                          decoration: BoxDecoration(
                            color: i == maxIndex
                                ? AppColors.accentDeep
                                : i > currentWeek
                                ? AppColors.fieldBorder
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'M${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: i == currentWeek
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: i == currentWeek
                                ? AppColors.accentDeep
                                : AppColors.body,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (maxIndex >= 0) ...[
            const SizedBox(height: 12),
            Text(
              'Minggu ke-${maxIndex + 1} paling banyak pengeluaran (${formatRupiah(maxValue)}).',
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.body,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 1500000 -> "1,5jt", 85000 -> "85rb".
  String _short(int v) {
    if (v >= 1000000) {
      final s = (v / 1000000).toStringAsFixed(1).replaceAll('.', ',');
      return '${s.endsWith(',0') ? s.substring(0, s.length - 2) : s}jt';
    }
    if (v >= 1000) return '${(v / 1000).round()}rb';
    return '$v';
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.name,
    required this.amount,
    required this.tenths,
  });

  final Color color;
  final String name;
  final int amount;
  final int tenths;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 14.5, color: AppColors.ink),
          ),
        ),
        Text(
          '${formatRupiah(amount)} · ${formatTenths(tenths)}',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.rank,
    required this.item,
    required this.maxAmount,
  });

  final int rank;
  final Transaction item;
  final int maxAmount;

  @override
  Widget build(BuildContext context) {
    final color = item.kategori == Kategori.primer
        ? _primerColor
        : item.kategori == Kategori.sekunder
        ? _sekunderColor
        : _tersierColor;
    final ratio = maxAmount <= 0 ? 0.0 : item.amount / maxAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.softFill,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentDeep,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${item.kategori.label} · ${formatDate(item.date)}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.body),
                  ),
                ],
              ),
            ),
            Text(
              formatRupiah(item.amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.softFill,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
