import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_badge.dart';

class PantauHafalanScreen extends StatefulWidget {
  const PantauHafalanScreen({super.key});

  @override
  State<PantauHafalanScreen> createState() => _PantauHafalanScreenState();
}

class _PantauHafalanScreenState extends State<PantauHafalanScreen> {
  int _selectedChildIndex = 0;
  List<dynamic> _santriList = [];
  List<Map<String, dynamic>> _timelines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSantriAndTimeline();
  }

  Future<void> _loadSantriAndTimeline() async {
    setState(() => _isLoading = true);
    try {
      final dashboardResponse = await ApiClient().dio.get(
        ApiEndpoints.ortuDashboard,
      );
      final dashboardData =
          dashboardResponse.data['data'] as Map<String, dynamic>? ?? {};
      final santris = (dashboardData['santris'] as List?) ?? [];

      if (!mounted) return;

      setState(() {
        _santriList = santris;
      });

      if (_santriList.isNotEmpty) {
        final activeSantriId = _santriList[_selectedChildIndex]['id'];
        await _loadTimelineForSantri(activeSantriId);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTimelineForSantri(dynamic santriId) async {
    try {
      final response = await ApiClient().dio.get(
        ApiEndpoints.santriTimeline(
          santriId is int ? santriId : int.parse(santriId.toString()),
        ),
      );
      final data = response.data['data'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _timelines = data.map((item) {
            final t = item as Map<String, dynamic>;
            final surahName = t['surah']?['nama_latin'] ?? '-';
            final ayatStr = '${t['ayat_mulai'] ?? 1}-${t['ayat_selesai'] ?? 1}';
            final statusStr = t['status']?.toString() ?? 'lancar';

            return {
              'date': t['waktu_setor']?.toString().split('T').first ?? '-',
              'surah': '$surahName ($ayatStr)',
              'ustadz': t['guru']?['name'] ?? '-',
              'status': statusStr.toUpperCase(),
              'variant': statusStr == 'lancar'
                  ? BadgeVariant.success
                  : (statusStr == 'kurang'
                        ? BadgeVariant.warning
                        : BadgeVariant.danger),
              'catatan': t['catatan']?.toString() ?? 'Tidak ada catatan.',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSelectChild(int index) {
    if (index != _selectedChildIndex && index < _santriList.length) {
      setState(() {
        _selectedChildIndex = index;
        _isLoading = true;
      });
      _loadTimelineForSantri(_santriList[index]['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Pantau Hafalan Anak',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                if (_santriList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_santriList.length, (index) {
                          final s = _santriList[index];
                          final name = s['nama_lengkap'] ?? 'Anak';
                          final kelas = s['kelas']?['nama_kelas'] ?? '';
                          final label = kelas.isNotEmpty
                              ? '$name ($kelas)'
                              : name;
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
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _timelines.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada riwayat setoran.',
                            style: GoogleFonts.inter(color: AppColors.muted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: _timelines.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final item = _timelines[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_month,
                                            size: 13,
                                            color: AppColors.muted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item['date'],
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.muted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      AppBadge(
                                        label: item['status'],
                                        variant: item['variant'],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.menu_book,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item['surah'],
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '· ${item['ustadz']}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryPale,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.comment_outlined,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item['catatan'],
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
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
}
