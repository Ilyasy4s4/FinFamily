import 'package:flutter/material.dart';

/// Decorative cream + orange backdrop used on the login screen.
///
/// Everything is painted with vectors so the illustration stays crisp on any
/// screen density without shipping extra image assets.
class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(painter: _LoginBackgroundPainter()),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _paintTopRight(canvas, w, h);
    _paintSoftDetails(canvas, w, h);
    _paintBottom(canvas, w, h);
  }

  void _paintTopRight(Canvas canvas, double w, double h) {
    // Soft peach wash behind the solid orange corner.
    final wash = Path()
      ..moveTo(w * 0.58, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.145)
      ..cubicTo(w * 0.91, h * 0.155, w * 0.83, h * 0.130, w * 0.77, h * 0.085)
      ..cubicTo(w * 0.71, h * 0.045, w * 0.66, h * 0.020, w * 0.58, 0)
      ..close();
    canvas.drawPath(
      wash,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFCE7D0), Color(0xB3FCE7D0), Color(0x00FCE7D0)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(w * 0.58, 0, w * 0.42, h * 0.155)),
    );

    // The solid orange ribbon in the top-right corner.
    final ribbon = Path()
      ..moveTo(w * 0.70, -h * 0.005)
      ..quadraticBezierTo(w * 0.85, h * 0.020, w * 1.01, h * 0.004)
      ..lineTo(w * 1.01, h * 0.100)
      ..cubicTo(w * 0.94, h * 0.135, w * 0.87, h * 0.125, w * 0.82, h * 0.095)
      ..cubicTo(
        w * 0.775,
        h * 0.065,
        w * 0.735,
        h * 0.030,
        w * 0.70,
        -h * 0.005,
      )
      ..close();
    canvas.drawPath(
      ribbon,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFF5871F), Color(0xFFF9AE63)],
        ).createShader(Rect.fromLTWH(w * 0.70, 0, w * 0.31, h * 0.14)),
    );

    // Small rounded square accent on the right.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w - 60, h * 0.145, 18, 18),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFF8AE68),
    );
  }

  void _paintSoftDetails(Canvas canvas, double w, double h) {
    // Faint circle hugging the right edge.
    canvas.drawCircle(
      Offset(w * 1.03, h * 0.690),
      w * 0.115,
      Paint()..color = const Color(0xFFFBE4CD).withValues(alpha: 0.65),
    );

    // Soft half blob on the left edge.
    canvas.drawCircle(
      Offset(-w * 0.045, h * 0.610),
      w * 0.085,
      Paint()..color = const Color(0xFFFDEEE0).withValues(alpha: 0.85),
    );

    // Tiny translucent bubble near the password field.
    canvas.drawCircle(
      Offset(w * 0.985, h * 0.735),
      w * 0.055,
      Paint()..color = const Color(0xFFFCEBD9).withValues(alpha: 0.7),
    );
  }

  void _paintBottom(Canvas canvas, double w, double h) {
    // Warm peach sky behind the house illustration.
    final peach = Path()
      ..moveTo(w * 0.46, h * 1.02)
      ..cubicTo(w * 0.62, h * 0.965, w * 0.80, h * 0.940, w * 1.02, h * 0.870)
      ..lineTo(w * 1.02, h * 1.02)
      ..close();
    canvas.drawPath(peach, Paint()..color = const Color(0xFFFCE9D6));

    // Large soft sun.
    canvas.drawCircle(
      Offset(w * 0.97, h * 0.935),
      w * 0.225,
      Paint()..color = const Color(0xFFFBE2C8).withValues(alpha: 0.85),
    );

    // Cream wave.
    final creamWave = Path()
      ..moveTo(-w * 0.05, h * 1.02)
      ..lineTo(-w * 0.05, h * 0.945)
      ..cubicTo(w * 0.16, h * 0.905, w * 0.30, h * 0.965, w * 0.47, h * 0.978)
      ..cubicTo(w * 0.60, h * 0.988, w * 0.68, h * 1.000, w * 0.75, h * 1.02)
      ..close();
    canvas.drawPath(
      creamWave,
      Paint()..color = const Color(0xFFFDE2C8).withValues(alpha: 0.90),
    );

    // Orange wave in the bottom-left corner.
    final orangeWave = Path()
      ..moveTo(-w * 0.05, h * 1.02)
      ..lineTo(-w * 0.05, h * 0.985)
      ..cubicTo(w * 0.08, h * 0.952, w * 0.20, h * 0.955, w * 0.31, h * 0.988)
      ..quadraticBezierTo(w * 0.40, h * 1.012, w * 0.52, h * 1.02)
      ..close();
    canvas.drawPath(
      orangeWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBBE83), Color(0xFFF4761A)],
        ).createShader(Rect.fromLTWH(0, h * 0.94, w * 0.55, h * 0.08)),
    );

    _paintHouse(canvas, w, h);
  }

  void _paintHouse(Canvas canvas, double w, double h) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.020
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFF9D6B2);

    // Roof.
    final roof = Path()
      ..moveTo(w * 0.615, h * 0.918)
      ..lineTo(w * 0.795, h * 0.845)
      ..quadraticBezierTo(w * 0.815, h * 0.837, w * 0.835, h * 0.845)
      ..lineTo(w * 1.015, h * 0.918);
    canvas.drawPath(roof, outline);

    // Chimney.
    final chimney = Path()
      ..moveTo(w * 0.925, h * 0.888)
      ..lineTo(w * 0.925, h * 0.854)
      ..lineTo(w * 0.965, h * 0.854)
      ..lineTo(w * 0.965, h * 0.906);
    canvas.drawPath(chimney, outline);

    // Walls.
    final walls = Path()
      ..moveTo(w * 0.655, h * 0.918)
      ..lineTo(w * 0.655, h * 1.010)
      ..lineTo(w * 0.975, h * 1.010)
      ..lineTo(w * 0.975, h * 0.918);
    canvas.drawPath(walls, outline);

    // Family silhouettes inside the house.
    final family = Paint()..color = const Color(0xFFFFF8F0);

    // Father.
    canvas.drawCircle(Offset(w * 0.735, h * 0.940), w * 0.030, family);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.688, h * 0.968, w * 0.782, h * 1.032),
        Radius.circular(w * 0.046),
      ),
      family,
    );

    // Mother.
    canvas.drawCircle(Offset(w * 0.865, h * 0.940), w * 0.030, family);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.818, h * 0.968, w * 0.912, h * 1.032),
        Radius.circular(w * 0.046),
      ),
      family,
    );

    // Child.
    canvas.drawCircle(Offset(w * 0.800, h * 0.970), w * 0.022, family);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.766, h * 0.990, w * 0.834, h * 1.034),
        Radius.circular(w * 0.033),
      ),
      family,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
