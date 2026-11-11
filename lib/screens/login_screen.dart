import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_repository.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/brand_logo.dart';
import '../widgets/error_banner.dart';
import '../widgets/gradient_button.dart';
import '../widgets/login_background.dart';
import 'main_shell.dart';
import 'register_screen.dart';
import 'setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _loginError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _loginError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final user = AuthRepository.instance.login(
      _emailController.text,
      _passwordController.text,
    );
    if (user == null) {
      setState(() {
        _isLoading = false;
        _loginError = 'Email atau password salah';
      });
      return;
    }

    setState(() => _isLoading = false);
    // Akun baru -> Pengaturan Awal, akun lama -> Beranda (test case LG_002).
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            user.setupDone ? const MainShell() : const SetupScreen(),
      ),
    );
  }

  Future<void> _openRegister() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const RegisterScreen()),
    );
    if (!mounted || email == null) return;

    // Setelah registrasi berhasil pengguna kembali ke Login (test case REG_001).
    setState(() {
      _emailController.text = email;
      _passwordController.clear();
      _loginError = null;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil. Silakan masuk.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: LoginBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final logoGap =
                      (constraints.maxHeight * 0.09).clamp(48.0, 84.0);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(26, 36, 26, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: BrandLogo(),
                            ),
                            SizedBox(height: logoGap),
                            const Text(
                              'Selamat datang kembali',
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
                              'Masuk untuk melanjutkan mengelola keuangan keluarga.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: AppColors.body,
                              ),
                            ),
                            const SizedBox(height: 22),
                            if (_loginError != null) ...[
                              ErrorBanner(message: _loginError!),
                              const SizedBox(height: 18),
                            ],
                            AutofillGroup(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AppTextField(
                                      label: 'Email',
                                      hint: 'nama@email.com',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      validator: Validators.email,
                                    ),
                                    const SizedBox(height: 18),
                                    AppTextField(
                                      label: 'Password',
                                      hint: 'Masukkan password',
                                      controller: _passwordController,
                                      obscure: true,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) => _handleLogin(),
                                      validator: (value) =>
                                          Validators.required(
                                        value,
                                        'Password wajib diisi',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),
                            GradientButton(
                              label: 'Masuk',
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            ),
                            const SizedBox(height: 22),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Belum punya akun? ',
          style: TextStyle(fontSize: 14, color: AppColors.body),
        ),
        TextButton(
          onPressed: _openRegister,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentDeep,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Daftar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.accentDeep,
            ),
          ),
        ),
      ],
    );
  }
}
