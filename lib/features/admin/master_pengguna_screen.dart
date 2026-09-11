import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_confirm_dialog.dart';

class MasterPenggunaScreen extends StatefulWidget {
  const MasterPenggunaScreen({super.key});

  @override
  State<MasterPenggunaScreen> createState() => _MasterPenggunaScreenState();
}

class _MasterPenggunaScreenState extends State<MasterPenggunaScreen> {
  String _selectedRole = 'Semua';
  List<Map<String, dynamic>> _users = [];
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nipCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _nipCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.get(
        ApiEndpoints.users,
        queryParameters: _selectedRole != 'Semua' ? {'role': _selectedRole} : null,
      );
      final data = (response.data['data'] as List<dynamic>? ?? []);
      setState(() {
        _users = data.map((item) {
          final user = item as Map<String, dynamic>;
          final role = user['role']?.toString() ?? '-';
          final roleLabel = role == 'ortu'
              ? 'Orang Tua'
              : role == 'guru'
                  ? 'Guru'
                  : role == 'admin'
                      ? 'Admin'
                      : role;
          return {
            'id': user['id'],
            'name': user['name'] ?? '-',
            'email': user['email'] ?? '',
            'role': role,
            'roleLabel': roleLabel,
            'no_hp': user['no_hp'] ?? '',
            'nip': user['nip'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _passwordCtrl.clear();
    _nipCtrl.clear();
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tambah Akun Baru',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: AppColors.primary),
              ),
              title: const Text('Guru'),
              subtitle: const Text('Tambah akun guru pengajar'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddModal(role: 'guru');
              },
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.bluePale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings, color: AppColors.blue),
              ),
              title: const Text('Admin'),
              subtitle: const Text('Tambah akun administrator'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddModal(role: 'admin');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddModal({required String role}) {
    _clearForm();
    String currentRole = role;
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
                      'Tambah ${currentRole == 'guru' ? 'Guru' : 'Admin'}',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                AppTextField(
                  label: 'NAMA LENGKAP',
                  hint: 'Ust. Zulkifli, M.Ag',
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'EMAIL',
                  hint: 'zulkifli@sekolah.ac.id',
                  controller: _emailCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'PASSWORD (default: password123)',
                  hint: 'Kosongkan untuk default',
                  controller: _passwordCtrl,
                  isPassword: true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'NO. WHATSAPP',
                  hint: '+62 812-3456-7890',
                  controller: _phoneCtrl,
                ),
                if (currentRole == 'guru') ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'NIP',
                    hint: '198801012022',
                    controller: _nipCtrl,
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: 'SIMPAN',
                  icon: Icons.save,
                  isLoading: _isLoading,
                  onPressed: () => _saveUser(ctx, currentRole),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveUser(BuildContext ctx, String role) async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan email harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim().isNotEmpty
            ? _passwordCtrl.text.trim()
            : 'password123',
        'role': role,
        'no_hp': _phoneCtrl.text.trim(),
        if (role == 'guru') 'nip': _nipCtrl.text.trim(),
      };

      await ApiClient().dio.post(ApiEndpoints.users, data: payload);

      if (ctx.mounted) Navigator.pop(ctx);
      await _loadUsers();
      _clearForm();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$role berhasil ditambahkan'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditModal(Map<String, dynamic> u) {
    _nameCtrl.text = u['name']?.toString() ?? '';
    _emailCtrl.text = u['email']?.toString() ?? '';
    _phoneCtrl.text = u['no_hp']?.toString() ?? '';
    _nipCtrl.text = u['nip']?.toString() ?? '';
    _passwordCtrl.clear();
    String currentRole = u['role']?.toString() ?? 'guru';
    final userId = u['id'] as int;

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
                      'Edit Pengguna',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'ROLE / PERAN',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    {'role': 'admin', 'label': 'Admin'},
                    {'role': 'guru', 'label': 'Guru'},
                    {'role': 'ortu', 'label': 'Orang Tua'},
                  ].map((r) {
                    final isSel = currentRole == r['role'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          r['label']!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : AppColors.muted,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        onSelected: (selected) {
                          if (selected) {
                            setModal(() => currentRole = r['role']!);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'NAMA LENGKAP',
                  hint: 'Masukkan nama lengkap',
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'EMAIL',
                  hint: 'email@sekolah.ac.id',
                  controller: _emailCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'GANTI PASSWORD (OPSIONAL)',
                  hint: 'Kosongkan jika tidak ingin diubah',
                  controller: _passwordCtrl,
                  isPassword: true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'NO. WHATSAPP',
                  hint: '+62 812-3456-7890',
                  controller: _phoneCtrl,
                ),
                if (currentRole == 'guru') ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'NIP',
                    hint: '198801012022',
                    controller: _nipCtrl,
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: 'SIMPAN PERUBAHAN',
                  icon: Icons.save,
                  isLoading: _isLoading,
                  onPressed: () => _updateUser(ctx, userId, currentRole),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateUser(BuildContext ctx, int userId, String role) async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan email harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': role,
        'no_hp': _phoneCtrl.text.trim(),
      };

      if (_passwordCtrl.text.trim().isNotEmpty) {
        payload['password'] = _passwordCtrl.text.trim();
      }

      if (role == 'guru') {
        payload['nip'] = _nipCtrl.text.trim();
      }

      await ApiClient().dio.put(
        ApiEndpoints.userUpdate(userId),
        data: payload,
      );

      if (ctx.mounted) Navigator.pop(ctx);
      await _loadUsers();
      _clearForm();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pengguna berhasil diperbarui'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: AppColors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> u) async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = prefs.getString('user_email');

    if (currentEmail != null && currentEmail.toLowerCase() == (u['email'] as String).toLowerCase()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat menghapus akun Anda sendiri yang sedang aktif.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Hapus Pengguna?',
      message: 'Yakin ingin menghapus akun "${u['name']}" (${u['roleLabel']})? Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Ya, Hapus',
      cancelLabel: 'Batal',
      confirmColor: AppColors.red,
      icon: Icons.person_remove_rounded,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient().dio.delete(ApiEndpoints.userDelete(u['id'] as int));
      await _loadUsers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengguna "${u['name']}" berhasil dihapus.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus pengguna: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmResetPassword(Map<String, dynamic> u) async {
    final name = u['name'] ?? 'Pengguna';
    final userId = u['id'];

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Reset Kata Sandi?',
      message: 'Kata sandi untuk $name akan direset menjadi default: "murabbiapp".',
      confirmLabel: 'Reset Sandi',
      cancelLabel: 'Batal',
      confirmColor: const Color(0xFFD97706),
      icon: Icons.key_rounded,
    );

    if (confirmed != true || userId == null) return;

    try {
      final response = await ApiClient().dio.post(
        ApiEndpoints.resetUserPassword(userId as int),
      );

      final msg = response.data['message']?.toString() ?? 'Kata sandi berhasil direset menjadi "murabbiapp".';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mereset kata sandi: $e'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Pengguna',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Admin', 'Guru', 'Orang Tua'].map((role) {
                  final isSel = _selectedRole == role;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        role,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? Colors.white : AppColors.muted,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      onSelected: (_) {
                        setState(() => _selectedRole = role);
                        _loadUsers();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // User list
          Expanded(
            child: _isLoading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pengguna',
                              style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final u = _users[i];
                          return _userCard(u);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> u) {
    final role = u['role'] as String;
    final color = role == 'admin'
        ? AppColors.blue
        : (role == 'ortu' ? const Color(0xFFD97706) : AppColors.primary);
    final bg = role == 'admin'
        ? AppColors.bluePale
        : (role == 'ortu' ? AppColors.goldPale : AppColors.primaryPale);

    return InkWell(
      onTap: () => _showEditModal(u),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: bg,
              child: Icon(Icons.person, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          u['name'] as String,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppBadge(
                        label: u['roleLabel'] as String,
                        variant: role == 'admin'
                            ? BadgeVariant.blue
                            : (role == 'ortu' ? BadgeVariant.warning : BadgeVariant.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    u['email'] as String,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (u['nip'] != null && (u['nip'] as String).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'NIP: ${u['nip']}',
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              tooltip: 'Edit Data',
              onPressed: () => _showEditModal(u),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: AppColors.muted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'reset') {
                  _confirmResetPassword(u);
                } else if (val == 'delete') {
                  _confirmDelete(u);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.key_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 10),
                      Text('Reset Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.red, size: 18),
                      SizedBox(width: 10),
                      Text('Hapus Pengguna', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
