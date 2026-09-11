import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'master_santri_screen.dart';
import 'master_kelas_screen.dart';
import 'master_pengguna_screen.dart';
import 'master_tahun_ajaran_screen.dart';
import 'rombel_screen.dart';
import 'daftar_surat_screen.dart';
import 'riwayat_setoran_screen.dart';
import '../../widgets/change_password_dialog.dart';

class MasterAkademikScreen extends StatelessWidget {
  const MasterAkademikScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Master Akademik',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DATA PENGGUNA',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            _buildMenuCard(
              context,
              label: 'Pengguna',
              sub: 'Kelola akun Guru/Ustadz & Admin',
              icon: Icons.people,
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MasterPenggunaScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _buildMenuCard(
              context,
              label: 'Ganti Kata Sandi',
              sub: 'Perbarui kata sandi akun Admin saat ini',
              icon: Icons.lock_reset,
              color: Colors.teal,
              onTap: () => showChangePasswordDialog(context),
            ),
            const SizedBox(height: 24),
            Text(
              'DATA SANTRI',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            _buildMenuCard(
              context,
              label: 'Data Santri',
              sub: 'Lihat & tambah data lengkap santri + ortu',
              icon: Icons.school,
              color: AppColors.gold,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MasterSantriScreen()),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'DATA KELAS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            _buildMenuCard(
              context,
              label: 'Master Kelas',
              sub: 'CRUD nama kelas (wadah rombel)',
              icon: Icons.class_,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MasterKelasScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              label: 'Rombel Kelas',
              sub: 'Assign santri ke kelas per tahun ajaran',
              icon: Icons.group_work,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RombelScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              label: 'Riwayat Setoran',
              sub: 'Lihat semua setoran hafalan',
              icon: Icons.history,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RiwayatSetoranScreen()),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'REFERENSI',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            _buildMenuCard(
              context,
              label: 'Tahun Ajaran',
              sub: 'Kelola tahun ajaran & aktifasi',
              icon: Icons.calendar_month,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MasterTahunAjaranScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              label: 'Daftar Surat',
              sub: 'Data Al-Quran (114 Surah) - Read only',
              icon: Icons.menu_book,
              color: Colors.brown,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DaftarSuratScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String label,
    required String sub,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
