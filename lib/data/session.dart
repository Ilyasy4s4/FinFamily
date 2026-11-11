import 'auth_repository.dart';
import 'family_repository.dart';

/// Akun yang sedang login dan ruang tempat ia bekerja.
/// Data keuangan disimpan per ruang ([spaceId] = email Kepala Keluarga).
abstract final class Session {
  static String get email => AuthRepository.instance.currentUser?.email ?? '';

  static String get spaceId => FamilyRepository.instance.spaceOf(email);

  static FamilyRole get role => FamilyRepository.instance.roleOf(email);
}
