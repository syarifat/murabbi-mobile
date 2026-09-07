import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../widgets/app_badge.dart';
import '../auth/welcome_screen.dart';

class ProfilGuruScreen extends StatefulWidget {
  const ProfilGuruScreen({super.key});

  @override
  State<ProfilGuruScreen> createState() => _ProfilGuruScreenState();
}

class _ProfilGuruScreenState extends State<ProfilGuruScreen> {
  Map<String, dynamic>? _guruData;
  List<dynamic> _kelasBinaan = [];
  Map<int, int> _suratSelesaiBySantri = {};
  int _santriCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.guruDashboard);
      final data = response.data['data'] as Map<String, dynamic>;

      Map<int, int> fallbackSuratSelesai = {};
      try {
        final setoransRes = await ApiClient().dio.get(
          ApiEndpoints.setorans,
          queryParameters: {'per_page': 200},
        );
        final sData = setoransRes.data['data'];
        final sList = sData is Map<String, dynamic>
            ? (sData['data'] as List? ?? [])
            : (sData as List? ?? []);

        final Map<int, Set<int>> santriCompletedSurahs = {};
        for (final item in sList) {
          if (item is Map && item['status'] != 'mengulang') {
            final santriId = (item['santri_id'] as num?)?.toInt();
            final surahId = (item['surah_id'] as num?)?.toInt();
            final ayatSelesai = (item['ayat_selesai'] as num?)?.toInt() ?? 0;
            final surahJmlAyat = (item['surah']?['jumlah_ayat'] as num?)?.toInt();

            if (santriId != null && surahId != null) {
              if (surahJmlAyat != null && ayatSelesai >= surahJmlAyat) {
                santriCompletedSurahs.putIfAbsent(santriId, () => {}).add(surahId);
              }
            }
          }
        }
        fallbackSuratSelesai = santriCompletedSurahs.map((k, v) => MapEntry(k, v.length));
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _guruData = data['guru'] as Map<String, dynamic>?;
        _kelasBinaan = (data['kelas_binaan'] as List?) ?? [];
        _santriCount = data['stats']?['santri_terampu'] as int? ?? 0;
        _suratSelesaiBySantri = fallbackSuratSelesai;
        _isLoading = false;
      });
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _guruData = {
          'name': prefs.getString('user_name') ?? 'Ustadz',
          'email': prefs.getString('user_email') ?? '',
          'role': prefs.getString('user_role') ?? 'guru',
        };
        _isLoading = false;
      });
    }
  }

  void _showKelasDetail(Map<String, dynamic> kelas) {
    final santris = (kelas['santris'] as List?) ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      kelas['nama_kelas'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${santris.length} Santri',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              if (kelas['jadwal'] != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      kelas['jadwal'] ?? '',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
              const Divider(height: 24),
              Expanded(
                child: santris.isEmpty
                    ? const Center(child: Text('Tidak ada santri'))
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: santris.length,
                        itemBuilder: (ctx, i) {
                          final s = santris[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryPale,
                              radius: 18,
                              child: Text(
                                (s['nama_lengkap'] ?? 'S')[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              s['nama_lengkap'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'NIS: ${s['nis'] ?? "-"}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                            trailing: Builder(
                              builder: (context) {
                                final sId = (s['id'] as num?)?.toInt();
                                final suratSelesai = (s['surat_selesai'] as num?)?.toInt() ??
                                    (sId != null ? _suratSelesaiBySantri[sId] : null) ??
                                    0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPale,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$suratSelesai Surat Selesai',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
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

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guruName = _guruData?['name'] ?? 'Ustadz';
    final guruEmail = _guruData?['email'] ?? '';
    final guruNip = _guruData?['nip'] as String?;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Profil Pembimbing', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: AppBadge(label: 'Ustadz', variant: BadgeVariant.success),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Profile Card Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              guruName.isNotEmpty ? guruName[0].toUpperCase() : 'U',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            guruName,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            guruNip != null ? 'NIP: $guruNip' : guruEmail,
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA7F3D0), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Kelas Binaan',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '$_santriCount Santri',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Kelas Cards
                    if (_kelasBinaan.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada kelas yang dipetakan',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                          ),
                        ),
                      )
                    else
                      ..._kelasBinaan.map((kelas) => _buildKelasCard(kelas)),

                    const SizedBox(height: 16),
                    _buildProfileItem(Icons.lock_outline, 'Email Akun', guruEmail),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, size: 18, color: AppColors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Keluar dari Akun',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.red),
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

  Widget _buildKelasCard(Map<String, dynamic> kelas) {
    final namaKelas = kelas['nama_kelas'] ?? '-';
    final jadwal = kelas['jadwal'] as String?;
    final santris = (kelas['santris'] as List?) ?? [];
    final count = santris.length;

    return GestureDetector(
      onTap: () => _showKelasDetail(kelas),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  namaKelas.length > 4 ? namaKelas.substring(0, 4) : namaKelas,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaKelas,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark),
                  ),
                  if (jadwal != null && jadwal.isNotEmpty)
                    Text(
                      jadwal,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count Santri',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
