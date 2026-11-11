import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/info_card.dart';

/// Layar "Buat akun". Jika berhasil, menutup diri dan mengirim email ke Login.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _emailTaken = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusManager.instance.primaryFocus?.unfocus();
    _emailTaken = false;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final email = _emailController.text.trim();
    final repo = AuthRepository.instance;
    if (repo.emailExists(email)) {
      setState(() {
        _isLoading = false;
        _emailTaken = true;
      });
      _formKey.currentState?.validate(); // tampilkan "Email sudah terdaftar"
      return;
    }

    repo.register(
      name: _nameController.text,
      email: email,
      password: _passwordController.text,
    );
    setState(() => _isLoading = false);
    Navigator.of(context).pop(email.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 8, 26, 32),
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
                      const SizedBox(height: 22),
                      const Text(
                        'Buat akun',
                        style: TextStyle(
                          fontSize: 30,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mulai catat keuangan keluarga dalam satu aplikasi.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.body,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'Nama',
                              hint: 'Nama lengkap',
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              validator: (value) => Validators.required(
                                value,
                                'Nama wajib diisi',
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Email',
                              hint: 'nama@email.com',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _emailTaken = false,
                              validator: (value) {
                                if (_emailTaken) return 'Email sudah terdaftar';
                                return Validators.email(value);
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Password',
                              hint: 'Minimal 8 karakter',
                              controller: _passwordController,
                              obscure: true,
                              textInputAction: TextInputAction.next,
                              validator: Validators.newPassword,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Konfirmasi password',
                              hint: 'Ulangi password',
                              controller: _confirmController,
                              obscure: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleRegister(),
                              validator: (value) => Validators.confirmPassword(
                                value,
                                _passwordController.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      InfoCard(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.ink,
                            ),
                            children: [
                              TextSpan(
                                text: 'Ruang keuangan pribadi dibuat otomatis. Kamu menjadi ',
                              ),
                              TextSpan(
                                text: 'Kepala Keluarga',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(
                                text: ' untuk ruang ini, lalu bisa bergabung ke keluarga lain lewat kode.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      GradientButton(
                        label: 'Daftar',
                        isLoading: _isLoading,
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.body,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accentDeep,
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 4,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentDeep,
                              ),
                            ),
                          ),
                        ],
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
}
