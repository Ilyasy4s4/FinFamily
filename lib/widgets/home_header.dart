import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Header beranda: sapaan, badge peran + subjudul, lonceng notifikasi (opsional),
/// dan avatar yang membuka menu. Dipakai beranda Anak dan beranda Kepala/Pasangan.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.initial,
    required this.menuItems,
    required this.onMenuSelected,
    this.roleLabel,
    this.unread = 0,
    this.onNotifications,
  });

  final String greeting;
  final String subtitle;

  /// Huruf di dalam avatar.
  final String initial;
  final String? roleLabel;

  /// Jumlah notifikasi belum dibaca. Titik merah tampil jika > 0.
  final int unread;

  /// Null = lonceng disembunyikan (mis. beranda Anak yang belum punya notifikasi).
  final VoidCallback? onNotifications;

  final List<PopupMenuEntry<String>> menuItems;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final role = roleLabel;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (role != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentDeep,
                        ),
                      ),
                    ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.body,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (onNotifications != null) ...[
          const SizedBox(width: 8),
          _BellButton(unread: unread, onTap: onNotifications!),
        ],
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          color: Colors.white,
          offset: const Offset(0, 48),
          onSelected: onMenuSelected,
          itemBuilder: (_) => menuItems,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.logoGradient,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: unread > 0 ? 'Notifikasi ($unread belum dibaca)' : 'Notifikasi',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: AppColors.fieldBorder)),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 24,
                  color: AppColors.ink,
                ),
                if (unread > 0)
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
