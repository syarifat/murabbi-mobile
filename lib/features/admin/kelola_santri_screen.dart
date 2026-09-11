import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

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

  Future<void> _assignToKelas(int rombelId, int santriId) async {
    try {
      await ApiClient().dio.post(ApiEndpoints.rombelAssign, data: {
        'santri_id': santriId,
        'kelas_id': rombelId,
      });
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siswa berhasil dimasukkan ke kelas'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      debugPrint('Error assign: $e');
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
          tanpaKelas: _tanpaKelas,
          onAssign: _assignToKelas,
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
  final List<Map<String, dynamic>> tanpaKelas;
  final Future<void> Function(int rombelId, int santriId) onAssign;
  final Future<void> Function(int santriId) onRemove;
  final Future<void> Function() onRefresh;

  const _KelasDetailScreen({
    required this.rombel,
    required this.tanpaKelas,
    required this.onAssign,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  State<_KelasDetailScreen> createState() => _KelasDetailScreenState();
}

class _KelasDetailScreenState extends State<_KelasDetailScreen> {
  bool _showTanpaKelas = false;

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
        actions: [
          IconButton(
            icon: Icon(_showTanpaKelas ? Icons.group : Icons.person_add),
            tooltip: _showTanpaKelas ? 'Lihat di Kelas' : 'Tambah Siswa',
            onPressed: () => setState(() => _showTanpaKelas = !_showTanpaKelas),
          ),
        ],
      ),
      body: _showTanpaKelas ? _buildTanpaKelas() : _buildSantriList(),
      floatingActionButton: _showTanpaKelas
          ? FloatingActionButton.extended(
              onPressed: () => _showAssignDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Tambah Siswa',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSantriList() {
    if (_santris.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Belum ada siswa di kelas ini',
              style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              'Klik tombol + untuk menambahkan',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
            ),
          ],
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryPale,
                radius: 20,
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['nama_lengkap'] ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.red),
                tooltip: 'Keluarkan dari kelas',
                onPressed: () => _confirmRemove(s),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTanpaKelas() {
    final tanpa = widget.tanpaKelas;
    if (tanpa.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Semua siswa sudah punya kelas',
              style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.goldPale,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${tanpa.length} Siswa belum masuk kelas manapun',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tanpa.length,
            itemBuilder: (ctx, i) {
              final s = tanpa[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.goldPale,
                      radius: 20,
                      child: const Icon(Icons.person_outline, color: AppColors.gold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['nama_lengkap'] ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                    ElevatedButton(
                      onPressed: () => _confirmAssign(s),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        'Masukkan',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAssignDialog() {
    if (widget.tanpaKelas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua siswa sudah punya kelas')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Siswa',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: widget.tanpaKelas.length,
                itemBuilder: (ctx, i) {
                  final s = widget.tanpaKelas[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.goldPale,
                      child: const Icon(Icons.person_outline, color: AppColors.gold),
                    ),
                    title: Text(
                      s['nama_lengkap'] ?? '-',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('NIS: ${s['nis'] ?? '-'}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmAssign(s);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pilih'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAssign(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Masukkan ke Kelas', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Yakin masukkan ${s['nama_lengkap']} ke ${widget.rombel['nama_kelas']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.onAssign(widget.rombel['id'] as int, s['id'] as int);
              await widget.onRefresh();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ya, Masukkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Keluarkan dari Kelas', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Yakin keluarkan ${s['nama_lengkap']} dari kelas ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.onRemove(s['id'] as int);
              await widget.onRefresh();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Ya, Keluarkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
