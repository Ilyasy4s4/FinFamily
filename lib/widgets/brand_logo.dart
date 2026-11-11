import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// FinFamily wordmark with the house + family mark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 44,
          height: 44,
          child: CustomPaint(painter: _BrandMarkPainter()),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 21.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
                children: [
                  TextSpan(
                    text: 'Fin',
                    style: TextStyle(color: AppColors.ink),
                  ),
                  TextSpan(
                    text: 'Family',
                    style: TextStyle(color: AppColors.primaryDeep),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Kelola Keuangan,',
              style: TextStyle(
                fontSize: 7.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            const Text(
              'Raih Masa Depan Bersama',
              style: TextStyle(
                fontSize: 7.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Orange house outline with the three family silhouettes inside.
class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gradientShader = AppColors.logoGradient.createShader(
      Rect.fromLTWH(0, 0, w, h),
    );

    final familyPaint = Paint()..shader = gradientShader;

    // Father.
    canvas.drawCircle(Offset(w * 0.30, h * 0.475), w * 0.095, familyPaint);
    canvas.drawOval(
      Rect.fromLTRB(w * 0.10, h * 0.615, w * 0.50, h * 1.15),
      familyPaint,
    );

    // Mother.
    canvas.drawCircle(Offset(w * 0.70, h * 0.475), w * 0.095, familyPaint);
    canvas.drawOval(
      Rect.fromLTRB(w * 0.50, h * 0.615, w * 0.90, h * 1.15),
      familyPaint,
    );

    // Child in front.
    canvas.drawCircle(Offset(w * 0.50, h * 0.560), w * 0.075, familyPaint);
    canvas.drawOval(
      Rect.fromLTRB(w * 0.345, h * 0.665, w * 0.655, h * 1.18),
      familyPaint,
    );

    // Thin cream gap so the child reads as a separate silhouette.
    final childGap = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..color = AppColors.background;
    canvas.drawCircle(Offset(w * 0.50, h * 0.560), w * 0.075, childGap);
    canvas.drawOval(
      Rect.fromLTRB(w * 0.345, h * 0.665, w * 0.655, h * 1.18),
      childGap,
    );

    // House outline.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.095
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradientShader;

    final roof = Path()
      ..moveTo(w * 0.055, h * 0.375)
      ..lineTo(w * 0.47, h * 0.085)
      ..quadraticBezierTo(w * 0.50, h * 0.065, w * 0.53, h * 0.085)
      ..lineTo(w * 0.945, h * 0.375);
    canvas.drawPath(roof, outline);

    // Short walls under the eaves.
    final walls = Path()
      ..moveTo(w * 0.055, h * 0.375)
      ..lineTo(w * 0.055, h * 0.560)
      ..moveTo(w * 0.945, h * 0.375)
      ..lineTo(w * 0.945, h * 0.560);
    canvas.drawPath(walls, outline);

    // Chimney on the right slope.
    final chimney = Path()
      ..moveTo(w * 0.755, h * 0.265)
      ..lineTo(w * 0.755, h * 0.115)
      ..lineTo(w * 0.865, h * 0.115)
      ..lineTo(w * 0.865, h * 0.300);
    canvas.drawPath(chimney, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
