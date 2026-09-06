import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

enum BadgeVariant { success, warning, danger, neutral, blue }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.success,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (variant) {
      case BadgeVariant.success:
        bg = AppColors.primaryPale;
        border = AppColors.primaryLight;
        text = AppColors.primary;
        break;
      case BadgeVariant.warning:
        bg = AppColors.goldPale;
        border = const Color(0xFFFDE68A);
        text = AppColors.gold;
        break;
      case BadgeVariant.danger:
        bg = AppColors.redPale;
        border = const Color(0xFFFECACA);
        text = AppColors.red;
        break;
      case BadgeVariant.blue:
        bg = AppColors.bluePale;
        border = const Color(0xFFBFDBFE);
        text = AppColors.blue;
        break;
      case BadgeVariant.neutral:
        bg = const Color(0xFFF1F5F9);
        border = AppColors.border;
        text = AppColors.muted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
