import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Kotak info krem dengan ikon di kiri (dipakai di Registrasi, Umpan Balik, dst).
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.icon = Icons.home_outlined,
  });

  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.accentDeep),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}
