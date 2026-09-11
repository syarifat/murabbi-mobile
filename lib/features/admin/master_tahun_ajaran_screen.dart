import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_confirm_dialog.dart';

class MasterTahunAjaranScreen extends StatefulWidget {
  const MasterTahunAjaranScreen({super.key});

  @override
  State<MasterTahunAjaranScreen> createState() => _MasterTahunAjaranScreenState();
}

class _MasterTahunAjaranScreenState extends State<MasterTahunAjaranScreen> {
  List<Map<String, dynamic>> _items = [];
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
      final resp = await ApiClient().dio.get(ApiEndpoints.masterTahunAjaran);
      setState(() {
        _items = (resp.data['data'] as List).map((t) {
          return {
            'id': t['id'],
            'nama': t['nama'],
            'aktif': t['aktif'] == true || t['aktif'] == 1,
            'kelas_count': t['kelas_count'] ?? 0,
            'santris_count': t['santris_count'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setAktif(int id) async {
    try {
      await ApiClient().dio.put('${ApiEndpoints.masterTahunAjaran}/$id', data: {'aktif': true});
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tahun ajaran berhasil diaktifkan'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Hapus Tahun Ajaran?',
      message: 'Yakin ingin menghapus tahun ajaran "${item['nama']}"? Data ini tidak dapat dikembalikan.',
      confirmLabel: 'Ya, Hapus',
      cancelLabel: 'Batal',
      confirmColor: AppColors.red,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      try {
        await ApiClient().dio.delete('${ApiEndpoints.masterTahunAjaran}/${item['id']}');
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red),
          );
        }
      }
    }
  }

  void _showAddModal() {
    _namaCtrl.clear();
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
                  'Tambah Tahun Ajaran',
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
              label: 'NAMA TAHUN AJARAN',
              hint: '2026/2027',
              controller: _namaCtrl,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'SIMPAN',
              icon: Icons.save,
              isLoading: _isLoading,
              onPressed: () => _saveItem(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem(BuildContext ctx) async {
    if (_namaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tahun ajaran harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiClient().dio.post(ApiEndpoints.masterTahunAjaran, data: {
        'nama': _namaCtrl.text.trim(),
      });
      if (ctx.mounted) Navigator.pop(ctx);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil ditambahkan'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Tahun Ajaran',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month,
                          size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada tahun ajaran',
                        style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _itemCard(_items[i]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    final isAktif = item['aktif'] as bool;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAktif ? AppColors.primary : AppColors.border,
          width: isAktif ? 2 : 1,
        ),
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
              color: isAktif ? AppColors.primaryPale : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month,
              color: isAktif ? AppColors.primary : AppColors.muted,
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
                      item['nama'] ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isAktif) ...[
                      const SizedBox(width: 8),
                      const AppBadge(label: 'AKTIF', variant: BadgeVariant.success),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.class_, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${item['kelas_count']} Kelas',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.people, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${item['santris_count']} Siswa',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isAktif)
            TextButton(
              onPressed: () => _setAktif(item['id'] as int),
              child: Text(
                'Aktifkan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.muted),
            onSelected: (val) {
              if (val == 'delete') _deleteItem(item);
            },
            itemBuilder: (ctx) => [
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
