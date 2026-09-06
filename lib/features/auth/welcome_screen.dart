// welcome_screen.dart
// Identical Flutter implementation of Figma 0A. Welcome Screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top & Body Content Group
                      Column(
                        children: [
                          const SizedBox(height: 8),

                          // Top Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPale,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'PLATFORM MUTABA\'AH TAHFIDZ',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Hero Visual Showcase Card
                          Container(
                            width: double.infinity,
                            height: 235,
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B), // Deep Emerald Forest
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Concentric Glow Ring Outer
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF047857).withValues(alpha: 0.25),
                                  ),
                                ),

                                // Concentric Glow Ring Mid
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                  ),
                                ),

                                // Central Emblem
                                Container(
                                  width: 96,
                                  height: 96,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF34D399), width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                // Floating Badge 1 (Top Left)
                                Positioned(
                                  top: 18,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(17),
                                      border: Border.all(color: const Color(0xFF10B981)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          '30 Juz Mutaba\'ah',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Floating Badge 2 (Bottom Right)
                                Positioned(
                                  bottom: 18,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(17),
                                      border: Border.all(color: const Color(0xFFF59E0B)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          '1,250+ Santri Aktif',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // App Branding & Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'MURABBI',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.dark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bimbing Generasi Qur\'ani Lebih Mudah & Terpantau',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Satu aplikasi terpadu untuk Ustadz mencatat setoran, Orang Tua memantau progres harian, dan Sekolah mengelola mutaba\'ah secara real-time.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3 Value Capsules
                          Row(
                            children: [
                              Expanded(
                                child: _buildCapsule(
                                  icon: Icons.mic_rounded,
                                  title: 'Setoran',
                                  subtitle: 'Real-time',
                                  bgColor: AppColors.primaryPale,
                                  borderColor: const Color(0xFFA7F3D0),
                                  iconColor: AppColors.primary,
                                  titleColor: const Color(0xFF065F46),
                                  subtitleColor: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCapsule(
                                  icon: Icons.trending_up_rounded,
                                  title: 'Progres',
                                  subtitle: '30 Juz',
                                  bgColor: AppColors.goldPale,
                                  borderColor: const Color(0xFFFDE68A),
                                  iconColor: AppColors.gold,
                                  titleColor: const Color(0xFF92400E),
                                  subtitleColor: AppColors.gold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCapsule(
                                  icon: Icons.notifications_active_rounded,
                                  title: 'Notifikasi',
                                  subtitle: 'Wali Murid',
                                  bgColor: AppColors.bluePale,
                                  borderColor: const Color(0xFFBFDBFE),
                                  iconColor: AppColors.blue,
                                  titleColor: const Color(0xFF1E40AF),
                                  subtitleColor: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Bottom Actions Group
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          // Primary Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 0,
                                shadowColor: AppColors.primary.withValues(alpha: 0.3),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Mulai Sekarang',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Secondary Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.login_rounded, color: AppColors.mid, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Sudah Punya Akun? Masuk',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.mid,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Footer Tag
                          Text(
                            'Murabbi v1.0 · Sekolah Digital Ecosystem',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.sub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCapsule({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
