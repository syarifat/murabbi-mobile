import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/app_confirm_dialog.dart';

class MasterSantriScreen extends StatefulWidget {
  const MasterSantriScreen({super.key});

  @override
  State<MasterSantriScreen> createState() => _MasterSantriScreenState();
}

class _MasterSantriScreenState extends State<MasterSantriScreen> {
  List<Map<String, dynamic>> _santris = [];
  List<Map<String, dynamic>> _ortuList = [];
  bool _isLoading = false;

  // Form controllers
  final _namaCtrl = TextEditingController();
  final _nisCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _waliNamaCtrl = TextEditingController();
  final _waliEmailCtrl = TextEditingController();
  final _waliHpCtrl = TextEditingController();
  final _waliPasswordCtrl = TextEditingController();
  final _waliAlamatCtrl = TextEditingController();

  int? _selectedKelasId;
  int? _selectedOrtuId;
  bool _createWaliAccount = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nisCtrl.dispose();
    _alamatCtrl.dispose();
    _waliNamaCtrl.dispose();
    _waliEmailCtrl.dispose();
    _waliHpCtrl.dispose();
    _waliPasswordCtrl.dispose();
    _waliAlamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final santrisResp = await ApiClient().dio.get(ApiEndpoints.masterSantrisAll);
      final ortuResp = await ApiClient().dio.get(ApiEndpoints.masterOrtu);

      setState(() {
        _santris = (santrisResp.data['data'] as List).map((s) {
          return {
            'id': s['id'],
            'nama': s['nama_lengkap'],
            'nis': s['nis'],
            'alamat': s['alamat'] ?? '-',
            'kelas': s['kelas']?['nama_kelas'] ?? '-',
            'wali': s['wali'] != null
                ? {
                    'id': s['wali']['id'],
                    'nama': s['wali']['name'],
                    'email': s['wali']['email'],
                    'hp': s['wali']['no_hp'] ?? '-',
                    'alamat': s['wali']['alamat'] ?? '-',
                  }
                : null,
          };
        }).toList();

        _ortuList = (ortuResp.data['data'] as List).map((o) {
          return {
            'id': o['id'],
            'nama': o['name'],
            'email': o['email'],
            'hp': o['no_hp'] ?? '-',
            'alamat': o['alamat'] ?? '-',
            'santris_count': o['santris_count'],
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _namaCtrl.clear();
    _nisCtrl.clear();
    _alamatCtrl.clear();
    _waliNamaCtrl.clear();
    _waliEmailCtrl.clear();
    _waliHpCtrl.clear();
    _waliPasswordCtrl.clear();
    _waliAlamatCtrl.clear();
    setState(() {
      _selectedKelasId = null;
      _selectedOrtuId = null;
      _createWaliAccount = true;
    });
  }

  Future<void> _saveSantri() async {
    if (_namaCtrl.text.trim().isEmpty || _nisCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan NIS harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'nama_lengkap': _namaCtrl.text.trim(),
        'nis': _nisCtrl.text.trim(),
        'alamat': _alamatCtrl.text.trim().isNotEmpty ? _alamatCtrl.text.trim() : null,
        'kelas_id': _selectedKelasId,
        'create_wali_account': _createWaliAccount,
      };

      if (_createWaliAccount) {
        payload['wali_nama'] = _waliNamaCtrl.text.trim();
        payload['wali_email'] = _waliEmailCtrl.text.trim().isNotEmpty
            ? _waliEmailCtrl.text.trim()
            : '${_nisCtrl.text.trim()}@wali.local';
        payload['wali_hp'] = _waliHpCtrl.text.trim().isNotEmpty ? _waliHpCtrl.text.trim() : null;
        payload['wali_password'] = _waliPasswordCtrl.text.trim().isNotEmpty
            ? _waliPasswordCtrl.text.trim()
            : 'password123';
        payload['wali_alamat'] = _waliAlamatCtrl.text.trim().isNotEmpty
            ? _waliAlamatCtrl.text.trim()
            : null;
      } else if (_selectedOrtuId != null) {
        payload['wali_id'] = _selectedOrtuId;
      }

      await ApiClient().dio.post(ApiEndpoints.santrisAdmin, data: payload);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Siswa berhasil ditambahkan'),
          ),
        );
        _clearForm();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Gagal menambahkan siswa';
        if (e is DioException && e.response?.data?['message'] != null) {
          msg = e.response!.data['message'].toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.red,
            content: Text(msg),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddModal() {
    _clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tambah Data Siswa',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _clearForm();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const Divider(),

                // Data Siswa
                _sectionTitle('DATA SISWA'),
                AppTextField(
                  label: 'NAMA LENGKAP',
                  hint: 'Nama lengkap siswa',
                  controller: _namaCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'NIS',
                  hint: 'Nomor Induk Siswa',
                  controller: _nisCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'ALAMAT',
                  hint: 'Alamat lengkap',
                  controller: _alamatCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Data Orang Tua
                _sectionTitle('DATA ORANG TUA / WALI'),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _createWaliAccount,
                        activeColor: AppColors.gold,
                        onChanged: (v) {
                          setModal(() => _createWaliAccount = v ?? true);
                          setState(() => _createWaliAccount = v ?? true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Buat akun orang tua baru', style: GoogleFonts.inter(fontSize: 13)),
                  ],
                ),

                if (_createWaliAccount) ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'NAMA ORANG TUA',
                    hint: 'Nama lengkap ortu',
                    controller: _waliNamaCtrl,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'EMAIL ORANG TUA',
                    hint: 'email@contoh.com',
                    controller: _waliEmailCtrl,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'NO. HP',
                    hint: '+62 812-3456-7890',
                    controller: _waliHpCtrl,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'PASSWORD (default: password123)',
                    hint: 'Kosongkan untuk default',
                    controller: _waliPasswordCtrl,
                    isPassword: true,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'ALAMAT ORANG TUA',
                    hint: 'Alamat lengkap ortu',
                    controller: _waliAlamatCtrl,
                    maxLines: 2,
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  AppDropdown<int?>(
                    label: 'PILIH ORANG TUA',
                    hint: 'Pilih Orang Tua / Wali',
                    leadIcon: Icons.family_restroom_rounded,
                    leadIconColor: const Color(0xFFD97706),
                    value: _selectedOrtuId,
                    items: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '- Belum Ditentukan -',
                        icon: Icons.remove_circle_outline,
                        iconColor: AppColors.muted,
                      ),
                      ..._ortuList.map((o) => AppDropdownItem<int?>(
                        value: o['id'] as int,
                        label: o['nama'] as String,
                        subtitle: '${o['santris_count']} anak terdaftar',
                        initial: ((o['nama'] as String?)?.isNotEmpty == true ? o['nama'][0] : 'O').toUpperCase(),
                        iconColor: const Color(0xFFD97706),
                      )),
                    ],
                    onChanged: (v) {
                      setModal(() => _selectedOrtuId = v);
                      setState(() => _selectedOrtuId = v);
                    },
                  ),
                ],

                const SizedBox(height: 20),
                AppButton(
                  label: 'SIMPAN',
                  icon: Icons.save,
                  isLoading: _isLoading,
                  onPressed: _saveSantri,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditModal(Map<String, dynamic> s) {
    _namaCtrl.text = s['nama']?.toString() ?? '';
    _nisCtrl.text = s['nis']?.toString() ?? '';
    _alamatCtrl.text = (s['alamat'] != null && s['alamat'] != '-') ? s['alamat'].toString() : '';
    int? editOrtuId = s['wali']?['id'] as int?;
    final santriId = s['id'] as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Data Siswa',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _clearForm();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const Divider(),

                // Data Siswa
                _sectionTitle('DATA SISWA'),
                AppTextField(
                  label: 'NAMA LENGKAP',
                  hint: 'Nama lengkap siswa',
                  controller: _namaCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'NIS',
                  hint: 'Nomor Induk Siswa',
                  controller: _nisCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'ALAMAT',
                  hint: 'Alamat lengkap',
                  controller: _alamatCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Data Orang Tua / Wali
                _sectionTitle('ORANG TUA / WALI'),
                AppDropdown<int?>(
                  label: 'PILIH ORANG TUA / WALI',
                  hint: 'Pilih Orang Tua / Wali',
                  leadIcon: Icons.family_restroom_rounded,
                  leadIconColor: const Color(0xFFD97706),
                  value: editOrtuId,
                  items: [
                    const AppDropdownItem<int?>(
                      value: null,
                      label: '- Belum Ditentukan -',
                      icon: Icons.remove_circle_outline,
                      iconColor: AppColors.muted,
                    ),
                    ..._ortuList.map((o) => AppDropdownItem<int?>(
                      value: o['id'] as int,
                      label: o['nama'] as String,
                      subtitle: '${o['santris_count']} anak terdaftar',
                      initial: ((o['nama'] as String?)?.isNotEmpty == true ? o['nama'][0] : 'O').toUpperCase(),
                      iconColor: const Color(0xFFD97706),
                    )),
                  ],
                  onChanged: (v) {
                    setModal(() => editOrtuId = v);
                  },
                ),

                const SizedBox(height: 20),
                AppButton(
                  label: 'SIMPAN PERUBAHAN',
                  icon: Icons.save,
                  isLoading: _isLoading,
                  onPressed: () => _updateSantri(ctx, santriId, editOrtuId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateSantri(BuildContext ctx, int santriId, int? waliId) async {
    if (_namaCtrl.text.trim().isEmpty || _nisCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan NIS harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = <String, dynamic>{
        'nama_lengkap': _namaCtrl.text.trim(),
        'nis': _nisCtrl.text.trim(),
        'alamat': _alamatCtrl.text.trim().isNotEmpty ? _alamatCtrl.text.trim() : null,
        'wali_id': waliId,
      };

      await ApiClient().dio.put(
        ApiEndpoints.santriUpdate(santriId),
        data: payload,
      );

      if (ctx.mounted) Navigator.pop(ctx);
      await _loadData();
      _clearForm();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Data siswa berhasil diperbarui'),
        ),
      );
    } catch (e) {
      if (mounted) {
        String msg = 'Gagal memperbarui data siswa';
        if (e is DioException && e.response?.data?['message'] != null) {
          msg = e.response!.data['message'].toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.red,
            content: Text(msg),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> s) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Hapus Data Siswa?',
      message: 'Yakin ingin menghapus siswa "${s['nama']}" (NIS: ${s['nis']})? Data setoran dan hafalan yang terhubung akan terhapus.',
      confirmLabel: 'Ya, Hapus',
      cancelLabel: 'Batal',
      confirmColor: AppColors.red,
      icon: Icons.person_remove_rounded,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient().dio.delete(ApiEndpoints.santriDelete(s['id'] as int));
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Data siswa "${s['nama']}" berhasil dihapus.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.red,
          content: Text('Gagal menghapus siswa: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
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
          'Master Data Siswa',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading && _santris.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _santris.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = _santris[i];
                return _santriCard(s);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _santriCard(Map<String, dynamic> s) {
    return InkWell(
      onTap: () => _showEditModal(s),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryPale,
                  radius: 24,
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['nama'],
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'NIS: ${s['nis']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppBadge(
                  label: s['kelas'] != '-' ? '✓ Ada Kelas' : 'Tanpa Kelas',
                  variant: s['kelas'] != '-' ? BadgeVariant.success : BadgeVariant.warning,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                  tooltip: 'Edit Siswa',
                  onPressed: () => _showEditModal(s),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
                  tooltip: 'Hapus Siswa',
                  onPressed: () => _confirmDelete(s),
                ),
              ],
            ),
          if (s['alamat'] != '-') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    s['alamat'],
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'ORANG TUA / WALI',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          if (s['wali'] != null) ...[
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.goldPale,
                  radius: 18,
                  child: const Icon(Icons.person_outline, color: AppColors.gold, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['wali']['nama'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        s['wali']['email'],
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                      ),
                      if (s['wali']['hp'] != '-')
                        Text(
                          s['wali']['hp'],
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldPale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Belum ada data orang tua',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}
