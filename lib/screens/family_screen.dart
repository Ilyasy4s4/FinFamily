import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/session.dart';
import '../theme/app_colors.dart';
import '../utils/rupiah.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';
import 'child_monitor_screen.dart';
import 'feedback_screen.dart';

enum _MemberAction { jatah, pantau, peran, hapus }

/// Keluarga: daftar anggota dan peran, undang anggota dengan kode (7 hari),
/// gabung dengan kode, atur jatah Anak, ubah peran, dan hapus anggota
/// (INV_004, INV_014, ROL_010, ROL_020, GAB_021, RUA_019).
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _code = TextEditingController();
  String? _joinError;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _join() {
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _joinError = 'Kode undangan wajib diisi');
      return;
    }
    final repo = FamilyRepository.instance;
    final result = repo.join(Session.email, code);
    switch (result) {
      case JoinResult.ok:
        _code.clear();
        setState(() => _joinError = null);
        _snack('Berhasil bergabung sebagai ${repo.roleOf(Session.email).label}.');
      case JoinResult.invalid:
        setState(() => _joinError = 'Kode undangan tidak valid');
      case JoinResult.expired:
        setState(() => _joinError = 'Kode undangan sudah kedaluwarsa');
      case JoinResult.alreadyMember:
        setState(() => _joinError = 'Kamu sudah tergabung di keluarga');
    }
  }

  Future<void> _invite() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _InviteSheet(owner: Session.spaceId),
    );
  }

  Future<void> _setJatah(String email) async {
    final amount = await showDialog<int>(
      context: context,
      builder: (_) => _JatahDialog(initial: FamilyRepository.instance.jatahOf(email)),
    );
    if (amount == null || !mounted) return;
    FamilyRepository.instance.setJatah(email, amount);
    _snack('Jatah tersimpan.');
  }

  Future<void> _changeRole(String email) async {
    final role = await showDialog<FamilyRole>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: Colors.white,
        title: const Text('Ubah peran'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(FamilyRole.pasangan),
            child: const Text('Pasangan'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(FamilyRole.anak),
            child: const Text('Anak'),
          ),
        ],
      ),
    );
    if (role == null || !mounted) return;
    FamilyRepository.instance.changeRole(Session.spaceId, email, role);
    _snack('Peran diubah menjadi ${role.label}.');
  }

  Future<void> _remove(String email) async {
    final name = AuthRepository.instance.nameOf(email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus anggota?'),
        content: Text('$name akan keluar dari keluarga dan kembali ke ruang pribadinya.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    FamilyRepository.instance.removeMember(Session.spaceId, email);
    _snack('Anggota dihapus.');
  }

  void _onAction(_MemberAction action, String email) {
    switch (action) {
      case _MemberAction.jatah:
        _setJatah(email);
      case _MemberAction.pantau:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ChildMonitorScreen(childEmail: email)),
        );
      case _MemberAction.peran:
        _changeRole(email);
      case _MemberAction.hapus:
        _remove(email);
    }
  }

  String _subtitle(String email, FamilyRole role) {
    final repo = FamilyRepository.instance;
    return switch (role) {
      FamilyRole.kepala => 'Kepala Keluarga · akses penuh',
      FamilyRole.pasangan => 'Pasangan · mencatat transaksi, laporan, dan Plan',
      FamilyRole.anak => repo.jatahOf(email) > 0
          ? 'Anak · jatah ${formatRupiah(repo.jatahOf(email))} per bulan'
          : 'Anak · jatah belum ditetapkan',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FamilyRepository.instance,
      builder: (context, _) {
        final repo = FamilyRepository.instance;
        final me = Session.email;
        final owner = Session.spaceId;
        final canManage = Session.role == FamilyRole.kepala;
        final members = repo.membersOf(owner);
        return Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: AppBackground()),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Keluarga',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kelola anggota, peran, dan undangan.',
                          style: TextStyle(fontSize: 15, color: AppColors.body),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: AppColors.fieldBorder),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < members.length; i++) ...[
                                _MemberTile(
                                  name: AuthRepository.instance.nameOf(members[i]),
                                  isMe: members[i] == me,
                                  subtitle: _subtitle(members[i], repo.roleOf(members[i])),
                                  role: repo.roleOf(members[i]),
                                  onAction: canManage && members[i] != owner
                                      ? (action) => _onAction(action, members[i])
                                      : null,
                                ),
                                if (i != members.length - 1) const Divider(height: 1),
                              ],
                            ],
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(height: 14),
                          GradientButton(label: 'Undang Anggota', onPressed: _invite),
                          const SizedBox(height: 6),
                          const Text(
                            'Opsional. Seluruh fitur tetap bisa dipakai sendirian.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: AppColors.fieldBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gabung Keluarga',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Dengan bergabung, kamu pindah ke ruang keluarga. Data pribadimu tetap tersimpan dan kembali jika kamu keluar.',
                                style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.body),
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                label: 'Kode undangan',
                                hint: 'Masukkan kode undangan',
                                controller: _code,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) {
                                  if (_joinError != null) setState(() => _joinError = null);
                                },
                                onFieldSubmitted: (_) => _join(),
                              ),
                              if (_joinError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _joinError!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.dangerDeep,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              OutlinedButton(
                                onPressed: _join,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  foregroundColor: AppColors.accentDeep,
                                  side: const BorderSide(color: AppColors.primary, width: 1.6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                child: const Text('Gabung'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const FeedbackScreen(showBack: true),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.fieldBorder),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accentDeep),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Kirim Umpan Balik',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppColors.body),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.name,
    required this.isMe,
    required this.subtitle,
    required this.role,
    required this.onAction,
  });

  final String name;
  final bool isMe;
  final String subtitle;
  final FamilyRole role;
  final ValueChanged<_MemberAction>? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(colors: [Color(0xFFFFAE5C), Color(0xFFF97316)])
                  : null,
              color: isMe ? null : AppColors.softFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: isMe ? AppColors.ink : AppColors.accentDeep,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$name (Kamu)' : name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.body),
                ),
              ],
            ),
          ),
          if (onAction != null)
            PopupMenuButton<_MemberAction>(
              icon: const Icon(Icons.more_vert, color: AppColors.body),
              tooltip: 'Kelola anggota',
              color: Colors.white,
              onSelected: onAction,
              itemBuilder: (_) => [
                if (role == FamilyRole.anak) ...const [
                  PopupMenuItem(value: _MemberAction.jatah, child: Text('Atur jatah')),
                  PopupMenuItem(value: _MemberAction.pantau, child: Text('Pantau')),
                ],
                const PopupMenuItem(value: _MemberAction.peran, child: Text('Ubah peran')),
                const PopupMenuItem(value: _MemberAction.hapus, child: Text('Hapus anggota')),
              ],
            ),
        ],
      ),
    );
  }
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.owner});

  final String owner;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  FamilyRole _role = FamilyRole.pasangan;
  Invite? _invite;

  Widget _roleOption(FamilyRole role, String description) {
    final selected = _role == role;
    return InkWell(
      onTap: () => setState(() => _role = role),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.softFill : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.fieldBorder,
            width: selected ? 2 : 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.accentDeep : AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.body),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invite = _invite;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Undang Anggota',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            if (invite == null) ...[
              const Text(
                'Pilih peran anggota yang akan diundang.',
                style: TextStyle(fontSize: 14, color: AppColors.body),
              ),
              const SizedBox(height: 14),
              _roleOption(FamilyRole.pasangan, 'Mencatat transaksi, melihat laporan, dan mengatur Plan.'),
              const SizedBox(height: 10),
              _roleOption(FamilyRole.anak, 'Hanya melihat jatah dan transaksi pribadinya.'),
              const SizedBox(height: 18),
              GradientButton(
                label: 'Buat Kode Undangan',
                onPressed: () => setState(() {
                  _invite = FamilyRepository.instance.createInvite(widget.owner, _role);
                }),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ] else ...[
              Text(
                'Berikan kode ini kepada calon ${_role.label}.',
                style: const TextStyle(fontSize: 14, color: AppColors.body),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.softFill,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primarySoft, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invite.code,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: AppColors.ink,
                            ),
                          ),
                          const Text(
                            'Berlaku 7 hari',
                            style: TextStyle(fontSize: 13, color: AppColors.body),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: invite.code));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(content: Text('Kode disalin.')));
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.accentDeep),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Salin'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Selesai'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JatahDialog extends StatefulWidget {
  const _JatahDialog({required this.initial});

  final int initial;

  @override
  State<_JatahDialog> createState() => _JatahDialogState();
}

class _JatahDialogState extends State<_JatahDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.initial > 0 ? formatNumber(widget.initial) : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Jatah wajib diisi';
    final parsed = parseRupiah(value);
    if (parsed == null || parsed <= 0) return 'Jatah harus lebih dari 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Atur jatah bulanan'),
      content: Form(
        key: _formKey,
        child: AppTextField(
          label: 'Jatah per bulan',
          hint: '0',
          prefix: 'Rp',
          controller: _controller,
          inputFormatters: [RupiahInputFormatter()],
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          validator: _validate,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(parseRupiah(_controller.text));
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
