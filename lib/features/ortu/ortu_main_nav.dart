import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'ortu_dashboard_screen.dart';
import 'pantau_hafalan_screen.dart';
import 'rekap_perkembangan_screen.dart';
import 'profil_ortu_screen.dart';

class OrtuMainNav extends StatefulWidget {
  const OrtuMainNav({super.key});

  @override
  State<OrtuMainNav> createState() => _OrtuMainNavState();
}

class _OrtuMainNavState extends State<OrtuMainNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OrtuDashboardScreen(),
    const PantauHafalanScreen(),
    const RekapPerkembanganScreen(),
    const ProfilOrtuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, 'Beranda', Icons.home_outlined, Icons.home),
              _buildNavItem(1, 'Hafalan', Icons.menu_book_outlined, Icons.menu_book),
              _buildNavItem(2, 'Grafik', Icons.bar_chart_outlined, Icons.bar_chart),
              _buildNavItem(3, 'Akun', Icons.person_outline, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, IconData activeIcon) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPale : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
