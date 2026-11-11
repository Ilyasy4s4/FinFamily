import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Banner merah muda untuk pesan error umum (mis. "Email atau password salah").
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 22,
            color: AppColors.dangerDeep,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.dangerDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
