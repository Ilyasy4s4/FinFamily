/// Aturan validasi form. Pesan mengikuti test case di Excel (tanpa titik).
abstract final class Validators {
  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi';
    if (!_emailPattern.hasMatch(email)) return 'Format email tidak valid';
    return null;
  }

  /// Password baru (registrasi): minimal 8 karakter.
  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password wajib diisi';
    if (password.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final confirm = value ?? '';
    if (confirm.isEmpty) return 'Konfirmasi password wajib diisi';
    if (confirm != original) return 'Konfirmasi password tidak sama';
    return null;
  }

  /// Harga transaksi: wajib diisi dan harus lebih dari 0 (TRX_015).
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Harga wajib diisi';
    final parsed = int.tryParse(value.replaceAll('.', '').trim());
    if (parsed == null || parsed <= 0) return 'Harga harus lebih dari 0';
    return null;
  }

  /// Umpan balik: tidak boleh kosong dan maksimal [maxFeedbackLength] karakter.
  static const maxFeedbackLength = 500;

  static String? feedback(String? value) {
    final text = value ?? '';
    if (text.trim().isEmpty) return 'Umpan balik tidak boleh kosong';
    if (text.length > maxFeedbackLength) {
      return 'Umpan balik maksimal $maxFeedbackLength karakter';
    }
    return null;
  }
}
