import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class AppDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? initial;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.initial,
  });
}

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String hint;
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData? leadIcon;
  final Color? leadIconColor;
  final bool enabled;
  final String? disabledHint;
  final String? helperText;
  final Color? helperTextColor;
  final bool isRequired;

  const AppDropdown({
    super.key,
    this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.leadIcon,
    this.leadIconColor,
    this.enabled = true,
    this.disabledHint,
    this.helperText,
    this.helperTextColor,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasMatch = value != null && items.any((it) => it.value == value);
    final effectiveValue = hasMatch ? value : null;
    final primaryTheme = leadIconColor ?? AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: GoogleFonts.inter(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              if (isRequired)
                const Text(' *', style: TextStyle(color: AppColors.red, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: !enabled
                ? const Color(0xFFF1F5F9)
                : (effectiveValue != null ? Colors.white : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: !enabled
                  ? const Color(0xFFE2E8F0)
                  : (effectiveValue != null
                      ? primaryTheme.withValues(alpha: 0.5)
                      : AppColors.border),
              width: effectiveValue != null ? 1.5 : 1.0,
            ),
            boxShadow: effectiveValue != null
                ? [
                    BoxShadow(
                      color: primaryTheme.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: effectiveValue,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: Colors.white,
              elevation: 6,
              menuMaxHeight: 320,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: enabled ? primaryTheme.withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled ? primaryTheme : AppColors.muted,
                  size: 18,
                ),
              ),
              hint: Row(
                children: [
                  if (leadIcon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: primaryTheme.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(leadIcon, size: 14, color: primaryTheme),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      enabled ? hint : (disabledHint ?? hint),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              selectedItemBuilder: items.isEmpty
                  ? null
                  : (BuildContext ctx) {
                      return items.map<Widget>((item) {
                        final color = item.iconColor ?? primaryTheme;
                        return Row(
                          children: [
                            if (item.initial != null) ...[
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Text(
                                  item.initial!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ] else if (item.icon != null || leadIcon != null) ...[
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(item.icon ?? leadIcon, size: 14, color: color),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                item.label,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
              items: items.map((item) {
                final isSelected = item.value == effectiveValue;
                final color = item.iconColor ?? primaryTheme;

                return DropdownMenuItem<T>(
                  value: item.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        if (item.initial != null) ...[
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: isSelected ? color : color.withValues(alpha: 0.12),
                            child: Text(
                              item.initial!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ] else if (item.icon != null || leadIcon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected ? color : color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.icon ?? leadIcon,
                              size: 15,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.label,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? color : AppColors.dark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded, size: 18, color: color),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
        if (helperText != null && helperText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: helperTextColor ?? AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
