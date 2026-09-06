import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'riwayat_setoran_screen.dart';

class InputSetoranScreen extends StatefulWidget {
  const InputSetoranScreen({super.key});

  @override
  State<InputSetoranScreen> createState() => _InputSetoranScreenState();
}

class _InputSetoranScreenState extends State<InputSetoranScreen> {
  // Live State
  int? _selectedKelasId;
  String _selectedKelasName = 'Pilih Kelas / Rombel';

  int? _selectedSantriId;
  String _selectedSantriName = 'Pilih Santri';

  int? _selectedSurahId;
  String _selectedSurahName = 'Pilih Surah';

  final _ayatMulaiCtrl = TextEditingController(text: '1');
  final _ayatSelesaiCtrl = TextEditingController(text: '20');
  final _catatanCtrl = TextEditingController();

  String _statusTajwid = 'lancar'; // lancar, kurang, mengulang
  bool _isLoading = false;

  List<dynamic> _kelasList = [];
  List<dynamic> _santriList = [];
  List<dynamic> _surahList = [];

  // Setoran Selesai / Tuntas untuk Santri Terpilih
  Set<int> _completedSurahIds = {};
  Map<int, int> _lastAyatBySurah = {};
  bool _isLoadingHistory = false;
  Set<int> _santriSudahSetorHariIniIds = {};

  @override
  void initState() {
    super.initState();
    _fetchMasterData();
  }

  int get _currentMaxAyat {
    if (_selectedSurahId == null || _surahList.isEmpty) return 286;
    for (final s in _surahList) {
      if (s is Map && s['id'] == _selectedSurahId) {
        return (s['jumlah_ayat'] as num?)?.toInt() ?? 286;
      }
    }
    return 286;
  }

  Future<void> _fetchMasterData() async {
    List<dynamic> kelasBinaan = [];
    List<dynamic> surahs = [];
    final Set<int> todaySetorIds = {};

    // 1. Ambil data kelas binaan & santri langsung dari API database MySQL
    try {
      final dashRes = await ApiClient().dio.get(ApiEndpoints.guruDashboard);
      final dashboardData = dashRes.data['data'] as Map<String, dynamic>?;
      kelasBinaan = (dashboardData?['kelas_binaan'] as List?) ?? [];

      // Ambil ID santri yang sudah setor hari ini dari dashboard
      final rawTodayIds = dashboardData?['santri_sudah_setor_today_ids'] as List?;
      if (rawTodayIds != null) {
        for (final item in rawTodayIds) {
          if (item is num) todaySetorIds.add(item.toInt());
        }
      }

      for (final k in kelasBinaan) {
        final sList = (k['santris'] as List?) ?? [];
        for (final s in sList) {
          if (s['sudah_setor_hari_ini'] == true && s['id'] != null) {
            todaySetorIds.add((s['id'] as num).toInt());
          }
        }
      }
    } catch (e) {
      debugPrint('Gagal memuat kelas binaan dari server: $e');
    }

    // 2. Ambil data setoran hari ini dari API untuk verifikasi instan
    try {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final setoransRes = await ApiClient().dio.get(
        ApiEndpoints.setorans,
        queryParameters: {'tanggal': todayStr},
      );
      final setorList = (setoransRes.data['data']?['data'] as List?) ??
          (setoransRes.data['data'] as List?) ??
          [];
      for (final item in setorList) {
        final sId = (item['santri_id'] as num?)?.toInt();
        if (sId != null) {
          todaySetorIds.add(sId);
        }
      }
    } catch (e) {
      debugPrint('Info: Cek setoran hari ini: $e');
    }

    // 3. Ambil data surah langsung dari API database MySQL (semua 114 surah)
    try {
      final surahRes = await ApiClient().dio.get(ApiEndpoints.surahs);
      final rawSurahs = (surahRes.data['data'] as List?) ?? [];
      
      if (rawSurahs.isNotEmpty) {
        surahs = rawSurahs.map((s) {
          final nomor = ((s['nomor'] ?? s['number'] ?? s['id']) as num).toInt();
          final dbId = (s['id'] != null) ? (s['id'] as num).toInt() : nomor;
          return {
            ...s,
            'id': dbId,
            'nomor': nomor,
            'nama_latin': s['nama_latin'] ?? s['name'] ?? 'Surah $nomor',
            'jumlah_ayat': (s['jumlah_ayat'] ?? s['number_of_ayahs'] ?? 7) as int,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Gagal memuat surah dari server: $e');
    }

    if (!mounted) return;

    setState(() {
      _kelasList = kelasBinaan;
      _surahList = surahs;
      _santriSudahSetorHariIniIds = todaySetorIds;

      if (_kelasList.isNotEmpty) {
        _selectedKelasId = _kelasList[0]['id'];
        _selectedKelasName = _kelasList[0]['nama_kelas'] ?? 'Pilih Kelas';
        final santris = (_kelasList[0]['santris'] as List?) ?? [];
        _santriList = santris;
        if (_santriList.isNotEmpty) {
          _selectedSantriId = _santriList[0]['id'];
          _selectedSantriName = _santriList[0]['nama_lengkap'] ?? 'Pilih Santri';
        } else {
          _selectedSantriId = null;
          _selectedSantriName = 'Tidak ada santri';
        }
      } else {
        _selectedKelasId = null;
        _selectedKelasName = 'Pilih Kelas / Rombel';
        _santriList = [];
        _selectedSantriId = null;
        _selectedSantriName = 'Pilih Santri';
      }

      if (_surahList.isNotEmpty) {
        _selectedSurahId = _surahList[0]['id'] as int?;
        _selectedSurahName = '${_surahList[0]['nomor']}. ${_surahList[0]['nama_latin']}';
      } else {
        _selectedSurahId = null;
        _selectedSurahName = 'Pilih Surah';
      }
    });

    if (_selectedSantriId != null) {
      _fetchCompletedSurahsForSantri(_selectedSantriId);
    }
  }

  Future<void> _fetchCompletedSurahsForSantri(int? santriId) async {
    if (santriId == null) {
      if (mounted) {
        setState(() {
          _completedSurahIds = {};
          _lastAyatBySurah = {};
        });
      }
      return;
    }

    setState(() => _isLoadingHistory = true);
    try {
      final res = await ApiClient().dio.get(
        ApiEndpoints.santriCompletedSurahs(santriId),
      );
      final rawList =
          (res.data['data']?['completed_surah_ids'] as List?) ?? [];
      final completed = rawList.map((e) => (e as num).toInt()).toSet();

      final parsedLastAyat = <int, int>{};
      final rawLastAyat = res.data['data']?['last_ayat_by_surah'];
      if (rawLastAyat is Map) {
        rawLastAyat.forEach((k, v) {
          final sId = int.tryParse(k.toString());
          final aVal = (v as num?)?.toInt();
          if (sId != null && aVal != null) {
            parsedLastAyat[sId] = aVal;
          }
        });
      }

      // Ambil juga riwayat setoran riil untuk santri ini dari server
      try {
        final setoransRes = await ApiClient().dio.get(
          ApiEndpoints.setorans,
          queryParameters: {'search': _selectedSantriName},
        );
        final setoransData = setoransRes.data['data'];
        final sList = setoransData is Map<String, dynamic>
            ? (setoransData['data'] as List? ?? [])
            : (setoransData as List? ?? []);
        for (final item in sList) {
          if (item is Map &&
              item['santri_id'] == santriId &&
              item['status'] != 'mengulang') {
            final sId = (item['surah_id'] as num?)?.toInt();
            final aSelesai = (item['ayat_selesai'] as num?)?.toInt() ?? 0;
            if (sId != null && aSelesai > (parsedLastAyat[sId] ?? 0)) {
              parsedLastAyat[sId] = aSelesai;
            }
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _completedSurahIds = completed;
        _lastAyatBySurah = parsedLastAyat;
        _autoAdjustSelectedSurah();
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Gagal memuat status tuntas santri: $e');
      setState(() {
        _completedSurahIds = {};
        _lastAyatBySurah = {};
        _autoAdjustSelectedSurah();
      });
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _updateAyatControllersForSelectedSurah() {
    if (_selectedSurahId == null) return;
    final max = _currentMaxAyat;
    final lastAyat = _lastAyatBySurah[_selectedSurahId!] ?? 0;

    if (lastAyat > 0 && lastAyat < max) {
      // Santri sudah mencapai lastAyat, otomatis lanjutkan dari lastAyat + 1 s/d max (atau habis)!
      _ayatMulaiCtrl.text = (lastAyat + 1).toString();
      _ayatSelesaiCtrl.text = max.toString();
    } else if (lastAyat >= max) {
      // Sudah tuntas (misal ingin muroja'ah)
      _ayatMulaiCtrl.text = '1';
      _ayatSelesaiCtrl.text = max.toString();
    } else {
      // Belum pernah setor surah ini
      _ayatMulaiCtrl.text = '1';
      _ayatSelesaiCtrl.text = max <= 20 ? max.toString() : '20';
    }
  }

  void _autoAdjustSelectedSurah() {
    if (_surahList.isEmpty) return;

    final isCurrentCompleted = _selectedSurahId != null &&
        _completedSurahIds.contains(_selectedSurahId);

    if (isCurrentCompleted || _selectedSurahId == null) {
      dynamic nextSurah;
      for (final s in _surahList) {
        if (s is Map) {
          final id = s['id'] as int?;
          if (id != null && !_completedSurahIds.contains(id)) {
            nextSurah = s;
            break;
          }
        }
      }

      if (nextSurah != null) {
        _selectSurah(nextSurah);
      } else {
        _selectedSurahId = null;
        _selectedSurahName = 'Semua Surah Selesai Dihafal';
      }
    } else {
      _updateAyatControllersForSelectedSurah();
    }
  }

  void _selectSurah(dynamic surah) {
    final sId = (surah['id'] as num).toInt();
    final nomor = surah['nomor'];
    final namaLatin = surah['nama_latin'] ?? '';
    setState(() {
      _selectedSurahId = sId;
      _selectedSurahName = nomor != null ? '$nomor. $namaLatin' : namaLatin;
      _updateAyatControllersForSelectedSurah();
    });
  }

  void _onAyatSelesaiChanged(String val) {
    if (val.isEmpty) return;
    final numVal = int.tryParse(val);
    if (numVal == null) return;
    final max = _currentMaxAyat;
    if (numVal > max) {
      _ayatSelesaiCtrl.value = TextEditingValue(
        text: max.toString(),
        selection: TextSelection.collapsed(offset: max.toString().length),
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primary,
          content: Text(
            'Maksimal ayat untuk surah $_selectedSurahName adalah $max ayat.',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else if (numVal < 1) {
      _ayatSelesaiCtrl.value = const TextEditingValue(
        text: '1',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
  }

  void _onAyatMulaiChanged(String val) {
    if (val.isEmpty) return;
    final numVal = int.tryParse(val);
    if (numVal == null) return;
    final max = _currentMaxAyat;
    if (numVal > max) {
      _ayatMulaiCtrl.value = TextEditingValue(
        text: max.toString(),
        selection: TextSelection.collapsed(offset: max.toString().length),
      );
    } else if (numVal < 1) {
      _ayatMulaiCtrl.value = const TextEditingValue(
        text: '1',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
  }

  void _fetchSantriByKelas(int kelasId) {
    Map<String, dynamic>? kelas;
    for (final k in _kelasList) {
      if (k is Map && k['id'] == kelasId) {
        kelas = Map<String, dynamic>.from(k);
        break;
      }
    }
    final santris = (kelas?['santris'] as List?) ?? [];
    setState(() {
      _santriList = santris;
      if (santris.isNotEmpty) {
        _selectedSantriId = santris[0]['id'];
        _selectedSantriName = santris[0]['nama_lengkap'];
      } else {
        _selectedSantriId = null;
        _selectedSantriName = 'Tidak ada santri';
      }
    });

    if (_selectedSantriId != null) {
      _fetchCompletedSurahsForSantri(_selectedSantriId);
    } else {
      setState(() => _completedSurahIds = {});
    }
  }

  void _showKelasPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Kelas / Rombel',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(),
              Expanded(
                child: _kelasList.isEmpty
                    ? const Center(child: Text('Memuat daftar kelas...'))
                    : ListView.builder(
                        controller: scrollCtrl,
                        shrinkWrap: true,
                        itemCount: _kelasList.length,
                        itemBuilder: (ctx, i) {
                          final k = _kelasList[i];
                          return ListTile(
                            title: Text(
                              k['nama_kelas'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Target: ${k['target_juz'] ?? "Juz 30"}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                            trailing: _selectedKelasId == k['id']
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedKelasId = k['id'];
                                _selectedKelasName = k['nama_kelas'];
                              });
                              Navigator.pop(ctx);
                              _fetchSantriByKelas(k['id']);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSantriPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filteredSantris = _santriList.where((s) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.trim().toLowerCase();
              final nama = (s['nama_lengkap'] ?? '').toString().toLowerCase();
              final nis = (s['nis'] ?? '').toString().toLowerCase();
              return nama.contains(q) || nis.contains(q);
            }).toList();

            final int sudahCount = _santriList.where((s) {
              final sId = (s['id'] as num?)?.toInt();
              return (sId != null && _santriSudahSetorHariIniIds.contains(sId)) || s['sudah_setor_hari_ini'] == true;
            }).length;
            final int belumCount = _santriList.length - sudahCount;

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (ctx, scrollCtrl) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Santri',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPale,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '$sudahCount Sudah · $belumCount Belum',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Santri bertanda hijau sudah menyetorkan hafalan hari ini.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (val) => setModalState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Cari nama santri atau NIS...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.bg,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 16),
                    Expanded(
                      child: _santriList.isEmpty
                          ? const Center(child: Text('Tidak ada santri di kelas ini'))
                          : filteredSantris.isEmpty
                              ? Center(
                                  child: Text(
                                    'Santri "$searchQuery" tidak ditemukan',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollCtrl,
                                  itemCount: filteredSantris.length,
                                  itemBuilder: (ctx, i) {
                                    final s = filteredSantris[i];
                                    final sId = (s['id'] as num?)?.toInt();
                                    final bool sudahSetor = (sId != null && _santriSudahSetorHariIniIds.contains(sId)) || s['sudah_setor_hari_ini'] == true;
                                    final bool isSelected = _selectedSantriId == sId;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryPale
                                            : (sudahSetor ? AppColors.primaryPale.withValues(alpha: 0.25) : Colors.white),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary.withValues(alpha: 0.5)
                                              : (sudahSetor ? AppColors.primary.withValues(alpha: 0.25) : AppColors.border),
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: sudahSetor
                                              ? AppColors.primaryPale
                                              : AppColors.border.withValues(alpha: 0.4),
                                          radius: 18,
                                          child: sudahSetor
                                              ? const Icon(Icons.check, size: 18, color: AppColors.primary)
                                              : Text(
                                                  ((s['nama_lengkap'] as String?)?.isNotEmpty == true)
                                                      ? s['nama_lengkap'][0].toUpperCase()
                                                      : 'S',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.dark,
                                                  ),
                                                ),
                                        ),
                                        title: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                s['nama_lengkap'] ?? '',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.dark,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (sudahSetor) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Sudah Setor Hari Ini ✓',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        subtitle: Text(
                                          'NIS: ${s['nis'] ?? "-"} · Progres: ${s['progress_pct'] ?? 0}%${sudahSetor ? " · Sudah setor" : " · Belum setor"}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: sudahSetor ? AppColors.primary : AppColors.muted,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: AppColors.primary,
                                              )
                                            : (sudahSetor
                                                ? const Icon(
                                                    Icons.done_all,
                                                    size: 18,
                                                    color: AppColors.primary,
                                                  )
                                                : null),
                                        onTap: () {
                                          setState(() {
                                            _selectedSantriId = sId;
                                            _selectedSantriName = s['nama_lengkap'];
                                          });
                                          Navigator.pop(ctx);
                                          _fetchCompletedSurahsForSantri(sId);
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSurahPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredSurahs = _surahList.where((s) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.trim().toLowerCase();
              final nomor = (s['nomor'] ?? '').toString();
              final namaLatin = (s['nama_latin'] ?? '').toString().toLowerCase();
              final namaArab = (s['nama_arab'] ?? '').toString();
              return nomor == q || namaLatin.contains(q) || namaArab.contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (ctx, scrollCtrl) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Surah Al-Qur\'an',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_completedSurahIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPale,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${_completedSurahIds.length} Surah Tuntas',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Surah yang telah tuntas dihafal santri dinonaktifkan (mati).',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (val) => setModalState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Cari nama surah atau nomor (1-114)...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.bg,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 16),
                    Expanded(
                      child: filteredSurahs.isEmpty
                          ? Center(
                              child: Text(
                                'Surah "$searchQuery" tidak ditemukan',
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollCtrl,
                              itemCount: filteredSurahs.length,
                              itemBuilder: (context, i) {
                                final surah = filteredSurahs[i];
                                final surahId = (surah['id'] as num).toInt();
                                final isCompleted = _completedSurahIds.contains(surahId);
                                final isSelected = _selectedSurahId == surahId;

                                return Opacity(
                                  opacity: isCompleted ? 0.45 : 1.0,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? AppColors.border.withValues(alpha: 0.2)
                                          : (isSelected
                                              ? AppColors.primaryPale
                                              : Colors.transparent),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: 0.3)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isCompleted
                                            ? AppColors.border
                                            : AppColors.primaryPale,
                                        radius: 14,
                                        child: isCompleted
                                            ? const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: AppColors.muted,
                                              )
                                            : Text(
                                                '${surah['nomor']}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : AppColors.dark,
                                                ),
                                              ),
                                      ),
                                      title: Text(
                                        '${surah['nomor']}. ${surah['nama_latin'] ?? ''}',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isCompleted
                                              ? AppColors.muted
                                              : AppColors.dark,
                                          decoration: isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      subtitle: Text(
                                        isCompleted
                                            ? 'Sudah Tuntas Diselesaikan Santri'
                                            : ((_lastAyatBySurah[surahId] ?? 0) > 0
                                                ? 'Hafalan terakhir: Ayat 1-${_lastAyatBySurah[surahId]} · ${surah['jumlah_ayat']} Ayat'
                                                : '${surah['jumlah_ayat']} Ayat · ${surah['tempat_turun'] ?? ""}'),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: isCompleted
                                              ? AppColors.muted
                                              : ((_lastAyatBySurah[surahId] ?? 0) > 0
                                                  ? AppColors.primary
                                                  : AppColors.sub),
                                        ),
                                      ),
                                      trailing: isCompleted
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.border,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Tuntas ✓',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            )
                                          : (isSelected
                                              ? const Icon(
                                                  Icons.check_circle,
                                                  color: AppColors.primary,
                                                )
                                              : null),
                                      onTap: isCompleted
                                          ? null
                                          : () {
                                              _selectSurah(surah);
                                              Navigator.pop(ctx);
                                            },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedSantriId == null || _selectedSurahId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih santri dan surah terlebih dahulu!'),
        ),
      );
      return;
    }

    if (_completedSurahIds.contains(_selectedSurahId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Surah ini sudah tuntas diselesaikan oleh santri terpilih!',
          ),
        ),
      );
      return;
    }

    final mulai = int.tryParse(_ayatMulaiCtrl.text.trim());
    final selesai = int.tryParse(_ayatSelesaiCtrl.text.trim());
    final maxAyat = _currentMaxAyat;

    if (mulai == null ||
        selesai == null ||
        mulai < 1 ||
        selesai < mulai ||
        selesai > maxAyat) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rentang ayat tidak valid (maksimal $maxAyat ayat untuk surah ini).',
          ),
        ),
      );
      return;
    }

    final lastAyat = _lastAyatBySurah[_selectedSurahId!] ?? 0;

    // Validasi kelanjutan hafalan: jika bukan status mengulang dan mulai <= lastAyat
    if (lastAyat > 0 && _statusTajwid != 'mengulang' && mulai <= lastAyat) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.red,
          content: Text(
            'Ayat 1-$lastAyat sudah disetorkan sebelumnya. Silakan lanjutkan dari ayat ${lastAyat + 1} s/d $maxAyat, atau ubah status ke "Mengulang".',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiClient().dio.post(
        ApiEndpoints.setorans,
        data: {
          'santri_id': _selectedSantriId,
          'surah_id': _selectedSurahId,
          'ayat_mulai': mulai,
          'ayat_selesai': selesai,
          'status': _statusTajwid,
          'catatan': _catatanCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Perbarui progres hafalan lokal secara instan
      if (_statusTajwid != 'mengulang') {
        _lastAyatBySurah[_selectedSurahId!] = selesai;
      }

      // Jika setoran menuntaskan surah (ayat_selesai == maxAyat dan bukan mengulang)
      if (selesai >= maxAyat && _statusTajwid != 'mengulang') {
        _completedSurahIds.add(_selectedSurahId!);
      }

      // Tandai santri ini sudah setor hari ini
      if (_selectedSantriId != null) {
        _santriSudahSetorHariIniIds.add(_selectedSantriId!);
      }

      _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = 'Gagal menyimpan setoran.';
        if (e is DioException && e.response?.data?['message'] != null) {
          msg = e.response!.data['message'].toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.red, content: Text(msg)),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Setoran Tersimpan di Server!',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hafalan $_selectedSantriName untuk surah $_selectedSurahName (Ayat ${_ayatMulaiCtrl.text}-${_ayatSelesaiCtrl.text}) berhasil tercatat di database MySQL.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Lihat di Riwayat Setoran',
              icon: Icons.history,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RiwayatSetoranScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _autoAdjustSelectedSurah();
              },
              child: Text(
                'Lanjut Input Santri Lain',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
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
    final maxAyat = _currentMaxAyat;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Input Setoran Hafalan',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kelas Picker
            AppTextField(
              label: 'PILIH KELAS / ROMBEL',
              hint: _selectedKelasName,
              readOnly: true,
              suffixIcon: const Icon(Icons.expand_more, color: AppColors.sub),
              onTap: _showKelasPicker,
            ),
            const SizedBox(height: 14),

            // Santri Picker
            AppTextField(
              label: 'PILIH SANTRI',
              hint: _selectedSantriName,
              readOnly: true,
              suffixIcon: const Icon(Icons.expand_more, color: AppColors.sub),
              onTap: _showSantriPicker,
            ),
            if (_selectedSantriId != null && _santriSudahSetorHariIniIds.contains(_selectedSantriId)) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Santri ini sudah setor hari ini (bisa setor lagi jika ada tambahan)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // Surah Picker
            AppTextField(
              label: 'PILIH SURAH',
              hint: _selectedSurahName,
              readOnly: true,
              suffixIcon: _isLoadingHistory
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.expand_more, color: AppColors.sub),
              onTap: _showSurahPicker,
              helperText: _isLoadingHistory
                  ? 'Memeriksa riwayat hafalan santri...'
                  : (_completedSurahIds.isNotEmpty
                      ? '${_completedSurahIds.length} surah telah diselesaikan oleh santri ini'
                      : null),
            ),
            const SizedBox(height: 12),

            // Indikator Progres Terakhir Surah Terpilih
            if (_selectedSurahId != null) ...[
              Builder(
                builder: (context) {
                  final lastAyat = _lastAyatBySurah[_selectedSurahId!] ?? 0;
                  final hasPrev = lastAyat > 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: hasPrev
                          ? AppColors.primaryPale
                          : AppColors.border.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasPrev
                            ? AppColors.primary.withValues(alpha: 0.35)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasPrev
                              ? Icons.bookmark_added_rounded
                              : Icons.info_outline,
                          size: 16,
                          color: hasPrev ? AppColors.primary : AppColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasPrev
                                ? 'Hafalan terakhir santri: Ayat 1-$lastAyat (Lanjut otomatis ayat ${lastAyat + 1} s/d $maxAyat)'
                                : 'Setoran awal surah ini: Ayat 1 s/d $maxAyat',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hasPrev
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],

            // Ayat Mulai & Selesai
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'AYAT MULAI',
                    hint: '1',
                    controller: _ayatMulaiCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _onAyatMulaiChanged,
                    helperText: (_selectedSurahId != null &&
                            (_lastAyatBySurah[_selectedSurahId!] ?? 0) > 0)
                        ? 'Lanjut ayat ${(_lastAyatBySurah[_selectedSurahId!]! + 1)}'
                        : 'Min. 1',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'AYAT SELESAI',
                    hint: '$maxAyat',
                    controller: _ayatSelesaiCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _onAyatSelesaiChanged,
                    helperText: 'Maks. $maxAyat ayat',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Kelancaran Selector
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
              hint: 'Tulis makhraj/mad yang perlu diperhatikan santri...',
              controller: _catatanCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              label: 'SIMPAN KE DATABASE MYSQL',
              icon: Icons.cloud_upload_outlined,
              isLoading: _isLoading,
              onPressed: _handleSubmit,
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
