import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_confirm_dialog.dart';

class RombelScreen extends StatefulWidget {
  const RombelScreen({super.key});

  @override
  State<RombelScreen> createState() => _RombelScreenState();
}

class _RombelScreenState extends State<RombelScreen> {
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
        _rombels = (data['rombels'] as List).cast<Map<String, dynamic>>();
        _tanpaKelas = (data['tanpa_kelas'] as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Error loading rombel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red),
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
          const SnackBar(content: Text('Berhasil'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      debugPrint('Error assign: $e');
    }
  }

  Future<void> _removeFromKelas(int santriId) async {
    try {
      await ApiClient().dio.post(ApiEndpoints.rombelRemove, data: {'santri_id': santriId});
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil'), backgroundColor: AppColors.primary),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
            child: Text(
              'DAFTAR KELAS',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading && _rombels.isEmpty && _tanpaKelas.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // List kelas
                        ..._rombels.map((rombel) => _rombelCard(rombel)),
                        // Section tanpa kelas
                        if (_tanpaKelas.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _tanpaKelasSection(),
                        ],
                        if (_rombels.isEmpty && _tanpaKelas.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.class_outlined,
                                      size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada kelas',
                                    style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tambah kelas di Master > Master Kelas',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.primaryPale, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(
                  'K${rombel['id'] ?? '?'}',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
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
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text('$count Siswa', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
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

  Widget _tanpaKelasSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.goldPale,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SISWA BELUM ADA KELAS (${_tanpaKelas.length})',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._tanpaKelas.map((s) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.goldPale,
                  child: const Icon(Icons.person_outline, color: AppColors.gold, size: 20),
                ),
                title: Text(s['nama_lengkap'] ?? '-', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('NIS: ${s['nis'] ?? '-'}'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                onTap: () => _showPilihKelasDialog(s),
              )),
        ],
      ),
    );
  }

  void _showPilihKelasDialog(Map<String, dynamic> santri) {
    if (_rombels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada kelas yang dibuat. Silakan buat kelas terlebih dahulu.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Kelas untuk Siswa',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
                        ),
                        Text(
                          santri['nama_lengkap'] ?? '-',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (_rombels.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Belum ada kelas yang tersedia.',
                      style: GoogleFonts.inter(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _rombels.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final rombel = _rombels[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryPale,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'K${rombel['id']}',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                          title: Text(
                            rombel['nama_kelas'] ?? '-',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${rombel['santris_count'] ?? 0} Siswa terdaftar',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                          ),
                          trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _assignToKelas(rombel['id'] as int, santri['id'] as int);
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
    return ((widget.rombel['santris'] as List?) ?? []).cast<Map<String, dynamic>>();
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
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS: ${s['nis'] ?? '-'}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
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
