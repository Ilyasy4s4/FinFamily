import 'package:flutter/material.dart';

import '../data/session.dart';
import '../data/finance_repository.dart';
import '../data/income_repository.dart';
import '../data/plan_repository.dart';
import '../data/transaction_repository.dart';
import '../models/transaction.dart';
import '../models/usage_status.dart';
import '../services/budget_service.dart';
import '../theme/app_colors.dart';
import '../theme/status_style.dart';
import '../utils/author_label.dart';
import '../utils/date_labels.dart';
import '../utils/percent.dart';
import '../utils/rupiah.dart';
import '../widgets/app_background.dart';
import '../widgets/donut_chart.dart';

const _primerColor = Color(0xFFC2410C);
const _sekunderColor = Color(0xFFF97316);
const _tersierColor = Color(0xFFFDBA74);

/// Hasil & Analisis: pengeluaran bulan ini per kategori, status batas
/// Sekunder + Tersier (70%, 90%, 100%), dan kebutuhan Primer (ANL_007, ANL_017).
/// Berubah otomatis saat transaksi ditambah atau dihapus.
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key, required this.onNavigate});

  /// Pindah tab pada MainShell (3 = Plan).
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        TransactionRepository.instance,
        IncomeRepository.instance,
        FinanceRepository.instance,
        PlanRepository.instance,
      ]),
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final email = Session.spaceId;
    final finance = FinanceRepository.instance.of(email);
    final repo = TransactionRepository.instance;
    final month = DateTime.now();

    final primer = repo.totalInMonth(email, Kategori.primer, month);
    final sekunder = repo.totalInMonth(email, Kategori.sekunder, month);
    final tersier = repo.totalInMonth(email, Kategori.tersier, month);
    final total = primer + sekunder + tersier;
    final limit = BudgetService.of(email, month).limit;
    final kebutuhan = finance?.setup.kebutuhan ?? 0;
    final summary = UsageSummary(used: sekunder + tersier, limit: limit);
    final shares = sharesInTenths([primer, sekunder, tersier]);
    final byAuthor = repo.byAuthorInMonth(email, month);

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
                      'Hasil & Analisis',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pengeluaran bulan ${monthName(month)}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.body,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (summary.status == UsageStatus.melebihi) ...[
                      _OverLimitBanner(summary: summary),
                      const SizedBox(height: 14),
                    ],
                    _buildDonutCard(primer, sekunder, tersier, total, shares),
                    const SizedBox(height: 14),
                    _buildLimitCard(summary),
                    const SizedBox(height: 14),
                    _StatusLegend(current: summary.status),
                    if (kebutuhan > 0) ...[
                      const SizedBox(height: 14),
                      _buildPrimerCard(primer, kebutuhan),
                    ],
                    if (byAuthor.length > 1) ...[
                      const SizedBox(height: 14),
                      _buildByPersonCard(byAuthor),
                    ],
                    if (summary.status != UsageStatus.aman) ...[
                      const SizedBox(height: 14),
                      _buildPlanLink(),
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

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: child,
    );
  }

  Widget _buildDonutCard(
    int primer,
    int sekunder,
    int tersier,
    int total,
    List<int> shares,
  ) {
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
            name: 'Primer',
            amount: primer,
            tenths: shares[0],
          ),
          const SizedBox(height: 12),
          _LegendRow(
            color: _sekunderColor,
            name: 'Sekunder',
            amount: sekunder,
            tenths: shares[1],
          ),
          const SizedBox(height: 12),
          _LegendRow(
            color: _tersierColor,
            name: 'Tersier',
            amount: tersier,
            tenths: shares[2],
          ),
        ],
      ),
    );
  }

  String _statusMessage(UsageSummary summary) {
    final percent = summary.percent;
    return switch (summary.status) {
      UsageStatus.aman => '',
      UsageStatus.waspada =>
        'Pengeluaran sudah mencapai $percent% batas. Kurangi pengeluaran Sekunder atau Tersier agar tidak melewati batas.',
      UsageStatus.merah =>
        'Pengeluaran sudah mencapai $percent% batas dan hampir habis. Tahan dulu belanja Sekunder dan Tersier.',
      UsageStatus.melebihi => 'Pengeluaran Sekunder dan Tersier sudah mencapai batas. Mohon lebih berhati-hati.',
    };
  }

  Widget _buildLimitCard(UsageSummary summary) {
    final style = statusStyleFor(summary.status);
    final chipText = summary.status == UsageStatus.melebihi
        ? '${summary.percent}%'
        : summary.status.label;
    final message = _statusMessage(summary);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Batas Sekunder + Tersier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  chipText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: style.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatRupiah(summary.used)} terpakai',
                  style: const TextStyle(fontSize: 13.5, color: AppColors.body),
                ),
              ),
              Text(
                'Batas ${formatRupiah(summary.limit)}',
                style: const TextStyle(fontSize: 13.5, color: AppColors.body),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: AppColors.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Pengeluaran bulan ini per pencatat. Netral: menunjukkan siapa yang
  /// mencatat, bukan siapa yang berbelanja.
  Widget _buildByPersonCard(Map<String, Map<Kategori, int>> byAuthor) {
    int totalOf(Map<Kategori, int> m) => m.values.fold(0, (a, b) => a + b);
    final entries = byAuthor.entries.toList()
      ..sort((a, b) => totalOf(b.value).compareTo(totalOf(a.value)));
    final shares = sharesInTenths([for (final e in entries) totalOf(e.value)]);

    String nameOf(String authorEmail) {
      final name = authorFirstName(authorEmail);
      if (name.isEmpty) return 'Tidak diketahui';
      return authorEmail == Session.email ? '$name (Kamu)' : name;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dicatat per orang',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    nameOf(entries[i].key),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  '${formatRupiah(totalOf(entries[i].value))} · ${formatTenths(shares[i])}',
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
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: shares[i] / 1000,
                minHeight: 10,
                backgroundColor: AppColors.softFill,
                valueColor: const AlwaysStoppedAnimation<Color>(_sekunderColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Primer ${formatRupiah(entries[i].value[Kategori.primer]!)} · '
              'Sekunder ${formatRupiah(entries[i].value[Kategori.sekunder]!)} · '
              'Tersier ${formatRupiah(entries[i].value[Kategori.tersier]!)}',
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.body),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Menunjukkan siapa yang mencatat transaksi, bukan siapa yang berbelanja.',
            style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimerCard(int primer, int kebutuhan) {
    final ratio = primer / kebutuhan;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kebutuhan Primer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.softFill,
              valueColor: const AlwaysStoppedAnimation<Color>(_primerColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatRupiah(primer)} dari ${formatRupiah(kebutuhan)}',
            style: const TextStyle(fontSize: 13.5, color: AppColors.body),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanLink() {
    return InkWell(
      onTap: () => onNavigate(3),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.softFill,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: AppColors.accentDeep),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Cek apakah Plan masa depanmu masih aman',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.body),
          ],
        ),
      ),
    );
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
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                formatRupiah(amount),
                style: const TextStyle(fontSize: 13, color: AppColors.body),
              ),
            ],
          ),
        ),
        Text(
          formatTenths(tenths),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _OverLimitBanner extends StatelessWidget {
  const _OverLimitBanner({required this.summary});

  final UsageSummary summary;

  @override
  Widget build(BuildContext context) {
    final over = summary.used - summary.limit;
    final detail = over > 0
        ? 'Sekunder + Tersier sudah melewati batas ${formatRupiah(over)}. Mohon lebih berhati-hati sampai akhir bulan.'
        : 'Sekunder + Tersier sudah mencapai batas. Mohon lebih berhati-hati sampai akhir bulan.';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Melebihi batas pengeluaran',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empat tingkat status; yang sedang berlaku diberi garis tepi oranye.
class _StatusLegend extends StatelessWidget {
  const _StatusLegend({required this.current});

  final UsageStatus current;

  static const _labels = {
    UsageStatus.aman: 'Aman\n< 70%',
    UsageStatus.waspada: 'Waspada\n70%',
    UsageStatus.merah: 'Merah\n90%',
    UsageStatus.melebihi: 'Melebihi\n100%',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final status in UsageStatus.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: status == UsageStatus.melebihi ? 0 : 8,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: statusStyleFor(status).background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: status == current
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  _labels[status]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: statusStyleFor(status).foreground,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
