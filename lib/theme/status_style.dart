import 'package:flutter/material.dart';

import '../models/usage_status.dart';

class StatusStyle {
  const StatusStyle({
    required this.background,
    required this.foreground,
    required this.bar,
  });

  final Color background;
  final Color foreground;
  final Color bar;
}

StatusStyle statusStyleFor(UsageStatus status) => switch (status) {
      UsageStatus.aman => const StatusStyle(
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF166534),
          bar: Color(0xFF22C55E),
        ),
      UsageStatus.waspada => const StatusStyle(
          background: Color(0xFFFEF3C7),
          foreground: Color(0xFF92400E),
          bar: Color(0xFFF59E0B),
        ),
      UsageStatus.merah => const StatusStyle(
          background: Color(0xFFFEE2E2),
          foreground: Color(0xFF991B1B),
          bar: Color(0xFFDC2626),
        ),
      UsageStatus.melebihi => const StatusStyle(
          background: Color(0xFF7F1D1D),
          foreground: Colors.white,
          bar: Color(0xFFB91C1C),
        ),
    };
