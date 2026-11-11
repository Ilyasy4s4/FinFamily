import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../utils/rupiah.dart';

/// Satu baris transaksi (Beranda dan Riwayat). [onDelete] menampilkan tombol hapus.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.dateText,
    this.onDelete,
  });

  final Transaction transaction;
  final String dateText;
  final VoidCallback? onDelete;

  IconData get _icon => switch (transaction.kategori) {
        Kategori.primer => Icons.shopping_basket_outlined,
        Kategori.sekunder => Icons.local_cafe_outlined,
        Kategori.tersier => Icons.diamond_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.softFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_icon, color: AppColors.accentDeep, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${transaction.kategori.label} · $dateText',
                  style: const TextStyle(fontSize: 13, color: AppColors.body),
                ),
              ],
            ),
          ),
          Text(
            '−${formatRupiah(transaction.amount)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline, size: 22, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}
