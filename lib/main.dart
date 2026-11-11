import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const FinFamilyApp());
}

class FinFamilyApp extends StatelessWidget {
  const FinFamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFamily',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PlusJakartaSans',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary)
            .copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: AppColors.primary.withValues(alpha: 0.20),
          selectionHandleColor: AppColors.primary,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          contentTextStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
