import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  // Production Server
  static String baseUrl = 'https://murabbi.satcloud.tech/api';

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('server_base_url');
    if (saved != null && saved.isNotEmpty) {
      baseUrl = saved;
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_base_url', newUrl);
  }

  // Auth
  static String get login => '$baseUrl/login';
  static String get logout => '$baseUrl/logout';
  static String get me => '$baseUrl/me';
  static String get changePassword => '$baseUrl/change-password';

  // Guru
  static String get guruDashboard => '$baseUrl/guru/dashboard';
  static String get kelasList => '$baseUrl/guru/master/kelas';
  static String get surahs => '$baseUrl/guru/master/surahs';
  static String get guruSantris => '$baseUrl/guru/santris';
  static String get setorans => '$baseUrl/guru/setorans';
  static String santriCompletedSurahs(int santriId) =>
      '$baseUrl/guru/santris/$santriId/completed-surahs';

  // Ortu
  static String get ortuDashboard => '$baseUrl/ortu/dashboard';
  static String santriTimeline(int santriId) =>
      '$baseUrl/ortu/santri/$santriId/timeline';
  static String santriRekap(int santriId) =>
      '$baseUrl/ortu/santri/$santriId/rekap';

  // Admin
  static String get adminDashboard => '$baseUrl/admin/dashboard';
  static String get users => '$baseUrl/admin/users';
  static String userUpdate(int id) => '$baseUrl/admin/users/$id';
  static String userDelete(int id) => '$baseUrl/admin/users/$id';
  static String resetUserPassword(int id) => '$baseUrl/admin/users/$id/reset-password';
  static String get santrisAdmin => '$baseUrl/admin/santris';
  static String santriUpdate(int id) => '$baseUrl/admin/santris/$id';
  static String santriDelete(int id) => '$baseUrl/admin/santris/$id';
  static String get mappingGuru => '$baseUrl/admin/mapping';
  static String get laporanGlobal => '$baseUrl/admin/laporan';

  // Master Data
  static String get masterOrtu => '$baseUrl/admin/master/ortu';
  static String masterOrtuUpdate(int id) => '$baseUrl/admin/master/ortu/$id';
  static String get masterKelasAll => '$baseUrl/admin/master/kelas-all';
  static String get masterSantrisAll => '$baseUrl/admin/master/santris-all';
  static String get masterTahunAjaran => '$baseUrl/admin/master/tahun-ajaran';

  // Rombel
  static String get rombelList => '$baseUrl/admin/rombel';
  static String get rombelAssign => '$baseUrl/admin/rombel/assign';
  static String get rombelRemove => '$baseUrl/admin/rombel/remove';

  // Master Kelas
  static String get masterKelasStore => '$baseUrl/admin/master/kelas';
  static String masterKelasUpdate(int id) => '$baseUrl/admin/master/kelas/$id';
  static String masterKelasDelete(int id) => '$baseUrl/admin/master/kelas/$id';

  // Surahs
  static String get masterSurahs => '$baseUrl/admin/master/surahs';
  static String get syncSurahsAdmin => '$baseUrl/admin/master/surahs/sync';

  // Setorans
  static String get setoransAdmin => '$baseUrl/admin/setorans';
}
