import '../data/auth_repository.dart';

/// Nama depan pencatat transaksi untuk ditampilkan di daftar.
/// Kosong jika pencatat tidak diketahui (data lama).
String authorFirstName(String authorEmail) {
  if (authorEmail.isEmpty) return '';
  return AuthRepository.instance.nameOf(authorEmail).trim().split(' ').first;
}

/// "3 Nov 2026 · Siti". Tanpa nama jika pencatat tidak diketahui.
String dateWithAuthor(String dateText, String authorEmail) {
  final name = authorFirstName(authorEmail);
  return name.isEmpty ? dateText : '$dateText · $name';
}
