import 'package:flutter/services.dart';

String _group(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
  }
  return buffer.toString();
}

/// 1500000 -> "1.500.000" (negatif: "-500.000").
String formatNumber(int value) {
  final grouped = _group(value.abs().toString());
  return value < 0 ? '-$grouped' : grouped;
}

/// 1500000 -> "Rp 1.500.000" (negatif: "-Rp 500.000").
String formatRupiah(int value) {
  final grouped = _group(value.abs().toString());
  return value < 0 ? '-Rp $grouped' : 'Rp $grouped';
}

/// "1.500.000" -> 1500000. Mengembalikan null jika kosong atau bukan angka.
int? parseRupiah(String? text) {
  if (text == null) return null;
  final cleaned = text.replaceAll('.', '').trim();
  if (cleaned.isEmpty || cleaned == '-') return null;
  return int.tryParse(cleaned);
}

/// Hanya menerima angka (dan tanda minus di depan), tampil berformat ribuan.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final negative = newValue.text.trimLeft().startsWith('-');
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 12) return oldValue;

    String text;
    if (digits.isEmpty) {
      text = negative ? '-' : '';
    } else {
      final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      text = negative ? '-${_group(trimmed)}' : _group(trimmed);
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
