import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../data/session.dart';
import '../data/transaction_repository.dart';
import '../theme/app_colors.dart';
import '../utils/author_label.dart';
import '../utils/date_labels.dart';
import '../utils/rupiah.dart';
import '../widgets/app_background.dart';
import '../widgets/transaction_tile.dart';
import '../models/transaction.dart';

/// Riwayat transaksi: lihat semua, hapus, dan total pengeluaran ikut berubah.
/// Di riwayat keluarga, tiap transaksi menampilkan pencatatnya dan bisa
/// disaring per orang.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.memberEmail});

  /// Jika diisi: hanya transaksi pribadi anggota ini (riwayat Anak).
  final String? memberEmail;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? get memberEmail => widget.memberEmail;

  /// null = semua pencatat.
  String? _filter;

  /// Anggota yang transaksinya masuk riwayat keluarga (Anak punya riwayat pribadi).
  List<String> _recorders(String space) => [
    for (final email in FamilyRepository.instance.membersOf(space))
      if (FamilyRepository.instance.roleOf(email) != FamilyRole.anak) email,
  ];

  Future<void> _confirmDelete(BuildContext context, Transaction item, String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus transaksi?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        content: Text(
          '${item.name} (${formatRupiah(item.amount)}) akan dihapus dari riwayat.',
          style: const TextStyle(height: 1.5, color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    TransactionRepository.instance.remove(email, item.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Transaksi dihapus.')));
  }

  Widget _buildFilter(List<String> recorders, String? selected) {
    Widget chip(String label, String? value) {
      final isSelected = selected == value;
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filter = value),
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: AppColors.softFill,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.fieldBorder,
          width: isSelected ? 1.4 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.accentDeep : AppColors.body,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Semua', null),
        for (final r in recorders)
          chip(
            r == Session.email
                ? '${authorFirstName(r)} (Kamu)'
                : authorFirstName(r),
            r,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = Session.spaceId;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: ListenableBuilder(
              listenable: TransactionRepository.instance,
              builder: (context, _) {
                final repo = TransactionRepository.instance;
                final all = repo.all(email, memberEmail: memberEmail);
                final recorders = _recorders(email);
                final showFilter = memberEmail == null && recorders.length > 1;
                final filter = showFilter && recorders.contains(_filter) ? _filter : null;
                final items = filter == null
                    ? all
                    : [for (final t in all) if (t.authorEmail == filter) t];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
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
                          'Riwayat Transaksi',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (showFilter) ...[
                          _buildFilter(recorders, filter),
                          const SizedBox(height: 14),
                        ],
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFAE5C), Color(0xFFF97316)],
                            ),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                filter == null
                                    ? 'Total pengeluaran'
                                    : 'Total pengeluaran · ${authorFirstName(filter)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                formatRupiah(items.fold<int>(0, (sum, item) => sum + item.amount)),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '${items.length} transaksi',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              filter == null
                                  ? 'Belum ada transaksi.'
                                  : 'Belum ada transaksi yang dicatat ${authorFirstName(filter)}.',
                              style: const TextStyle(color: AppColors.body),
                            ),
                          )
                        else
                          for (final item in items) ...[
                            TransactionTile(
                              transaction: item,
                              dateText: memberEmail == null
                                  ? dateWithAuthor(formatDate(item.date), item.authorEmail)
                                  : formatDate(item.date),
                              onDelete: () => _confirmDelete(context, item, email),
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
