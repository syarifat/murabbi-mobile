import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EditSetoranScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditSetoranScreen({super.key, required this.initialData});

  @override
  State<EditSetoranScreen> createState() => _EditSetoranScreenState();
}

class _EditSetoranScreenState extends State<EditSetoranScreen> {
  late final TextEditingController _ayatMulaiCtrl;
  late final TextEditingController _ayatSelesaiCtrl;
  late final TextEditingController _catatanCtrl;
  late String _statusTajwid;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ayatMulaiCtrl = TextEditingController(
      text: widget.initialData['ayat_mulai']?.toString() ?? '1',
    );
    _ayatSelesaiCtrl = TextEditingController(
      text: widget.initialData['ayat_selesai']?.toString() ?? '20',
    );
    _catatanCtrl = TextEditingController(
      text: widget.initialData['catatan']?.toString() ?? '',
    );
    _statusTajwid =
        widget.initialData['status']?.toString().toLowerCase() ?? 'lancar';
  }

  Future<void> _handleUpdate() async {
    final id = widget.initialData['id'];
    if (id == null) {
      Navigator.pop(context);
      return;
    }

    final mulai = int.tryParse(_ayatMulaiCtrl.text.trim());
    final selesai = int.tryParse(_ayatSelesaiCtrl.text.trim());
    if (mulai == null || selesai == null || mulai < 1 || selesai < mulai) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rentang ayat tidak valid.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final targetId = id is int ? id : int.tryParse(id.toString());
      if (targetId == null) throw Exception();
      await ApiClient().dio.put(
        '${ApiEndpoints.setorans}/$targetId',
        data: {
          'ayat_mulai': mulai,
          'ayat_selesai': selesai,
          'status': _statusTajwid,
          'nilai': _statusTajwid == 'lancar'
              ? 95
              : (_statusTajwid == 'kurang' ? 78 : 65),
          'catatan': _catatanCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Data setoran berhasil diperbarui!'),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui setoran.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    final santriName = widget.initialData['santri'] ?? 'Santri';
    final surahName = widget.initialData['surah'] ?? 'Surah';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Edit Setoran Hafalan',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Santri & Surah Info
            AppTextField(
              label: 'NAMA SANTRI',
              hint: santriName,
              readOnly: true,
            ),
            const SizedBox(height: 14),

            AppTextField(label: 'SURAH', hint: surahName, readOnly: true),
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

            // Status Kelancaran
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
              hint: 'Tulis evaluasi...',
              controller: _catatanCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              label: 'SIMPAN PERUBAHAN KE DATABASE',
              icon: Icons.save,
              isLoading: _isLoading,
              onPressed: _handleUpdate,
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
