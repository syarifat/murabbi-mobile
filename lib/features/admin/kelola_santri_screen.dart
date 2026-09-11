import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_confirm_dialog.dart';

class KelolaSantriScreen extends StatefulWidget {
  const KelolaSantriScreen({super.key});

  @override
  State<KelolaSantriScreen> createState() => _KelolaSantriScreenState();
}

class _KelolaSantriScreenState extends State<KelolaSantriScreen> {
  List<Map<String, dynamic>> _rombels = [];
  List<Map<String, dynamic>> _tanpaKelas = [];
  Map<String, dynamic>? _tahunAjaran;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient().dio.get(ApiEndpoints.rombelList);
      final data = resp.data['data'];
      setState(() {
        _tahunAjaran = data['tahun_ajaran'];
        _rombels = (data['rombels'] as List).map((r) => r as Map<String, dynamic>).toList();
        _tanpaKelas = (data['tanpa_kelas'] as List).map((s) => s as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint('Error loading rombel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _removeFromKelas(int santriId) async {
    try {
      await ApiClient().dio.post(ApiEndpoints.rombelRemove, data: {
        'santri_id': santriId,
      });
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siswa dikeluarkan dari kelas'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      debugPrint('Error remove: $e');
    }
  }

  void _showKelasDetail(Map<String, dynamic> rombel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _KelasDetailScreen(
          rombel: rombel,
          onRemove: _removeFromKelas,
          onRefresh: _loadData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Rombel',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tahunAjaran != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tahun Ajaran: ${_tahunAjaran!['nama'] ?? '-'}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DAFTAR KELAS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                if (_tanpaKelas.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_tanpaKelas.length} tanpa kelas',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading && _rombels.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _rombels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.class_outlined, size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada kelas',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambah kelas di menu Master > Kelas',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _rombels.length,
                        itemBuilder: (ctx, i) {
                          final rombel = _rombels[i];
                          return _rombelCard(rombel);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _rombelCard(Map<String, dynamic> rombel) {
    final count = rombel['santris_count'] as int? ?? 0;
    return GestureDetector(
      onTap: () => _showKelasDetail(rombel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'K${rombel['id'] ?? '?'}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rombel['nama_kelas'] ?? '-',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        '$count Siswa',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _KelasDetailScreen extends StatefulWidget {
  final Map<String, dynamic> rombel;
  final Future<void> Function(int santriId) onRemove;
  final Future<void> Function() onRefresh;

  const _KelasDetailScreen({
    required this.rombel,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  State<_KelasDetailScreen> createState() => _KelasDetailScreenState();
}

class _KelasDetailScreenState extends State<_KelasDetailScreen> {
  List<Map<String, dynamic>> get _santris {
    return (widget.rombel['santris'] as List? ?? [])
        .map((s) => s as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          widget.rombel['nama_kelas'] ?? 'Kelas',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildSantriList(),
    );
  }

  Widget _buildSantriList() {
    if (_santris.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Belum ada siswa di kelas ini',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark),
              ),
              const SizedBox(height: 8),
              Text(
                'Untuk menambahkan siswa ke kelas ini, pilih siswa dari daftar "Siswa Belum Ada Kelas" di halaman Rombel.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _santris.length,
      itemBuilder: (ctx, i) {
        final s = _santris[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryPale,
                radius: 20,
                child: Text(
                  ((s['nama_lengkap'] as String?)?.isNotEmpty == true ? s['nama_lengkap'][0] : 'S').toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['nama_lengkap'] ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS: ${s['nis'] ?? '-'}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_outlined, color: AppColors.red),
                tooltip: 'Keluarkan dari Kelas',
                onPressed: () => _confirmRemove(s),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmRemove(Map<String, dynamic> s) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Keluarkan dari Kelas?',
      message: 'Yakin ingin mengeluarkan ${s['nama_lengkap']} dari kelas ini?',
      confirmLabel: 'Ya, Keluarkan',
      cancelLabel: 'Batal',
      confirmColor: AppColors.red,
      icon: Icons.person_remove_rounded,
    );

    if (confirmed == true) {
      await widget.onRemove(s['id'] as int);
      setState(() {
        (widget.rombel['santris'] as List?)?.removeWhere((item) => item['id'] == s['id']);
        final currentCount = widget.rombel['santris_count'] as int? ?? 1;
        widget.rombel['santris_count'] = currentCount > 0 ? currentCount - 1 : 0;
      });
      await widget.onRefresh();
    }
  }
}
