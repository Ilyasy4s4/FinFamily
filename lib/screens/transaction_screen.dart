import 'package:flutter/material.dart';

import '../data/session.dart';
import '../data/family_repository.dart';
import '../data/transaction_repository.dart';
import '../models/receipt_item.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';
import '../services/receipt_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_labels.dart';
import '../utils/rupiah.dart';
import '../utils/validators.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/category_selector.dart';
import '../widgets/error_banner.dart';
import '../widgets/gradient_button.dart';
import 'history_screen.dart';
import 'receipt_confirm_screen.dart';

enum _Mode { manual, scan }

enum _ScanState { idle, scanning, failed }

/// Catat Transaksi: input manual atau scan struk (TRX_005, TRX_006, TRX_015, TRX_016).
class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _note = TextEditingController();
  final _dateText = TextEditingController();
  final _formatter = RupiahInputFormatter();

  _Mode _mode = _Mode.manual;
  _ScanState _scan = _ScanState.idle;
  DateTime _date = DateTime.now();
  Kategori _kategori = Kategori.sekunder;
  bool _categoryEdited = false;
  bool _hasSuggestion = false;
  bool _saving = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _dateText.text = formatDate(_date);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _note.dispose();
    _dateText.dispose();
    super.dispose();
  }

  String get _email => Session.spaceId;

  /// Meminta usulan kategori dari layanan (sekarang aturan, nanti model).
  Future<void> _onNameChanged(String value) async {
    final name = value.trim();
    if (name.isEmpty) {
      setState(() => _hasSuggestion = false);
      return;
    }
    if (_categoryEdited) return;
    final id = ++_requestId;
    final result = await classifySafely(CategoryService.instance, name);
    if (!mounted || id != _requestId || _categoryEdited) return;
    setState(() {
      _kategori = result;
      _hasSuggestion = true;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateText.text = formatDate(picked);
    });
  }

  Future<void> _saveManual() async {
    if (_saving) return; // cegah simpan ganda
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    TransactionRepository.instance.add(
      _email,
      Transaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        amount: parseRupiah(_price.text) ?? 0,
        kategori: _kategori,
        date: DateTime(_date.year, _date.month, _date.day),
        note: _note.text.trim(),
        authorEmail: Session.email,
        isPersonal: Session.role == FamilyRole.anak,
      ),
    );

    _name.clear();
    _price.clear();
    _note.clear();
    setState(() {
      _saving = false;
      _categoryEdited = false;
      _hasSuggestion = false;
      _kategori = Kategori.sekunder;
    });
    _formKey.currentState?.reset();
    _showSnack('Transaksi tersimpan.');
  }

  Future<void> _startScan({bool blurry = false}) async {
    setState(() => _scan = _ScanState.scanning);
    try {
      final service = blurry
          ? const DummyReceiptService(blurry: true)
          : ReceiptService.instance;
      final List<ReceiptItem> items = await service.scan();
      if (!mounted) return;
      setState(() => _scan = _ScanState.idle);

      final result = await Navigator.of(context).push<ConfirmResult>(
        MaterialPageRoute<ConfirmResult>(
          builder: (_) => ReceiptConfirmScreen(items: items),
        ),
      );
      if (!mounted || result == null) return;
      if (result.saved) {
        _showSnack('Transaksi tersimpan. Total ${formatRupiah(result.total)}.');
      } else if (result.manual) {
        setState(() => _mode = _Mode.manual);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _scan = _ScanState.failed);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catat Transaksi',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.6,
                                  color: AppColors.ink,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tanpa struk atau dengan scan, pilih yang paling cepat.',
                                style: TextStyle(fontSize: 14.5, height: 1.4, color: AppColors.body),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => HistoryScreen(
                                memberEmail: Session.role == FamilyRole.anak ? Session.email : null,
                              ),
                            ),
                          ),
                          tooltip: 'Riwayat transaksi',
                          icon: const Icon(Icons.history_rounded, color: AppColors.accentDeep),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildModeSwitch(),
                    const SizedBox(height: 18),
                    if (_mode == _Mode.manual) _buildManualForm() else _buildScan(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitch() {
    Widget segment(String label, IconData icon, _Mode mode) {
      final selected = _mode == mode;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _mode = mode),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: selected
                  ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 3))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? AppColors.accentDeep : AppColors.body),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.accentDeep : AppColors.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          segment('Input Manual', Icons.edit_outlined, _Mode.manual),
          segment('Scan Struk', Icons.photo_camera_outlined, _Mode.scan),
        ],
      ),
    );
  }

  Widget _buildManualForm() {
    final caption = _categoryEdited
        ? 'Kategori kamu ubah sendiri.'
        : _hasSuggestion
            ? '${_name.text.trim()} masuk ${_kategori.label}. Kamu bisa mengubahnya sebelum menyimpan.'
            : 'Kategori diusulkan otomatis setelah nama barang diisi.';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Nama barang',
            hint: 'Contoh: Sayur bayam',
            controller: _name,
            textInputAction: TextInputAction.next,
            onChanged: _onNameChanged,
            validator: (value) => Validators.required(value, 'Nama barang wajib diisi'),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Harga',
            hint: '0',
            prefix: 'Rp',
            controller: _price,
            inputFormatters: [_formatter],
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            textInputAction: TextInputAction.next,
            validator: Validators.price,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Tanggal',
                  hint: '',
                  controller: _dateText,
                  readOnly: true,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Catatan',
                  hint: 'Opsional',
                  controller: _note,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Kategori (diusulkan otomatis)',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          CategorySelector(
            selected: _kategori,
            onChanged: (value) => setState(() {
              _kategori = value;
              _categoryEdited = true;
            }),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.body),
          ),
          const SizedBox(height: 18),
          GradientButton(label: 'Simpan', isLoading: _saving, onPressed: _saveManual),
        ],
      ),
    );
  }

  Widget _buildScan() {
    final scanning = _scan == _ScanState.scanning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_scan == _ScanState.failed) ...[
          const ErrorBanner(
            message: 'Struk tidak terbaca. Pastikan foto jelas dan cukup terang.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _scan = _ScanState.idle),
                  style: _outlined(),
                  child: const Text('Foto Ulang'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _scan = _ScanState.idle;
                    _mode = _Mode.manual;
                  }),
                  style: _outlined(),
                  child: const Text('Pakai Input Manual'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.softFill,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.accentDeep),
              ),
              const SizedBox(height: 14),
              const Text(
                'Foto struk belanja',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              const Text(
                'Arahkan kamera ke struk. Barang, harga, dan kategori dibaca otomatis, lalu kamu periksa sebelum menyimpan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.body),
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'Ambil Foto Struk',
                isLoading: scanning,
                onPressed: () => _startScan(),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: scanning ? null : () => _startScan(blurry: true),
                child: const Text('Coba struk buram (contoh)'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Kamera dan pembacaan struk (OCR) menyusul. Saat ini memakai contoh struk minimarket.',
          style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.muted),
        ),
      ],
    );
  }

  ButtonStyle _outlined() => OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.accentDeep,
        side: const BorderSide(color: AppColors.primary, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      );
}
