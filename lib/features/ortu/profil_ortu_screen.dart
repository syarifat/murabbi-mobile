import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/change_password_dialog.dart';
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

  void _showSantriDetailPopup(BuildContext context, List<dynamic> santris) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.goldPale,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.family_restroom, color: AppColors.gold, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Data Siswa Terdaftar',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              ...santris.map((s) {
                final nama = s['nama_lengkap'] ?? '-';
                final nis = s['nis'] ?? '-';
                final kelas = s['kelas']?['nama_kelas'] ?? '-';
                final suratSelesai = s['surat_selesai'] ?? 0;
                final totalAyat = s['total_ayat_hafal'] ?? 0;
                final progressPct = (s['progress_pct'] as num?)?.toInt() ?? 0;
                final totalSetoran = s['total_setoran'] ?? 0;
                final capaianTerbaru = s['capaian_terbaru'];
                String? infoTerakhir;
                if (capaianTerbaru != null && capaianTerbaru['surah'] != null) {
                  final surahName = capaianTerbaru['surah']['nama_latin'] ?? '';
                  final ayat = '${capaianTerbaru['ayat_mulai']}-${capaianTerbaru['ayat_selesai']}';
                  final status = (capaianTerbaru['status'] ?? '').toString().toUpperCase();
                  infoTerakhir = '$surahName (Ayat $ayat) · $status';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.goldPale,
                            child: Text(
                              nama.isNotEmpty ? nama[0].toUpperCase() : 'S',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nama,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NIS: $nis · $kelas',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Metrics
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSantriStatCol('Surat Selesai', '$suratSelesai Surah'),
                            Container(width: 1, height: 24, color: AppColors.border),
                            _buildSantriStatCol('Ayat Dihafal', '$totalAyat Ayat'),
                            Container(width: 1, height: 24, color: AppColors.border),
                            _buildSantriStatCol('Total Setor', '$totalSetoran Sesi'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progres Hafalan',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$progressPct%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPct / 100.0,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                          minHeight: 6,
                        ),
                      ),
                      if (infoTerakhir != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.goldPale,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.history_rounded, size: 14, color: AppColors.gold),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Setoran Terakhir: $infoTerakhir',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSantriStatCol(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wali = _data['wali']?['name'] ?? 'Wali Murid';
    final email = _data['wali']?['email'] ?? '';
    final santris = (_data['santris'] as List?) ?? [];

    // Build wali dari text
    String waliDariText = 'Belum ada siswa';
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

                    // Santri List (Clickable to show popup)
                    if (santris.isNotEmpty) ...[
                      _buildProfileItem(
                        Icons.family_restroom,
                        'Siswa Terdaftar',
                        '${santris.length} Anak (${santris.map((s) => s['nama_lengkap'] ?? '').join(', ')}) · Ketuk untuk detail',
                        onTap: () => _showSantriDetailPopup(context, santris),
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

                    // Ganti Kata Sandi
                    _buildProfileItem(
                      Icons.lock_reset,
                      'Ganti Kata Sandi',
                      'Perbarui kata sandi login Anda',
                      onTap: () => showChangePasswordDialog(context),
                    ),
                    const SizedBox(height: 10),

                    // Laporan
                    _buildProfileItem(
                      Icons.picture_as_pdf,
                      'Laporan Mutaba\'ah Hafalan',
                      'Buka Grafik & Capaian Siswa',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RekapPerkembanganScreen(),
                        ),
                      ),
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
