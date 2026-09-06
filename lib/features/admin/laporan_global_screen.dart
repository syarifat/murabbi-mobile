import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class LaporanGlobalScreen extends StatefulWidget {
  const LaporanGlobalScreen({super.key});

  @override
  State<LaporanGlobalScreen> createState() => _LaporanGlobalScreenState();
}

class _LaporanGlobalScreenState extends State<LaporanGlobalScreen> {
  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = true;

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

  void _showExportSuccessDialog(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ekspor $type belum tersedia')),
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
                            onPressed: () => _showExportSuccessDialog(context, 'PDF'),
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: Text('Cetak PDF', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
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
                            onPressed: () => _showExportSuccessDialog(context, 'Excel'),
                            icon: const Icon(Icons.table_view, size: 16, color: AppColors.primary),
                            label: Text('Export Excel', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
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
                        _buildKpi('Total Santri', '$totalSantri', Icons.school, AppColors.primary),
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
              children: ['Kelas', 'Santri', 'Lancar', '%', 'Ulang']
                  .map((col) => Expanded(child: Text(col, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))))
                  .toList(),
            ),
          ),
          ..._tableData.map((row) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
                child: Row(
                  children: [
                    Expanded(child: Text(row['kelas']?.toString() ?? '-', textAlign: TextAlign.left, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700))),
                    Expanded(child: Text('${row['santri'] ?? 0}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12))),
                    Expanded(child: Text('${row['lancar'] ?? 0}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12))),
                    Expanded(child: Text(row['pct']?.toString() ?? '0%', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    Expanded(child: Text('${row['ulang'] ?? 0}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12))),
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
