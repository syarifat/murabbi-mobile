class SurahModel {
  final int nomor;
  final String namaLatin;
  final String namaArab;
  final int jumlahAyat;
  final int juz;

  SurahModel({
    required this.nomor,
    required this.namaLatin,
    required this.namaArab,
    required this.jumlahAyat,
    required this.juz,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      nomor: json['nomor'] as int,
      namaLatin: json['nama_latin'] as String,
      namaArab: json['nama_arab'] as String? ?? '',
      jumlahAyat: json['jumlah_ayat'] as int,
      juz: json['juz'] as int? ?? 30,
    );
  }
}
