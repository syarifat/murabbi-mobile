import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';

class DaftarSuratScreen extends StatefulWidget {
  const DaftarSuratScreen({super.key});

  @override
  State<DaftarSuratScreen> createState() => _DaftarSuratScreenState();
}

class _DaftarSuratScreenState extends State<DaftarSuratScreen> {
  List<Map<String, dynamic>> _surahs = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient().dio.get('/admin/master/surahs');
      if (resp.data['success'] == true) {
        setState(() {
          _surahs = (resp.data['data'] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading surahs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncSurahs() async {
    setState(() => _isSyncing = true);
    try {
      final resp = await ApiClient().dio.get('/admin/master/surahs');
      if (resp.data['success'] == true) {
        setState(() {
          _surahs = (resp.data['data'] as List).cast<Map<String, dynamic>>();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sinkronisasi berhasil! 114 Surah dimuat.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sinkronisasi gagal: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Daftar Surat',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sinkronisasi dari API',
            onPressed: _isSyncing ? null : _syncSurahs,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bluePale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data diambil dari API Al-Quran Cloud (api.alquran.cloud). Tekan ikon sync untuk memperbarui.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _surahs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _surahs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book,
                                size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada data surat',
                              style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _syncSurahs,
                              icon: const Icon(Icons.sync),
                              label: const Text('Sinkronisasi Sekarang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _surahs.length,
                        itemBuilder: (ctx, i) {
                          final s = _surahs[i];
                          return _surahCard(s, i + 1);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _surahCard(Map<String, dynamic> s, int index) {
    final isMeccan = s['revelation_type'] == 'Meccan';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${s['number']}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      s['name'] ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMeccan ? AppColors.bluePale : AppColors.goldPale,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isMeccan ? 'Makkiyyah' : 'Madaniyyah',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isMeccan ? AppColors.blue : AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s['meaning'] ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.format_list_numbered, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${s['number_of_ayahs']} Ayat',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            s['name_arabic'] ?? '',
            style: GoogleFonts.amiri(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
