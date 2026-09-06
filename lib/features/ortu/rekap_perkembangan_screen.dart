import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_badge.dart';

class RekapPerkembanganScreen extends StatefulWidget {
  const RekapPerkembanganScreen({super.key});

  @override
  State<RekapPerkembanganScreen> createState() =>
      _RekapPerkembanganScreenState();
}

class _RekapPerkembanganScreenState extends State<RekapPerkembanganScreen> {
  Map<String, dynamic> _data = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.ortuDashboard);
      if (mounted) {
        setState(() {
          _data = response.data['data'] as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final santris = (_data['santris'] as List?) ?? [];
    final firstSantri = santris.isNotEmpty ? santris.first : null;
    final progressPct = firstSantri != null
        ? (firstSantri['progress_pct'] ?? 0)
        : 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Rekap Perkembangan',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: AppBadge(label: 'Juz 30', variant: BadgeVariant.neutral),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Santri',
                        '${santris.length}',
                        Icons.menu_book,
                        AppColors.primary,
                        AppColors.primaryPale,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Capaian',
                        '$progressPct%',
                        Icons.military_tech_outlined,
                        AppColors.goldLight,
                        AppColors.goldPale,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progres Hafalan Per Bulan',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 96,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBar('Jul', 48, AppColors.primaryMid),
                              _buildBar('Agu', 68, AppColors.primaryMid),
                              _buildBar(
                                'Sep',
                                progressPct.toDouble().clamp(10, 90),
                                AppColors.primary,
                              ),
                              _buildBar('Okt', 28, AppColors.border),
                              _buildBar('Nov', 18, AppColors.border),
                              _buildBar('Des', 10, AppColors.border),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Status Capaian Surah',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSurahRow(
                    'An-Naba\' (78)',
                    '40 Ayat',
                    'TUNTAS',
                    BadgeVariant.success,
                  ),
                  const SizedBox(height: 8),
                  _buildSurahRow(
                    'An-Nazi\'at (79)',
                    '46 Ayat',
                    'TUNTAS',
                    BadgeVariant.success,
                  ),
                  const SizedBox(height: 8),
                  _buildSurahRow(
                    'Abasa (80)',
                    '42 Ayat',
                    'TUNTAS',
                    BadgeVariant.success,
                  ),
                  const SizedBox(height: 8),
                  _buildSurahRow(
                    'At-Takwir (81)',
                    '29 Ayat',
                    'PROSES',
                    BadgeVariant.warning,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String label,
    String val,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String month, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          month,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildSurahRow(
    String name,
    String ayat,
    String status,
    BadgeVariant variant,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: variant == BadgeVariant.success
                    ? AppColors.primaryMid
                    : AppColors.goldLight,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· $ayat',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          AppBadge(label: status, variant: variant),
        ],
      ),
    );
  }
}
