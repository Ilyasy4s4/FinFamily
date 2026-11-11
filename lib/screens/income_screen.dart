import 'package:flutter/material.dart';

import '../data/income_repository.dart';
import '../data/session.dart';
import '../models/income_entry.dart';
import '../theme/app_colors.dart';
import '../utils/date_labels.dart';
import '../utils/rupiah.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';

/// Mencatat pemasukan tambahan, misalnya hasil freelance.
/// Pengguna memilih berapa porsi yang boleh menambah batas belanja.
class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _formatter = RupiahInputFormatter();

  IncomeSource _source = IncomeSource.freelance;
  int _spendingPercent = 30;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_refresh);
  }

  @override
  void dispose() {
    _amount.removeListener(_refresh);
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  String get _space => Session.spaceId;

  int get _amountValue => parseRupiah(_amount.text) ?? 0;

  int get _spendingPortion => (_amountValue * _spendingPercent / 100).round();

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nominal wajib diisi';
    final parsed = parseRupiah(value);
    if (parsed == null || parsed <= 0) return 'Nominal harus lebih dari 0';
    return null;
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    final amount = _amountValue;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    IncomeRepository.instance.add(
      _space,
      IncomeEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: amount,
        source: _source,
        date: DateTime.now(),
        note: _note.text.trim(),
        spendingAllocation: _spendingPortion,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final entries = IncomeRepository.instance
        .all(_space)
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .toList();
    final monthTotal = IncomeRepository.instance.totalInMonth(_space, now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Kembali',
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Catat Pemasukan',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pemasukan tambahan tidak otomatis menaikkan batas belanja. Pilih porsi yang aman.',
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: AppColors.body,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'Nominal pemasukan',
                              hint: '0',
                              prefix: 'Rp',
                              controller: _amount,
                              inputFormatters: [_formatter],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: false,
                                  ),
                              textInputAction: TextInputAction.next,
                              validator: _validateAmount,
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Sumber',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final source in IncomeSource.values)
                                  _SourceChip(
                                    label: source.label,
                                    selected: source == _source,
                                    onTap: () =>
                                        setState(() => _source = source),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            AppTextField(
                              label: 'Catatan (opsional)',
                              hint: 'Contoh: proyek desain bulan ini',
                              controller: _note,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildAllocationCard(),
                      const SizedBox(height: 20),
                      GradientButton(
                        label: 'Simpan Pemasukan',
                        isLoading: _saving,
                        onPressed: _save,
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Pemasukan bulan ini',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Text(
                            formatRupiah(monthTotal),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (entries.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.fieldBorder),
                          ),
                          child: const Text(
                            'Belum ada pemasukan tambahan. Mulai catat di atas.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.body,
                            ),
                          ),
                        )
                      else
                        for (final entry in entries.take(5)) ...[
                          _IncomeTile(entry: entry),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationCard() {
    final amount = _amountValue;
    final spending = _spendingPortion;
    final surplus = amount - spending;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atur porsi pemasukan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sisanya masuk ke surplus/tabungan, bukan ke batas belanja.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.body,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AllocationTile(
                  label: 'Batas belanja',
                  value: formatRupiah(spending),
                  hint: '$_spendingPercent%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AllocationTile(
                  label: 'Surplus/tabungan',
                  value: formatRupiah(surplus),
                  hint: '${100 - _spendingPercent}%',
                ),
              ),
            ],
          ),
          Slider(
            value: _spendingPercent.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: Colors.white,
            onChanged: amount <= 0
                ? null
                : (value) => setState(() => _spendingPercent = value.round()),
          ),
          Text(
            amount <= 0
                ? 'Isi nominal untuk melihat pembagian.'
                : 'Batas belanja bertambah ${formatRupiah(spending)}.',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.accentDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.softFill : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.fieldBorder,
            width: selected ? 2 : 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? AppColors.accentDeep : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _AllocationTile extends StatelessWidget {
  const _AllocationTile({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.body),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          Text(
            hint,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({required this.entry});

  final IncomeEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.softFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.south_west_rounded,
              color: AppColors.accentDeep,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.source.label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  entry.note.isEmpty
                      ? formatDate(entry.date)
                      : '${formatDate(entry.date)} · ${entry.note}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.body),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+${formatRupiah(entry.amount)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }
}
