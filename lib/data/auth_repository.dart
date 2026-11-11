/// Data akun DUMMY (di memori) untuk demo UTS.
/// Nanti isi class ini diganti pemanggilan API NestJS, layar tidak perlu diubah.
class AppUser {
  AppUser({
    required this.name,
    required this.email,
    required this.password,
    this.setupDone = false,
  });

  final String name;
  final String email;
  final String password;

  /// false = akun baru (diarahkan ke Pengaturan Awal), true = akun lama (ke Beranda).
  bool setupDone;
}

class AuthRepository {
  AuthRepository._() {
    reset();
  }

  static final AuthRepository instance = AuthRepository._();

  final List<AppUser> _users = [];
  AppUser? currentUser;

  /// Mengembalikan data awal: satu akun lama dari data uji di Excel.
  void reset() {
    _users
      ..clear()
      ..addAll([
        AppUser(
          name: 'Ilyas',
          email: 'ilyas@gmail.com',
          password: 'Keluarga123',
          setupDone: true,
        ),
        AppUser(
          name: 'Siti Santoso',
          email: 'siti.santoso@example.com',
          password: 'Keluarga123',
          setupDone: true,
        ),
        AppUser(
          name: 'Andi Santoso',
          email: 'gusti@gmail.com',
          password: 'Keluarga123',
          setupDone: true,
        ),
      ]);
    currentUser = null;
  }

  /// Nama tampilan akun (email jika tidak ditemukan).
  String nameOf(String email) {
    for (final user in _users) {
      if (user.email == email) return user.name;
    }
    return email;
  }

  String _normalize(String email) => email.trim().toLowerCase();

  bool emailExists(String email) {
    final key = _normalize(email);
    return _users.any((user) => user.email == key);
  }

  /// Membuat akun baru. Panggil [emailExists] lebih dulu.
  AppUser register({
    required String name,
    required String email,
    required String password,
  }) {
    final user = AppUser(
      name: name.trim(),
      email: _normalize(email),
      password: password,
    );
    _users.add(user);
    return user;
  }

  /// Mengembalikan akun jika cocok, atau null jika email/password salah.
  AppUser? login(String email, String password) {
    final key = _normalize(email);
    for (final user in _users) {
      if (user.email == key && user.password == password) {
        currentUser = user;
        return user;
      }
    }
    return null;
  }

  void logout() => currentUser = null;
}
