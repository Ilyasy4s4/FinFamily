import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import 'login_screen.dart';

/// Layar sementara untuk tujuan setelah login. Akan diganti layar asli
/// (Pengaturan Awal dan Beranda) pada langkah berikutnya.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.userName,
  });

  final String title;
  final String userName;

  void _logout(BuildContext context) {
    AuthRepository.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Halo, $userName. Layar ini dibuat pada langkah berikutnya.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.body,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => _logout(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentDeep,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
