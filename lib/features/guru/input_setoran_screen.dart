import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'riwayat_setoran_screen.dart';

class InputSetoranScreen extends StatefulWidget {
  const InputSetoranScreen({super.key});

  @override
  State<InputSetoranScreen> createState() => _InputSetoranScreenState();
}

class _InputSetoranScreenState extends State<InputSetoranScreen> {
  // Live State
  int? _selectedKelasId;
  String _selectedKelasName = 'Pilih Kelas / Rombel';

  int? _selectedSantriId;
  String _selectedSantriName = 'Pilih Santri';

  int? _selectedSurahId;
  String _selectedSurahName = 'Pilih Surah';

  final _ayatMulaiCtrl = TextEditingController(text: '1');
  final _ayatSelesaiCtrl = TextEditingController(text: '20');
  final _catatanCtrl = TextEditingController();

  String _statusTajwid = 'lancar'; // lancar, kurang, mengulang
  bool _isLoading = false;

  List<dynamic> _kelasList = [];
  List<dynamic> _santriList = [];
  List<dynamic> _surahList = [];

  @override
  void initState() {
    super.initState();
    _fetchMasterData();
  }

  Future<void> _fetchMasterData() async {
    try {
      final responses = await Future.wait([
        ApiClient().dio.get(ApiEndpoints.kelasList),
        ApiClient().dio.get(ApiEndpoints.surahs),
      ]);
      if (!mounted) return;
      setState(() {
        _kelasList = (responses[0].data['data'] as List?) ?? [];
        _surahList = (responses[1].data['data'] as List?) ?? [];
        if (_kelasList.isNotEmpty) {
          _selectedKelasId = _kelasList[0]['id'];
          _selectedKelasName = _kelasList[0]['nama_kelas'];
        }
        if (_surahList.isNotEmpty) {
          _selectedSurahId = _surahList[0]['id'];
          _selectedSurahName = _surahList[0]['nama_latin'];
        }
      });
      if (_selectedKelasId != null) {
        await _fetchSantriByKelas(_selectedKelasId!);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data master.')),
        );
      }
    }
  }

  Future<void> _fetchSantriByKelas(int kelasId) async {
    try {
      final response = await ApiClient().dio.get(
        ApiEndpoints.guruSantris,
        queryParameters: {'kelas_id': kelasId},
      );
      if (!mounted) return;
      final santris = (response.data['data'] as List?) ?? [];
      setState(() {
        _santriList = santris;
        _selectedSantriId = santris.isEmpty ? null : santris[0]['id'];
        _selectedSantriName = santris.isEmpty
            ? 'Tidak ada santri'
            : santris[0]['nama_lengkap'];
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal memuat santri.')));
      }
    }
  }

  void _showKelasPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Kelas / Rombel',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(),
              Expanded(
                child: _kelasList.isEmpty
                    ? const Center(child: Text('Memuat daftar kelas...'))
                    : ListView.builder(
                        controller: scrollCtrl,
                        shrinkWrap: true,
                        itemCount: _kelasList.length,
                        itemBuilder: (ctx, i) {
                          final k = _kelasList[i];
                          return ListTile(
                            title: Text(
                              k['nama_kelas'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Target: ${k['target_juz'] ?? "Juz 30"}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                            trailing: _selectedKelasId == k['id']
                                ? const Icon(Icons.check_circle, color: AppColors.primary)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedKelasId = k['id'];
                                _selectedKelasName = k['nama_kelas'];
                              });
                              Navigator.pop(ctx);
                              _fetchSantriByKelas(k['id']);
                            },
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

  void _showSantriPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Santri',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(),
              Expanded(
                child: _santriList.isEmpty
                    ? const Center(child: Text('Tidak ada santri di kelas ini'))
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: _santriList.length,
                        itemBuilder: (ctx, i) {
                          final s = _santriList[i];
                          return ListTile(
                            title: Text(
                              s['nama_lengkap'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'NIS: ${s['nis'] ?? "-"} · Progres: ${s['progress_pct'] ?? 0}%',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                            trailing: _selectedSantriId == s['id']
                                ? const Icon(Icons.check_circle, color: AppColors.primary)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedSantriId = s['id'];
                                _selectedSantriName = s['nama_lengkap'];
                              });
                              Navigator.pop(ctx);
                            },
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

  void _showSurahPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: 400,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Surah Al-Qur\'an',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _surahList.length,
                itemBuilder: (context, i) {
                  final surah = _surahList[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryPale,
                      radius: 14,
                      child: Text(
                        '${surah['nomor']}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      surah['nama_latin'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${surah['jumlah_ayat']} Ayat · ${surah['tempat_turun']}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    trailing: _selectedSurahId == surah['id']
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSurahId = surah['id'];
                        _selectedSurahName = surah['nama_latin'];
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedSantriId == null || _selectedSurahId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih santri dan surah terlebih dahulu!'),
        ),
      );
      return;
    }

    final mulai = int.tryParse(_ayatMulaiCtrl.text.trim());
    final selesai = int.tryParse(_ayatSelesaiCtrl.text.trim());
    final maxAyat =
        (_surahList.firstWhere(
                  (s) => s['id'] == _selectedSurahId,
                  orElse: () => {},
                )['jumlah_ayat']
                as num?)
            ?.toInt();
    if (mulai == null ||
        selesai == null ||
        mulai < 1 ||
        selesai < mulai ||
        (maxAyat != null && selesai > maxAyat)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rentang ayat tidak valid.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiClient().dio.post(
        ApiEndpoints.setorans,
        data: {
          'santri_id': _selectedSantriId,
          'surah_id': _selectedSurahId,
          'ayat_mulai': mulai,
          'ayat_selesai': selesai,
          'status': _statusTajwid,
          'catatan': _catatanCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessDialog();
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan setoran.')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Setoran Tersimpan di Server!',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hafalan $_selectedSantriName untuk surah $_selectedSurahName (Ayat ${_ayatMulaiCtrl.text}-${_ayatSelesaiCtrl.text}) berhasil tercatat di database MySQL.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Lihat di Riwayat Setoran',
              icon: Icons.history,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RiwayatSetoranScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'Kembali ke Dashboard',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ayatMulaiCtrl.dispose();
    _ayatSelesaiCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Input Setoran Hafalan',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kelas Picker
            AppTextField(
              label: 'PILIH KELAS / ROMBEL',
              hint: _selectedKelasName,
              readOnly: true,
              suffixIcon: const Icon(Icons.expand_more, color: AppColors.sub),
              onTap: _showKelasPicker,
            ),
            const SizedBox(height: 14),

            // Santri Picker
            AppTextField(
              label: 'PILIH SANTRI',
              hint: _selectedSantriName,
              readOnly: true,
              suffixIcon: const Icon(Icons.expand_more, color: AppColors.sub),
              onTap: _showSantriPicker,
            ),
            const SizedBox(height: 14),

            // Surah Picker
            AppTextField(
              label: 'PILIH SURAH',
              hint: _selectedSurahName,
              readOnly: true,
              suffixIcon: const Icon(Icons.expand_more, color: AppColors.sub),
              onTap: _showSurahPicker,
            ),
            const SizedBox(height: 14),

            // Ayat Mulai & Selesai
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'AYAT MULAI',
                    hint: '1',
                    controller: _ayatMulaiCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'AYAT SELESAI',
                    hint: '20',
                    controller: _ayatSelesaiCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Kelancaran Selector
            Text(
              'STATUS KELANCARAN & TAJWID',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusOption(
                  'lancar',
                  'Lancar (A)',
                  AppColors.primaryMid,
                ),
                const SizedBox(width: 8),
                _buildStatusOption('kurang', 'Kurang (B)', AppColors.goldLight),
                const SizedBox(width: 8),
                _buildStatusOption('mengulang', 'Ulang (C)', AppColors.red),
              ],
            ),
            const SizedBox(height: 16),

            // Catatan Form
            AppTextField(
              label: 'CATATAN EVALUASI & TAJWID',
              hint: 'Tulis makhraj/mad yang perlu diperhatikan santri...',
              controller: _catatanCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              label: 'SIMPAN KE DATABASE MYSQL',
              icon: Icons.cloud_upload_outlined,
              isLoading: _isLoading,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String value, String label, Color color) {
    final isSelected = _statusTajwid == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _statusTajwid = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
