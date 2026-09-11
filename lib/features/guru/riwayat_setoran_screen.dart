import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_confirm_dialog.dart';
import 'edit_setoran_screen.dart';

class RiwayatSetoranScreen extends StatefulWidget {
  const RiwayatSetoranScreen({super.key});

  @override
  State<RiwayatSetoranScreen> createState() => _RiwayatSetoranScreenState();
}

class _RiwayatSetoranScreenState extends State<RiwayatSetoranScreen> {
  String _selectedStatus = 'Semua';
  final _searchCtrl = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _setoranList = [];

  @override
  void initState() {
    super.initState();
    _fetchSetorans();
  }

  Future<void> _fetchSetorans() async {
    setState(() => _isLoading = true);
    String? statusFilter;
    if (_selectedStatus == 'Lancar') statusFilter = 'lancar';
    if (_selectedStatus == 'Kurang') statusFilter = 'kurang';
    if (_selectedStatus == 'Mengulang') statusFilter = 'mengulang';

    try {
      final queryParameters = <String, dynamic>{};
      if (statusFilter != null) {
        queryParameters['status'] = statusFilter;
      }
      final search = _searchCtrl.text.trim();
      if (search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      final response = await ApiClient().dio.get(
        ApiEndpoints.setorans,
        queryParameters: queryParameters,
      );
      final data = response.data['data'];
      if (!mounted) return;
      setState(() {
        _setoranList = data is Map<String, dynamic>
            ? (data['data'] as List? ?? [])
            : (data as List? ?? []);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat riwayat setoran.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSetoran(int id) async {
    try {
      await ApiClient().dio.delete('${ApiEndpoints.setorans}/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Data setoran berhasil dihapus!'),
        ),
      );
      _fetchSetorans();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus setoran.')),
        );
      }
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Status Kelancaran',
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
            ...['Semua', 'Lancar', 'Kurang', 'Mengulang'].map(
              (st) => ListTile(
                title: Text(
                  st,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: _selectedStatus == st
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedStatus = st);
                  Navigator.pop(ctx);
                  _fetchSetorans();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(dynamic log) async {
    final id = log['id'];
    final sName = log['santri']?['nama_lengkap'] ?? 'Siswa';
    final surah = log['surah']?['nama_latin'] ?? 'Surah';

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Hapus Riwayat Setoran?',
      message: 'Anda yakin ingin menghapus data setoran $sName ($surah)? Aksi ini tidak dapat dibatalkan.',
      confirmLabel: 'Ya, Hapus Data',
      cancelLabel: 'Batal',
      confirmColor: AppColors.red,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true && id != null) {
      _deleteSetoran(id);
    }
  }

  void _showDetailModal(dynamic log) {
    final sName = log['santri']?['nama_lengkap'] ?? 'Siswa';
    final kName = log['santri']?['kelas']?['nama_kelas'] ?? 'Kelas Tahfidz';
    final surah = log['surah']?['nama_latin'] ?? 'Surah';
    final ayat = '${log['ayat_mulai']}-${log['ayat_selesai']}';
    final status = log['status'] ?? 'lancar';
    final nilai = log['nilai'] ?? 85;
    final catatan = log['catatan'] ?? 'Tajwid dan kelancaran sangat baik.';
    final waktu = log['waktu_setor'] ?? '-';

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
                  'Detail Catatan Setoran',
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
            _buildRow('Siswa', sName),
            _buildRow('Kelas', kName),
            _buildRow('Materi Hafalan', '$surah (Ayat $ayat)'),
            _buildRow('Status Kelancaran', status.toString().toUpperCase()),
            _buildRow('Nilai Skor', '$nilai / 100'),
            _buildRow('Waktu Setor', waktu),
            const SizedBox(height: 12),
            Text(
              'Catatan Evaluasi Pembimbing:',
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

  Widget _buildRow(String label, String value) {
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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Riwayat Setoran Siswa',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.dark),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextFormField(
              controller: _searchCtrl,
              onFieldSubmitted: (_) => _fetchSetorans(),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.sub,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.send,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  onPressed: _fetchSetorans,
                ),
                hintText: 'Cari nama siswa / surah...',
              ),
            ),
          ),
          // Filter indicator pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Filter: ',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
                AppBadge(label: _selectedStatus, variant: BadgeVariant.neutral),
                const Spacer(),
                Text(
                  '${_setoranList.length} Entri Ditemukan',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _setoranList.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada data setoran ditemukan.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchSetorans,
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: _setoranList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final log = _setoranList[i];
                        final sName =
                            log['santri']?['nama_lengkap'] ?? 'Siswa';
                        final surah = log['surah']?['nama_latin'] ?? 'Surah';
                        final ayat =
                            "${log['ayat_mulai']}-${log['ayat_selesai']}";
                        final status = log['status'] ?? 'lancar';
                        final badgeVar = status == 'lancar'
                            ? BadgeVariant.success
                            : (status == 'kurang'
                                  ? BadgeVariant.warning
                                  : BadgeVariant.danger);

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
                                  Text(
                                    sName,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  AppBadge(
                                    label: status.toString().toUpperCase(),
                                    variant: badgeVar,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.menu_book,
                                    size: 14,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$surah · Ayat $ayat',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () => _showDetailModal(log),
                                    child: Text(
                                      'Lihat Detail Catatan',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditSetoranScreen(
                                                initialData: {
                                                  'id': log['id'],
                                                  'santri': sName,
                                                  'surah': surah,
                                                  'ayat_mulai':
                                                      log['ayat_mulai'],
                                                  'ayat_selesai':
                                                      log['ayat_selesai'],
                                                  'status': status,
                                                  'catatan':
                                                      log['catatan'] ?? '',
                                                },
                                              ),
                                            ),
                                          ).then((_) => _fetchSetorans());
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryPale,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _showDeleteDialog(log),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.redPale,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            size: 14,
                                            color: AppColors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
