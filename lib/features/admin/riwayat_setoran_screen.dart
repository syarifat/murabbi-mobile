import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class RiwayatSetoranScreen extends StatefulWidget {
  const RiwayatSetoranScreen({super.key});

  @override
  State<RiwayatSetoranScreen> createState() => _RiwayatSetoranScreenState();
}

class _RiwayatSetoranScreenState extends State<RiwayatSetoranScreen> {
  List<Map<String, dynamic>> _setorans = [];
  List<Map<String, dynamic>> _rombels = [];
  Map<String, dynamic>? _selectedRombel;
  DateTime? _tanggal;
  final _searchCtrl = TextEditingController();
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadRombels();
    _loadSetorans();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRombels() async {
    try {
      final resp = await ApiClient().dio.get(ApiEndpoints.rombelList);
      final rombels = resp.data['data']['rombels'] as List<dynamic>? ?? [];
      setState(() {
        _rombels = [
          {'id': null, 'nama_kelas': 'Semua Kelas'},
          ...rombels.map((r) => {'id': r['id'], 'nama_kelas': r['nama_kelas']}),
        ];
      });
    } catch (e) {
      debugPrint('Error loading rombels: $e');
    }
  }

  Future<void> _loadSetorans({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': 30,
      };

      if (_selectedRombel != null && _selectedRombel!['id'] != null) {
        params['kelas_id'] = _selectedRombel!['id'];
      }

      if (_tanggal != null) {
        params['tanggal'] = DateFormat('yyyy-MM-dd').format(_tanggal!);
      }

      if (_searchCtrl.text.trim().isNotEmpty) {
        params['search'] = _searchCtrl.text.trim();
      }

      final resp = await ApiClient().dio.get(ApiEndpoints.setoransAdmin, queryParameters: params);
      final data = resp.data['data'];

      setState(() {
        _setorans = ((data['data'] as List?) ?? []).map((s) {
          return {
            'id': s['id'],
            'santri_nama': s['santri']?['nama_lengkap'] ?? '-',
            'santri_nis': s['santri']?['nis'] ?? '-',
            'kelas_nama': s['santri']?['kelas']?['nama_kelas'] ?? '-',
            'guru_nama': s['guru']?['name'] ?? '-',
            'surah': s['surah'] ?? '-',
            'ayat_awal': s['ayat_awal'] ?? 0,
            'ayat_akhir': s['ayat_akhir'] ?? 0,
            'status': s['status'] ?? '-',
            'catatan': s['catatan'] ?? '',
            'waktu_setor': s['waktu_setor'] ?? '',
          };
        }).toList();
        _currentPage = data['current_page'] ?? 1;
        _totalPages = data['last_page'] ?? 1;
      });
    } catch (e) {
      debugPrint('Error loading setorans: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              // Filter Kelas
              Text('KELAS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>?>(
                    isExpanded: true,
                    value: _selectedRombel ?? _rombels.first,
                    items: _rombels.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r['nama_kelas'] ?? '-'),
                    )).toList(),
                    onChanged: (v) => setModal(() => _selectedRombel = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Filter Tanggal
              Text('TANGGAL', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: _tanggal ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setModal(() => _tanggal = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Text(
                        _tanggal != null
                            ? DateFormat('dd MMM yyyy').format(_tanggal!)
                            : 'Pilih Tanggal',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _tanggal != null ? Colors.black : AppColors.muted,
                        ),
                      ),
                      if (_tanggal != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setModal(() => _tanggal = null),
                          child: const Icon(Icons.clear, size: 18, color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModal(() {
                          _selectedRombel = _rombels.first;
                          _tanggal = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _loadSetorans();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          'Riwayat Setoran',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSetorans(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama / NIS...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadSetorans();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              onSubmitted: (_) => _loadSetorans(),
            ),
          ),
          // Active filters
          if (_selectedRombel != null && _selectedRombel!['id'] != null || _tanggal != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_selectedRombel != null && _selectedRombel!['id'] != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedRombel!['nama_kelas'] ?? '',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _selectedRombel = null),
                            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  if (_tanggal != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goldPale,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(_tanggal!),
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.gold),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _tanggal = null),
                            child: const Icon(Icons.close, size: 14, color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          // List
          Expanded(
            child: _isLoading && _setorans.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _setorans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text('Belum ada data setoran', style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSetorans,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _setorans.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _setoranCard(_setorans[i]),
                        ),
                      ),
          ),
          // Pagination
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1 ? () => _loadSetorans(page: _currentPage - 1) : null,
                  ),
                  Text(
                    '$_currentPage / $_totalPages',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages ? () => _loadSetorans(page: _currentPage + 1) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _setoranCard(Map<String, dynamic> s) {
    final status = s['status'] as String;
    final statusColor = status == 'lancar'
        ? AppColors.primary
        : status == 'mengulang'
            ? AppColors.gold
            : AppColors.red;
    final statusBg = status == 'lancar'
        ? AppColors.primaryPale
        : status == 'mengulang'
            ? AppColors.goldPale
            : AppColors.red.withValues(alpha: 0.1);

    final waktu = DateTime.tryParse(s['waktu_setor'] ?? '');
    final waktuFormatted = waktu != null ? DateFormat('dd MMM yyyy, HH:mm').format(waktu) : '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      s['santri_nama'] ?? '-',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'NIS: ${s['santri_nis']} · ${s['kelas_nama']}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'lancar' ? 'Lancar' : status == 'mengulang' ? 'Mengulang' : 'Tidak Lancar',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.menu_book, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(
                'QS. ${s['surah']} ayat ${s['ayat_awal']}-${s['ayat_akhir']}',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(waktuFormatted, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
              const SizedBox(width: 12),
              const Icon(Icons.person_outline, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Text('Guru: ${s['guru_nama']}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
            ],
          ),
          if ((s['catatan'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 14, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s['catatan'] ?? '',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
