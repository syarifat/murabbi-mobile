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
  List<Map<String, dynamic>> _rombels = [];
  bool _isLoading = false;
  final _namaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient().dio.get(ApiEndpoints.masterKelasAll);
      setState(() {
        _rombels = (resp.data['data'] as List).map((r) {
          return {
            'id': r['id'],
            'nama_kelas': r['nama_kelas'],
            'tahun_ajaran': r['tahun_ajaran']?['nama'] ?? '-',
            'santris_count': r['santris_count'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading kelas: $e');
    } finally {
      setState(() => _isLoading = false);
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
        // Create - use store endpoint
        await ApiClient().dio.post(
          ApiEndpoints.masterKelasStore,
          data: {
            'nama_kelas': _namaCtrl.text.trim(),
          },
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      _namaCtrl.clear();
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id != null ? 'Kelas berhasil diperbarui' : 'Kelas berhasil ditambahkan'),
          backgroundColor: AppColors.primary,
        ),
      );
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

  Future<void> _deleteKelas(Map<String, dynamic> rombel) async {
    if ((rombel['santris_count'] as int? ?? 0) > 0) {
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
      message: 'Yakin ingin menghapus kelas "${rombel['nama_kelas']}"? Data ini tidak dapat dikembalikan.',
      confirmLabel: 'Ya, Hapus',
      cancelLabel: 'Batal',
      confirmColor: AppColors.red,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ApiClient().dio.delete(
          ApiEndpoints.masterKelasDelete(rombel['id'] as int),
        );
        await _loadData();
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

  void _showEditModal(Map<String, dynamic> rombel) {
    _namaCtrl.text = rombel['nama_kelas'] ?? '';
    _showFormModal(id: rombel['id'] as int);
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
                Text(
                  isEdit ? 'Edit Kelas' : 'Tambah Kelas',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
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
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading && _rombels.isEmpty
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
                        style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Klik tombol + untuk menambah kelas',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rombels.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final r = _rombels[i];
                    return _kelasCard(r);
                  },
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
