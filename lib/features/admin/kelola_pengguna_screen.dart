import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class KelolaPenggunaScreen extends StatefulWidget {
  const KelolaPenggunaScreen({super.key});

  @override
  State<KelolaPenggunaScreen> createState() => _KelolaPenggunaScreenState();
}

class _KelolaPenggunaScreenState extends State<KelolaPenggunaScreen> {
  String _selectedRole = 'Semua';
  List<Map<String, dynamic>> _users = [];
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nipCtrl = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, String>> _roleOptions = [
    {'value': 'guru', 'label': 'Guru / Ustadz'},
    {'value': 'admin', 'label': 'Admin'},
    {'value': 'ortu', 'label': 'Orang Tua'},
  ];

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
    try {
      final response = await ApiClient().dio.get(
        ApiEndpoints.users,
        queryParameters: {if (_selectedRole != 'Semua') 'role': _selectedRole},
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
          final santris = user['santris'] as List<dynamic>? ?? [];
          return {
            'id': user['id'],
            'name': user['name'] ?? '-',
            'email': user['email'] ?? '',
            'role': role,
            'roleLabel': roleLabel,
            'no_hp': user['no_hp'] ?? '',
            'nip': user['nip'] ?? '',
            'santris': santris,
            'status': 'Aktif',
            'color': role == 'admin' ? AppColors.blue
                : role == 'ortu' ? AppColors.gold
                : AppColors.primary,
            'bg': role == 'admin' ? AppColors.bluePale
                : role == 'ortu' ? AppColors.goldPale
                : AppColors.primaryPale,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  Future<void> _saveUser(BuildContext ctx) async {
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
        'role': _selectedRole,
        'no_hp': _phoneCtrl.text.trim(),
        if (_selectedRole == 'guru') 'nip': _nipCtrl.text.trim(),
      };

      await ApiClient().dio.post(ApiEndpoints.users, data: payload);

      if (!mounted || !ctx.mounted) return;
      Navigator.pop(ctx);
      await _loadUsers();
      _clearForm();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengguna baru berhasil ditambahkan'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan pengguna: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _passwordCtrl.clear();
    _nipCtrl.clear();
    setState(() => _selectedRole = 'guru');
  }

  void _showAddUserModal() {
    _clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                      'Tambah Pengguna Baru',
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
                AppTextField(
                  label: 'NAMA LENGKAP & GELAR',
                  hint: 'Ust. Zulkifli, M.Ag',
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'EMAIL LOGIN',
                  hint: 'zulkifli@sekolah.ac.id',
                  controller: _emailCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'PASSWORD (default: password123)',
                  hint: 'Kosongkan untuk password default',
                  controller: _passwordCtrl,
                  isPassword: true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'NO. WHATSAPP',
                  hint: '+62 812-3456-7890',
                  controller: _phoneCtrl,
                ),
                const SizedBox(height: 12),
                Text(
                  'ROLE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mid,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _roleOptions.map((opt) {
                    final isSelected = _selectedRole == opt['value'];
                    return ChoiceChip(
                      label: Text(opt['label']!),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      onSelected: (_) {
                        setModalState(() => _selectedRole = opt['value']!);
                        setState(() => _selectedRole = opt['value']!);
                      },
                    );
                  }).toList(),
                ),
                if (_selectedRole == 'guru') ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'NIP',
                    hint: '198801012022',
                    controller: _nipCtrl,
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: 'SIMPAN PENGGUNA',
                  icon: Icons.save,
                  isLoading: _isLoading,
                  onPressed: () => _saveUser(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = _users.isEmpty
        ? [
            {
              'name': '-',
              'role': '-',
              'status': '-',
              'color': AppColors.primary,
              'bg': AppColors.primaryPale,
            },
          ]
        : _users;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Kelola Pengguna',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddUserModal,
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Tambah',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextFormField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18, color: AppColors.sub),
                hintText: 'Cari nama / NIP...',
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final u = users[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: u['bg'],
                        child: Icon(Icons.person, color: u['color'], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u['name'],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              u['role'],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppBadge(
                        label: u['status'],
                        variant: u['status'] == 'Aktif'
                            ? BadgeVariant.success
                            : BadgeVariant.danger,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
