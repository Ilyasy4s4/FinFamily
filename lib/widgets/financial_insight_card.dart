import 'package:flutter/material.dart';

import '../models/financial_insight.dart';
import '../theme/app_colors.dart';

/// Kartu saran dari hasil klasifikasi kondisi keuangan.
/// Kelas kondisi tidak ditampilkan; pengguna hanya melihat saran yang relevan.
class FinancialInsightCard extends StatelessWidget {
  const FinancialInsightCard({
    super.key,
    required this.insight,
    this.maxActions = 3,
  });

  final FinancialInsight insight;
  final int maxActions;

  @override
  Widget build(BuildContext context) {
    final actions = insight.actions.take(maxActions).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.softFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.accentDeep,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rekomendasi untukmu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.body,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insight.headline,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.summary,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: AppColors.body,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < actions.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      actions[i],
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              if (i != actions.length - 1) const SizedBox(height: 7),
            ],
          ],
        ],
      ),
    );
  }
}
