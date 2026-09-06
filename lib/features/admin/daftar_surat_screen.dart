import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/api_endpoints.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'Makkiyyah', 'Madaniyyah'

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient().dio.get(ApiEndpoints.masterSurahs);
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
      try {
        final syncResp = await ApiClient().dio.post(ApiEndpoints.syncSurahsAdmin);
        if (syncResp.data['success'] == true && syncResp.data['data'] != null) {
          final list = (syncResp.data['data'] as List).cast<Map<String, dynamic>>();
          setState(() => _surahs = list);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sinkronisasi database berhasil! ${list.length} Surah tersimpan.'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
          return;
        }
      } catch (_) {
        // Fallback to GET masterSurahs
      }

      final resp = await ApiClient().dio.get(ApiEndpoints.masterSurahs);
      if (resp.data['success'] == true) {
        final list = (resp.data['data'] as List).cast<Map<String, dynamic>>();
        setState(() {
          _surahs = list;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sinkronisasi berhasil! ${list.length} Surah dimuat.'),
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

  List<Map<String, dynamic>> get _filteredSurahs {
    return _surahs.where((s) {
      final nomor = (s['nomor'] ?? s['number'] ?? '').toString();
      final namaLatin = (s['nama_latin'] ?? s['name'] ?? '').toString().toLowerCase();
      final namaInggris = (s['nama_inggris'] ?? s['meaning'] ?? '').toString().toLowerCase();
      final namaArab = (s['nama_arab'] ?? s['name_arabic'] ?? '').toString();
      final tempatTurun = (s['tempat_turun'] ?? s['revelation_type'] ?? '').toString().toLowerCase();
      final isMeccan = tempatTurun == 'meccan' || tempatTurun == 'makkiyyah';

      // Type filter
      if (_selectedFilter == 'Makkiyyah' && !isMeccan) return false;
      if (_selectedFilter == 'Madaniyyah' && isMeccan) return false;

      // Search query
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return nomor == q ||
          namaLatin.contains(q) ||
          namaInggris.contains(q) ||
          namaArab.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSurahs;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Daftar 114 Surat Al-Qur\'an',
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
          // Search box & Filters
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari nama surat atau nomor (1-114)...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.muted),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.bg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _filterChip('Semua', _surahs.length),
                    const SizedBox(width: 8),
                    _filterChip('Makkiyyah', _countByType('Makkiyyah')),
                    const SizedBox(width: 8),
                    _filterChip('Madaniyyah', _countByType('Madaniyyah')),
                    const Spacer(),
                    Text(
                      '${filtered.length} Surat',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bluePale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data resmi 114 Surah Al-Qur\'an dari API Al-Quran Cloud (api.alquran.cloud).',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Surah List
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
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 48, color: AppColors.muted),
                                const SizedBox(height: 12),
                                Text(
                                  'Surat "$_searchQuery" tidak ditemukan',
                                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final s = filtered[i];
                              return _surahCard(s, i + 1);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  int _countByType(String type) {
    return _surahs.where((s) {
      final tempat = (s['tempat_turun'] ?? s['revelation_type'] ?? '').toString().toLowerCase();
      final isMeccan = tempat == 'meccan' || tempat == 'makkiyyah';
      return type == 'Makkiyyah' ? isMeccan : !isMeccan;
    }).length;
  }

  Widget _filterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.dark,
          ),
        ),
      ),
    );
  }

  Widget _surahCard(Map<String, dynamic> s, int index) {
    final nomor = s['nomor'] ?? s['number'] ?? index;
    final namaLatin = s['nama_latin'] ?? s['name'] ?? 'Surah';
    final namaArab = s['nama_arab'] ?? s['name_arabic'] ?? '';
    final namaInggris = s['nama_inggris'] ?? s['meaning'] ?? '-';
    final jumlahAyat = s['jumlah_ayat'] ?? s['number_of_ayahs'] ?? 0;
    final tempatTurun = (s['tempat_turun'] ?? s['revelation_type'] ?? 'Meccan').toString();
    final isMeccan = tempatTurun.toLowerCase() == 'meccan' || tempatTurun.toLowerCase() == 'makkiyyah';

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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$nomor',
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
                    Flexible(
                      child: Text(
                        namaLatin,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                  namaInggris,
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
                      '$jumlahAyat Ayat',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            namaArab,
            style: GoogleFonts.amiri(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
