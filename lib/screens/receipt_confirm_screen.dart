import 'package:flutter/material.dart';

import '../data/session.dart';
import '../data/family_repository.dart';
import '../data/transaction_repository.dart';
import '../models/receipt_item.dart';
import '../models/transaction.dart';
import '../services/receipt_service.dart';
import '../theme/app_colors.dart';
import '../utils/rupiah.dart';
import '../utils/validators.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/category_selector.dart';
import '../widgets/gradient_button.dart';

/// Hasil layar konfirmasi: disimpan, pilih input manual, atau foto ulang.
class ConfirmResult {
  const ConfirmResult._(this.saved, this.manual, this.total);
  const ConfirmResult.saved(int total) : this._(true, false, total);
  const ConfirmResult.manual() : this._(false, true, 0);
  const ConfirmResult.retake() : this._(false, false, 0);

  final bool saved;
  final bool manual;
  final int total;
}

/// Konfirmasi Struk: periksa dan koreksi hasil bacaan sebelum disimpan (TRX_006).
class ReceiptConfirmScreen extends StatefulWidget {
  const ReceiptConfirmScreen({super.key, required this.items});

  final List<ReceiptItem> items;

  @override
  State<ReceiptConfirmScreen> createState() => _ReceiptConfirmScreenState();
}

class _ReceiptConfirmScreenState extends State<ReceiptConfirmScreen> {
  late final List<ReceiptItem> _items = [...widget.items];
  bool _saved = false;

  int get _total => receiptTotal(_items);

  /// Dijalankan sekali saja: tekan dua kali cepat tetap hanya satu transaksi (TRX_016).
  void _save() {
    if (_saved) return;
    _saved = true;

    final email = Session.spaceId;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var index = 0;
    for (final item in _items) {
      TransactionRepository.instance.add(
        email,
        Transaction(
          id: '${now.microsecondsSinceEpoch}-${index++}',
          name: item.name,
          amount: item.price,
          kategori: item.kategori,
          date: today,
          note: 'Dari scan struk',
          authorEmail: Session.email,
          isPersonal: Session.role == FamilyRole.anak,
        ),
      );
    }
    Navigator.of(context).pop(ConfirmResult.saved(_total));
  }

  Future<void> _edit(int index) async {
    final updated = await showModalBottomSheet<ReceiptItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _EditItemSheet(item: _items[index]),
    );
    if (updated != null) setState(() => _items[index] = updated);
  }

  Future<void> _retakeOrManual() async {
    final choice = await showModalBottomSheet<ConfirmResult>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Foto Ulang'),
              onTap: () => Navigator.of(sheetContext).pop(const ConfirmResult.retake()),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Input Manual'),
              onTap: () => Navigator.of(sheetContext).pop(const ConfirmResult.manual()),
            ),
          ],
        ),
      ),
    );
    if (choice != null && mounted) Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
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
                          onPressed: () => Navigator.of(context).pop(const ConfirmResult.retake()),
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
                        'Konfirmasi Struk',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Periksa hasil bacaan sebelum disimpan.',
                        style: TextStyle(fontSize: 15, color: AppColors.body),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF166534)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Struk terbaca. ${_items.length} barang ditemukan.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.fieldBorder),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < _items.length; i++) ...[
                              InkWell(
                                onTap: () => _edit(i),
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _items[i].name,
                                              style: const TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            Text(
                                              _items[i].kategori.label,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.body,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        formatRupiah(_items[i].price),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (i != _items.length - 1)
                                const Divider(height: 1, indent: 20, endIndent: 20),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFAE5C), Color(0xFFF97316)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatRupiah(_total),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Kategori diusulkan otomatis dan bisa diubah per barang. Ketuk barang untuk mengedit.',
                        style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.body),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(label: 'Simpan', onPressed: _save),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _retakeOrManual,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: AppColors.accentDeep,
                          side: const BorderSide(color: AppColors.primary, width: 1.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: const Text(
                          'Foto Ulang atau Input Manual',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
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
}

class _EditItemSheet extends StatefulWidget {
  const _EditItemSheet({required this.item});

  final ReceiptItem item;

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item.name);
  late final _price = TextEditingController(text: formatNumber(widget.item.price));
  late Kategori _kategori = widget.item.kategori;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _apply() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      ReceiptItem(
        name: _name.text.trim(),
        price: parseRupiah(_price.text) ?? 0,
        kategori: _kategori,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit barang',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nama barang',
                hint: 'Nama barang',
                controller: _name,
                validator: (value) => Validators.required(value, 'Nama barang wajib diisi'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Harga',
                hint: '0',
                prefix: 'Rp',
                controller: _price,
                inputFormatters: [RupiahInputFormatter()],
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                validator: Validators.price,
              ),
              const SizedBox(height: 14),
              CategorySelector(
                selected: _kategori,
                onChanged: (value) => setState(() => _kategori = value),
              ),
              const SizedBox(height: 20),
              GradientButton(label: 'Simpan perubahan', onPressed: _apply),
            ],
          ),
        ),
      ),
    );
  }
}
