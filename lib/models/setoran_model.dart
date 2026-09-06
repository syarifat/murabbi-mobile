class SetoranModel {
  final int id;
  final int santriId;
  final String namaSantri;
  final String namaKelas;
  final int surahId;
  final String namaSurah;
  final int ayatMulai;
  final int ayatSelesai;
  final String status; // 'lancar', 'kurang', 'mengulang'
  final String? catatan;
  final String waktuSetor;

  SetoranModel({
    required this.id,
    required this.santriId,
    required this.namaSantri,
    required this.namaKelas,
    required this.surahId,
    required this.namaSurah,
    required this.ayatMulai,
    required this.ayatSelesai,
    required this.status,
    this.catatan,
    required this.waktuSetor,
  });

  factory SetoranModel.fromJson(Map<String, dynamic> json) {
    return SetoranModel(
      id: json['id'] as int,
      santriId: json['santri_id'] as int,
      namaSantri: json['santri'] != null ? json['santri']['nama_lengkap'] as String : (json['nama_santri'] as String? ?? 'Santri'),
      namaKelas: json['santri'] != null && json['santri']['kelas'] != null ? json['santri']['kelas']['nama_kelas'] as String : (json['nama_kelas'] as String? ?? '7A'),
      surahId: json['surah_id'] as int? ?? 78,
      namaSurah: json['surah'] != null ? json['surah']['nama_latin'] as String : (json['nama_surah'] as String? ?? "An-Naba'"),
      ayatMulai: json['ayat_mulai'] as int? ?? 1,
      ayatSelesai: json['ayat_selesai'] as int? ?? 20,
      status: json['status'] as String? ?? 'lancar',
      catatan: json['catatan'] as String?,
      waktuSetor: json['waktu_setor'] as String? ?? '08:45 WIB',
    );
  }
}
