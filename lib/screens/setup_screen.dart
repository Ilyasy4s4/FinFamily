import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../data/finance_repository.dart';
import '../data/session.dart';
import '../models/finance_setup.dart';
import '../services/financial_classifier.dart';
import '../services/recommendation_service.dart';
import '../theme/app_colors.dart';
import '../utils/rupiah.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/error_banner.dart';
import '../widgets/financial_insight_card.dart';
import '../widgets/gradient_button.dart';
import 'join_family_screen.dart';
import 'main_shell.dart';

/// Pengaturan Awal: data keuangan bulanan + sisa uang bebas belanja.
/// Tidak meminta membuat keluarga atau mengundang anggota (test case SET_003).
///
/// [editMode] dipakai saat pengguna membuka ulang pengaturan setelah data
/// tersimpan: isian langsung terisi data lama dan Simpan memperbarui data.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, this.editMode = false});

  final bool editMode;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gaji = TextEditingController();
  final _kebutuhan = TextEditingController();
  final _cicilan = TextEditingController();
  final _tagihan = TextEditingController();
  final _formatter = RupiahInputFormatter();

  int _sekunderPercent = 70;
  RecommendationSource _source = RecommendationSource.defaultRule;
  Recommendation? _recommendation;
  HousingStatus _housing = HousingStatus.milikSendiri;
  // Fitur model: jumlah_anggota (1-8) dan jumlah_anak_sekolah (< anggota).
  static const int _minAnggota = 1;
  static const int _maxAnggota = 8;
  int _anggota = 1;
  int _anakSekolah = 0;
  bool _userAdjusted = false;
  int _requestId = 0;
  bool _isSaving = false;

  List<TextEditingController> get _controllers => [
    _gaji,
    _kebutuhan,
    _cicilan,
    _tagihan,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editMode) _prefill();
    for (final controller in _controllers) {
      controller.addListener(_onInputChanged);
    }
    if (widget.editMode) _refreshRecommendation();
  }

  /// Mengisi form dengan data tersimpan. Hanya dipakai di [SetupScreen.editMode].
  void _prefill() {
    final saved = FinanceRepository.instance.of(Session.spaceId);
    if (saved == null) return;
    final setup = saved.setup;
    _gaji.text = setup.gaji > 0 ? formatNumber(setup.gaji) : '';
    _kebutuhan.text = setup.kebutuhan > 0 ? formatNumber(setup.kebutuhan) : '';
    _cicilan.text = setup.cicilan > 0 ? formatNumber(setup.cicilan) : '';
    _tagihan.text = setup.tagihanLain > 0
        ? formatNumber(setup.tagihanLain)
        : '';
    _housing = setup.housing;
    _anggota = setup.anggota.clamp(_minAnggota, _maxAnggota);
    _anakSekolah = setup.anakSekolah.clamp(0, _anggota - 1);

    // Pertahankan pembagian yang pernah diubah manual. Kalau nilainya sama
    // dengan rekomendasi otomatis, biarkan rekomendasi menyesuaikan lagi.
    final recommended = sekunderShareFor(
      FinancialClassifier.instance.assess(setup).condition,
    );
    if (saved.sekunderPercent > 0 && saved.sekunderPercent != recommended) {
      _sekunderPercent = saved.sekunderPercent;
      _userAdjusted = true;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_onInputChanged);
      controller.dispose();
    }
    super.dispose();
  }

  int _value(TextEditingController controller) =>
      parseRupiah(controller.text) ?? 0;

  FinanceSetup get _setup => FinanceSetup(
    gaji: _value(_gaji),
    kebutuhan: _value(_kebutuhan),
    cicilan: _value(_cicilan),
    tagihanLain: _value(_tagihan),
    housing: _housing,
    anggota: _anggota,
    anakSekolah: _anakSekolah,
  );

  void _changeAnggota(int delta) {
    final next = (_anggota + delta).clamp(_minAnggota, _maxAnggota);
    if (next == _anggota) return;
    setState(() {
      _anggota = next;
      // Aturan model: anak sekolah harus lebih kecil dari jumlah anggota.
      if (_anakSekolah > _anggota - 1) _anakSekolah = _anggota - 1;
    });
    _refreshRecommendation();
  }

  void _changeAnak(int delta) {
    final next = (_anakSekolah + delta).clamp(0, _anggota - 1);
    if (next == _anakSekolah) return;
    setState(() => _anakSekolah = next);
    _refreshRecommendation();
  }

  void _onInputChanged() {
    setState(() {});
    _refreshRecommendation();
  }

  /// Meminta rekomendasi dari layanan klasifikasi.
  /// Kelas kondisi tidak ditampilkan; hasilnya dipakai untuk kartu saran.
  Future<void> _refreshRecommendation() async {
    final setup = _setup;
    final id = ++_requestId;
    final result = await recommendSafely(RecommendationService.instance, setup);
    if (!mounted || id != _requestId) return;
    setState(() {
      _recommendation = result;
      if (!_userAdjusted && setup.sisa > 0) {
        _sekunderPercent = result.sekunderPercent;
        _source = result.source;
      }
    });
  }

  String? _validateGaji(String? value) {
    if (value == null || value.trim().isEmpty) return 'Gaji wajib diisi';
    final parsed = parseRupiah(value);
    if (parsed == null || parsed <= 0) return 'Gaji harus lebih dari 0';
    return null;
  }

  String? _validateOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = parseRupiah(value);
    if (parsed == null || parsed < 0) return 'Nominal tidak boleh negatif';
    return null;
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final setup = _setup;
    if (setup.sisa < 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Periksa kembali datamu',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          content: const Text(
            'Pengeluaran tetap melebihi pemasukan. Tetap simpan data ini?',
            style: TextStyle(height: 1.5, color: AppColors.body),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Perbaiki'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Tetap simpan'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final user = AuthRepository.instance.currentUser;
    FinanceRepository.instance.save(
      email: Session.spaceId,
      setup: setup,
      sekunderPercent: setup.sisa > 0 ? _sekunderPercent : 0,
    );
    user?.setupDone = true;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            widget.editMode
                ? 'Data keuangan diperbarui. Sisa uang bebas belanja ${formatRupiah(setup.sisa)}.'
                : 'Data keuangan tersimpan. Sisa uang bebas belanja ${formatRupiah(setup.sisa)}.',
          ),
        ),
      );

    if (widget.editMode) {
      Navigator.of(context).pop(true);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  Future<void> _openJoin() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const JoinFamilyScreen()),
    );
  }

  Widget _moneyField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required TextInputAction action,
  }) {
    return AppTextField(
      label: label,
      hint: '0',
      prefix: 'Rp',
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      textInputAction: action,
      inputFormatters: [_formatter],
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final setup = _setup;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (widget.editMode) ...[
                            IconButton(
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
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softFill,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.editMode
                                    ? 'Pengaturan Keuangan'
                                    : 'Pengaturan Awal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentDeep,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.editMode
                            ? 'Atur ulang keuanganmu'
                            : 'Atur keuangan bulananmu',
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.editMode
                            ? 'Ubah data bulanan kapan saja. Batas belanja dan rekomendasi ikut menyesuaikan.'
                            : 'Isi data per bulan. Untuk freelancer, gunakan perkiraan pemasukan yang paling aman.',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.body,
                        ),
                      ),
                      if (!widget.editMode) ...[
                        const SizedBox(height: 16),
                        _buildJoinBanner(),
                      ],
                      const SizedBox(height: 18),
                      _buildFamilySection(),
                      const SizedBox(height: 18),
                      _buildHousingSection(),
                      const SizedBox(height: 18),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _moneyField(
                              label: 'Gaji per bulan',
                              controller: _gaji,
                              validator: _validateGaji,
                              action: TextInputAction.next,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Untuk pemasukan tidak tetap, isi angka yang paling aman. Pemasukan tambahan bisa dicatat nanti di Beranda.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _moneyField(
                              label: 'Kebutuhan pokok per bulan',
                              controller: _kebutuhan,
                              validator: _validateOptional,
                              action: TextInputAction.next,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Contoh: makan, listrik dan air, biaya sekolah, sewa rumah.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _moneyField(
                              label: 'Cicilan per bulan',
                              controller: _cicilan,
                              validator: _validateOptional,
                              action: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            _moneyField(
                              label: 'Tagihan rutin lain per bulan',
                              controller: _tagihan,
                              validator: _validateOptional,
                              action: TextInputAction.done,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Contoh: internet, pulsa, atau langganan. Jangan isi ulang yang sudah masuk kebutuhan pokok.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (setup.sisa < 0) ...[
                        const ErrorBanner(
                          message: 'Pengeluaran tetap melebihi pemasukan. Kurangi kebutuhan, cicilan, atau tagihan rutin.',
                        ),
                        const SizedBox(height: 14),
                      ],
                      _buildSisaCard(setup),
                      if (setup.sisa > 0) ...[
                        const SizedBox(height: 14),
                        _buildRecommendationCard(setup),
                      ],
                      _buildInsightCard(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 6, 26, 12),
          child: GradientButton(
            label: widget.editMode ? 'Simpan Perubahan' : 'Simpan',
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }

  Widget _buildJoinBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.group_outlined, size: 24, color: AppColors.accentDeep),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mau bergabung dengan keluarga?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pakai akun yang sama. Data pribadimu tidak otomatis dibagikan.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _openJoin,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: AppColors.accentDeep,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.primary, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Gabung dengan Kode Keluarga'),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Data keluarga',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Jumlah tanggungan dan anak sekolah memengaruhi penilaian kondisi keuanganmu.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        _CounterTile(
          label: 'Jumlah anggota keluarga',
          hint: 'Termasuk kamu (1 sampai $_maxAnggota orang)',
          value: _anggota,
          canDecrease: _anggota > _minAnggota,
          canIncrease: _anggota < _maxAnggota,
          onDecrease: () => _changeAnggota(-1),
          onIncrease: () => _changeAnggota(1),
        ),
        const SizedBox(height: 10),
        _CounterTile(
          label: 'Jumlah anak sekolah',
          hint: 'Harus lebih kecil dari jumlah anggota',
          value: _anakSekolah,
          canDecrease: _anakSekolah > 0,
          canIncrease: _anakSekolah < _anggota - 1,
          onDecrease: () => _changeAnak(-1),
          onIncrease: () => _changeAnak(1),
        ),
      ],
    );
  }

  Widget _buildHousingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tempat tinggal',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Dipakai untuk menyesuaikan rekomendasi bulananmu.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final housing in HousingStatus.values)
              _HousingChip(
                label: housing.label,
                selected: housing == _housing,
                onTap: () {
                  setState(() => _housing = housing);
                  _refreshRecommendation();
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard() {
    final insight = _recommendation?.insight;
    if (insight == null || !insight.hasData) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: FinancialInsightCard(insight: insight),
    );
  }

  Widget _buildSisaCard(FinanceSetup setup) {
    final negative = setup.sisa < 0;
    final textColor = negative ? AppColors.dangerDeep : AppColors.ink;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: negative ? AppColors.dangerSoft : null,
        gradient: negative
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFAE5C), Color(0xFFF97316)],
              ),
        borderRadius: BorderRadius.circular(28),
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
          Text(
            'Sisa uang bebas belanja',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(setup.sisa),
            style: TextStyle(
              fontSize: 34,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            negative
                ? '${formatNumber(setup.gaji)} − ${formatNumber(setup.kebutuhan)} − ${formatNumber(setup.cicilan)} − ${formatNumber(setup.tagihanLain)}.'
                : '${formatNumber(setup.gaji)} − ${formatNumber(setup.kebutuhan)} − ${formatNumber(setup.cicilan)} − ${formatNumber(setup.tagihanLain)}. Ini batas awal pengeluaran Sekunder + Tersier. Alokasi Plan akan mengurangi batas ini.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(FinanceSetup setup) {
    final sekunder = (setup.sisa * _sekunderPercent / 100).round();
    final tersier = setup.sisa - sekunder;
    final note = _source == RecommendationSource.model
        ? 'Rekomendasi model. Geser untuk mengubah.'
        : _userAdjusted
        ? 'Pembagian pilihanmu. Geser untuk mengubah.'
        : 'Disesuaikan dengan kondisimu. Geser untuk mengubah.';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pembagian sisa uang',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _shareTile(
                  'Sekunder',
                  '$_sekunderPercent%',
                  formatRupiah(sekunder),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _shareTile(
                  'Tersier',
                  '${100 - _sekunderPercent}%',
                  formatRupiah(tersier),
                ),
              ),
            ],
          ),
          Slider(
            value: _sekunderPercent.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.softFill,
            onChanged: (value) => setState(() {
              _sekunderPercent = value.round();
              _userAdjusted = true;
            }),
          ),
          Text(
            note,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _shareTile(String label, String percent, String amount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.body),
          ),
          const SizedBox(height: 2),
          Text(
            percent,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.accentDeep,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.label,
    required this.hint,
    required this.value,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String hint;
  final int value;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder, width: 1.4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canDecrease ? onDecrease : null,
            tooltip: 'Kurangi',
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: AppColors.accentDeep,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          IconButton(
            onPressed: canIncrease ? onIncrease : null,
            tooltip: 'Tambah',
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppColors.accentDeep,
          ),
        ],
      ),
    );
  }
}

class _HousingChip extends StatelessWidget {
  const _HousingChip({
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