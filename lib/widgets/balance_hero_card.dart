import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/rupiah.dart';

/// Kotak kecil di dalam hero card (mis. "Batas awal", "Tambahan pemasukan").
class HeroInfo {
  const HeroInfo({required this.label, required this.value});

  final String label;
  final int value;
}

/// Kartu utama beranda: sisa uang, status pemakaian, progres, rincian, dan tip.
///
/// Sengaja tidak bergantung pada repository atau model apa pun supaya bisa
/// dipakai ulang: beranda Kepala/Pasangan ("Sisa Uang Bebas Belanja") dan
/// beranda Anak ("Sisa Jatah") cukup mengisi parameternya.
class BalanceHeroCard extends StatefulWidget {
  const BalanceHeroCard({
    super.key,
    required this.title,
    required this.remaining,
    required this.used,
    required this.limit,
    required this.ratio,
    required this.monthLabel,
    this.statusText,
    this.infos = const [],
    this.tip,
    this.usedLabel = 'Terpakai',
    this.limitLabel = 'Batas',
  });

  final String title;

  /// Sisa = batas - terpakai. Boleh negatif (dianggap melebihi batas).
  final int remaining;
  final int used;
  final int limit;

  /// Rasio pemakaian 0..1 (nilai di luar rentang akan dipotong).
  final double ratio;
  final String monthLabel;

  /// Teks chip status, mis. "Waspada 70%". Null = chip disembunyikan.
  final String? statusText;
  final List<HeroInfo> infos;
  final String? tip;
  final String usedLabel;
  final String limitLabel;

  @override
  State<BalanceHeroCard> createState() => _BalanceHeroCardState();
}

class _BalanceHeroCardState extends State<BalanceHeroCard> {
  bool _hidden = false;

  String _money(int value) => _hidden ? 'Rp ••••••' : formatRupiah(value);

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _infoBox(HeroInfo info) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _money(info.value),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final over = widget.remaining < 0;
    final shown = over ? 0 : widget.remaining;
    final progress = widget.limit <= 0 ? 0.0 : widget.ratio.clamp(0.0, 1.0);
    final tip = widget.tip;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFAE5C), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F97316),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                tooltip: _hidden ? 'Tampilkan nominal' : 'Sembunyikan nominal',
                padding: const EdgeInsets.symmetric(horizontal: 8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              _pill(widget.monthLabel),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _money(shown),
                    style: const TextStyle(
                      fontSize: 36,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              if (widget.statusText != null) ...[
                const SizedBox(width: 8),
                _pill(widget.statusText!),
              ],
            ],
          ),
          if (over) ...[
            const SizedBox(height: 2),
            Text(
              'Melebihi ${widget.limitLabel.toLowerCase()} ${_money(-widget.remaining)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0x66FFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.usedLabel} ${_money(widget.used)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '${widget.limitLabel} ${_money(widget.limit)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          if (widget.infos.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < widget.infos.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _infoBox(widget.infos[i]),
                ],
              ],
            ),
          ],
          if (tip != null && tip.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
