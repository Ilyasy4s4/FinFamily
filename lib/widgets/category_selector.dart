import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_colors.dart';

/// Pilihan tiga kategori: Primer, Sekunder, Tersier.
class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Kategori selected;
  final ValueChanged<Kategori> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final kategori in Kategori.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: kategori == Kategori.values.last ? 0 : 10,
              ),
              child: _CategoryChip(
                label: kategori.label,
                selected: kategori == selected,
                onTap: () => onChanged(kategori),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: selected ? AppColors.softFill : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.fieldBorder,
            width: selected ? 2 : 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 18, color: AppColors.accentDeep),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppColors.accentDeep : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
