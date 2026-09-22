import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_confirm_dialog.dart';

class MasterKelasScreen extends StatefulWidget {
  const MasterKelasScreen({super.key});

  @override
  State<MasterKelasScreen> createState() => _MasterKelasScreenState();
}

class _MasterKelasScreenState extends State<MasterKelasScreen> {
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _tahunAjarans = [];
  int? _selectedTahunAjaranId;
  String _selectedTahunAjaranNama = '';
  bool _selectedTahunAjaranAktif = true;
  bool _isLoading = false;
  final _namaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch available Tahun Ajaran list
      final taResp = await ApiClient().dio.get(ApiEndpoints.masterTahunAjaran);
      final taRaw = taResp.data['data'] as List<dynamic>? ?? [];
      final taList = taRaw.map((t) {
        return {
          'id': t['id'] as int,
          'nama': t['nama'] as String? ?? '-',
          'aktif': t['aktif'] == true || t['aktif'] == 1,
        };
      }).toList();

      if (taList.isNotEmpty) {
        final activeTa = taList.firstWhere(
          (t) => t['aktif'] == true,
          orElse: () => taList.first,
        );
        _selectedTahunAjaranId = activeTa['id'] as int;
        _selectedTahunAjaranNama = activeTa['nama'] as String;
        _selectedTahunAjaranAktif = activeTa['aktif'] as bool;
      }
      _tahunAjarans = taList;

      // 2. Fetch kelas for selected tahun ajaran
      await _loadKelasOnly(setLoadingState: false);
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadKelasOnly({bool setLoadingState = true}) async {
    if (setLoadingState) setState(() => _isLoading = true);
    try {
      final resp = await ApiClient().dio.get(
        ApiEndpoints.masterKelasAll,
        queryParameters: _selectedTahunAjaranId != null
            ? {'tahun_ajaran_id': _selectedTahunAjaranId}
            : null,
      );

      final dataList = resp.data['data'] as List<dynamic>? ?? [];
      final activeTaInfo = resp.data['tahun_ajaran'];
      if (_selectedTahunAjaranNama.isEmpty && activeTaInfo != null) {
        _selectedTahunAjaranNama = activeTaInfo['nama'] ?? '';
      }

      setState(() {
        _kelasList = dataList.map((r) {
          final m = r as Map<String, dynamic>;
          return {
            'id': m['id'],
            'nama_kelas': m['nama_kelas'] ?? '-',
            'tahun_ajaran': m['tahun_ajaran']?['nama'] ?? _selectedTahunAjaranNama,
            'santris_count': m['santris_count'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading kelas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar kelas: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (setLoadingState && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveKelas({int? id}) async {
    if (_namaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kelas harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (id != null) {
        // Update - call update endpoint
        await ApiClient().dio.put(
          ApiEndpoints.masterKelasUpdate(id),
          data: {
            'nama_kelas': _namaCtrl.text.trim(),
          },
        );
      } else {
        // Create - use store endpoint with current tahun_ajaran_id
        await ApiClient().dio.post(
          ApiEndpoints.masterKelasStore,
          data: {
            'nama_kelas': _namaCtrl.text.trim(),
            if (_selectedTahunAjaranId != null) 'tahun_ajaran_id': _selectedTahunAjaranId,
          },
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      _namaCtrl.clear();
      await _loadKelasOnly();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(id != null ? 'Kelas berhasil diperbarui' : 'Kelas berhasil ditambahkan'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving kelas: $e');
      String msg = 'Gagal menyimpan kelas';
      if (e is DioException && e.response?.data?['message'] != null) {
        msg = e.response!.data['message'].toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteKelas(Map<String, dynamic> kelas) async {
    if ((kelas['santris_count'] as int? ?? 0) > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa hapus kelas yang sudah memiliki siswa'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Hapus Kelas?',
      message: 'Yakin ingin menghapus kelas "${kelas['nama_kelas']}"? Data ini tidak dapat dikembalikan.',
      confirmLabel: 'Ya, Hapus',
      cancelLabel: 'Batal',
      confirmColor: AppColors.red,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ApiClient().dio.delete(
          ApiEndpoints.masterKelasDelete(kelas['id'] as int),
        );
        await _loadKelasOnly();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kelas berhasil dihapus'), backgroundColor: AppColors.primary),
          );
        }
      } catch (e) {
        debugPrint('Error deleting kelas: $e');
        String msg = 'Gagal menghapus kelas';
        if (e is DioException && e.response?.data?['message'] != null) {
          msg = e.response!.data['message'].toString();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showAddModal() {
    _namaCtrl.clear();
    _showFormModal();
  }

  void _showEditModal(Map<String, dynamic> kelas) {
    _namaCtrl.text = kelas['nama_kelas'] ?? '';
    _showFormModal(id: kelas['id'] as int);
  }

  void _showFormModal({int? id}) {
    final isEdit = id != null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Kelas' : 'Tambah Kelas',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (_selectedTahunAjaranNama.isNotEmpty)
                      Text(
                        'Tahun Ajaran: $_selectedTahunAjaranNama',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            AppTextField(
              label: 'NAMA KELAS',
              hint: 'Contoh: Kelas 7A',
              controller: _namaCtrl,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: isEdit ? 'UPDATE' : 'SIMPAN',
              icon: Icons.save,
              isLoading: _isLoading,
              onPressed: () => _saveKelas(id: id),
            ),
          ],
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
          'Master Kelas',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadKelasOnly(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tahun Ajaran Selector Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAHUN AJARAN',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _selectedTahunAjaranNama.isNotEmpty
                                ? _selectedTahunAjaranNama
                                : 'Memuat...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          if (_selectedTahunAjaranAktif) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPale,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'AKTIF',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (_tahunAjarans.length > 1)
                  PopupMenuButton<int>(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune, color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Ganti',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    tooltip: 'Pilih Tahun Ajaran',
                    onSelected: (taId) {
                      final selected = _tahunAjarans.firstWhere((t) => t['id'] == taId);
                      setState(() {
                        _selectedTahunAjaranId = taId;
                        _selectedTahunAjaranNama = selected['nama'] ?? '';
                        _selectedTahunAjaranAktif = selected['aktif'] == true;
                      });
                      _loadKelasOnly();
                    },
                    itemBuilder: (ctx) => _tahunAjarans.map((t) {
                      final isSelected = t['id'] == _selectedTahunAjaranId;
                      final isAktif = t['aktif'] == true;
                      return PopupMenuItem<int>(
                        value: t['id'] as int,
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 18,
                              color: isSelected ? AppColors.primary : AppColors.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t['nama'] ?? '-',
                              style: GoogleFonts.inter(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            if (isAktif) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPale,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Aktif',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Body: List of Kelas or Empty State
          Expanded(
            child: _isLoading && _kelasList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _kelasList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.class_outlined,
                                size: 64,
                                color: AppColors.muted.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedTahunAjaranNama.isNotEmpty
                                    ? 'Belum ada kelas di Tahun Ajaran $_selectedTahunAjaranNama'
                                    : 'Belum ada kelas',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Klik tombol + di bawah untuk menambahkan kelas baru pada tahun ajaran ini.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _showAddModal,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Tambah Kelas Sekarang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _kelasList.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final k = _kelasList[i];
                          return _kelasCard(k);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _kelasCard(Map<String, dynamic> r) {
    final count = r['santris_count'] as int? ?? 0;
    return Container(
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'K${r['id']}',
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
                Text(
                  r['nama_kelas'] ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      count > 0 ? Icons.people : Icons.people_outline,
                      size: 14,
                      color: count > 0 ? AppColors.primary : AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count Siswa',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: count > 0 ? AppColors.primary : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      r['tahun_ajaran'] ?? '-',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.muted),
            onSelected: (val) {
              if (val == 'edit') {
                _showEditModal(r);
              } else if (val == 'delete') {
                _deleteKelas(r);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Edit', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: AppColors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
