import 'package:flutter/material.dart';

/// Central palette for the FinFamily look & feel.
abstract final class AppColors {
  static const background = Color(0xFFFFF9F2);
  static const card = Colors.white;

  static const primary = Color(0xFFF97316);
  static const primaryDeep = Color(0xFFEE6A0A);
  static const primarySoft = Color(0xFFFBB26D);

  static const ink = Color(0xFF241B13);
  static const body = Color(0xFF6F665E);
  static const muted = Color(0xFF938A82);
  static const hint = Color(0xFFA9A099);
  static const fieldBorder = Color(0xFFEADFD4);
  static const danger = Color(0xFFD94A38);

  // Warna tambahan dari desain PDF (UI Design).
  static const accentDeep = Color(0xFFC2410C); // tombol, link "Daftar"/"Masuk"
  static const softFill = Color(0xFFFFE9D2); // kotak info
  static const dangerSoft = Color(0xFFFDE2E2); // banner error
  static const dangerDeep = Color(0xFF9B1C1C); // teks error

  static const buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFCAE64), Color(0xFFF97316)],
  );

  /// Gradien tombol utama pada desain PDF (oranye tua, teks putih).
  static const buttonDeepGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFD9530F), Color(0xFFC2410C)],
  );

  static const logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBA23F), Color(0xFFEE6A0A)],
  );
}
