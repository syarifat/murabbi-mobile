import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

void showPrivacyPolicyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kebijakan Privasi',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Perlindungan Privasi & Keamanan Data',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark),
            ),
            const SizedBox(height: 6),
            Text(
              'Murobbi-Qu berkomitmen untuk menjaga keamanan dan kerahasiaan data pribadi pengguna, siswa, serta guru dengan standar keamanan terbaik.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            _buildPolicyPoint('1. Pengumpulan Data', 'Data yang dikumpulkan mencakup nama akun, alamat email, data akademik siswa, dan riwayat setoran hafalan semata-mata untuk keperluan pelaporan pendidikan.'),
            const SizedBox(height: 8),
            _buildPolicyPoint('2. Keamanan Jaringan', 'Seluruh pengiriman data antara aplikasi dan server diamankan dengan protokol enkripsi modern (HTTPS/TLS).'),
            const SizedBox(height: 8),
            _buildPolicyPoint('3. Tidak Ada Pihak Ketiga', 'Data siswa dan orang tua tidak pernah diperjualbelikan atau dibagikan kepada pihak ketiga di luar pihak sekolah/lembaga.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Tutup',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPolicyPoint(String title, String desc) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark),
      ),
      const SizedBox(height: 2),
      Text(
        desc,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted, height: 1.3),
      ),
    ],
  );
}

void showHelpSupportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bantuan & Dukungan',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Butuh bantuan terkait akun atau sinkronisasi data?',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          _buildContactRow(Icons.email_outlined, 'Email Support', 'support.murobbiqu@gmail.com'),
          const SizedBox(height: 10),
          _buildContactRow(Icons.chat_outlined, 'WhatsApp Admin', '+62 812-3456-7890'),
          const SizedBox(height: 10),
          _buildContactRow(Icons.schedule_outlined, 'Jam Layanan', 'Senin - Jumat (08:00 - 16:00 WIB)'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Tutup',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}

Widget _buildContactRow(IconData icon, String label, String val) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
            Text(val, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark)),
          ],
        ),
      ),
    ],
  );
}
