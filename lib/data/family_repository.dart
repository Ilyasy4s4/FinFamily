import 'dart:math';

import 'package:flutter/foundation.dart';

enum FamilyRole { kepala, pasangan, anak }

extension FamilyRoleX on FamilyRole {
  String get label => switch (this) {
    FamilyRole.kepala => 'Kepala Keluarga',
    FamilyRole.pasangan => 'Pasangan',
    FamilyRole.anak => 'Anak',
  };
}

enum JoinResult { ok, invalid, expired, alreadyMember }

class Membership {
  Membership({required this.ownerEmail, required this.role});

  /// Pemilik ruang keluarga (Kepala Keluarga).
  final String ownerEmail;
  FamilyRole role;
}

class Invite {
  const Invite({
    required this.code,
    required this.ownerEmail,
    required this.role,
    required this.createdAt,
  });

  final String code;
  final String ownerEmail;
  final FamilyRole role;
  final DateTime createdAt;

  DateTime get expiresAt => createdAt.add(const Duration(days: 7));
}

String _randomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random();
  return 'SMART-${List.generate(5, (_) => chars[random.nextInt(chars.length)]).join()}';
}

/// Keluarga DUMMY (di memori): anggota, peran, jatah Anak, dan kode undangan.
/// Setiap akun punya ruang pribadi. Saat bergabung, akun pindah ke ruang
/// Kepala Keluarga; data pribadinya tidak ikut dan kembali jika dikeluarkan.
/// Nanti diganti API.
class FamilyRepository extends ChangeNotifier {
  FamilyRepository._() {
    reset();
  }

  static final FamilyRepository instance = FamilyRepository._();

  static const ilyas = 'ilyas@gmail.com';
  static const siti = 'siti.santoso@example.com';
  static const andi = 'gusti@gmail.com';

  /// Pembuat kode; bisa diganti di test supaya kode bisa ditebak.
  String Function() codeGenerator = _randomCode;

  final Map<String, Membership> _memberships = {};
  final Map<String, int> _jatah = {};
  final List<Invite> _invites = [];

  /// Data awal: keluarga Ilyas dengan Siti (Pasangan) dan Andi (Anak, jatah Rp1.000.000).
  void reset() {
    _memberships
      ..clear()
      ..[siti] = Membership(ownerEmail: ilyas, role: FamilyRole.pasangan)
      ..[andi] = Membership(ownerEmail: ilyas, role: FamilyRole.anak);
    _jatah
      ..clear()
      ..[andi] = 1000000;
    _invites.clear();
    codeGenerator = _randomCode;
    notifyListeners();
  }

  FamilyRole roleOf(String email) =>
      _memberships[email]?.role ?? FamilyRole.kepala;

  /// Pemilik ruang tempat akun ini bekerja (dirinya sendiri jika belum bergabung).
  String spaceOf(String email) => _memberships[email]?.ownerEmail ?? email;

  bool isMember(String email) => _memberships.containsKey(email);

  bool _hasMembers(String owner) =>
      _memberships.values.any((m) => m.ownerEmail == owner);

  /// Kepala Keluarga lebih dulu, lalu anggota sesuai urutan bergabung.
  List<String> membersOf(String owner) => [
    owner,
    for (final entry in _memberships.entries)
      if (entry.value.ownerEmail == owner) entry.key,
  ];

  int activeInviteCount(String owner) =>
      _invites.where((invite) => invite.ownerEmail == owner).length;

  Invite createInvite(String owner, FamilyRole role, {DateTime? now}) {
    final invite = Invite(
      code: codeGenerator(),
      ownerEmail: owner,
      role: role,
      createdAt: now ?? DateTime.now(),
    );
    _invites.add(invite);
    notifyListeners();
    return invite;
  }

  /// Mencari undangan tanpa memakainya, untuk menampilkan preview
  /// sebelum pengguna menekan tombol gabung.
  Invite? findInvite(String code) {
    final normalized = code.trim().toUpperCase();
    for (final invite in _invites) {
      if (invite.code.toUpperCase() == normalized) return invite;
    }
    return null;
  }

  /// Memakai kode undangan (INV_004, INV_014, GAB_021). Kode hanya berlaku sekali.
  JoinResult join(String email, String code, {DateTime? now}) {
    final normalized = code.trim().toUpperCase();
    final index = _invites.indexWhere(
      (invite) => invite.code.toUpperCase() == normalized,
    );
    if (index == -1) return JoinResult.invalid;

    final invite = _invites[index];
    if (invite.ownerEmail == email) return JoinResult.invalid;
    if (isMember(email) || _hasMembers(email)) return JoinResult.alreadyMember;
    if ((now ?? DateTime.now()).isAfter(invite.expiresAt)) {
      _invites.removeAt(index);
      notifyListeners();
      return JoinResult.expired;
    }

    _memberships[email] = Membership(
      ownerEmail: invite.ownerEmail,
      role: invite.role,
    );
    _invites.removeAt(index);
    notifyListeners();
    return JoinResult.ok;
  }

  void removeMember(String owner, String email) {
    if (_memberships[email]?.ownerEmail != owner) return;
    _memberships.remove(email);
    _jatah.remove(email);
    notifyListeners();
  }

  void changeRole(String owner, String email, FamilyRole role) {
    final membership = _memberships[email];
    if (membership == null || membership.ownerEmail != owner) return;
    membership.role = role;
    notifyListeners();
  }

  int jatahOf(String email) => _jatah[email] ?? 0;

  void setJatah(String email, int amount) {
    _jatah[email] = amount;
    notifyListeners();
  }
}
