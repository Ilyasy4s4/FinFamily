import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../data/session.dart';
import '../theme/app_colors.dart';
import 'analysis_screen.dart';
import 'child_analysis_screen.dart';
import 'child_home_screen.dart';
import 'family_screen.dart';
import 'feedback_screen.dart';
import 'home_screen.dart';
import 'plan_screen.dart';
import 'transaction_screen.dart';

/// Kerangka utama dengan navigasi bawah. Menyesuaikan peran:
/// Kepala Keluarga dan Pasangan melihat 5 menu, Anak hanya 4 menu (ROL_010).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FamilyRepository.instance,
      builder: (context, _) => _buildShell(),
    );
  }

  Widget _buildShell() {
    final isChild = Session.role == FamilyRole.anak;

    final pages = isChild
        ? <Widget>[
            ChildHomeScreen(onNavigate: _go),
            const TransactionScreen(),
            const ChildAnalysisScreen(),
            const FeedbackScreen(),
          ]
        : <Widget>[
            HomeScreen(onNavigate: _go),
            const TransactionScreen(),
            AnalysisScreen(onNavigate: _go),
            const PlanScreen(),
            const FamilyScreen(),
          ];

    final destinations = isChild
        ? const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.add_rounded), label: 'Catat'),
            NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Analisis'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Umpan Balik'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.add_rounded), label: 'Transaksi'),
            NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Analisis'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Plan'),
            NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group_rounded), label: 'Keluarga'),
          ];

    if (_index >= pages.length) _index = 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < pages.length; i++)
            Offstage(
              offstage: i != _index,
              child: TickerMode(enabled: i == _index, child: pages[i]),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.softFill,
          height: 72,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.accentDeep : AppColors.body,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.accentDeep : AppColors.body,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: destinations,
        ),
      ),
    );
  }
}