class SantriModel {
  final int id;
  final String nis;
  final String namaLengkap;
  final int kelasId;
  final String? namaKelas;
  final int? waliId;
  final String? targetJuz;
  final String? progressPct;

  SantriModel({
    required this.id,
    required this.nis,
    required this.namaLengkap,
    required this.kelasId,
    this.namaKelas,
    this.waliId,
    this.targetJuz,
    this.progressPct,
  });

  factory SantriModel.fromJson(Map<String, dynamic> json) {
    return SantriModel(
      id: json['id'] as int,
      nis: json['nis'] as String,
      namaLengkap: json['nama_lengkap'] as String,
      kelasId: json['kelas_id'] as int,
      namaKelas: json['kelas'] != null ? json['kelas']['nama_kelas'] as String? : null,
      waliId: json['wali_id'] as int?,
      targetJuz: json['target_juz'] as String?,
      progressPct: json['progress_pct'] as String?,
    );
  }
}
