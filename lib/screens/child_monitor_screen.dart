import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/session.dart';
import '../data/transaction_repository.dart';
import '../models/usage_status.dart';
import '../theme/app_colors.dart';
import '../theme/status_style.dart';
import '../utils/date_labels.dart';
import '../utils/rupiah.dart';
import '../widgets/app_background.dart';
import '../widgets/transaction_tile.dart';

/// Pemantauan Anak oleh Kepala Keluarga: jatah, sisa jatah, dan riwayat (ROL_020 langkah 4).
class ChildMonitorScreen extends StatelessWidget {
  const ChildMonitorScreen({super.key, required this.childEmail});

  final String childEmail;

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
              listenable: Listenable.merge([TransactionRepository.instance, FamilyRepository.instance]),
              builder: (context, _) {
                final space = Session.spaceId;
                final repo = TransactionRepository.instance;
                final jatah = FamilyRepository.instance.jatahOf(childEmail);
                final used = repo.personalInMonth(space, childEmail, DateTime.now());
                final summary = UsageSummary(used: used, limit: jatah);
                final style = statusStyleFor(summary.status);
                final items = repo.all(space, memberEmail: childEmail);
                final name = AuthRepository.instance.nameOf(childEmail);
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
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Pantau $name',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: AppColors.fieldBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Sisa jatah bulan ini',
                                      style: TextStyle(fontSize: 14, color: AppColors.body),
                                    ),
                                  ),
                                  if (jatah > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: style.background,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        summary.status.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: style.foreground,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                formatRupiah(jatah - used),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: summary.ratio.clamp(0.0, 1.0),
                                  minHeight: 10,
                                  backgroundColor: AppColors.softFill,
                                  valueColor: AlwaysStoppedAnimation<Color>(style.bar),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Terpakai ${formatRupiah(used)} dari jatah ${formatRupiah(jatah)}',
                                style: const TextStyle(fontSize: 13.5, color: AppColors.body),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Riwayat transaksi',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                        const SizedBox(height: 10),
                        if (items.isEmpty)
                          const Text('Belum ada transaksi.', style: TextStyle(color: AppColors.body))
                        else
                          for (final item in items) ...[
                            TransactionTile(
                              transaction: item,
                              dateText: formatDate(item.date),
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
