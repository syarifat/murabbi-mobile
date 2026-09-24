import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/laporan_export_helper.dart';

class LaporanGlobalScreen extends StatefulWidget {
  const LaporanGlobalScreen({super.key});

  @override
  State<LaporanGlobalScreen> createState() => _LaporanGlobalScreenState();
}

class _LaporanGlobalScreenState extends State<LaporanGlobalScreen> {
  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = true;
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.laporanGlobal);
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final rows = data['rekap_kelas'] as List<dynamic>? ?? [];
      setState(() {
        _data = data;
        _tableData = rows.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading laporan: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExportPdf() async {
    if (_tableData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data laporan untuk dicetak')),
      );
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      final totalSantri = _tableData.fold<int>(0, (sum, r) => sum + ((r['santri'] as num?)?.toInt() ?? 0));
      final totalLancar = _tableData.fold<int>(0, (sum, r) => sum + ((r['lancar'] as num?)?.toInt() ?? 0));
      final totalUlang = _tableData.fold<int>(0, (sum, r) => sum + ((r['ulang'] as num?)?.toInt() ?? 0));
      final avgPct = totalSantri > 0 ? ((totalLancar / (totalSantri + totalUlang)) * 100).round() : 0;

      await LaporanExportHelper.printOrPreviewPdf(
        data: _data,
        tableData: _tableData,
        totalSantri: totalSantri,
        totalLancar: totalLancar,
        totalUlang: totalUlang,
        avgPct: avgPct,
      );

      if (mounted) {
        _showExportSuccessModal(context, 'PDF');
      }
    } catch (e) {
      debugPrint('Error export PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _handleExportExcel() async {
    if (_tableData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data laporan untuk diekspor')),
      );
      return;
    }

    setState(() => _isExportingExcel = true);
    try {
      final totalSantri = _tableData.fold<int>(0, (sum, r) => sum + ((r['santri'] as num?)?.toInt() ?? 0));
      final totalLancar = _tableData.fold<int>(0, (sum, r) => sum + ((r['lancar'] as num?)?.toInt() ?? 0));
      final totalUlang = _tableData.fold<int>(0, (sum, r) => sum + ((r['ulang'] as num?)?.toInt() ?? 0));
      final avgPct = totalSantri > 0 ? ((totalLancar / (totalSantri + totalUlang)) * 100).round() : 0;

      await LaporanExportHelper.shareExcelFile(
        data: _data,
        tableData: _tableData,
        totalSantri: totalSantri,
        totalLancar: totalLancar,
        totalUlang: totalUlang,
        avgPct: avgPct,
      );

      if (mounted) {
        _showExportSuccessModal(context, 'Excel');
      }
    } catch (e) {
      debugPrint('Error export Excel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor Excel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  Future<void> _sharePdfDirect() async {
    final totalSantri = _tableData.fold<int>(0, (sum, r) => sum + ((r['santri'] as num?)?.toInt() ?? 0));
    final totalLancar = _tableData.fold<int>(0, (sum, r) => sum + ((r['lancar'] as num?)?.toInt() ?? 0));
    final totalUlang = _tableData.fold<int>(0, (sum, r) => sum + ((r['ulang'] as num?)?.toInt() ?? 0));
    final avgPct = totalSantri > 0 ? ((totalLancar / (totalSantri + totalUlang)) * 100).round() : 0;

    await LaporanExportHelper.sharePdf(
      data: _data,
      tableData: _tableData,
      totalSantri: totalSantri,
      totalLancar: totalLancar,
      totalUlang: totalUlang,
      avgPct: avgPct,
    );
  }

  void _showExportSuccessModal(BuildContext context, String type) {
    final tahunAjaran = _data['tahun_ajaran'];
    final taName = tahunAjaran != null ? (tahunAjaran['nama']?.toString() ?? '-') : '-';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon wrap circle (Figma: ExpIcWrap)
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.primaryPale,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'File Berhasil Diekspor!',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Laporan Mutaba\'ah TA $taName ($type)\nsiap untuk diunduh / dibagikan.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (type == 'PDF') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _sharePdfDirect();
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: Text(
                      'Bagikan File PDF',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mid,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Tutup & Kembali',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tahunAjaran = _data['tahun_ajaran'];
    final totalSantri = _tableData.fold<int>(0, (sum, r) => sum + ((r['santri'] as num?)?.toInt() ?? 0));
    final totalLancar = _tableData.fold<int>(0, (sum, r) => sum + ((r['lancar'] as num?)?.toInt() ?? 0));
    final totalUlang = _tableData.fold<int>(0, (sum, r) => sum + ((r['ulang'] as num?)?.toInt() ?? 0));
    final avgPct = totalSantri > 0 ? ((totalLancar / (totalSantri + totalUlang)) * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Laporan Global',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (tahunAjaran != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tahunAjaran['nama'] ?? '-',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isExportingPdf ? null : _handleExportPdf,
                            icon: _isExportingPdf
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.picture_as_pdf, size: 16),
                            label: Text(
                              _isExportingPdf ? 'Memproses...' : 'Cetak PDF',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isExportingExcel ? null : _handleExportExcel,
                            icon: _isExportingExcel
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  )
                                : const Icon(Icons.table_view, size: 16, color: AppColors.primary),
                            label: Text(
                              _isExportingExcel ? 'Memproses...' : 'Export Excel',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _buildKpi('Total Siswa', '$totalSantri', Icons.school, AppColors.primary),
                        const SizedBox(width: 12),
                        _buildKpi('Avg Kelancaran', '$avgPct%', Icons.bar_chart, AppColors.primaryMid),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildKpi('Total Lancar', '$totalLancar', Icons.check_circle, Colors.green),
                        const SizedBox(width: 12),
                        _buildKpi('Perlu Ulang', '$totalUlang', Icons.refresh, AppColors.red),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Rekapitulasi Per Kelas', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _buildTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTable() {
    if (_tableData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Belum ada data', style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: ['Kelas', 'Siswa', 'Lancar', '%', 'Ulang']
                  .map((col) => Expanded(
                        child: Text(
                          col,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ))
                  .toList(),
            ),
          ),
          ..._tableData.map((row) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row['kelas']?.toString() ?? '-',
                        textAlign: TextAlign.left,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${row['santri'] ?? 0}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${row['lancar'] ?? 0}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row['pct']?.toString() ?? '0%',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${row['ulang'] ?? 0}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildKpi(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(val, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dark)),
                Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
