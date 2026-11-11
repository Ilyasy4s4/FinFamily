import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Latar lembut dengan lengkung oranye di pojok kanan atas dan kiri bawah.
/// Dipakai layar dalam (Registrasi, Pengaturan Awal, dst).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  Widget _circle(double size, Decoration decoration) =>
      Container(width: size, height: size, decoration: decoration);

  @override
  Widget build(BuildContext context) {
    const soft = BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFDE6CC));
    const strong = BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primarySoft, AppColors.primary],
      ),
    );
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -170, right: -120, child: _circle(330, soft)),
          Positioned(top: -120, right: -90, child: _circle(220, strong)),
          Positioned(bottom: -250, left: -130, child: _circle(340, soft)),
        ],
      ),
    );
  }
}
