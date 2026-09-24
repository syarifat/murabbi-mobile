import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class LaporanExportHelper {
  /// Menghasilkan berkas PDF Laporan Global Rekapitulasi Tahfidz
  static Future<Uint8List> generatePdfBytes({
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> tableData,
    required int totalSantri,
    required int totalLancar,
    required int totalUlang,
    required int avgPct,
  }) async {
    final pdf = pw.Document();

    final tahunAjaran = data['tahun_ajaran'];
    final taName = tahunAjaran != null ? (tahunAjaran['nama']?.toString() ?? '-') : '-';
    String printDate;
    try {
      await initializeDateFormatting('id_ID', null);
      printDate = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now());
    } catch (_) {
      printDate = DateFormat('dd/MM/yyyy, HH:mm').format(DateTime.now());
    }

    // Warna tema selaras Murobbi-Qu
    final primaryColor = PdfColor.fromHex('#1B5E20'); // Deep Green
    final primaryLight = PdfColor.fromHex('#E8F5E9');
    final darkColor = PdfColor.fromHex('#0F172A');
    final mutedColor = PdfColor.fromHex('#64748B');
    final borderColor = PdfColor.fromHex('#E2E8F0');
    final goldColor = PdfColor.fromHex('#D97706');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context ctx) {
          if (ctx.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MUROBBI-QU',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Sistem Informasi Manajemen Hafalan Al-Qur\'an & Monitoring Tahfidz',
                          style: pw.TextStyle(fontSize: 8.5, color: mutedColor),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: primaryLight,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: primaryColor, width: 0.8),
                      ),
                      child: pw.Text(
                        'TA: $taName',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1.5, color: primaryColor),
                pw.SizedBox(height: 12),
              ],
            );
          }
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Murobbi-Qu — Laporan Global Rekapitulasi Hafalan',
                  style: pw.TextStyle(fontSize: 8, color: mutedColor),
                ),
                pw.Text(
                  'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: mutedColor),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dokumen Resmi Lembaga · Dicetak otomatis oleh Murobbi-Qu',
                  style: pw.TextStyle(fontSize: 7.5, color: mutedColor),
                ),
                pw.Text(
                  'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, color: mutedColor),
                ),
              ],
            ),
          );
        },
        build: (pw.Context ctx) {
          return [
            // Judul Laporan
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'LAPORAN GLOBAL REKAPITULASI HAFALAN SISWA',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Tahun Ajaran: $taName · Waktu Cetak: $printDate WIB',
                    style: pw.TextStyle(fontSize: 9, color: mutedColor),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 4 KPI Cards
            pw.Row(
              children: [
                _buildPdfKpiCard('Total Siswa', '$totalSantri Siswa', primaryColor),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Avg Kelancaran', '$avgPct%', goldColor),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Setoran Lancar', '$totalLancar Kali', PdfColor.fromHex('#2E7D32')),
                pw.SizedBox(width: 8),
                _buildPdfKpiCard('Perlu Ulang', '$totalUlang Kali', PdfColor.fromHex('#D32F2F')),
              ],
            ),
            pw.SizedBox(height: 18),

            // Header Tabel
            pw.Text(
              'Rekapitulasi Per Kelas Rombongan Belajar',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkColor),
            ),
            pw.SizedBox(height: 8),

            // Tabel Data Rekapitulasi
            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(30),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.5),
                4: pw.FlexColumnWidth(1.5),
                5: pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    _buildTableCell('No', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell('Kelas Rombel', isHeader: true, align: pw.TextAlign.left),
                    _buildTableCell('Jumlah Siswa', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell('Setoran Lancar', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell('Kelancaran (%)', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell('Perlu Mengulang', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                // Data Rows
                ...tableData.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  final isEven = idx % 2 == 0;
                  final bgColor = isEven ? PdfColors.white : PdfColor.fromHex('#F8FAFC');

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bgColor),
                    children: [
                      _buildTableCell('${idx + 1}', align: pw.TextAlign.center),
                      _buildTableCell(row['kelas']?.toString() ?? '-', align: pw.TextAlign.left, isBold: true),
                      _buildTableCell('${row['santri'] ?? 0}', align: pw.TextAlign.center),
                      _buildTableCell('${row['lancar'] ?? 0}', align: pw.TextAlign.center),
                      _buildTableCell(row['pct']?.toString() ?? '0%', align: pw.TextAlign.center, isBold: true, color: primaryColor),
                      _buildTableCell('${row['ulang'] ?? 0}', align: pw.TextAlign.center),
                    ],
                  );
                }),
                // Footer / Total Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryLight),
                  children: [
                    _buildTableCell('', align: pw.TextAlign.center),
                    _buildTableCell('TOTAL', isHeader: true, isBold: true, align: pw.TextAlign.left, color: primaryColor),
                    _buildTableCell('$totalSantri', isHeader: true, isBold: true, align: pw.TextAlign.center, color: primaryColor),
                    _buildTableCell('$totalLancar', isHeader: true, isBold: true, align: pw.TextAlign.center, color: primaryColor),
                    _buildTableCell('$avgPct%', isHeader: true, isBold: true, align: pw.TextAlign.center, color: primaryColor),
                    _buildTableCell('$totalUlang', isHeader: true, isBold: true, align: pw.TextAlign.center, color: primaryColor),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Lembar Tanda Tangan
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Catatan Administratif:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor)),
                    pw.SizedBox(height: 2),
                    pw.Text('1. Data setoran dihitung secara kumulatif pada tahun ajaran aktif.', style: pw.TextStyle(fontSize: 7.5, color: mutedColor)),
                    pw.Text('2. Nilai kelancaran (%) dihitung dari rasio setoran lancar terhadap total setoran.', style: pw.TextStyle(fontSize: 7.5, color: mutedColor)),
                    pw.Text('3. Dokumen ini sah dan diakui untuk pelaporan mutaba\'ah akademik.', style: pw.TextStyle(fontSize: 7.5, color: mutedColor)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Dicetak pada: $printDate',
                      style: pw.TextStyle(fontSize: 8, color: darkColor),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Mengetahui,\nKoordinator Tahfidz',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
                    ),
                    pw.SizedBox(height: 38),
                    pw.Container(
                      width: 130,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 0.8)),
                      ),
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Center(
                        child: pw.Text(
                          'Kepala Lembaga / Koordinator',
                          style: pw.TextStyle(fontSize: 7.5, color: mutedColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfKpiCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F8FAFC'),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#64748B')),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7.5,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : (color ?? PdfColor.fromHex('#0F172A')),
        ),
      ),
    );
  }

  /// Menghasilkan string CSV berstandar Excel dengan UTF-8 BOM
  static String generateExcelCsvString({
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> tableData,
    required int totalSantri,
    required int totalLancar,
    required int totalUlang,
    required int avgPct,
  }) {
    final buffer = StringBuffer();
    // Tambahkan UTF-8 BOM agar Microsoft Excel langsung membaca aksen & teks dengan rapi
    buffer.write('\uFEFF');

    final tahunAjaran = data['tahun_ajaran'];
    final taName = tahunAjaran != null ? (tahunAjaran['nama']?.toString() ?? '-') : '-';
    final printDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    buffer.writeln('"MUROBBI-QU - SISTEM INFORMASI MONITORING TAHFIDZ"');
    buffer.writeln('"LAPORAN GLOBAL REKAPITULASI HAFALAN SISWA"');
    buffer.writeln('"Tahun Ajaran","$taName"');
    buffer.writeln('"Tanggal Ekspor","$printDate"');
    buffer.writeln('""');

    // Ringkasan Statistik
    buffer.writeln('"RINGKASAN KPI LEMBAGA"');
    buffer.writeln('"Metrik","Nilai"');
    buffer.writeln('"Total Siswa Terdaftar",$totalSantri');
    buffer.writeln('"Rata-rata Tingkat Kelancaran","$avgPct%"');
    buffer.writeln('"Total Setoran Lancar",$totalLancar');
    buffer.writeln('"Total Setoran Perlu Mengulang",$totalUlang');
    buffer.writeln('""');

    // Tabel Rekapitulasi Per Kelas
    buffer.writeln('"REKAPITULASI KELAS ROMBEL"');
    buffer.writeln('"No","Kelas","Jumlah Siswa","Setoran Lancar","Persentase Kelancaran","Setoran Mengulang"');

    for (var i = 0; i < tableData.length; i++) {
      final row = tableData[i];
      final no = i + 1;
      final kelas = _escapeCsv(row['kelas']?.toString() ?? '-');
      final santri = row['santri'] ?? 0;
      final lancar = row['lancar'] ?? 0;
      final pct = _escapeCsv(row['pct']?.toString() ?? '0%');
      final ulang = row['ulang'] ?? 0;

      buffer.writeln('$no,$kelas,$santri,$lancar,$pct,$ulang');
    }

    // Total Row
    buffer.writeln('""');
    buffer.writeln('"TOTAL","-",$totalSantri,$totalLancar,"$avgPct%",$totalUlang');

    return buffer.toString();
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return '"$value"';
  }

  /// Ekspor CSV Excel dan simpan ke file lokal lalu bagikan / share
  static Future<File> saveExcelCsvFile({
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> tableData,
    required int totalSantri,
    required int totalLancar,
    required int totalUlang,
    required int avgPct,
  }) async {
    final csvContent = generateExcelCsvString(
      data: data,
      tableData: tableData,
      totalSantri: totalSantri,
      totalLancar: totalLancar,
      totalUlang: totalUlang,
      avgPct: avgPct,
    );

    final tahunAjaran = data['tahun_ajaran'];
    final taName = tahunAjaran != null
        ? (tahunAjaran['nama']?.toString().replaceAll(RegExp(r'[\\/ ]'), '_') ?? 'TA')
        : 'TA';

    final tempDir = await getTemporaryDirectory();
    final fileName = 'Laporan_Global_Tahfidz_$taName.csv';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(csvContent, encoding: utf8);
    return file;
  }

  /// Buka dialog pratinjau dan pencetakan PDF
  static Future<void> printOrPreviewPdf({
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> tableData,
    required int totalSantri,
    required int totalLancar,
    required int totalUlang,
    required int avgPct,
  }) async {
    final tahunAjaran = data['tahun_ajaran'];
    final taName = tahunAjaran != null
        ? (tahunAjaran['nama']?.toString().replaceAll(RegExp(r'[\\/ ]'), '_') ?? 'TA')
        : 'TA';

    final pdfBytes = await generatePdfBytes(
      data: data,
      tableData: tableData,
      totalSantri: totalSantri,
      totalLancar: totalLancar,
      totalUlang: totalUlang,
      avgPct: avgPct,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Laporan_Global_Tahfidz_$taName.pdf',
    );
  }

  /// Bagikan file PDF secara langsung
  static Future<void> sharePdf({
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> tableData,
    required int totalSantri,
    required int totalLancar,
    required int totalUlang,
    required int avgPct,
  }) async {
    final tahunAjaran = data['tahun_ajaran'];
    final taName = tahunAjaran != null
        ? (tahunAjaran['nama']?.toString().replaceAll(RegExp(r'[\\/ ]'), '_') ?? 'TA')
        : 'TA';

    final pdfBytes = await generatePdfBytes(
      data: data,
      tableData: tableData,
      totalSantri: totalSantri,
      totalLancar: totalLancar,
      totalUlang: totalUlang,
      avgPct: avgPct,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Laporan_Global_Tahfidz_$taName.pdf',
    );
  }

  /// Bagikan file Excel CSV secara langsung
  static Future<void> shareExcelFile({
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> tableData,
    required int totalSantri,
    required int totalLancar,
    required int totalUlang,
    required int avgPct,
  }) async {
    final file = await saveExcelCsvFile(
      data: data,
      tableData: tableData,
      totalSantri: totalSantri,
      totalLancar: totalLancar,
      totalUlang: totalUlang,
      avgPct: avgPct,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv', name: file.uri.pathSegments.last)],
        text: 'Laporan Global Rekapitulasi Hafalan Siswa Murobbi-Qu',
      ),
    );
  }
}
