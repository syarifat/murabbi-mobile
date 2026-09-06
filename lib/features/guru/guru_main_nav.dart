import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'guru_dashboard_screen.dart';
import 'input_setoran_screen.dart';
import 'riwayat_setoran_screen.dart';
import 'profil_guru_screen.dart';

class GuruMainNav extends StatefulWidget {
  const GuruMainNav({super.key});

  @override
  State<GuruMainNav> createState() => _GuruMainNavState();
}

class _GuruMainNavState extends State<GuruMainNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const GuruDashboardScreen(),
    const InputSetoranScreen(),
    const RiwayatSetoranScreen(),
    const ProfilGuruScreen(),
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
              _buildNavItem(0, 'Dashboard', Icons.home_outlined, Icons.home),
              _buildNavItem(1, 'Setoran', Icons.edit_note_outlined, Icons.edit_note),
              _buildNavItem(2, 'Riwayat', Icons.menu_book_outlined, Icons.menu_book),
              _buildNavItem(3, 'Profil', Icons.person_outline, Icons.person),
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
