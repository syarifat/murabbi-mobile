import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_badge.dart';
import '../auth/welcome_screen.dart';
import 'rekap_perkembangan_screen.dart';

class ProfilOrtuScreen extends StatefulWidget {
  const ProfilOrtuScreen({super.key});

  @override
  State<ProfilOrtuScreen> createState() => _ProfilOrtuScreenState();
}

class _ProfilOrtuScreenState extends State<ProfilOrtuScreen> {
  Map<String, dynamic> _data = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.ortuDashboard);
      setState(() {
        _data = response.data['data'] as Map<String, dynamic>? ?? {};
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.redPale,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: AppColors.red, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Keluar dari Akun?',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda harus login ulang untuk mengakses aplikasi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Keluar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wali = _data['wali']?['name'] ?? 'Wali Murid';
    final email = _data['wali']?['email'] ?? '';
    final noHp = _data['wali']?['no_hp'] as String?;
    final santris = (_data['santris'] as List?) ?? [];

    // Build wali dari text
    String waliDariText = 'Belum ada santri';
    if (santris.isNotEmpty) {
      final names = santris.map((s) {
        final nama = s['nama_lengkap'] ?? '';
        final kelas = s['kelas']?['nama_kelas'] ?? '';
        return kelas.isNotEmpty ? '$nama ($kelas)' : nama;
      }).toList();
      waliDariText = names.join(' & ');
      if (waliDariText.length > 40) {
        waliDariText = '${santris.length} Anak';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Akun Wali Murid',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: AppBadge(label: 'Wali Murid', variant: BadgeVariant.warning),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.goldPale,
                            child: Text(
                              wali.isNotEmpty ? wali[0].toUpperCase() : 'W',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            wali,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Wali dari: $waliDariText',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFFFFBEB),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Santri List
                    if (santris.isNotEmpty) ...[
                      _buildProfileItem(
                        Icons.family_restroom,
                        'Santri Terdaftar',
                        '${santris.length} Anak (${santris.map((s) => s['nama_lengkap'] ?? '').join(', ')})',
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Email
                    _buildProfileItem(
                      Icons.email_outlined,
                      'Email Akun',
                      email.isNotEmpty ? email : '-',
                    ),
                    const SizedBox(height: 10),

                    // No HP
                    _buildProfileItem(
                      Icons.phone_android,
                      'Nomor WhatsApp',
                      noHp != null && noHp.isNotEmpty ? '$noHp (Terverifikasi)' : '-',
                    ),
                    const SizedBox(height: 10),

                    // Laporan
                    _buildProfileItem(
                      Icons.picture_as_pdf,
                      'Laporan Mutaba\'ah Hafalan',
                      'Buka Grafik & Capaian Santri',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RekapPerkembanganScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Notifikasi
                    _buildProfileItem(
                      Icons.notifications_active_outlined,
                      'Pengaturan Notifikasi',
                      'Laporan Harian & Pembaruan Sistem',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              'Pengaturan Notifikasi',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.phone_android,
                                    color: AppColors.primary,
                                  ),
                                  title: Text(
                                    'Notifikasi WhatsApp',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'Kirim laporan setoran harian ke nomor terdaftar',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                                  ),
                                  trailing: const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  'Tutup',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _handleLogout,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.redPale,
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, size: 18, color: AppColors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Keluar dari Aplikasi',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.sub),
          ],
        ),
      ),
    );
  }
}
