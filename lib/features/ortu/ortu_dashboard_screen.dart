import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_badge.dart';
import 'pantau_hafalan_screen.dart';
import 'rekap_perkembangan_screen.dart';

class OrtuDashboardScreen extends StatefulWidget {
  final Function(int)? onTabSelected;
  const OrtuDashboardScreen({super.key, this.onTabSelected});

  @override
  State<OrtuDashboardScreen> createState() => _OrtuDashboardScreenState();
}

class _OrtuDashboardScreenState extends State<OrtuDashboardScreen> {
  Map<String, dynamic> _data = {};
  int _selectedChildIndex = 0;
  Map<int, int> _suratSelesaiBySantri = {};
  Map<int, Map<String, dynamic>?> _latestSetoranBySantri = {};
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
      final d = response.data['data'] as Map<String, dynamic>? ?? {};
      final santris = (d['santris'] as List?) ?? [];

      Map<int, int> sMap = {};
      Map<int, Map<String, dynamic>?> lMap = {};

      for (final s in santris) {
        if (s is Map && s['id'] != null) {
          final sId = (s['id'] as num).toInt();
          // Coba ambil timeline untuk riil surat tuntas & setoran terbaru
          try {
            final tRes = await ApiClient().dio.get(ApiEndpoints.santriTimeline(sId));
            final tList = (tRes.data['data'] as List?) ?? [];

            if (tList.isNotEmpty && tList.first is Map) {
              lMap[sId] = Map<String, dynamic>.from(tList.first as Map);
            }

            final Set<int> tuntasSurahs = {};
            for (final item in tList) {
              if (item is Map && item['status'] != 'mengulang') {
                final surahId = (item['surah_id'] as num?)?.toInt();
                final aSelesai = (item['ayat_selesai'] as num?)?.toInt() ?? 0;
                final jmlAyat = (item['surah']?['jumlah_ayat'] as num?)?.toInt() ?? 999;
                if (surahId != null && aSelesai >= jmlAyat) {
                  tuntasSurahs.add(surahId);
                }
              }
            }
            sMap[sId] = tuntasSurahs.length;
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _data = d;
          _suratSelesaiBySantri = sMap;
          _latestSetoranBySantri = lMap;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wali = _data['wali']?['name'] ?? 'Wali Murid';
    final santris = (_data['santris'] as List?) ?? [];
    final count = santris.length;

    final activeSantri = santris.isNotEmpty && _selectedChildIndex < santris.length
        ? santris[_selectedChildIndex]
        : (santris.isNotEmpty ? santris.first : null);

    final activeSantriId = activeSantri?['id'] != null ? (activeSantri!['id'] as num).toInt() : null;
    final capaian = activeSantriId != null
        ? (_latestSetoranBySantri[activeSantriId] ?? _data['capaian_terbaru'] as Map<String, dynamic>?)
        : (_data['capaian_terbaru'] as Map<String, dynamic>?);

    final suratSelesaiCount = activeSantriId != null
        ? (_suratSelesaiBySantri[activeSantriId] ?? (activeSantri?['surat_selesai'] as num?)?.toInt() ?? 0)
        : 0;

    const totalTargetSurah = 114;
    final progressVal = (suratSelesaiCount / totalTargetSurah).clamp(0.0, 1.0);
    final progressPercent = (progressVal * 100).round();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _load,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.goldPale,
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.goldLight,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat Datang',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  Text(
                                    wali,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          AppBadge(
                            label: '$count Siswa',
                            variant: BadgeVariant.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Child Switcher jika santri > 1
                      if (santris.length > 1) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(santris.length, (index) {
                              final s = santris[index];
                              final isSel = _selectedChildIndex == index;
                              final name = s['nama_lengkap'] ?? 'Anak';
                              final kelas = s['kelas']?['nama_kelas'] ?? '';
                              final label = kelas.isNotEmpty ? '$name ($kelas)' : name;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedChildIndex = index),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSel ? AppColors.primary : AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSel ? AppColors.primary : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSel ? Icons.person : Icons.person_outline,
                                          size: 14,
                                          color: isSel ? Colors.white : AppColors.muted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          label,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                            color: isSel ? Colors.white : AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Capaian Terbaru Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeSantri != null
                                  ? 'Capaian Terbaru · ${activeSantri['nama_lengkap']}'
                                  : 'Capaian Terbaru',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              capaian != null
                                  ? '${capaian['surah']?['nama_latin'] ?? '-'} Ayat ${capaian['ayat_mulai']}-${capaian['ayat_selesai']}  ·  ${capaian['status']?.toString().toUpperCase() ?? '-'}'
                                  : 'Belum Ada Setoran',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PantauHafalanScreen(),
                                ),
                              ),
                              child: Text(
                                'Lihat Detail Riwayat ›',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6EE7B7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Target Tahfidz Santri Card (Riil)
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    activeSantri != null
                                        ? 'Progres Hafalan · ${activeSantri['nama_lengkap']}'
                                        : 'Progres Tahfidz Siswa',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$suratSelesaiCount Surat Selesai ($progressPercent%)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressVal,
                                minHeight: 8,
                                backgroundColor: AppColors.border,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$suratSelesaiCount dari 114 Surat Selesai',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                                Text(
                                  '${totalTargetSurah - suratSelesaiCount} Surat Tersisa',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _tile(
                              'Pantau\nHafalan',
                              Icons.remove_red_eye_outlined,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PantauHafalanScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _tile(
                              'Rekap\nPerkembangan',
                              Icons.bar_chart,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RekapPerkembanganScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _tile(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
