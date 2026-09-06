import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import 'input_setoran_screen.dart';

class GuruDashboardScreen extends StatefulWidget {
  final Function(int)? onTabSelected;
  const GuruDashboardScreen({super.key, this.onTabSelected});

  @override
  State<GuruDashboardScreen> createState() => _GuruDashboardScreenState();
}

class _GuruDashboardScreenState extends State<GuruDashboardScreen> {
  bool _isLoading = false;
  String _guruName = 'Ust. Abdullah';
  List<dynamic> _kelasBinaan = [];
  int _sudahSetor = 0;
  int _totalSantri = 0;
  List<dynamic> _recentFeeds = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name');
      final response = await ApiClient().dio.get(ApiEndpoints.guruDashboard);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _guruName = (savedName?.isNotEmpty ?? false)
            ? savedName!
            : (data['guru']?['name']?.toString() ?? _guruName);
        _kelasBinaan = (data['kelas_binaan'] as List?) ?? (data['kelasBinaan'] as List?) ?? [];
        _sudahSetor = (data['stats']?['setoran_hari_ini'] as num?)?.toInt() ?? 0;
        _totalSantri = (data['stats']?['santri_terampu'] as num?)?.toInt() ?? (data['stats']?['total_santri'] as num?)?.toInt() ?? 0;
        _recentFeeds = (data['recent_feed'] as List?) ?? (data['recentSetorans'] as List?) ?? [];
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.red,
          content: Text('Gagal memuat dashboard.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDetailModal(BuildContext context, dynamic feed) {
    final santriName = feed['santri']?['nama_lengkap'] ?? 'Santri';
    final kelasName = feed['santri']?['kelas']?['nama_kelas'] ?? '-';
    final surahName = feed['surah']?['nama_latin'] ?? 'Surah';
    final ayat = "${feed['ayat_mulai'] ?? 1}-${feed['ayat_selesai'] ?? 20}";
    final status = feed['status'] ?? 'lancar';
    final catatan = feed['catatan'] ?? '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Sesi Setoran',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('Santri', santriName),
            _buildDetailRow('Kelas', kelasName),
            _buildDetailRow('Surah & Ayat', '$surahName: Ayat $ayat'),
            _buildDetailRow('Status Tajwid', status.toString().toUpperCase()),
            const SizedBox(height: 12),
            Text(
              'Catatan Evaluasi Ustadz:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                catatan,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.dark),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Tutup Detail',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _fetchDashboardData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top App Bar Profile Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primaryLight,
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assalamualaikum',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _guruName,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const AppBadge(
                            label: 'Halaqah Pagi',
                            variant: BadgeVariant.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Halaqah Schedule Banner Cards (multiple kelas)
                      ..._kelasBinaan.asMap().entries.map((entry) {
                        final index = entry.key;
                        final kelas = entry.value;
                        final namaKelas = kelas['nama_kelas'] ?? 'Kelas';
                        final jadwal = kelas['jadwal'] as String? ?? '';
                        final isFirst = index == 0;

                        return Padding(
                          padding: EdgeInsets.only(bottom: isFirst ? 0 : 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isFirst ? AppColors.primary : AppColors.primaryMid,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isFirst ? AppColors.primary : AppColors.primaryMid).withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      namaKelas,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (jadwal.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              jadwal,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.stars,
                                        color: Color(0xFFFDE68A),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Target Sesi: Minimal 15 Ayat Baru / Muroja\'ah',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // 2 Metric Counters
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'SUDAH SETOR',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: AppColors.primaryMid,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_sudahSetor Santri',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'BELUM SETOR',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.schedule,
                                        size: 18,
                                        color: AppColors.red,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_totalSantri - _sudahSetor} Santri',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Quick CTA Input Setoran
                      AppButton(
                        label: '+ INPUT SETORAN HAFALAN CEPAT',
                        icon: Icons.add_circle_outline,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InputSetoranScreen(),
                            ),
                          ).then((_) => _fetchDashboardData());
                        },
                      ),
                      const SizedBox(height: 20),

                      // Recent Feed Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sesi Terakhir Santri',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () => widget.onTabSelected?.call(2),
                            child: Text(
                              'Lihat Semua',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Dynamic Recent Feed from Live API
                      if (_recentFeeds.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'Belum ada data setoran hari ini.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._recentFeeds.map((feed) {
                          final sName =
                              feed['santri']?['nama_lengkap'] ?? 'Santri';
                          final surah = feed['surah']?['nama_latin'] ?? 'Surah';
                          final ayat =
                              '${feed['ayat_mulai']}-${feed['ayat_selesai']}';
                          final status = feed['status'] ?? 'lancar';
                          final badgeVar = status == 'lancar'
                              ? BadgeVariant.success
                              : (status == 'kurang'
                                    ? BadgeVariant.warning
                                    : BadgeVariant.danger);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: const Icon(
                                    Icons.menu_book,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$surah: Ayat $ayat',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppBadge(
                                  label: status.toString().toUpperCase(),
                                  variant: badgeVar,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: AppColors.sub,
                                  ),
                                  onPressed: () =>
                                      _showDetailModal(context, feed),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
