import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Diagram donat sederhana. [center] ditaruh di tengah lubang.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.values,
    required this.colors,
    required this.center,
    this.size = 168,
  });

  final List<int> values;
  final List<Color> colors;
  final Widget center;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(values: values, colors: colors),
          ),
          center,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});

  final List<int> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 26.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.softFill;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    final total = values.fold<int>(0, (sum, v) => sum + v);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = 2 * math.pi * values[i] / total;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = colors[i];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      !listEquals(oldDelegate.values, values) ||
      !listEquals(oldDelegate.colors, colors);
}
