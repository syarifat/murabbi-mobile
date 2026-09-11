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
  List<dynamic> _santris = [];
  int _selectedChildIndex = 0;
  bool _isLoading = true;

  // Real data untuk santri terpilih
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _monthlyStats = [];
  List<Map<String, dynamic>> _surahs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardAndRekap();
  }

  Future<void> _loadDashboardAndRekap() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.ortuDashboard);
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final santriList = (data['santris'] as List?) ?? [];

      if (!mounted) return;
      setState(() {
        _santris = santriList;
      });

      if (_santris.isNotEmpty) {
        final activeSantriId = _santris[_selectedChildIndex]['id'];
        await _loadRekapForSantri(activeSantriId);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRekapForSantri(dynamic santriId) async {
    final sId = santriId is int ? santriId : int.parse(santriId.toString());

    // 1. Coba ambil dari endpoint rekap
    try {
      final res = await ApiClient().dio.get(ApiEndpoints.santriRekap(sId));
      final rData = res.data['data'] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _summary = (rData['summary'] as Map<String, dynamic>?) ?? {};
          _monthlyStats = ((rData['monthly_stats'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _surahs = ((rData['surahs'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Fallback ke timeline jika endpoint rekap belum aktif di remote
    }

    // 2. Fallback: Hitung riil dari santriTimeline
    try {
      final tRes = await ApiClient().dio.get(ApiEndpoints.santriTimeline(sId));
      final tList = (tRes.data['data'] as List?) ?? [];

      // Hitung 6 bulan terakhir nyata
      final now = DateTime.now();
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final List<Map<String, dynamic>> computedMonthly = [];

      for (int i = 5; i >= 0; i--) {
        final mDate = DateTime(now.year, now.month - i, 1);
        final mLabel = monthNames[mDate.month - 1];
        int count = 0;

        for (final item in tList) {
          if (item is Map && item['waktu_setor'] != null) {
            try {
              final w = DateTime.parse(item['waktu_setor'].toString());
              if (w.year == mDate.year && w.month == mDate.month) {
                count++;
              }
            } catch (_) {}
          }
        }
        computedMonthly.add({
          'month': mLabel,
          'count': count,
        });
      }

      // Hitung capaian per surah riil
      final Map<int, Map<String, dynamic>> surahMap = {};
      int totalSetoran = 0;

      for (final item in tList) {
        if (item is Map) {
          totalSetoran++;
          final surahObj = item['surah'] as Map<String, dynamic>?;
          if (surahObj == null) continue;

          final sSurahId = (surahObj['id'] as num?)?.toInt() ?? 0;
          final nomor = (surahObj['nomor'] as num?)?.toInt() ?? sSurahId;
          final namaLatin = surahObj['nama_latin'] ?? 'Surah';
          final jumlahAyat = (surahObj['jumlah_ayat'] as num?)?.toInt() ?? 0;
          final ayatSelesai = (item['ayat_selesai'] as num?)?.toInt() ?? 0;
          final status = item['status']?.toString();

          if (status != 'mengulang') {
            final prevMax = (surahMap[sSurahId]?['ayat_hafal'] as int?) ?? 0;
            final currentMax = ayatSelesai > prevMax ? ayatSelesai : prevMax;
            final isTuntas = jumlahAyat > 0 && currentMax >= jumlahAyat;

            surahMap[sSurahId] = {
              'surah_id': sSurahId,
              'nomor': nomor,
              'nama_latin': namaLatin,
              'jumlah_ayat': jumlahAyat,
              'ayat_hafal': currentMax,
              'is_tuntas': isTuntas,
              'status_label': isTuntas ? 'TUNTAS' : 'PROSES ($currentMax/$jumlahAyat)',
            };
          }
        }
      }

      final computedSurahs = surahMap.values.toList();
      computedSurahs.sort((a, b) => ((a['nomor'] as int?) ?? 0).compareTo((b['nomor'] as int?) ?? 0));

      final tuntasCount = computedSurahs.where((s) => s['is_tuntas'] == true).length;
      final totalAyatHafal = computedSurahs.fold<int>(0, (sum, item) => sum + ((item['ayat_hafal'] as int?) ?? 0));

      const totalTargetSurah = 114;
      final progressPct = ((tuntasCount / totalTargetSurah) * 100).clamp(0, 100).round();

      if (mounted) {
        setState(() {
          _summary = {
            'total_setoran': totalSetoran,
            'surat_selesai': tuntasCount,
            'total_ayat': totalAyatHafal,
            'progress_pct': progressPct,
          };
          _monthlyStats = computedMonthly;
          _surahs = computedSurahs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSelectChild(int index) {
    if (index != _selectedChildIndex && index < _santris.length) {
      setState(() {
        _selectedChildIndex = index;
        _isLoading = true;
      });
      _loadRekapForSantri(_santris[index]['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPct = _summary['progress_pct'] ?? 0;
    final totalSetoran = _summary['total_setoran'] ?? 0;
    final suratSelesai = _summary['surat_selesai'] ?? 0;
    final totalAyat = _summary['total_ayat'] ?? 0;

    // Hitung max count untuk scaling bar chart
    int maxMonthlyCount = 1;
    for (final m in _monthlyStats) {
      final c = (m['count'] as num?)?.toInt() ?? 0;
      if (c > maxMonthlyCount) maxMonthlyCount = c;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Rekap Perkembangan',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: () async {
                if (_santris.isNotEmpty) {
                  await _loadRekapForSantri(_santris[_selectedChildIndex]['id']);
                } else {
                  await _loadDashboardAndRekap();
                }
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Child Selector (jika santri > 1)
                    if (_santris.length > 1) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_santris.length, (index) {
                            final s = _santris[index];
                            final name = s['nama_lengkap'] ?? 'Anak';
                            final kelas = s['kelas']?['nama_kelas'] ?? '';
                            final label = kelas.isNotEmpty ? '$name ($kelas)' : name;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _buildChildPill(
                                index,
                                label,
                                index == _selectedChildIndex
                                    ? Icons.person
                                    : Icons.person_outline,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Stat Cards (Data Riil)
                    Row(
                      children: [
                        _buildStatCard(
                          'Total Setoran',
                          '$totalSetoran Kali',
                          Icons.menu_book,
                          AppColors.primary,
                          AppColors.primaryPale,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Surat Selesai',
                          '$suratSelesai Surat',
                          Icons.check_circle_outline,
                          const Color(0xFF059669),
                          const Color(0xFFD1FAE5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatCard(
                          'Ayat Dihafal',
                          '$totalAyat Ayat',
                          Icons.military_tech_outlined,
                          AppColors.goldLight,
                          AppColors.goldPale,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Progres Hafalan',
                          '$progressPct%',
                          Icons.trending_up_rounded,
                          AppColors.primaryMid,
                          AppColors.primaryPale,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Real Monthly Activity Bar Chart
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
                              Text(
                                'Aktivitas Setoran 6 Bulan Terakhir',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Riil Data',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 104,
                            child: _monthlyStats.isEmpty
                                ? Center(
                                    child: Text(
                                      'Belum ada data aktivitas bulanan.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: _monthlyStats.map((m) {
                                      final count = (m['count'] as num?)?.toInt() ?? 0;
                                      final month = m['month']?.toString() ?? '-';
                                      final double barHeight = count > 0
                                          ? (count / maxMonthlyCount * 60.0).clamp(14.0, 60.0)
                                          : 4.0;
                                      final color = count > 0 ? AppColors.primary : AppColors.border;

                                      return _buildBar(month, count, barHeight, color);
                                    }).toList(),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Real Capaian Surah
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status Capaian Surah',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_surahs.length} Surah Disetor',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_surahs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.menu_book_outlined,
                                size: 32,
                                color: AppColors.muted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada riwayat setoran surah untuk santri ini.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._surahs.map((surah) {
                        final isTuntas = surah['is_tuntas'] == true;
                        final nama = '${surah['nama_latin']} (${surah['nomor']})';
                        final ayatText = isTuntas
                            ? '${surah['jumlah_ayat']} Ayat'
                            : '${surah['ayat_hafal']}/${surah['jumlah_ayat']} Ayat';
                        final statusText = isTuntas ? 'TUNTAS' : 'PROSES';
                        final variant = isTuntas ? BadgeVariant.success : BadgeVariant.warning;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildSurahRow(nama, ayatText, statusText, variant),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChildPill(int index, String name, IconData icon) {
    final isSel = _selectedChildIndex == index;
    return InkWell(
      onTap: () => _onSelectChild(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSel ? Colors.white : AppColors.muted),
            const SizedBox(width: 6),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel ? Colors.white : AppColors.muted,
              ),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    val,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String month, int count, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          count > 0 ? '$count' : '0',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: count > 0 ? AppColors.primary : AppColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 26,
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
                variant == BadgeVariant.success
                    ? Icons.check_circle
                    : Icons.access_time_filled,
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
