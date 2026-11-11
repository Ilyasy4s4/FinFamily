import 'package:flutter/material.dart';

import '../data/finance_repository.dart';
import '../data/income_repository.dart';
import '../data/notification_repository.dart';
import '../data/plan_repository.dart';
import '../data/session.dart';
import '../data/transaction_repository.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';

/// Pusat notifikasi in-app: pengingat batas belanja, cicilan, tagihan,
/// dan rencana yang belum tercapai. Isinya dihitung dari data terbaru.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, this.onNavigate});

  /// Pindah tab MainShell setelah notifikasi diketuk (2 = Analisis, 3 = Plan).
  final ValueChanged<int>? onNavigate;

  String get _space => Session.spaceId;

  void _open(BuildContext context, AppNotification item) {
    NotificationRepository.instance.markRead(_space, item.id);
    final tab = item.actionTab;
    final navigate = onNavigate;
    if (tab == null || navigate == null) return;
    Navigator.of(context).pop();
    navigate(tab);
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
            child: ListenableBuilder(
              listenable: Listenable.merge([
                TransactionRepository.instance,
                IncomeRepository.instance,
                FinanceRepository.instance,
                PlanRepository.instance,
                NotificationRepository.instance,
              ]),
              builder: (context, _) {
                final items = NotificationService.instance.forSpace(
                  _space,
                  DateTime.now(),
                );
                final unread = NotificationRepository.instance.unreadCount(
                  _space,
                  items,
                );
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
                          'Notifikasi',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unread == 0
                              ? 'Semua pengingat sudah dibaca.'
                              : '$unread pengingat belum dibaca.',
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: AppColors.body,
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () =>
                                  NotificationRepository.instance.markAllRead(
                                    _space,
                                    items.map((item) => item.id),
                                  ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 6,
                                ),
                                foregroundColor: AppColors.accentDeep,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Tandai semua dibaca'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        for (final item in items) ...[
                          _NotificationTile(
                            item: item,
                            read: NotificationRepository.instance.isRead(
                              _space,
                              item.id,
                            ),
                            onTap: () => _open(context, item),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'Pengingat dihitung dari batas belanja, cicilan, tagihan, dan Plan terbaru. '
                          'Notifikasi sistem (di luar aplikasi) belum aktif.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: AppColors.muted,
                          ),
                        ),
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.read,
    required this.onTap,
  });

  final AppNotification item;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = switch (item.level) {
      AppNotificationLevel.danger => const _LevelStyle(
        icon: Icons.error_outline_rounded,
        foreground: AppColors.dangerDeep,
        background: AppColors.dangerSoft,
      ),
      AppNotificationLevel.warning => const _LevelStyle(
        icon: Icons.warning_amber_rounded,
        foreground: Color(0xFF92400E),
        background: Color(0xFFFEF3C7),
      ),
      AppNotificationLevel.info => const _LevelStyle(
        icon: Icons.notifications_none_rounded,
        foreground: AppColors.accentDeep,
        background: AppColors.softFill,
      ),
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: read ? AppColors.fieldBorder : AppColors.primary,
              width: read ? 1 : 1.6,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(style.icon, color: style.foreground, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              fontWeight: read
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (!read)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 5),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.body,
                      ),
                    ),
                    if (item.actionTab != null) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Ketuk untuk membuka',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentDeep,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelStyle {
  const _LevelStyle({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
}
