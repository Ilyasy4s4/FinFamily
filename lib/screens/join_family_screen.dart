import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/session.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';
import 'main_shell.dart';

/// Alur bergabung memakai akun yang sudah ada.
/// Pengguna cukup memasukkan kode, melihat preview keluarga, lalu bergabung.
class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _code = TextEditingController();
  String? _error;
  Invite? _preview;
  bool _joining = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _checkCode() {
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() {
        _error = 'Kode undangan wajib diisi';
        _preview = null;
      });
      return;
    }

    final invite = FamilyRepository.instance.findInvite(code);
    if (invite == null) {
      setState(() {
        _error = 'Kode undangan tidak valid';
        _preview = null;
      });
      return;
    }
    if (invite.ownerEmail == Session.email) {
      setState(() {
        _error = 'Kamu tidak bisa memakai kode milik sendiri';
        _preview = null;
      });
      return;
    }
    if (FamilyRepository.instance.isMember(Session.email)) {
      setState(() {
        _error = 'Kamu sudah tergabung di keluarga. Keluar dulu untuk pindah.';
        _preview = null;
      });
      return;
    }
    if (DateTime.now().isAfter(invite.expiresAt)) {
      setState(() {
        _error = 'Kode undangan sudah kedaluwarsa';
        _preview = null;
      });
      return;
    }

    setState(() {
      _error = null;
      _preview = invite;
    });
  }

  Future<void> _join() async {
    final invite = _preview;
    if (invite == null || _joining) return;

    setState(() => _joining = true);
    final result = FamilyRepository.instance.join(Session.email, invite.code);
    if (!mounted) return;

    switch (result) {
      case JoinResult.ok:
        AuthRepository.instance.currentUser?.setupDone = true;
        final role = FamilyRepository.instance.roleOf(Session.email);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Berhasil bergabung sebagai ${role.label}.'),
            ),
          );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const MainShell()),
          (route) => false,
        );
      case JoinResult.invalid:
        setState(() {
          _joining = false;
          _error = 'Kode undangan tidak valid';
          _preview = null;
        });
      case JoinResult.expired:
        setState(() {
          _joining = false;
          _error = 'Kode undangan sudah kedaluwarsa';
          _preview = null;
        });
      case JoinResult.alreadyMember:
        setState(() {
          _joining = false;
          _error = 'Kamu sudah tergabung di keluarga';
          _preview = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final invite = _preview;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Kembali',
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Gabung ke Keluarga',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pakai akun yang sama, jangan buat akun baru. Data pribadimu tidak otomatis dibagikan ke anggota lain.',
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: AppColors.body,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: AppColors.fieldBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'Kode undangan',
                              hint: 'Contoh: SMART-7K2P9',
                              controller: _code,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) {
                                if (_error != null || _preview != null) {
                                  setState(() {
                                    _error = null;
                                    _preview = null;
                                  });
                                }
                              },
                              onFieldSubmitted: (_) => _checkCode(),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dangerDeep,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: _checkCode,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                foregroundColor: AppColors.accentDeep,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Cek Kode'),
                            ),
                          ],
                        ),
                      ),
                      if (invite != null) ...[
                        const SizedBox(height: 16),
                        _buildPreview(invite),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.softFill,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 22,
                              color: AppColors.accentDeep,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Setelah bergabung, kamu masuk ke ruang keluarga. Riwayat pribadimu tidak otomatis dibagikan ke anggota lain.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(Invite invite) {
    final ownerName = AuthRepository.instance.nameOf(invite.ownerEmail);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Kamu akan bergabung ke',
            style: TextStyle(fontSize: 13, color: AppColors.body),
          ),
          const SizedBox(height: 4),
          Text(
            'Keluarga $ownerName',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Peran: ${invite.role.label} · kode berlaku sampai ${_formatDate(invite.expiresAt)}',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.body,
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Gabung Sekarang',
            isLoading: _joining,
            onPressed: _join,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
