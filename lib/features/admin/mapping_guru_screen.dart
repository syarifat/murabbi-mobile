import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../widgets/app_text_field.dart';

class MappingGuruScreen extends StatefulWidget {
  const MappingGuruScreen({super.key});

  @override
  State<MappingGuruScreen> createState() => _MappingGuruScreenState();
}

class _MappingGuruScreenState extends State<MappingGuruScreen> {
  List<Map<String, dynamic>> _mappings = [];
  List<Map<String, dynamic>> _gurus = [];
  List<Map<String, dynamic>> _rombels = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMappings();
  }

  Future<void> _loadMappings() async {
    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient().dio.get(ApiEndpoints.mappingGuru);
      final data = resp.data['data'] as List<dynamic>? ?? [];
      setState(() {
        _mappings = data.map((item) {
          final m = item as Map<String, dynamic>;
          return {
            'id': m['id'],
            'guru_id': m['guru']?['id'],
            'guru_name': m['guru']?['name'] ?? '-',
            'kelas_id': m['kelas']?['id'],
            'kelas_nama': m['kelas']?['nama_kelas'] ?? '-',
            'jadwal': m['jadwal_halaqah'] ?? '-',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading mappings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGurus() async {
    try {
      final resp = await ApiClient().dio.get(ApiEndpoints.users, queryParameters: {'role': 'Guru'});
      setState(() {
        _gurus = ((resp.data['data'] as List?) ?? []).map((u) {
          return {'id': u['id'], 'name': u['name'] ?? '-'};
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading gurus: $e');
    }
  }

  Future<void> _loadRombels() async {
    try {
      final resp = await ApiClient().dio.get(ApiEndpoints.rombelList);
      final rombels = resp.data['data']['rombels'] as List<dynamic>? ?? [];

      // Get already mapped kelas ids
      final mappedKelasIds = _mappings.map((m) => m['kelas_id']).toSet();

      setState(() {
        _rombels = rombels
            .where((r) => !mappedKelasIds.contains(r['id']))
            .map((r) => {
                  'id': r['id'],
                  'nama': r['nama_kelas'] ?? '-',
                })
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading rombels: $e');
    }
  }

  void _showAddModal() {
    _loadGurus();
    _loadRombels();
    int? selectedGuruId;
    int? selectedKelasId;
    final jadwalCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final availableKelas = selectedGuruId != null ? _rombels : <Map<String, dynamic>>[];

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tambah Mapping', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                // Pilih Guru
                Text('GURU / USTADZ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      hint: const Text('Pilih Guru'),
                      value: selectedGuruId,
                      items: _gurus.map((g) => DropdownMenuItem(
                        value: g['id'] as int,
                        child: Text(g['name'] as String),
                      )).toList(),
                      onChanged: (v) => setModal(() {
                        selectedGuruId = v;
                        selectedKelasId = null; // Reset kelas when guru changes
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Pilih Kelas
                Text('KELAS / ROMBEL', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      hint: Text(availableKelas.isEmpty ? 'Pilih guru dulu' : 'Pilih Kelas'),
                      value: selectedKelasId,
                      items: availableKelas.map((k) => DropdownMenuItem(
                        value: k['id'] as int,
                        child: Text(k['nama'] as String),
                      )).toList(),
                      onChanged: availableKelas.isEmpty ? null : (v) => setModal(() => selectedKelasId = v),
                    ),
                  ),
                ),
                if (availableKelas.isEmpty && selectedGuruId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Semua kelas sudah dipetakan ke guru lain',
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.red),
                    ),
                  ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'JADWAL HALAQAH (OPSIONAL)',
                  hint: 'Contoh: Setiap Kamis 08.00',
                  controller: jadwalCtrl,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (selectedGuruId != null && selectedKelasId != null)
                        ? () async {
                            Navigator.pop(ctx);
                            await _saveMapping(selectedGuruId!, selectedKelasId!, jadwalCtrl.text.trim());
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('SIMPAN', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditModal(Map<String, dynamic> mapping) {
    _loadGurus();
    int selectedGuruId = mapping['guru_id'] as int;
    int selectedKelasId = mapping['kelas_id'] as int;
    final jadwalCtrl = TextEditingController(text: mapping['jadwal'] == '-' ? '' : mapping['jadwal']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Mapping', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              // Pilih Guru
              Text('GURU / USTADZ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selectedGuruId,
                    items: _gurus.map((g) => DropdownMenuItem(
                      value: g['id'] as int,
                      child: Text(g['name'] as String),
                    )).toList(),
                    onChanged: (v) => setModal(() => selectedGuruId = v!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'JADWAL HALAQAH (OPSIONAL)',
                hint: 'Contoh: Setiap Kamis 08.00',
                controller: jadwalCtrl,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _updateMapping(mapping['id'] as int, selectedGuruId, selectedKelasId, jadwalCtrl.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('UPDATE', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMapping(int guruId, int kelasId, String jadwal) async {
    try {
      await ApiClient().dio.post(ApiEndpoints.mappingGuru, data: {
        'guru_id': guruId,
        'kelas_id': kelasId,
        'jadwal_halaqah': jadwal.isNotEmpty ? jadwal : null,
      });
      await _loadMappings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mapping berhasil ditambahkan'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      debugPrint('Error saving: $e');
    }
  }

  Future<void> _updateMapping(int id, int guruId, int kelasId, String jadwal) async {
    try {
      await ApiClient().dio.put('${ApiEndpoints.mappingGuru}/$id', data: {
        'guru_id': guruId,
        'kelas_id': kelasId,
        'jadwal_halaqah': jadwal.isNotEmpty ? jadwal : null,
      });
      await _loadMappings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mapping berhasil diupdate'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      debugPrint('Error updating: $e');
    }
  }

  Future<void> _deleteMapping(Map<String, dynamic> mapping) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Mapping', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Yakin hapus mapping ${mapping['guru_name']} ke ${mapping['kelas_nama']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiClient().dio.delete('${ApiEndpoints.mappingGuru}/${mapping['id']}');
        await _loadMappings();
      } catch (e) {
        debugPrint('Error deleting: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Mapping Guru',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMappings),
        ],
      ),
      body: _isLoading && _mappings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _mappings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('Belum ada mapping', style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted)),
                      const SizedBox(height: 8),
                      Text('Tekan + untuk menambahkan', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mappings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _mappingCard(_mappings[i]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _mappingCard(Map<String, dynamic> m) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryPale,
            child: const Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['guru_name'] as String,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.class_, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      m['kelas_nama'] as String,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                    ),
                    if (m['jadwal'] != '-') ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.schedule, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          m['jadwal'] as String,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => _showEditModal(m),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red),
            onPressed: () => _deleteMapping(m),
          ),
        ],
      ),
    );
  }
}
