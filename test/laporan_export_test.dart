import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/core/utils/laporan_export_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockData = {
    'tahun_ajaran': {
      'id': 1,
      'nama': '2026/2027',
      'aktif': 1,
    }
  };

  final mockTableData = [
    {
      'kelas': '7A',
      'santri': 27,
      'lancar': 250,
      'pct': '85%',
      'ulang': 45,
    },
    {
      'kelas': '7B',
      'santri': 27,
      'lancar': 240,
      'pct': '82%',
      'ulang': 52,
    },
  ];

  group('LaporanExportHelper Tests', () {
    test('generatePdfBytes produces valid PDF bytes', () async {
      final bytes = await LaporanExportHelper.generatePdfBytes(
        data: mockData,
        tableData: mockTableData,
        totalSantri: 54,
        totalLancar: 490,
        totalUlang: 97,
        avgPct: 83,
      );

      expect(bytes, isNotEmpty);
      // PDF file magic bytes start with %PDF-
      final header = utf8.decode(bytes.sublist(0, 5), allowMalformed: true);
      expect(header, equals('%PDF-'));
    });

    test('generateExcelCsvString produces valid CSV with BOM and table data', () {
      final csv = LaporanExportHelper.generateExcelCsvString(
        data: mockData,
        tableData: mockTableData,
        totalSantri: 54,
        totalLancar: 490,
        totalUlang: 97,
        avgPct: 83,
      );

      expect(csv, isNotEmpty);
      // Harus diawali dengan UTF-8 BOM agar Excel membaca otomatis sebagai spreadsheet
      expect(csv.startsWith('\uFEFF'), isTrue);
      // Memuat informasi lembaga & judul
      expect(csv, contains('MUROBBI-QU'));
      expect(csv, contains('LAPORAN GLOBAL REKAPITULASI HAFALAN SISWA'));
      expect(csv, contains('2026/2027'));
      // Memuat baris kelas
      expect(csv, contains('7A'));
      expect(csv, contains('7B'));
      // Memuat total ringkasan
      expect(csv, contains('TOTAL'));
      expect(csv, contains('54'));
      expect(csv, contains('490'));
      expect(csv, contains('83%'));
      expect(csv, contains('97'));
    });
  });
}
