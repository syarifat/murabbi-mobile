// mock_database.dart
// Centralized In-Memory Mock Database for Murabbi App (100% Offline Standalone)

class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;

  MockDatabase._internal() {
    _initData();
  }

  // Active user session
  String currentRole = 'guru'; // 'guru', 'ortu', 'admin'
  String currentUserName = 'Ust. Abdullah, S.Pd.I';
  String currentUserEmail = 'ahmad.fauzi@sekolah.id';

  // Master Kelas
  List<Map<String, dynamic>> classes = [];

  // Master Surah (Juz 30 Lengkap 78 - 114)
  List<Map<String, dynamic>> surahs = [];

  // Data Santri
  List<Map<String, dynamic>> santris = [];

  // Log Riwayat Setoran
  List<Map<String, dynamic>> setorans = [];

  void _initData() {
    classes = [
      {'id': 1, 'nama_kelas': 'Kelas 7A — Tahfidz Putra', 'tingkat': '7', 'wali_kelas': 'Ust. Abdullah'},
      {'id': 2, 'nama_kelas': 'Kelas 7B — Tahfidz Putri', 'tingkat': '7', 'wali_kelas': 'Usth. Sarah'},
      {'id': 3, 'nama_kelas': 'Kelas 8A — Tahfidz Putra', 'tingkat': '8', 'wali_kelas': 'Ust. Mansur'},
      {'id': 4, 'nama_kelas': 'Kelas 8B — Tahfidz Putri', 'tingkat': '8', 'wali_kelas': 'Usth. Maryam'},
      {'id': 5, 'nama_kelas': 'Kelas 9A — Takhassus', 'tingkat': '9', 'wali_kelas': 'Ust. Zulkifli'},
    ];

    surahs = [
      {'id': 78, 'nomor': 78, 'nama_latin': 'An-Naba\'', 'nama_arab': 'النبأ', 'jumlah_ayat': 40},
      {'id': 79, 'nomor': 79, 'nama_latin': 'An-Nazi\'at', 'nama_arab': 'النازعات', 'jumlah_ayat': 46},
      {'id': 80, 'nomor': 80, 'nama_latin': '\'Abasa', 'nama_arab': 'عبس', 'jumlah_ayat': 42},
      {'id': 81, 'nomor': 81, 'nama_latin': 'At-Takwir', 'nama_arab': 'التكوير', 'jumlah_ayat': 29},
      {'id': 82, 'nomor': 82, 'nama_latin': 'Al-Infitar', 'nama_arab': 'الانفطار', 'jumlah_ayat': 19},
      {'id': 83, 'nomor': 83, 'nama_latin': 'Al-Muthaffifin', 'nama_arab': 'المطففين', 'jumlah_ayat': 36},
      {'id': 84, 'nomor': 84, 'nama_latin': 'Al-Insyiqaq', 'nama_arab': 'الانشقاق', 'jumlah_ayat': 25},
      {'id': 85, 'nomor': 85, 'nama_latin': 'Al-Buruj', 'nama_arab': 'البروج', 'jumlah_ayat': 22},
      {'id': 86, 'nomor': 86, 'nama_latin': 'At-Tariq', 'nama_arab': 'الطارق', 'jumlah_ayat': 17},
      {'id': 87, 'nomor': 87, 'nama_latin': 'Al-A\'la', 'nama_arab': 'الأعلى', 'jumlah_ayat': 19},
      {'id': 88, 'nomor': 88, 'nama_latin': 'Al-Ghasyiyah', 'nama_arab': 'الغاشية', 'jumlah_ayat': 26},
      {'id': 89, 'nomor': 89, 'nama_latin': 'Al-Fajr', 'nama_arab': 'الفجر', 'jumlah_ayat': 30},
      {'id': 90, 'nomor': 90, 'nama_latin': 'Al-Balad', 'nama_arab': 'البلد', 'jumlah_ayat': 20},
      {'id': 91, 'nomor': 91, 'nama_latin': 'Asy-Syams', 'nama_arab': 'الشمس', 'jumlah_ayat': 15},
      {'id': 92, 'nomor': 92, 'nama_latin': 'Al-Lail', 'nama_arab': 'الليل', 'jumlah_ayat': 21},
      {'id': 93, 'nomor': 93, 'nama_latin': 'Ad-Duha', 'nama_arab': 'الضحى', 'jumlah_ayat': 11},
      {'id': 94, 'nomor': 94, 'nama_latin': 'Asy-Syarh', 'nama_arab': 'الشرح', 'jumlah_ayat': 8},
      {'id': 95, 'nomor': 95, 'nama_latin': 'At-Tin', 'nama_arab': 'التين', 'jumlah_ayat': 8},
      {'id': 96, 'nomor': 96, 'nama_latin': 'Al-\'Alaq', 'nama_arab': 'العلق', 'jumlah_ayat': 19},
      {'id': 97, 'nomor': 97, 'nama_latin': 'Al-Qadr', 'nama_arab': 'القدر', 'jumlah_ayat': 5},
      {'id': 98, 'nomor': 98, 'nama_latin': 'Al-Bayyinah', 'nama_arab': 'البينة', 'jumlah_ayat': 8},
      {'id': 99, 'nomor': 99, 'nama_latin': 'Az-Zalzalah', 'nama_arab': 'الزلزلة', 'jumlah_ayat': 8},
      {'id': 100, 'nomor': 100, 'nama_latin': 'Al-\'Adiyat', 'nama_arab': 'العاديات', 'jumlah_ayat': 11},
      {'id': 101, 'nomor': 101, 'nama_latin': 'Al-Qari\'ah', 'nama_arab': 'القارعة', 'jumlah_ayat': 11},
      {'id': 102, 'nomor': 102, 'nama_latin': 'At-Takasur', 'nama_arab': 'التكاثر', 'jumlah_ayat': 8},
      {'id': 103, 'nomor': 103, 'nama_latin': 'Al-\'Asr', 'nama_arab': 'العصر', 'jumlah_ayat': 3},
      {'id': 104, 'nomor': 104, 'nama_latin': 'Al-Humazah', 'nama_arab': 'الهمزة', 'jumlah_ayat': 9},
      {'id': 105, 'nomor': 105, 'nama_latin': 'Al-Fil', 'nama_arab': 'الفيل', 'jumlah_ayat': 5},
      {'id': 106, 'nomor': 106, 'nama_latin': 'Quraisy', 'nama_arab': 'قريش', 'jumlah_ayat': 4},
      {'id': 107, 'nomor': 107, 'nama_latin': 'Al-Ma\'un', 'nama_arab': 'الماعون', 'jumlah_ayat': 7},
      {'id': 108, 'nomor': 108, 'nama_latin': 'Al-Kausar', 'nama_arab': 'الكوثر', 'jumlah_ayat': 3},
      {'id': 109, 'nomor': 109, 'nama_latin': 'Al-Kafirun', 'nama_arab': 'الكافرون', 'jumlah_ayat': 6},
      {'id': 110, 'nomor': 110, 'nama_latin': 'An-Nasr', 'nama_arab': 'النصر', 'jumlah_ayat': 3},
      {'id': 111, 'nomor': 111, 'nama_latin': 'Al-Lahab', 'nama_arab': 'اللهب', 'jumlah_ayat': 5},
      {'id': 112, 'nomor': 112, 'nama_latin': 'Al-Ikhlas', 'nama_arab': 'الإخلاص', 'jumlah_ayat': 4},
      {'id': 113, 'nomor': 113, 'nama_latin': 'Al-Falaq', 'nama_arab': 'الفلق', 'jumlah_ayat': 5},
      {'id': 114, 'nomor': 114, 'nama_latin': 'An-Nas', 'nama_arab': 'الناس', 'jumlah_ayat': 6},
    ];

    santris = [
      {'id': 1, 'nama_lengkap': 'Muhammad Salim', 'nis': '202607001', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Ibu Fatimah', 'total_juz': '2.5 Juz'},
      {'id': 2, 'nama_lengkap': 'Ahmad Farhan', 'nis': '202607002', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Bpk. Ridwan', 'total_juz': '1.8 Juz'},
      {'id': 3, 'nama_lengkap': 'Umar Al-Faruq', 'nis': '202607003', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Bpk. Hasan', 'total_juz': '2.0 Juz'},
      {'id': 4, 'nama_lengkap': 'Zaid bin Tsabit', 'nis': '202607004', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Ibu Fatimah', 'total_juz': '3.0 Juz'},
      {'id': 5, 'nama_lengkap': 'Ali Zainal', 'nis': '202607005', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Bpk. Usman', 'total_juz': '1.5 Juz'},
      {'id': 6, 'nama_lengkap': 'Hamzah Asadullah', 'nis': '202607006', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Ibu Aminah', 'total_juz': '2.2 Juz'},
      {'id': 7, 'nama_lengkap': 'Bilal bin Rabah', 'nis': '202607007', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Bpk. Syarif', 'total_juz': '1.2 Juz'},
      {'id': 8, 'nama_lengkap': 'Usamah bin Zaid', 'nis': '202607008', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Ibu Khadijah', 'total_juz': '2.8 Juz'},
      {'id': 9, 'nama_lengkap': 'Sa\'ad bin Abi Waqqas', 'nis': '202607009', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Bpk. Fauzi', 'total_juz': '2.1 Juz'},
      {'id': 10, 'nama_lengkap': 'Thalhah bin Ubaidillah', 'nis': '202607010', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Ibu Maryam', 'total_juz': '1.9 Juz'},
      {'id': 11, 'nama_lengkap': 'Zubair bin Awwam', 'nis': '202607011', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Bpk. Ibrahim', 'total_juz': '2.4 Juz'},
      {'id': 12, 'nama_lengkap': 'Abdurrahman bin Auf', 'nis': '202607012', 'kelas_id': 1, 'kelas_nama': 'Kelas 7A', 'wali': 'Ibu Aisyah', 'total_juz': '3.2 Juz'},
    ];

    setorans = [
      {
        'id': 101,
        'santri_id': 1,
        'santri': {'id': 1, 'nama_lengkap': 'Muhammad Salim', 'nis': '202607001'},
        'kelas_id': 1,
        'kelas': {'id': 1, 'nama_kelas': 'Kelas 7A — Tahfidz Putra'},
        'guru': {'id': 1, 'name': 'Ust. Abdullah, S.Pd.I'},
        'surah_id': 78,
        'surah': {'id': 78, 'nomor': 78, 'nama_latin': 'An-Naba\'', 'nama_arab': 'النبأ'},
        'ayat_mulai': 1,
        'ayat_selesai': 20,
        'status': 'lancar',
        'nilai': 95,
        'catatan': 'Makhraj dan mad thabi\'i sangat baik. Pertahankan hafalan juz 30!',
        'created_at': '2026-09-05 08:45:00',
        'waktu_label': '08:45 WIB'
      },
      {
        'id': 102,
        'santri_id': 2,
        'santri': {'id': 2, 'nama_lengkap': 'Ahmad Farhan', 'nis': '202607002'},
        'kelas_id': 1,
        'kelas': {'id': 1, 'nama_kelas': 'Kelas 7A — Tahfidz Putra'},
        'guru': {'id': 1, 'name': 'Ust. Abdullah, S.Pd.I'},
        'surah_id': 79,
        'surah': {'id': 79, 'nomor': 79, 'nama_latin': 'An-Nazi\'at', 'nama_arab': 'النازعات'},
        'ayat_mulai': 1,
        'ayat_selesai': 15,
        'status': 'kurang_lancar',
        'nilai': 78,
        'catatan': 'Perhatikan ghunnah dan panjang pendek harakat pada ayat 6-10.',
        'created_at': '2026-09-05 08:30:00',
        'waktu_label': '08:30 WIB'
      },
      {
        'id': 103,
        'santri_id': 3,
        'santri': {'id': 3, 'nama_lengkap': 'Umar Al-Faruq', 'nis': '202607003'},
        'kelas_id': 1,
        'kelas': {'id': 1, 'nama_kelas': 'Kelas 7A — Tahfidz Putra'},
        'guru': {'id': 1, 'name': 'Ust. Abdullah, S.Pd.I'},
        'surah_id': 81,
        'surah': {'id': 81, 'nomor': 81, 'nama_latin': 'At-Takwir', 'nama_arab': 'التكوير'},
        'ayat_mulai': 1,
        'ayat_selesai': 14,
        'status': 'mengulang',
        'nilai': 65,
        'catatan': 'Terdapat beberapa keraguan ayat. Diulang kembali di halaqah besok pagi.',
        'created_at': '2026-09-05 07:55:00',
        'waktu_label': '07:55 WIB'
      },
      {
        'id': 104,
        'santri_id': 4,
        'santri': {'id': 4, 'nama_lengkap': 'Zaid bin Tsabit', 'nis': '202607004'},
        'kelas_id': 1,
        'kelas': {'id': 1, 'nama_kelas': 'Kelas 7A — Tahfidz Putra'},
        'guru': {'id': 1, 'name': 'Ust. Abdullah, S.Pd.I'},
        'surah_id': 80,
        'surah': {'id': 80, 'nomor': 80, 'nama_latin': '\'Abasa', 'nama_arab': 'عبس'},
        'ayat_mulai': 1,
        'ayat_selesai': 25,
        'status': 'lancar',
        'nilai': 92,
        'catatan': 'Alhamdulillah bacaan tartil dan sangat fasih.',
        'created_at': '2026-09-04 08:15:00',
        'waktu_label': 'Kemarin'
      },
      {
        'id': 105,
        'santri_id': 5,
        'santri': {'id': 5, 'nama_lengkap': 'Ali Zainal', 'nis': '202607005'},
        'kelas_id': 1,
        'kelas': {'id': 1, 'nama_kelas': 'Kelas 7A — Tahfidz Putra'},
        'guru': {'id': 1, 'name': 'Ust. Abdullah, S.Pd.I'},
        'surah_id': 82,
        'surah': {'id': 82, 'nomor': 82, 'nama_latin': 'Al-Infitar', 'nama_arab': 'الانفطار'},
        'ayat_mulai': 1,
        'ayat_selesai': 19,
        'status': 'lancar',
        'nilai': 90,
        'catatan': 'Selesai 1 surah penuh dengan makhraj sempurna.',
        'created_at': '2026-09-04 07:45:00',
        'waktu_label': 'Kemarin'
      },
    ];
  }

  // --- METHODS FOR GURU FLOW ---

  Map<String, dynamic> getGuruDashboardData() {
    final lancarCount = setorans.where((s) => s['status'] == 'lancar').length;
    final totalSantriHalaqah = 24;
    final sudahSetor = setorans.length;
    final belumSetor = totalSantriHalaqah > sudahSetor ? totalSantriHalaqah - sudahSetor : 6;

    return {
      'guru': {
        'name': currentUserName,
        'nip': '198804152015031002',
        'halaqah': 'Halaqah Pagi (07:30 - 09:00 WIB)',
      },
      'jadwal': {
        'kelas': 'Kelas 7A — Tahfidz Putra',
        'jam': '07:30 - 09:00 WIB',
        'ruangan': 'Masjid Lt. 2 R. Al-Ikhlas',
      },
      'stats': {
        'sudah_setor': sudahSetor,
        'belum_setor': belumSetor,
        'lancar': lancarCount,
      },
      'recent_feed': setorans.take(5).toList(),
    };
  }

  List<Map<String, dynamic>> getSantriByKelas(int kelasId) {
    return santris.where((s) => s['kelas_id'] == kelasId).toList();
  }

  Map<String, dynamic> addSetoran({
    required int santriId,
    required int kelasId,
    required int surahId,
    required int ayatMulai,
    required int ayatSelesai,
    required String status,
    required int nilai,
    required String catatan,
  }) {
    final santri = santris.firstWhere(
      (s) => s['id'] == santriId,
      orElse: () => {'id': santriId, 'nama_lengkap': 'Santri Demo', 'nis': '202607099'},
    );
    final surah = surahs.firstWhere(
      (s) => s['id'] == surahId,
      orElse: () => {'id': surahId, 'nomor': surahId, 'nama_latin': 'An-Naba\'', 'nama_arab': 'النبأ'},
    );
    final kelas = classes.firstWhere(
      (k) => k['id'] == kelasId,
      orElse: () => {'id': kelasId, 'nama_kelas': 'Kelas 7A'},
    );

    final newId = DateTime.now().millisecondsSinceEpoch;
    final newEntry = {
      'id': newId,
      'santri_id': santriId,
      'santri': santri,
      'kelas_id': kelasId,
      'kelas': kelas,
      'guru': {'id': 1, 'name': currentUserName},
      'surah_id': surahId,
      'surah': surah,
      'ayat_mulai': ayatMulai,
      'ayat_selesai': ayatSelesai,
      'status': status,
      'nilai': nilai,
      'catatan': catatan.isNotEmpty ? catatan : 'Setoran dicatat oleh ustadz pengampu.',
      'created_at': DateTime.now().toString(),
      'waktu_label': 'Baru saja'
    };

    setorans.insert(0, newEntry);
    return newEntry;
  }

  bool updateSetoran({
    required int id,
    required int ayatMulai,
    required int ayatSelesai,
    required String status,
    required int nilai,
    required String catatan,
  }) {
    final index = setorans.indexWhere((s) => s['id'] == id);
    if (index != -1) {
      setorans[index]['ayat_mulai'] = ayatMulai;
      setorans[index]['ayat_selesai'] = ayatSelesai;
      setorans[index]['status'] = status;
      setorans[index]['nilai'] = nilai;
      setorans[index]['catatan'] = catatan;
      return true;
    }
    return false;
  }

  bool deleteSetoran(int id) {
    final countBefore = setorans.length;
    setorans.removeWhere((s) => s['id'] == id);
    return setorans.length < countBefore;
  }

  List<Map<String, dynamic>> filterSetoran({String? status, int? santriId}) {
    return setorans.where((s) {
      if (status != null && status.isNotEmpty && status != 'Semua') {
        final st = s['status']?.toString().toLowerCase();
        if (st != status.toLowerCase()) return false;
      }
      if (santriId != null && s['santri_id'] != santriId) {
        return false;
      }
      return true;
    }).toList();
  }
}
